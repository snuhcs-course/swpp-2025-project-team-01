import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 전체의 테마 모드를 관리하는 싱글톤 클래스
class ThemeManager extends ChangeNotifier {
  ThemeManager._();
  static final instance = ThemeManager._();

  ThemeMode _themeMode = ThemeMode.system;
  static const String _key = 'display_mode';

  ThemeMode get themeMode => _themeMode;

  /// 저장된 테마 모드를 불러옵니다
  Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_key) ?? 'system';
    _themeMode = _themeModeFromString(mode);
    notifyListeners();
  }

  /// 테마 모드를 변경하고 저장합니다
  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode);
    _themeMode = _themeModeFromString(mode);
    notifyListeners();
  }

  ThemeMode _themeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
