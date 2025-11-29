// 렉처 생성 로딩 상태를 전역으로 관리하는 서비스
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/core/localization/app_localizations.dart';

const String _serverAddress = '147.46.78.61';
const String _port = '8001';

/// 렉처 생성 로딩 상태 관리 싱글톤 서비스
class LectureLoadingService extends ChangeNotifier {
  LectureLoadingService._(this._hiveManager) {
    _restoreState();
  }

  @visibleForTesting
  factory LectureLoadingService.createForTest(HiveManager mockHiveManager) {
    return LectureLoadingService._(mockHiveManager);
  }

  // coverage:ignore-start
  static final LectureLoadingService instance = LectureLoadingService._(
    HiveManager.instance,
  );
  final HiveManager _hiveManager;
  // coverage:ignore-end

  Timer? _messageTimer;
  int _currentMessageIndex = 0;
  final Random _random = Random();
  String? _currentRoute; // 현재 라우트 추적
  Timer? _completionTimer; // 15초 자동 숨김 타이머
  bool _hasVisitedHome = false; // 홈 화면 방문 여부 (앱 실행 중에만 유지)

  /// 현재 언어 설정에 따른 AppLocalizations 인스턴스 가져오기
  AppLocalizations get _l10n {
    final language = _hiveManager.settings.language;
    final locale = Locale(language);
    return AppLocalizations(locale);
  }

  /// 현재 언어 설정에 따른 메시지 목록 가져오기
  List<String> get _friendlyMessages => _l10n.friendlyMessages;

  bool _isLoading = false;
  List<double> _progressLists = <double>[];
  double _progress = 0.0;
  String _message = '';
  String _lectureTitle = '';
  String? _lectureId; // 생성된 강의 ID
  bool _isCancelled = false;
  VoidCallback? _onCancel;
  bool _isCollapsed = false;
  bool _bubbleOnRight = true;
  double _bubbleX = 24.0; // X position from left edge
  double _bubbleY = 24.0; // Y position from bottom edge
  bool _hasError = false; // 에러 발생 여부
  String _errorTitle = ''; // 에러 제목
  String _errorMessage = ''; // 에러 상세 메시지
  bool _isCompleted = false; // 완료 뷰 표시 여부

  final Set<String> _jobIds = <String>{};

  /// 현재 로딩 중인지 여부
  bool get isLoading => _isLoading;

  /// 현재 진행도 (0.0 ~ 1.0)
  double get progress => _progress;

  /// 현재 진행 메시지
  String get message => _message;

  /// 현재 생성 중인 렉처 제목
  String get lectureTitle => _lectureTitle;

  /// 생성된 강의 ID
  String? get lectureId => _lectureId;

  /// 취소 여부
  bool get isCancelled => _isCancelled;

  /// 현재 로딩 바가 축소(bubble) 상태인지 여부
  bool get isCollapsed => _isCollapsed;

  /// 축소 상태에서 오른쪽에 위치하는지 여부
  bool get bubbleOnRight => _bubbleOnRight;

  /// 버블의 X 위치 (왼쪽 가장자리로부터의 거리)
  double get bubbleX => _bubbleX;

  /// 버블의 Y 위치 (하단 가장자리로부터의 거리)
  double get bubbleY => _bubbleY;

  /// 에러 발생 여부
  bool get hasError => _hasError;

  /// 에러 제목
  String get errorTitle => _errorTitle;

  /// 에러 상세 메시지
  String get errorMessage => _errorMessage;

  /// 완료 위젯 노출 여부
  bool get isCompleted => _isCompleted;

  /// 취소 콜백 등록
  void setOnCancel(VoidCallback? callback) {
    _onCancel = callback;
  }

  /// 강의로 이동 (위젯이 직접 Navigator를 사용할 수 없으므로 lectureId만 반환)
  String? getLectureIdAndHide() {
    debugPrint('🔥 getLectureIdAndHide called');
    debugPrint('🔥 _lectureId: $_lectureId');

    final id = _lectureId;
    hideLoading();
    return id;
  }

