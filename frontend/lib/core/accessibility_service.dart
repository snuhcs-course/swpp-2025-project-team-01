import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 접근성 설정을 관리하는 전역 서비스
class AccessibilityService extends ChangeNotifier {
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();
  static final AccessibilityService _instance =
      AccessibilityService._internal();

  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _emphasizeCaptions = true;
  bool _isInitialized = false;

  // SharedPreferences 인스턴스 캐싱
  SharedPreferences? _prefs;

  bool get highContrast => _highContrast;
  bool get reduceMotion => _reduceMotion;
  bool get emphasizeCaptions => _emphasizeCaptions;
  bool get isInitialized => _isInitialized;

  /// 앱 시작 시 설정 로드
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _prefs = await SharedPreferences.getInstance();
    _highContrast = _prefs!.getBool('accessibility_high_contrast') ?? false;
    _reduceMotion = _prefs!.getBool('accessibility_reduce_motion') ?? false;
    _emphasizeCaptions =
        _prefs!.getBool('accessibility_emphasize_captions') ?? true;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // 공통 setter 로직
  Future<void> _updateSetting(
    String key,
    bool value,
    bool Function() getCurrentValue,
    void Function(bool) setValue,
  ) async {
    await _ensureInitialized();

    if (getCurrentValue() == value) {
      return;
    }

    setValue(value);
    await _prefs?.setBool(key, value);
    notifyListeners();
  }

  /// 고대비 설정 변경
  Future<void> setHighContrast(bool value) async {
    await _updateSetting(
      'accesibility_high_contrast',
      value,
      () => _highContrast,
      (v) => _highContrast = v,
    );
  }

  /// 모션 줄이기 설정 변경
  Future<void> setReduceMotion(bool value) async {
    await _updateSetting(
      'accesibility_reduce_motion',
      value,
      () => _reduceMotion,
      (v) => _reduceMotion = v,
    );
  }

  /// 자막 강조 설정 변경
  Future<void> setEmphasizeCaptions(bool value) async {
    await _updateSetting(
      'accesibility_emphasize_captions',
      value,
      () => _emphasizeCaptions,
      (v) => _emphasizeCaptions = v,
    );
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
