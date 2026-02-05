import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';


abstract class AuthRemoteDataSource {
  Future<String> getRsaPublicKey();
  Future<String> getToken();
  Future<void> registerUser(String email, String lang);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSourceImpl({required this.client});



  @override
  Future<String> getRsaPublicKey() async {
    final url = Uri.parse('${ApiConstants.restBaseUrl}${ApiConstants.readRsa}');
    print('Fetching RSA Key from: $url');
    final response = await client.get(
      url,
      headers: {
        'Accept': 'text/plain',
        // 'Content-Type': 'text/plain' // Not needed for GET
      },
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to get RSA key: ${response.statusCode}');
    }
  }

  @override
  Future<String> getToken() async {
    final url = Uri.parse('${ApiConstants.restBaseUrl}${ApiConstants.readToken}');
    final response = await client.post( // JChat uses POST for readToken
      url,
      headers: {
        'Accept': 'text/plain',
        'Content-Type': 'text/plain', // If sending empty body, might default to logic
      },
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to get token: ${response.statusCode}');
    }
  }

  @override
  Future<void> registerUser(String email, String lang) async {
    final url = Uri.parse('${ApiConstants.restBaseUrl}${ApiConstants.signin}');
    print('Sending Registration Request to: $url');
    
    final response = await client.post(
      url,
      body: {
        'email': email,
        'lang': lang,
        'webconfirm': 'false',
      },
    );

    if (response.statusCode == 200) {
      print('Registration successful');
      return;
    } else {
      throw Exception('Registration failed: ${response.statusCode}');
    }
  }
}