  /// 로딩 시작
  void startLoading(String title, int audioCount) {
    _isLoading = true;
    _progressLists = List.filled(audioCount, 0.0);
    _progress = 0.0;
    _currentMessageIndex = 0;
    _message = _friendlyMessages[0];
    _lectureTitle = title;
    _isCancelled = false;
    _isCollapsed = false;
    _bubbleOnRight = true;
    _hasError = false;
    _errorTitle = '';
    _errorMessage = '';
    _isCompleted = false;
    _hasVisitedHome = false; // 새 로딩 시작 시 리셋

    // 주기적으로 메시지 변경 (3-5초마다)
    _startMessageTimer();

    notifyListeners();
    _saveState();
  }

  /// 메시지 타이머 시작
  void _startMessageTimer() {
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isLoading || _progress >= 1.0) {
        timer.cancel();
        return;
      }

      // 진행도에 따라 메시지 선택
      if (_progress < 0.9) {
        // 90% 미만일 때는 랜덤하게 메시지 선택 (마지막 메시지 제외)
        int nextIndex;
        do {
          nextIndex = _random.nextInt(_friendlyMessages.length - 1);
        } while (nextIndex == _currentMessageIndex);
        _currentMessageIndex = nextIndex;
      } else {
        // 90% 이상일 때는 마지막 메시지 표시
        _currentMessageIndex = _friendlyMessages.length - 1;
      }

