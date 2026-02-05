import 'dart:ui'; // For PlatformDispatcher
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/theme_repository.dart';

class LanguageCubit extends Cubit<Locale> {
  final ThemeRepository _themeRepository;
  String? _userId;

  LanguageCubit({
    required ThemeRepository themeRepository,
  })  : _themeRepository = themeRepository,
        super(const Locale('de')); // Initial placeholder

  Future<void> loadSavedLanguage({String? userId}) async {
    _userId = userId;
    print('LanguageCubit: Loading language. UserId: $userId');

    // 1. Try server if logged in
    if (userId != null) {
      final serverLang = await _themeRepository.fetchUserLanguage(userId);
      print('LanguageCubit: Server returned: $serverLang');
      if (serverLang != null && _isValidLocale(serverLang)) {
        print('LanguageCubit: Applying server language: $serverLang');
        emit(Locale(serverLang));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('language_code', serverLang);
        return;
      }
    }
    
    // 2. Local Storage
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');
    
    if (languageCode != null) {
      emit(Locale(languageCode));
    } else {
      // 3. System Fallback
      final systemLocale = PlatformDispatcher.instance.locale;
      if (_isValidLocale(systemLocale.languageCode)) {
         emit(Locale(systemLocale.languageCode));
      } else {
         emit(const Locale('de'));
      }
    }
  }

  Future<void> changeLanguage(Locale locale) async {
    emit(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    
    // Server persist if logged in
    final userId = _userId;
    if (userId != null) {
       print('LanguageCubit: Saving language ${locale.languageCode} for user $userId to server...');
       final success = await _themeRepository.updateUserLanguage(userId, locale.languageCode);
       if (success) {
          print('LanguageCubit: Server updated successfully.');
       } else {
          print('LanguageCubit: Server update failed.');
       }
    }
  }

  bool _isValidLocale(String code) {
    return ['de', 'en', 'es'].contains(code);
  }
}
