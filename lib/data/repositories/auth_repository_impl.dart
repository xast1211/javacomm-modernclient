import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/asymmetric/api.dart'; // For RSAPublicKey

import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/signin_response.dart';
import '../../core/network/websocket_service.dart';
import '../../core/utils/crypto_util.dart';
import '../../core/constants/api_constants.dart';
import '../models/protocol/enums.dart';
import '../models/protocol/usrlogin.dart';
import '../models/protocol/token.dart';
import '../models/protocol/update_user.dart';
import '../models/protocol/protocol_request_factory.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final WebSocketService webSocketService;
  
  final _userUpdatesController = StreamController<SignInResponse>.broadcast();

  // Storage for session keys
  encrypt.Key? _transactionAESKey;
  
  // Store current user credentials for UPDATEUSER
  String? _currentUserId;
  String? _currentEmail;
  String? _currentPassword;
  int? _currentForegroundColor;
  int? _currentBackgroundColor;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.webSocketService,
  });

  @override
  Future<SignInResponse> signIn(String email, String password, String lang) async {
       print('Starting WebSocket handshake for $email...'); 
       final result = await _performWebSocketLogin(email, password, userid: email);
       final sessionId = result['sessionId'] as String?;
       final userId = result['userid'] as String? ?? email; // Fallback to email if decode fails
       final nickname = result['nickname'] as String?;
       final foregroundColor = result['foregroundColor'] as int?;
       final backgroundColor = result['backgroundColor'] as int?;
       
       // Store credentials for UPDATEUSER
       _currentUserId = userId;
       _currentEmail = email;
       _currentPassword = password;
       _currentForegroundColor = foregroundColor;
       _currentBackgroundColor = backgroundColor;

       return SignInResponse(
           header: 'CONFIRM',
           userid: userId, 
           email: email,
           nickname: nickname,
           password: password,
           sessionId: sessionId,
           foregroundColor: foregroundColor,
           backgroundColor: backgroundColor,
       );
  }
  
  Future<void> connectAndLogin(String userid, String password, String email) async {
      await _performWebSocketLogin(email, password, userid: userid);
  }

  Future<Map<String, dynamic>> _performWebSocketLogin(String email, String password, {String? userid}) async {
    // 1. Prepare Encrypted Identity
    final encryptedIdentity = await _prepareEncryptedIdentity(email, password, userid ?? email);
    print('Encrypted Identity (First 50 chars): ${encryptedIdentity.substring(0, min(50, encryptedIdentity.length))}...');

    // 2. Connect WebSocket
    final wsUrl = Uri(
      scheme: ApiConstants.scheme == 'https' ? 'wss' : 'ws',
      host: ApiConstants.domain,
      path: ApiConstants.wsContextPath,
    ).toString(); 
    
    // 3. Listen for Handshake
    final completer = Completer<Map<String, dynamic>>();
    StreamSubscription? subscription;

    subscription = webSocketService.messages.listen((message) {
      if (message.command == Command.USRLOGIN) {
          if (message.header == Header.CONFIRM && message is UsrLogin) {
              _handleLoginConfirm(message, completer);
          } else if (message.header == Header.ERROR) {
               print('WebSocket Login Failed: ERROR header received');
               if (!completer.isCompleted) completer.completeError('Login Failed: Server returned ERROR');
          }
      }
    });

    try {
        await webSocketService.connect(wsUrl);
        print('WebSocket connected. Sending USRLOGIN...');

        // 4. Send USRLOGIN
        final usrLogin = ProtocolRequestFactory.createLoginRequest(
          agent: _getPlatformAgent(), 
          encryptedIdentity: encryptedIdentity,
        );
        
        webSocketService.sendMessage(usrLogin);

        // 5. Wait for response
        return await completer.future.timeout(ApiConstants.loginTimeout, onTimeout: () {
            throw TimeoutException('Login Handshake timed out');
        });
    } catch (e) {
        rethrow;
    } finally {
        await subscription?.cancel();
    }
  }

  void _handleLoginConfirm(UsrLogin message, Completer<Map<String, dynamic>> completer) {
      print('WebSocket Login Confirmed!');
      
      String? authoritativeUserId;
      // Decrypt Identity to get authoritative UUID
      final identityEncrypted = message.dataset['IDENTITY'] as String?;
      
      if (identityEncrypted != null && _transactionAESKey != null) {
          try {
             authoritativeUserId = _decryptIdentity(identityEncrypted, _transactionAESKey!);
             print('Decrypted Authoritative UserID: $authoritativeUserId');
          } catch (e) {
             if (!completer.isCompleted) completer.completeError(e);
             return;
          }
      }

      if (!completer.isCompleted) {
         completer.complete({
           'sessionId': message.session,
           'userid': authoritativeUserId,
           'nickname': message.nickname,
           'foregroundColor': message.foregroundColor,
           'backgroundColor': message.backgroundColor,
         });
      }
  }

  Future<String> _prepareEncryptedIdentity(String email, String password, String userid) async {
    // Fetch RSA and Token
    final rsaPem = await remoteDataSource.getRsaPublicKey();
    final rsaPublicKey = CryptoUtil.parsePublicKeyFromPem(rsaPem);
    final oneTimeToken = (await remoteDataSource.getToken()).trim();

    // Generate AES Key
    _transactionAESKey = CryptoUtil.createAESKey();

    // Create Token
    final token = Token(
      userid: userid, 
      email: email,
      password: password,
      aes: CryptoUtil.base64FromAES(_transactionAESKey!),
      onetime: oneTimeToken,
    );
    
    return CryptoUtil.encryptRSA(token.toString(), rsaPublicKey);
  }

  String? _decryptIdentity(String encryptedIdentity, encrypt.Key aesKey) {
      try {
         final decryptedBytes = CryptoUtil.decryptAESBytes(encryptedIdentity, aesKey);
         String decryptedString = utf8.decode(decryptedBytes, allowMalformed: true);
         
         // Sanitize: Extract JSON object only
         final startIndex = decryptedString.indexOf('{');
         final endIndex = decryptedString.lastIndexOf('}');
         
         if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
             decryptedString = decryptedString.substring(startIndex, endIndex + 1);
         }
         
         final tokenMap = jsonDecode(decryptedString);
         final token = Token.fromJson(tokenMap);
         return token.userid;
      } catch (e) {
         throw Exception('Decryption Failed: $e');
      }
  }

  @override
  Future<String> getRsaPublicKey() {
    return remoteDataSource.getRsaPublicKey();
  }

  @override
  Future<String> getToken() {
     return remoteDataSource.getToken();
  }

  @override
  Future<void> updateProfile(String userId, {String? nickname, String? email, String? password, int? foregroundColor, int? backgroundColor, String? language}) async {
    print('=== UPDATEUSER DEBUG START ===');
    print('Input parameters:');
    print('  userId: $userId');
    print('  language: $language');
    print('  nickname: $nickname');
    print('  email: $email');
    print('  password: ${password != null ? "[${password.length} chars]" : "null"}');
    print('  foregroundColor: $foregroundColor');
    print('  backgroundColor: $backgroundColor');
    
    // Get current session AES key
    if (_transactionAESKey == null) {
      print('ERROR: No active session - AES key not available');
      throw Exception('No active session - AES key not available');
    }
    
    // Use stored credentials if not provided
    final effectiveEmail = email ?? _currentEmail;
    final effectivePassword = password ?? _currentPassword;
    
    print('Effective credentials:');
    print('  effectiveEmail: $effectiveEmail');
    print('  effectivePassword: ${effectivePassword != null ? "[${effectivePassword.length} chars]" : "null"}');
    
    // VALIDATION: Check required fields
    if (effectiveEmail == null || effectiveEmail.isEmpty) {
      print('ERROR: Email is required but is null or empty');
      throw Exception('Email is required for profile update');
    }
    
    if (effectivePassword == null || effectivePassword.isEmpty) {
      print('ERROR: Password is required but is null or empty');
      throw Exception('Password is required for profile update');
    }
    
    if (effectivePassword.length < 3) {
      print('ERROR: Password too short (${effectivePassword.length} chars, minimum 3)');
      throw Exception('Password must be at least 3 characters');
    }
    
    if (nickname != null && nickname.isNotEmpty) {
      // Basic nickname validation (alphanumeric + some special chars)
      final nicknamePattern = RegExp(r'^[a-zA-Z0-9_\-\.]+$');
      if (!nicknamePattern.hasMatch(nickname)) {
        print('ERROR: Nickname contains invalid characters: $nickname');
        throw Exception('Nickname contains invalid characters');
      }
    }
    
    print('Validation passed ✓');
    
    // Get current colors from stored sign-in response if not provided
    // Server requires non-null color values
    final effectiveForegroundColor = foregroundColor ?? _currentForegroundColor ?? -16777216; // Default black
    final effectiveBackgroundColor = backgroundColor ?? _currentBackgroundColor ?? -1; // Default white
    
    print('Effective colors:');
    print('  foregroundColor: $effectiveForegroundColor');
    print('  backgroundColor: $effectiveBackgroundColor');
    
    // FETCH FRESH ONETIME TOKEN (Requested by User)
    String? onetimeToken;
    try {
      print('Fetching fresh OneTime Token for UPDATEUSER...');
      onetimeToken = await remoteDataSource.getToken();
      print('Fresh OneTime Token: "$onetimeToken"');
    } catch (e) {
      print('ERROR fetching OneTime Token: $e');
      throw Exception('Failed to fetch required validation token');
    }

    // Create Token with userid, email, password AND onetime token
    final token = Token(
      userid: userId,
      email: effectiveEmail,
      password: effectivePassword,
      onetime: onetimeToken,
    );
    
    // Encrypt the token as IDENTITY
    final tokenJson = token.toString();
    print('Token JSON before encryption:');
    print(tokenJson);
    
    final encryptedIdentity = CryptoUtil.encryptAES(tokenJson, _transactionAESKey!);
    print('Encrypted IDENTITY length: ${encryptedIdentity.length}');
    print('Encrypted IDENTITY (first 50): ${encryptedIdentity.substring(0, encryptedIdentity.length > 50 ? 50 : encryptedIdentity.length)}...');
    
    // Construct UpdateUser message with DATASET containing all fields
    final updateUserMsg = ProtocolRequestFactory.createUpdateUserRequest(
      encryptedIdentity: encryptedIdentity,
      nickname: nickname,
      foregroundColor: effectiveForegroundColor,
      backgroundColor: effectiveBackgroundColor,
      language: language,
    );
    
    print('UpdateUser message created');
    print('Full message JSON:');
    final messageJson = jsonEncode(updateUserMsg.toJson());
    print(messageJson);
    print('=== UPDATEUSER DEBUG END ===');

    // Listen for server response
    final responseCompleter = Completer<void>();
    StreamSubscription? subscription;
    
    subscription = webSocketService.messages.listen((message) {
      // DEBUG: Log ALL incoming messages
      print('WS Message received: Header=${message.header}, Command=${message.command}');
      
      try {
        if (message.command == Command.UPDATEUSER) {
          if (message.header == Header.CONFIRM) {
            print('  ✅ Profile update CONFIRMED by server');
            if (nickname != null) {
               // Update nickname logic if needed
            }
            if (foregroundColor != null) _currentForegroundColor = foregroundColor;
            if (backgroundColor != null) _currentBackgroundColor = backgroundColor;
            
            // EMIT UPDATE
            _emitUserUpdate(
                nickname: nickname,
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
                language: language
            );
            
            if (!responseCompleter.isCompleted) {
              responseCompleter.complete();
            }
          } else if (message.header == Header.ERROR) {
             print('  ❌ Profile update ERROR from server');
             String errorText = 'Unknown error';
             if (!responseCompleter.isCompleted) {
                responseCompleter.completeError('Server returned ERROR');
             }
          }
        }
      } catch (e) {
        print('Error processing response: $e');
      }
    });

    // Send via WebSocket
    webSocketService.sendMessage(updateUserMsg);
    
    // Wait for response (with timeout)
    try {
      await responseCompleter.future.timeout(
        ApiConstants.updateProfileTimeout,
        onTimeout: () {
          print('⚠️ UPDATEUSER response timeout - no response from server');
          subscription?.cancel();
          throw TimeoutException('No response from server');
        },
      );
    } catch (e) {
      print('UPDATEUSER failed: $e');
      subscription?.cancel();
      rethrow;
    }
    
    // Update stored credentials if changed
    if (email != null) _currentEmail = email;
    if (password != null) _currentPassword = password;
  }
    // Note: The server likely sends a response (CONFIRM or ERROR), but JChat protocol is async.
    // For now, we fire and forget, but in a real app we might want to wait for confirmation.
    // JChat seems to wait for property change, which implies async confirmation.
    // We will handle confirmation in the BLoC by listening to the stream if needed, 
    // or just assume success if no error.
    // or just assume success if no error.
  
  @override
  Future<void> disconnect() async {
      webSocketService.disconnect();
      _transactionAESKey = null;
      _currentUserId = null;
      // ... clear other current user data if needed
  }

  /// Returns platform-specific agent string
  /// Web → 'Browser'
  /// Android/iOS → 'Smartphone'
  /// Windows/macOS/Linux → 'Desktop'
  /// Returns platform-specific agent string
  /// Web → 'Browser'
  /// Android/iOS → 'Smartphone'
  /// Windows/macOS/Linux → 'Desktop'
  String _getPlatformAgent() {
    if (kIsWeb) {
      return 'Browser';
    }
    // Use defaultTargetPlatform for non-web platforms
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return 'SmartPhone';
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'Desktop';
    }
  }

  @override
  Stream<SignInResponse> get userUpdates => _userUpdatesController.stream;

  void _emitUserUpdate({String? nickname, int? foregroundColor, int? backgroundColor, String? language}) {
      // Construct updated response from current stored state
      final response = SignInResponse(
          header: 'UPDATE', // Internal header
          userid: _currentUserId,
          email: _currentEmail,
          password: _currentPassword,
          nickname: nickname, // If null, consumer might keep old value, but here we should ideally have the full state. 
                              // Since we don't store nickname in class fields (only in the response which is in Bloc),
                              // we rely on the Bloc to merge, OR we should store nickname in Rep too.
                              // For now, let's pass what we have.
                              // Improvements: Store 'nickname' in AuthRepositoryImpl too.
          foregroundColor: foregroundColor ?? _currentForegroundColor,
          backgroundColor: backgroundColor ?? _currentBackgroundColor,
          // We need sessionId for the response object, but we don't store it in _current* vars besides maybe logic.
          // Let's rely on Bloc's copyWith for fields we don't send here? 
          // Actually, if we emit SignInResponse, we should try to be complete.
          // Refactor: Add _currentNickname, _currentSessionId to AuthRepositoryImpl.
          sessionId: null, // Bloc should handle merging if null
      );
      _userUpdatesController.add(response);
  }
}
