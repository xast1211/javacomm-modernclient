import '../../data/models/signin_response.dart';

abstract class AuthRepository {
  Future<SignInResponse> signIn(String email, String password, String lang);
  Future<String> getRsaPublicKey();
  Future<String> getToken();
}
