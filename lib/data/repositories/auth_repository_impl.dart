import 'dart:async';
import 'dart:convert';
import 'dart:math';
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

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final WebSocketService webSocketService;
  
  // Storage for session keys
  encrypt.Key? _transactionAESKey;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.webSocketService,
  });

  @override
  Future<SignInResponse> signIn(String email, String password, String lang) async {
       print('Starting WebSocket handshake for $email...'); 
       final result = await _performWebSocketLogin(email, password, userid: email);
       final sessionId = result['sessionId'];
       final userId = result['userid'] ?? email; // Fallback to email if decode fails (shouldn't happen)

       return SignInResponse(
           header: 'CONFIRM',
           userid: userId!, 
           email: email,
           password: password,
           sessionId: sessionId,
       );
  }
  
  Future<void> connectAndLogin(String userid, String password, String email) async {
      await _performWebSocketLogin(email, password, userid: userid);
  }

  Future<Map<String, String?>> _performWebSocketLogin(String email, String password, {String? userid}) async {
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
    final completer = Completer<Map<String, String?>>();
    StreamSubscription? subscription;

    subscription = webSocketService.messages.listen((message) {
        if (message.command == Command.USRLOGIN) {
            if (message.header == Header.CONFIRM) {
                print('WebSocket Login Confirmed!');
                
                // Extract Session ID from DATASET
                String? sessionId;
                String? authoritativeUserId;

                if (message is UsrLogin) {
                     sessionId = message.dataset['SESSION'] as String?;
                     print('Session ID received: $sessionId');
                     
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
                     'userid': authoritativeUserId
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

        // 8. Send USRLOGIN
        final usrLogin = UsrLogin(
        header: Header.REQUEST,
        command: Command.USRLOGIN,
        dataset: {
            'AGENT': 'Browser', 
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
}
