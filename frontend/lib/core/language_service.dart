import 'package:shared_preferences/shared_preferences.dart';

/// 앱 언어 설정을 관리하는 서비스
class LanguageService {
  static const String _key = 'app_language';
  static const String defaultLanguage = 'ko';

  /// 저장된 언어 설정을 가져옵니다.
  /// 저장된 값이 없으면 기본값인 'ko'를 반환합니다.
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? defaultLanguage;
  }

  /// 언어 설정을 저장합니다.
  static Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, language);
  }

  /// 현재 언어가 한국어인지 확인합니다.
  static Future<bool> isKorean() async {
    final lang = await getLanguage();
    return lang == 'ko';
  }

  /// 현재 언어가 영어인지 확인합니다.
  static Future<bool> isEnglish() async {
    final lang = await getLanguage();
    return lang == 'en';
  }
}