import 'dart:ui';
import 'package:re_view/core/lecture_loading_service.dart';

/// 로딩 서비스 래퍼 클래스
///
/// LectureLoadingService 싱글톤을 감싸서 테스트 가능하게 만듦
/// 테스트 시 이 클래스를 상속하거나 Fake 객체로 대체하여 사용
class LoaderService {
  final LectureLoadingService _instance = LectureLoadingService.instance;

  bool get isCancelled => _instance.isCancelled;

  void startLoading(String title) => _instance.startLoading(title);

  void setOnCancel(VoidCallback onCancel) => _instance.setOnCancel(onCancel);

  void hideLoading() => _instance.hideLoading();
}
