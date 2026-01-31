import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  
  static const String KEY_EMAIL = 'biometric_email';
  static const String KEY_PASSWORD = 'biometric_password';

  Future<bool> get isBiometricAvailable async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await auth.authenticate(
        localizedReason: 'Bitte authentifiziere dich, um dich anzumelden',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      return false;
    }
  }
  
  Future<void> saveCredentials(String email, String password) async {
    await storage.write(key: KEY_EMAIL, value: email);
    await storage.write(key: KEY_PASSWORD, value: password);
  }
  
  Future<Map<String, String>?> getCredentials() async {
    final email = await storage.read(key: KEY_EMAIL);
    final password = await storage.read(key: KEY_PASSWORD);
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }
  
  Future<void> clearCredentials() async {
    await storage.delete(key: KEY_EMAIL);
    await storage.delete(key: KEY_PASSWORD);
  }
}