      _message = _friendlyMessages[_currentMessageIndex];
      notifyListeners();
      _saveState();
    });
  }

  void addJobId(String jobId) {
    _jobIds.add(jobId);
  }

  /// 현재 진행도
  double getProgress() {
    return _progress;
  }

  double computeProgress() {
    final sum = _progressLists.reduce((a, b) => a + b);
    return sum / _progressLists.length;
  }

  /// 진행도 업데이트
  void updateProgress(double progress, int order, String message) {
    if (!_isLoading) {
      return;
    }

    _progressLists[order - 1] = progress.clamp(0.0, 1.0);
    // 서버 메시지는 무시하고 현재 유저 친화적 메시지 유지
    // _message는 타이머에 의해서만 업데이트됨
    _progress = computeProgress();
    notifyListeners();
    _saveState();
  }

  /// 로딩 완료 (완료 화면을 잠시 표시하기 위해 isLoading은 유지)
  void completeLoading({String? lectureId}) {
    if (!_isLoading) {
      return;
    }

    _messageTimer?.cancel();
    _progress = 1.0;
    _message = _l10n.lectureCreationComplete;
    _lectureId = lectureId;
    _isCompleted = true;

    // 항상 15초 타이머 시작 (어디서 완료되든)
    _startCompletionTimer();

    notifyListeners();
    _saveState();
  }

  /// 로딩 숨김 (즉시)
  void hideLoading() {
    _messageTimer?.cancel();
    _completionTimer?.cancel(); // 완료 타이머도 취소
    _isLoading = false;
    _progress = 0.0;
    _message = '';
    _lectureTitle = '';
    _lectureId = null;
    _isCancelled = false;
    _onCancel = null;
    _isCollapsed = false;
    _bubbleOnRight = true;
    _hasError = false;
    _errorTitle = '';
    _errorMessage = '';
    _isCompleted = false;
    _currentRoute = null; // 라우트 정보 초기화
    _hasVisitedHome = false; // 홈 방문 플래그 리셋
    notifyListeners();
    _clearState();
  }

  /// 에러 발생 시
  void setError({String? errorTitle, String? errorMessage}) {
    _messageTimer?.cancel();
    _hasError = true;

    // 에러 제목 설정
    _errorTitle = errorTitle ?? _l10n.errorOccurred;

    // 에러 메시지 설정
    _errorMessage = errorMessage ?? _l10n.errorDefaultMessage;

    notifyListeners();
    _saveState();
  }

  /// 강의 생성 취소
  Future<void> cancelLoading({http.Client? fakeClient}) async {
    _messageTimer?.cancel();
    _completionTimer?.cancel(); // 완료 타이머도 취소
    _isCancelled = true;
    _message = _l10n.cancelling;
    notifyListeners();
    // 취소 콜백 실행
    _onCancel?.call();

    for (String jobId in _jobIds) {
      final endpoint = Uri.parse(
        'http://$_serverAddress:$_port/api/synchronize/cancel/$jobId',
      );
      final client = fakeClient ?? http.Client();
      final req = http.MultipartRequest('POST', endpoint);
      req.fields['job_id'] = jobId;
      try {
        final response = await client.post(endpoint);
        if (response.statusCode == 200 || response.statusCode == 400) {
          // Good
        } else {
          throw HttpException('Connection Error triggered');
        }
      } catch (_) {
        // Retry once
        await client.post(endpoint);
      }
    }
    _jobIds.clear();

    // 1초 후 숨김
    Future.delayed(const Duration(seconds: 1), hideLoading);
  }

  /// 로딩 바를 축소하여 버블 상태로 전환
  void collapseToBubble({required bool alignRight, bool snapToCorner = false}) {
    if (!_isLoading) {
      return;
    }
    _isCollapsed = true;
    _bubbleOnRight = alignRight;

    // 모서리에 붙이기 옵션이 활성화된 경우 기본 모서리 위치로 이동
    if (snapToCorner) {
      _bubbleX = 24.0;
      _bubbleY = 24.0;
    }

    notifyListeners();
    _saveState();
  }

  /// 축소된 버블을 다시 확장
  void expandFromBubble() {
    if (!_isLoading) {
      return;
    }
    if (!_isCollapsed) {
      return;
    }
    _isCollapsed = false;
    notifyListeners();
    _saveState();
  }

  /// 버블 위치 업데이트
  void updateBubblePosition(double x, double y) {
    if (!_isLoading || !_isCollapsed) {
      return;
    }
    _bubbleX = x;
    _bubbleY = y;
    notifyListeners();
    _saveState();
  }

  /// NavigatorObserver가 호출하는 메서드
  void onRouteChanged(String? routeName) {
    // 로딩 중이 아니면 아무 작업도 하지 않음
    if (!_isLoading) {
      return;
    }

    _currentRoute = routeName;
    debugPrint('‼️ $routeName');

    // 홈 화면 방문 체크
    if (routeName == '/home') {
      _hasVisitedHome = true;
    }

    // 조건 1: 완료 상태이고 홈 화면에서 벗어남 → 즉시 숨김 (타이머 취소)
    if (_isCompleted && routeName != '/home') {
      _completionTimer?.cancel();
      hideLoading();
      return;
    }

    // 조건 2: 완료되지 않은 상태이고 로딩 중이며 홈 화면에서 벗어남 → bubble로 축소
    // (단, 홈 화면을 최소 한 번 방문한 경우에만)
    if (!_isCompleted &&
        routeName != '/home' &&
        !_isCollapsed &&
        _hasVisitedHome) {
      collapseToBubble(alignRight: true, snapToCorner: true);
    }

    _saveState();
    notifyListeners();
  }

  /// 15초 후 자동 숨김 타이머 시작
  void _startCompletionTimer() {
    _completionTimer?.cancel(); // 기존 타이머 취소

    // 어디서 완료되든 항상 15초 타이머 시작
    _completionTimer = Timer(const Duration(seconds: 15), () {
      if (_isLoading && _isCompleted) {
        hideLoading();
      }
    });
  }

  // SharedPreferences keys
  static const _keyIsLoading = 'lecture_loading_is_loading';
  static const _keyProgress = 'lecture_loading_progress';
  static const _keyMessage = 'lecture_loading_message';
  static const _keyLectureTitle = 'lecture_loading_lecture_title';
  static const _keyIsCollapsed = 'lecture_loading_is_collapsed';
  static const _keyBubbleOnRight = 'lecture_loading_bubble_on_right';
  static const _keyBubbleX = 'lecture_loading_bubble_x';
  static const _keyBubbleY = 'lecture_loading_bubble_y';
  static const _keyIsCompleted = 'lecture_loading_is_completed';
  static const _keyCurrentRoute = 'lecture_loading_current_route';
  static const _keyHasError = 'lecture_loading_has_error';
  static const _keyErrorTitle = 'lecture_loading_error_title';
  static const _keyErrorMessage = 'lecture_loading_error_message';

  /// 상태를 SharedPreferences에 저장
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoading, _isLoading);
      await prefs.setDouble(_keyProgress, _progress);
      await prefs.setString(_keyMessage, _message);
      await prefs.setString(_keyLectureTitle, _lectureTitle);
      await prefs.setBool(_keyIsCollapsed, _isCollapsed);
      await prefs.setBool(_keyBubbleOnRight, _bubbleOnRight);
      await prefs.setDouble(_keyBubbleX, _bubbleX);
      await prefs.setDouble(_keyBubbleY, _bubbleY);
      await prefs.setBool(_keyIsCompleted, _isCompleted);
      await prefs.setString(_keyCurrentRoute, _currentRoute ?? '');
      await prefs.setBool(_keyHasError, _hasError);
      await prefs.setString(_keyErrorTitle, _errorTitle);
      await prefs.setString(_keyErrorMessage, _errorMessage);
    } catch (e) {
      debugPrint('Failed to save loading state: $e');
    }
  }

  /// 상태를 SharedPreferences에서 복원
  Future<void> _restoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoading = prefs.getBool(_keyIsLoading) ?? false;
      _progress = prefs.getDouble(_keyProgress) ?? 0.0;
      _message = prefs.getString(_keyMessage) ?? '';
      _lectureTitle = prefs.getString(_keyLectureTitle) ?? '';
      _isCollapsed = prefs.getBool(_keyIsCollapsed) ?? false;
      _bubbleOnRight = prefs.getBool(_keyBubbleOnRight) ?? true;
      _bubbleX = prefs.getDouble(_keyBubbleX) ?? 24.0;
      _bubbleY = prefs.getDouble(_keyBubbleY) ?? 24.0;
      _isCompleted = prefs.getBool(_keyIsCompleted) ?? false;
      _currentRoute = prefs.getString(_keyCurrentRoute);
      _hasError = prefs.getBool(_keyHasError) ?? false;
      _errorTitle = prefs.getString(_keyErrorTitle) ?? '';
      _errorMessage = prefs.getString(_keyErrorMessage) ?? '';

      // 완료 상태로 복원되면 타이머 재시작 (어디서든)
      if (_isLoading && _isCompleted) {
        _startCompletionTimer();
      }

      // 복원 후 UI 업데이트
      if (_isLoading) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to restore loading state: $e');
    }
  }

  /// 상태를 완전히 삭제 (로딩 종료 시)
  Future<void> _clearState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIsLoading);
      await prefs.remove(_keyProgress);
      await prefs.remove(_keyMessage);
      await prefs.remove(_keyLectureTitle);
      await prefs.remove(_keyIsCollapsed);
      await prefs.remove(_keyBubbleOnRight);
      await prefs.remove(_keyBubbleX);
      await prefs.remove(_keyBubbleY);
      await prefs.remove(_keyIsCompleted);
      await prefs.remove(_keyCurrentRoute);
      await prefs.remove(_keyHasError);
      await prefs.remove(_keyErrorTitle);
      await prefs.remove(_keyErrorMessage);
    } catch (e) {
      debugPrint('Failed to clear loading state: $e');
    }
  }
}
