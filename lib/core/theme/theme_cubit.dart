import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/theme_repository.dart';
import 'app_theme.dart';

enum AppThemeType {
  mokka,
  vanille,
  joghurt,
  blaubeere,
  erdbeere,
  zitrone,
  system, // Default
}



class ThemeState {
  final AppThemeType type;
  final ThemeData themeData;

  ThemeState(this.type, this.themeData);
}

class ThemeCubit extends Cubit<ThemeState> {
  final ThemeRepository _themeRepository;
  String? _userId;

  ThemeCubit({ThemeRepository? themeRepository}) 
      : _themeRepository = themeRepository ?? ThemeRepository(),
        super(ThemeState(AppThemeType.system, AppTheme.lightTheme));

  Future<void> loadSavedTheme({String? userId}) async {
    _userId = userId;
    
    // 1. Try to fetch from server first if userId provided
    if (userId != null) {
      final serverTheme = await _themeRepository.fetchUserTheme(userId);
      if (serverTheme != null) {
        // print('Theme loaded from server: $serverTheme');
        _emitTheme(serverTheme);
        // Also update local cache so it's available offline/next time
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('theme_index', serverTheme.index);
        return;
      }
    }

     // 2. Fallback to local storage
     final prefs = await SharedPreferences.getInstance();
     final index = prefs.getInt('theme_index');
     if (index != null && index >= 0 && index < AppThemeType.values.length) {
        final savedType = AppThemeType.values[index];
        _emitTheme(savedType);
     }
  }

  Future<void> changeTheme(AppThemeType type) async {
    await _emitTheme(type);
    
    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_index', type.index);

    // Sync with server if logged in
    if (_userId != null) {
      _themeRepository.updateUserTheme(_userId!, type);
    }
  }

  Future<void> _emitTheme(AppThemeType type) async {
    ThemeData theme;
    switch (type) {
      case AppThemeType.mokka:
        theme = AppTheme.mokkaTheme;
        break;
      case AppThemeType.vanille:
        theme = AppTheme.vanilleTheme;
        break;
      case AppThemeType.joghurt:
        theme = AppTheme.joghurtTheme;
        break;
      case AppThemeType.blaubeere:
        theme = AppTheme.blaubeereTheme;
        break;
      case AppThemeType.erdbeere:
        theme = AppTheme.erdbeereTheme;
        break;
      case AppThemeType.zitrone:
        theme = AppTheme.zitroneTheme;
        break;
      case AppThemeType.system:
      default:
        theme = AppTheme.lightTheme;
        break;
    }
    emit(ThemeState(type, theme));
  }
}
