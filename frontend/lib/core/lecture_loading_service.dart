// 렉처 생성 로딩 상태를 전역으로 관리하는 서비스
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 렉처 생성 로딩 상태 관리 싱글톤 서비스
class LectureLoadingService extends ChangeNotifier {
  LectureLoadingService._() {
    _restoreState();
  }
  static final LectureLoadingService instance = LectureLoadingService._();

  // 유저 친화적인 메시지 목록
  static const List<String> _friendlyMessages = [
    '열심히 강의를 받아적는 중..',
    '강의 내용을 정리하고 있어요',
    '교수님 목소리를 듣고 있어요',
    '슬라이드와 음성을 매칭하는 중',
    '강의 노트를 작성하고 있어요',
    '중요한 부분을 체크하고 있어요',
    '강의를 분석하고 있어요',
    '거의 다 됐어요!',
  ];

  Timer? _messageTimer;
  int _currentMessageIndex = 0;
  final Random _random = Random();

  bool _isLoading = false;
  List<double> _progressLists = <double>[];
  double _progress = 0.0;
  String _message = '';
  String _lectureTitle = '';
  bool _isCancelled = false;
  VoidCallback? _onCancel;
  bool _isCollapsed = false;
  bool _bubbleOnRight = true;
  double _bubbleX = 24.0; // X position from left edge
  double _bubbleY = 24.0; // Y position from bottom edge

  /// 현재 로딩 중인지 여부
  bool get isLoading => _isLoading;

  /// 현재 진행도 (0.0 ~ 1.0)
  double get progress => _progress;

  /// 현재 진행 메시지
  String get message => _message;

  /// 현재 생성 중인 렉처 제목
  String get lectureTitle => _lectureTitle;

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

  /// 취소 콜백 등록
  void setOnCancel(VoidCallback? callback) {
    _onCancel = callback;
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
  void completeLoading() {
    if (!_isLoading) {
      return;
    }

    _messageTimer?.cancel();
    _progress = 1.0;
    _message = '강의 생성 완료!';
    notifyListeners();
    _saveState();
  }

  /// 로딩 숨김 (즉시)
  void hideLoading() {
    _messageTimer?.cancel();
    _isLoading = false;
    _progress = 0.0;
    _message = '';
    _lectureTitle = '';
    _isCancelled = false;
    _onCancel = null;
    _isCollapsed = false;
    _bubbleOnRight = true;
    notifyListeners();
    _clearState();
  }

  /// 에러 발생 시
  void setError(String errorMessage) {
    _messageTimer?.cancel();
    _message = '오류가 발생했어요';
    notifyListeners();

    // 3초 후 자동으로 숨김
    Future.delayed(const Duration(seconds: 3), hideLoading);
  }

  /// 강의 생성 취소
  void cancelLoading() {
    _messageTimer?.cancel();
    _isCancelled = true;
    _message = '강의 생성을 취소하는 중..';
    notifyListeners();

    // 취소 콜백 실행
    _onCancel?.call();

    // 1초 후 숨김
    Future.delayed(const Duration(seconds: 1), hideLoading);
  }

  /// 로딩 바를 축소하여 버블 상태로 전환
  void collapseToBubble({required bool alignRight}) {
    if (!_isLoading) {
      return;
    }
    _isCollapsed = true;
    _bubbleOnRight = alignRight;
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

  // SharedPreferences keys
  static const _keyIsLoading = 'lecture_loading_is_loading';
  static const _keyProgress = 'lecture_loading_progress';
  static const _keyMessage = 'lecture_loading_message';
  static const _keyLectureTitle = 'lecture_loading_lecture_title';
  static const _keyIsCollapsed = 'lecture_loading_is_collapsed';
  static const _keyBubbleOnRight = 'lecture_loading_bubble_on_right';
  static const _keyBubbleX = 'lecture_loading_bubble_x';
  static const _keyBubbleY = 'lecture_loading_bubble_y';

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
    } catch (e) {
      debugPrint('Failed to clear loading state: $e');
    }
  }
}
