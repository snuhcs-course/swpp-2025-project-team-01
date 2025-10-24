// 렉처 생성 로딩 상태를 전역으로 관리하는 서비스
import 'package:flutter/foundation.dart';

/// 렉처 생성 로딩 상태 관리 싱글톤 서비스
class LectureLoadingService extends ChangeNotifier {
  LectureLoadingService._();
  static final LectureLoadingService instance = LectureLoadingService._();

  bool _isLoading = false;
  double _progress = 0.0;
  String _message = '';
  String _lectureTitle = '';
  bool _isCancelled = false;
  VoidCallback? _onCancel;
  bool _isCollapsed = false;
  bool _bubbleOnRight = true;

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

  /// 취소 콜백 등록
  void setOnCancel(VoidCallback? callback) {
    _onCancel = callback;
  }

  /// 로딩 시작
  void startLoading(String title) {
    _isLoading = true;
    _progress = 0.0;
    _message = 'Starting...';
    _lectureTitle = title;
    _isCancelled = false;
    _isCollapsed = false;
    _bubbleOnRight = true;
    notifyListeners();
  }

  /// 진행도 업데이트
  void updateProgress(double progress, String message) {
    if (!_isLoading) {
      return;
    }

    _progress = progress.clamp(0.0, 1.0);
    _message = message;
    notifyListeners();
  }

  /// 로딩 완료 (완료 화면을 잠시 표시하기 위해 isLoading은 유지)
  void completeLoading() {
    if (!_isLoading) {
      return;
    }

    _progress = 1.0;
    _message = 'Completed!';
    notifyListeners();
  }

  /// 로딩 숨김 (즉시)
  void hideLoading() {
    _isLoading = false;
    _progress = 0.0;
    _message = '';
    _lectureTitle = '';
    _isCancelled = false;
    _onCancel = null;
    _isCollapsed = false;
    _bubbleOnRight = true;
    notifyListeners();
  }

  /// 에러 발생 시
  void setError(String errorMessage) {
    _message = errorMessage;
    notifyListeners();

    // 3초 후 자동으로 숨김
    Future.delayed(const Duration(seconds: 3), hideLoading);
  }

  /// 강의 생성 취소
  void cancelLoading() {
    _isCancelled = true;
    _message = 'Cancelling...';
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
  }
}
