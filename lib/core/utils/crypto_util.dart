import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart'; // Keep for Key class and RSA key structure
import 'package:pointycastle/export.dart' as pc;

class CryptoUtil {
  static const int ivLength = 12; // 12 bytes for GCM
  static const int macSize = 128; // 128 bits = 16 bytes

  /// Generates a random 128-bit AES key.
  static Key createAESKey() {
    final secureRandom = _getSecureRandom();
    final keyBytes = secureRandom.nextBytes(16); // 128 bits
    return Key(keyBytes);
  }
  
  static pc.SecureRandom _getSecureRandom() {
    final secureRandom = pc.SecureRandom('Fortuna')
      ..seed(pc.KeyParameter(
          Uint8List.fromList(List.generate(32, (_) => Random.secure().nextInt(255)))));
    return secureRandom;
  }

  /// Encrypts data using AES/GCM/NoPadding.
  /// Returns Base64 encoded string containing [IV + EncryptedData + AuthTag].
  static String encryptAES(String plainText, Key key) {
    final secureRandom = _getSecureRandom();
    final iv = secureRandom.nextBytes(ivLength);

    final cipher = pc.GCMBlockCipher(pc.AESEngine());
    // PointyCastle AEADParameters: (KeyParameter, macSize in BITS, nonce, associatedData)
    final params = pc.AEADParameters(
      pc.KeyParameter(key.bytes), 
      macSize, 
      iv, 
      Uint8List(0) // Empty AAD
    );

    cipher.init(true, params); // true = encrypt
    
    final input = utf8.encode(plainText);
    final output = cipher.process(Uint8List.fromList(input)); // Output includes Ciphertext + Mac

    // Combine IV + Output (Ciphertext + Mac)
    final combined = Uint8List(iv.length + output.length);
    combined.setAll(0, iv);
    combined.setAll(iv.length, output);

    return base64.encode(combined);
  }

  /// Decrypts Base64 encoded string [IV + EncryptedData + AuthTag] using AES/GCM/NoPadding.
  /// Returns the decrypted String.
  static String decryptAES(String encryptedBase64, Key key) {
    final bytes = decryptAESBytes(encryptedBase64, key);
    return utf8.decode(bytes, allowMalformed: true);
  }

  /// Decrypts Base64 encoded string [IV + EncryptedData + AuthTag] and returns raw bytes.
  static List<int> decryptAESBytes(String encryptedBase64, Key key) {
    if (encryptedBase64.isEmpty) return [];
    final decoded = base64.decode(encryptedBase64);
    
    // Check reasonable length: IV (12) + Tag (16) = 28 bytes minimum
    if (decoded.length < ivLength + (macSize ~/ 8)) {
       // Just proceed, let pointycaste throw if invalid
    }

    final ivBytes = decoded.sublist(0, ivLength);
    final cipherTextWithTag = decoded.sublist(ivLength);
    
    final cipher = pc.GCMBlockCipher(pc.AESEngine());
    final params = pc.AEADParameters(
      pc.KeyParameter(key.bytes), 
      macSize, 
      ivBytes, 
      Uint8List(0) // Empty AAD
    );

    cipher.init(false, params); // false = decrypt
    
    return cipher.process(cipherTextWithTag);
  }
  
  /// Encrypts data using RSA/ECB/PKCS1Padding.
  static String encryptRSA(String plainText, pc.RSAPublicKey publicKey) {
    final encrypter = Encrypter(RSA(publicKey: publicKey, encoding: RSAEncoding.PKCS1));
    return encrypter.encrypt(plainText).base64;
  }

  /// Parses a PEM formatted Public Key string to RSAPublicKey
  static pc.RSAPublicKey parsePublicKeyFromPem(String pemString) {
    final parser = RSAKeyParser();
    
    String formattedPem = pemString;
    if (!pemString.contains('-----BEGIN PUBLIC KEY-----')) {
        formattedPem = '-----BEGIN PUBLIC KEY-----\n$pemString\n-----END PUBLIC KEY-----';
    }
    
    return parser.parse(formattedPem) as pc.RSAPublicKey;
  }
  
  static String base64FromAES(Key key) {
    return base64.encode(key.bytes);
  }
}
