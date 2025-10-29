import 'package:flutter_test/flutter_test.dart';
import 'package:re_view/features/edit/background_service.dart';
import 'package:re_view/features/edit/file_picker_service.dart';
import 'package:re_view/features/edit/lecture_creation_service.dart';
import 'package:re_view/features/edit/loader_service.dart';

/// 서비스 클래스 스모크 테스트
///
/// 각 서비스 클래스가 올바르게 인스턴스화되고 기본 타입이 일치하는지 검증합니다.
/// 이 테스트는 커버리지를 높이기 위한 최소한의 검증을 수행합니다.
void main() {
  // Flutter 바인딩 초기화 (LoaderService가 필요로 함)
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Service Classes Smoke Tests', () {
    test('BackgroundService can be instantiated', () {
      final service = BackgroundService();
      expect(service, isA<BackgroundService>());
      expect(service, isNotNull);
    });

    test('FilePickerService can be instantiated', () {
      final service = FilePickerService();
      expect(service, isA<FilePickerService>());
      expect(service, isNotNull);
    });

    test('LectureCreationService can be instantiated', () {
      final service = LectureCreationService();
      expect(service, isA<LectureCreationService>());
      expect(service, isNotNull);
    });

    test('LoaderService can be instantiated', () {
      final service = LoaderService();
      expect(service, isA<LoaderService>());
      expect(service, isNotNull);
    });

    test('CreationResult can be created with required parameters', () {
      final result = CreationResult(
        audioPath: '/fake/audio.m4a',
        jsonPath: '/fake/data.json',
        duration: 12345,
      );

      expect(result.audioPath, '/fake/audio.m4a');
      expect(result.jsonPath, '/fake/data.json');
      expect(result.duration, 12345);
    });
  });
}
