import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 언어 설정을 관리하는 서비스
class LanguageService extends ChangeNotifier {
  LanguageService._();
  static final instance = LanguageService._();

  static const String _key = 'app_language';
  static const String defaultLanguage = 'ko';

  Locale _locale = const Locale('ko', 'KR');

  Locale get locale => _locale;

  /// 앱 시작 시 저장된 언어 로드
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_key) ?? defaultLanguage;
    _locale = _localeFromString(lang);
    notifyListeners();
  }

  /// 저장된 언어 설정을 가져옵니다 (하위호환용 static 메서드)
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? defaultLanguage;
  }

  /// 언어 설정을 저장합니다
  Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, language);
    _locale = _localeFromString(language);
    notifyListeners();
  }

  /// 하위호환용 static 메서드
  static Future<void> setLanguageStatic(String language) async {
    await instance.setLanguage(language);
  }

  Locale _localeFromString(String lang) {
    switch (lang) {
      case 'ko':
        return const Locale('ko', 'KR');
      case 'en':
        return const Locale('en', 'US');
      default:
        return const Locale('ko', 'KR');
    }
  }

  /// 현재 언어가 한국어인지 확인합니다.
  bool get isKorean => _locale.languageCode == 'ko';

  /// 현재 언어가 영어인지 확인합니다.
  bool get isEnglish => _locale.languageCode == 'en';
}