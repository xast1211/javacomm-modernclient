
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/theme/theme_cubit.dart'; // For AppThemeType

class ThemeRepository {
  
  // Mapping from Server (Helado) to Flutter (AppThemeType)
  static const Map<String, AppThemeType> _serverToLocalMap = {
    'Moca': AppThemeType.mokka,
    'Vainilla': AppThemeType.vanille,
    'Yogur': AppThemeType.joghurt,
    'Arando': AppThemeType.blaubeere,
    'Fresa': AppThemeType.erdbeere,
    'Limón': AppThemeType.zitrone,
  };

  // Mapping from Flutter (AppThemeType) to Server (Helado)
  static const Map<AppThemeType, String> _localToServerMap = {
    AppThemeType.mokka: 'Moca',
    AppThemeType.vanille: 'Vainilla',
    AppThemeType.joghurt: 'Yogur',
    AppThemeType.blaubeere: 'Arando',
    AppThemeType.erdbeere: 'Fresa',
    AppThemeType.zitrone: 'Limón',
  };

  Future<AppThemeType?> fetchUserTheme(String userId) async {
    final url = Uri.parse('${ApiConstants.restBaseUrl}${ApiConstants.readUserData}/$userId');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final userMap = data[0];
          // print('DEBUG: User Data Keys: ${userMap.keys.toList()}'); 
          final helado = userMap['helado'] as String?;
          if (helado != null) {
            return _serverToLocalMap[helado];
          }
        }
      } else {
        print('Failed to fetch theme: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching theme: $e');
    }
    return null;
  }

  Future<bool> updateUserTheme(String userId, AppThemeType theme) async {
    final url = Uri.parse('${ApiConstants.restBaseUrl}${ApiConstants.writeTheme}');
    final helado = _localToServerMap[theme];
    
    if (helado == null) return false;

    try {
      final response = await http.post(
        url,
        body: {
          'userid': userId,
          'eis': helado,
        },
      );

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Error updating theme: $e');
      return false;
    }
  }

  Future<String?> fetchUserLanguage(String userId) async {
    final url = Uri.parse('${ApiConstants.restBaseUrl}${ApiConstants.readUserData}/$userId');
    print('ThemeRepo: Fetching language for $userId from $url');
    try {
      final response = await http.get(url);
      print('ThemeRepo: Fetch response ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final userMap = data[0];
          final lang = userMap['language'] as String?;
          print('ThemeRepo: Parsed language: $lang');
          return lang;
        }
      } 
    } catch (e) {
      print('ThemeRepo: Error fetching language: $e');
    }
    return null;
  }

  Future<bool> updateUserLanguage(String userId, String languageCode) async {
    // New Endpoint: PUT /javacommserver/user/write/language/{language}/{userid}
    // Server expects Lowercase Enum (de, en, es) - verified in Language.java
    final url = Uri.parse('${ApiConstants.restBaseUrl}${ApiConstants.writeLanguage}/${languageCode.toLowerCase()}/$userId');
    print('ThemeRepo: Updating language for $userId to ${languageCode.toLowerCase()} via $url');
    try {
      final response = await http.put(
        url,
        headers: {
           'Content-Type': 'text/plain', // PUT usually requires content-type even if body is empty? Or maybe not.
           // Server produces text/plain, maybe consumes nothing? JAX-RS path params usually don't need body.
        },
      );
      print('ThemeRepo: Update response ${response.statusCode}');

      // Returns 200 or 204. Server returns the language enum as string.
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('ThemeRepo: Error updating language: $e');
      return false;
    }
  }
}
