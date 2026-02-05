import '../../data/models/signin_response.dart';

abstract class AuthRepository {
  Future<SignInResponse> signIn(String email, String password, String lang);
  Future<String> getRsaPublicKey();
  Future<String> getToken();
  Future<void> updateProfile(String userId, {String? nickname, String? email, String? password, int? foregroundColor, int? backgroundColor, String? language});
  Future<void> disconnect();
  Future<void> register(String email);
  Stream<SignInResponse> get userUpdates;
}
