import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart' as pc;

class CryptoUtil {
  static const int ivLength = 12; // 12 bytes for GCM

  /// Generates a random 128-bit AES key.
  static Key createAESKey() {
      final secureRandom = pc.SecureRandom('Fortuna')
      ..seed(pc.KeyParameter(
          Uint8List.fromList(List.generate(32, (_) => Random.secure().nextInt(255)))));
      
    final keyBytes = secureRandom.nextBytes(16); // 128 bits
    return Key(keyBytes);
  }

  /// Encrypts data using AES/GCM/NoPadding.
  /// Returns Base64 encoded string containing [IV + EncryptedData].
  static String encryptAES(String plainText, Key key) {
    final iv = IV.fromLength(ivLength); // Random IV
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm, padding: null));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    // Combine IV + Ciphertext (ignoring Auth Tag issue for a moment, encrypt package GCM handles tag usually appended)
    // Java code: combined = iv + encryptedBytes
    // Package encrypt: encrypted.bytes usually includes tag? Need to verify specific GCM behavior.
    // Standard GCM: Ciphertext + Tag. 
    // Java's GCM implementation outputs Ciphertext + Tag.
    // Encrypter.encrypt returns Encrypted object. generic implementation.
    
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setAll(0, iv.bytes);
    combined.setAll(iv.bytes.length, encrypted.bytes);

    return base64.encode(combined);
  }

  /// Decrypts Base64 encoded string [IV + EncryptedData] using AES/GCM/NoPadding.
  /// Returns the decrypted String.
  static String decryptAES(String encryptedBase64, Key key) {
    final bytes = decryptAESBytes(encryptedBase64, key);
    return utf8.decode(bytes, allowMalformed: true); 
  }

  /// Decrypts Base64 encoded string [IV + EncryptedData] and returns raw bytes.
  static List<int> decryptAESBytes(String encryptedBase64, Key key) {
    final decoded = base64.decode(encryptedBase64);
    
    final ivBytes = decoded.sublist(0, ivLength);
    final cipherBytes = decoded.sublist(ivLength);
    
    final iv = IV(ivBytes);
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm, padding: null));
    
    final encrypted = Encrypted(cipherBytes);
    return encrypter.decryptBytes(encrypted, iv: iv);
  }
  
  /// Encrypts data using RSA/ECB/PKCS1Padding.
  static String encryptRSA(String plainText, pc.RSAPublicKey publicKey) {
    final encrypter = Encrypter(RSA(publicKey: publicKey, encoding: RSAEncoding.PKCS1));
    return encrypter.encrypt(plainText).base64;
  }

  /// Parses a PEM formatted Public Key string to RSAPublicKey
  static pc.RSAPublicKey parsePublicKeyFromPem(String pemString) {
    final parser = RSAKeyParser();
    // JChat returns clean Base64 or PEM?
    // Crypto.java: loadPublicRSAKey takes Base64 string of X.509
    // RSAKeyParser expects PEM format usually (-----BEGIN PUBLIC KEY-----).
    // If we get raw Base64, we might need to wrap it.
    
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
