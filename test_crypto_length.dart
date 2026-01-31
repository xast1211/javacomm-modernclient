import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_client/core/utils/crypto_util.dart';
import 'package:encrypt/encrypt.dart';

void main() {
  final key = CryptoUtil.createAESKey();
  final plainText = "test";
  
  // Encrypt
  final encryptedBase64 = CryptoUtil.encryptAES(plainText, key);
  final encryptedBytes = base64.decode(encryptedBase64);
  
  print('Plaintext length: ${plainText.length}');
  print('Encrypted bytes total length: ${encryptedBytes.length}');
  print('Expected length: 12 (IV) + 4 (Ciphertext) + 16 (Tag) = 32 bytes');
  
  if (encryptedBytes.length == 32) {
    print('SUCCESS: Length matches expected GCM format with 128-bit tag.');
  } else {
    print('FAILURE: Length mismatch!');
    print('IV length: 12');
    print('Remaining bytes: ${encryptedBytes.length - 12}');
  }
}
