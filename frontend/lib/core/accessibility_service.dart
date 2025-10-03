import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 접근성 설정을 관리하는 전역 서비스
class AccessibilityService extends ChangeNotifier {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _emphasizeCaptions = true;
  bool _isInitialized = false;

  bool get highContrast => _highContrast;
  bool get reduceMotion => _reduceMotion;
  bool get emphasizeCaptions => _emphasizeCaptions;
  bool get isInitialized => _isInitialized;

  /// 앱 시작 시 설정 로드
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _highContrast = prefs.getBool('accessibility_high_contrast') ?? false;
    _reduceMotion = prefs.getBool('accessibility_reduce_motion') ?? false;
    _emphasizeCaptions = prefs.getBool('accessibility_emphasize_captions') ?? true;
    _isInitialized = true;
    notifyListeners();
  }

  /// 고대비 설정 변경
  Future<void> setHighContrast(bool value) async {
    if (_highContrast == value) return;

    _highContrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accessibility_high_contrast', value);
    notifyListeners();
  }

  /// 모션 줄이기 설정 변경
  Future<void> setReduceMotion(bool value) async {
    if (_reduceMotion == value) return;

    _reduceMotion = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accessibility_reduce_motion', value);
    notifyListeners();
  }

  /// 자막 강조 설정 변경
  Future<void> setEmphasizeCaptions(bool value) async {
    if (_emphasizeCaptions == value) return;

    _emphasizeCaptions = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accessibility_emphasize_captions', value);
    notifyListeners();
  }

  /// 애니메이션 지속 시간 (모션 줄이기 적용)
  Duration getAnimationDuration(Duration defaultDuration) {
    return _reduceMotion ? Duration.zero : defaultDuration;
  }

  /// 애니메이션 커브 (모션 줄이기 적용)
  Curve getAnimationCurve(Curve defaultCurve) {
    return _reduceMotion ? Curves.linear : defaultCurve;
  }
}