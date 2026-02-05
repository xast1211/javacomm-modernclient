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

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final WebSocketService webSocketService;
  
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
    // 2. Fetch RSA Public Key
    final rsaPem = await remoteDataSource.getRsaPublicKey();
    final rsaPublicKey = CryptoUtil.parsePublicKeyFromPem(rsaPem);

    // 3. Fetch One-Time Token
    final oneTimeToken = (await remoteDataSource.getToken()).trim();
    print('OneTime Token: "$oneTimeToken"');

    // 4. Generate AES Key
    _transactionAESKey = CryptoUtil.createAESKey();

    // 5. Create Token (Identity Payload)
    final token = Token(
      userid: userid ?? email, 
      email: email,
      password: password,
      aes: CryptoUtil.base64FromAES(_transactionAESKey!),
      onetime: oneTimeToken,
    );
    
    print('Token JSON for Encryption: $token'); 

    // 6. Encrypt Identity with RSA
    final encryptedIdentity = CryptoUtil.encryptRSA(token.toString(), rsaPublicKey);
    print('Encrypted Identity (First 50 chars): ${encryptedIdentity.substring(0, min(50, encryptedIdentity.length))}...');

    // 7. Connect WebSocket
    final wsUrl = Uri(
      scheme: ApiConstants.scheme == 'https' ? 'wss' : 'ws',
      host: ApiConstants.domain,
      path: ApiConstants.wsContextPath,
    ).toString(); 
    
    // Prepare to listen for Handshake BEFORE sending
    final completer = Completer<Map<String, dynamic>>();
    StreamSubscription? subscription;

    subscription = webSocketService.messages.listen((message) {
      // DEBUG: Log ALL incoming messages
      print('WS Message received: Header=${message.header}, Command=${message.command}');
        if (message.command == Command.USRLOGIN) {
            if (message.header == Header.CONFIRM) {
                print('WebSocket Login Confirmed!');
                
                // Extract data from DATASET
                String? sessionId;
                String? authoritativeUserId;
                String? nickname;
                int? foregroundColor;
                int? backgroundColor;

                if (message is UsrLogin) {
                     sessionId = message.session;
                     nickname = message.nickname;
                     foregroundColor = message.foregroundColor;
                     backgroundColor = message.backgroundColor;
                     
                     print('Session ID received: $sessionId');
                     print('Nickname received: $nickname');
                     print('Colors received: FG=$foregroundColor, BG=$backgroundColor');
                     
                     // Fix: IDENTITY is inside DATASET, not top-level
                     final identityEncrypted = message.dataset['IDENTITY'] as String?;
                     
                     // Decrypt Identity to get authoritative UUID
                     if (identityEncrypted != null && _transactionAESKey != null) {
                        try {
                           print('Attempting decryption. Identity length: ${identityEncrypted.length}');
                           final decryptedBytes = CryptoUtil.decryptAESBytes(identityEncrypted, _transactionAESKey!);
                           
                           // Decode with allowMalformed to prevent crash on garbage bytes
                           String decryptedString = utf8.decode(decryptedBytes, allowMalformed: true);
                           // REMOVED UNSAFE PRINT: print('Decrypted String (Raw): ...');
                           
                           // Sanitize: Extract JSON object only
                           final startIndex = decryptedString.indexOf('{');
                           final endIndex = decryptedString.lastIndexOf('}');
                           
                           if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
                               decryptedString = decryptedString.substring(startIndex, endIndex + 1);
                               print('Sanitized JSON length: ${decryptedString.length}');
                           }
                           
                           final tokenMap = jsonDecode(decryptedString);
                           final token = Token.fromJson(tokenMap);
                           authoritativeUserId = token.userid;
                           print('Decrypted Authoritative UserID: $authoritativeUserId');
                           
                           if (authoritativeUserId == null) {
                             throw Exception('Decrypted token contains null USERID.');
                           }
                        } catch (e, stack) {
                           print('Failed to decrypt identity: $e');
                           // print(stack); // Stack trace is fine, but exception msg might contain binary if referenced
                           
                           // Fail loudly if we found identity but couldn't decrypt
                           if (!completer.isCompleted) {
                              completer.completeError('Decryption Failed: $e');
                           }
                           return;
                        }
                     } else {
                        print('Missing Identity in DATASET or AES Key.');
                     }
                }
                
                if (!completer.isCompleted) {
                   completer.complete({
                     'sessionId': sessionId,
                     'userid': authoritativeUserId,
                     'nickname': nickname,
                     'foregroundColor': foregroundColor,
                     'backgroundColor': backgroundColor,
                   });
                }
            } else if (message.header == Header.ERROR) {
                 print('WebSocket Login Failed: ERROR header received');
                 if (!completer.isCompleted) completer.completeError('Login Failed: Server returned ERROR');
            }
        }
    });

    try {
        await webSocketService.connect(wsUrl);
        
        print('WebSocket connected. Preparing USRLOGIN...');
        print('AGENT: ${_getPlatformAgent()}');
        print('Identifying as: $email');

        // 8. Send USRLOGIN
        final usrLogin = UsrLogin(
        header: Header.REQUEST,
        command: Command.USRLOGIN,
        dataset: {
            'AGENT': _getPlatformAgent(), 
            'IDENTITY': encryptedIdentity,
        },
        );
        
        webSocketService.sendMessage(usrLogin);

        // Wait for response with timeout
        return await completer.future.timeout(const Duration(seconds: 10), onTimeout: () {
            throw TimeoutException('Login Handshake timed out');
        });
    } catch (e) {
        rethrow;
    } finally {
        await subscription?.cancel();
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
    final updateUserMsg = UpdateUser(
      dataset: UpdateUserDataset(
        identity: encryptedIdentity,
        nickname: nickname,
        foregroundColor: effectiveForegroundColor,
        backgroundColor: effectiveBackgroundColor,
        language: language,
      ),
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
        const Duration(seconds: 5),
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
}
