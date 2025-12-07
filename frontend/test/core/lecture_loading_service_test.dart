import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/core/lecture_loading_service.dart';

import 'lecture_loading_service_test.mocks.dart';

// Mockito 코드 생성을 위해 @GenerateMocks 사용
@GenerateMocks([HiveManager])
void main() {
  // 테스트에 사용할 변수 선언
  late LectureLoadingService service;
  late MockHiveManager mockHiveManager;
  late AppSettings appSettings;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockHiveManager = MockHiveManager();
    appSettings = AppSettings(language: 'ko');
    when(mockHiveManager.settings).thenReturn(appSettings);
    service = LectureLoadingService.createForTest(mockHiveManager);
  });

  tearDown(() {
    service.hideLoading();
  });

  group('Initialization and Default State', () {
    test('Initial state should be false/empty/0', () {
      expect(service.isLoading, false);
      expect(service.progress, 0.0);
      expect(service.message, '');
      expect(service.lectureTitle, '');
      expect(service.isCollapsed, false);
      expect(service.hasError, false);
      expect(service.isCompleted, false);
      expect(service.lectureId, null);
    });

    test('startLoading() sets state correctly and calls listeners', () async {
      bool notified = false;
      service.addListener(() => notified = true);

      service.startLoading('Test Lecture', 2);

      expect(service.isLoading, true);
      expect(service.lectureTitle, 'Test Lecture');
      expect(service.progress, 0.0);
      expect(service.message, '강의 생성 요청이 서버에서 대기 중이에요');
      expect(service.isCancelled, false);
      expect(service.hasError, false);
      expect(service.isCompleted, false);
      expect(notified, true);

      await Future.delayed(Duration(milliseconds: 100));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('lecture_loading_is_loading'), true);
      expect(prefs.getString('lecture_loading_lecture_title'), 'Test Lecture');
    });
  });

  group('Progress and Messages', () {
    test(
      'updateProgress() calculates progress and ignores when not loading',
      () {
        service.startLoading('Test Lecture', 3);

        service.updateProgress(0.6, 1, 'msg');
        expect(service.progress, closeTo(0.2, 0.001));

        service.updateProgress(0.9, 3, 'msg');
        expect(service.progress, closeTo(0.5, 0.001));

        service.updateProgress(0.3, 2, 'msg');
        expect(service.progress, closeTo(0.6, 0.001));
        expect(service.message, '열심히 강의를 받아적는 중..');

        expect(service.getProgress(), closeTo(0.6, 0.001));

        service.hideLoading();
        service.updateProgress(0.5, 1, 'msg');
        expect(service.progress, 0.0);
      },
    );

    test('Message timer stops when progress reaches 100%', () {
      fakeAsync((async) {
        service.startLoading('Test Lecture', 1);
        service.updateProgress(1.0, 1, 'msg');
        async.elapse(Duration(seconds: 4));

        final messageBeforeTimer = service.message;
        async.elapse(Duration(seconds: 4));
        expect(service.message, messageBeforeTimer);
        service.hideLoading();
      });
    });

    test('Message timer changes message every 4 seconds (below 90%)', () {
      fakeAsync((async) {
        service.startLoading('Test Lecture', 1);
        final initialMessage = service.message;

        service.updateProgress(0.5, 1, 'msg');
        async.elapse(Duration(seconds: 4));

        expect(service.message, isNot(initialMessage));
        expect(
          service.message,
          isIn([
            '강의 생성 요청이 서버에서 대기 중이에요',
            '열심히 강의를 받아적는 중..',
            '강의 내용을 정리하고 있어요',
            '음성 파일을 듣고 있어요',
            '슬라이드와 음성을 매칭하는 중..',
            '강의 노트를 작성하고 있어요',
            '중요한 부분을 체크하고 있어요',
            '강의를 분석하고 있어요',
          ]),
        );
        service.hideLoading();
      });
    });

    test('Message timer shows final message at 90%+ progress', () {
      fakeAsync((async) {
        service.startLoading('Test Lecture', 1);
        service.updateProgress(0.95, 1, 'msg');
        async.elapse(Duration(seconds: 4));

        expect(service.message, '거의 다 됐어요!');
        service.hideLoading();
      });
    });

    test('Returns English messages when language is set to "en"', () {
      appSettings = AppSettings(language: 'en');
      when(mockHiveManager.settings).thenReturn(appSettings);
      service = LectureLoadingService.createForTest(mockHiveManager);

      service.startLoading('Test Lecture', 1);
      expect(service.message, 'Lecture creation request queued on the server');

      service.setError();
      expect(service.errorTitle, null);
    });
  });

  group('State Control (Complete, Error, Cancel)', () {
    test('completeLoading() handles completion flow correctly', () {
      service.startLoading('Test Lecture', 1);
      service.completeLoading(lectureId: 'lecture-123');

      expect(service.progress, 1.0);
      expect(service.isCompleted, true);
      expect(service.lectureId, 'lecture-123');
      expect(service.message, '강의 생성 완료!');
      expect(service.isLoading, true);

      final id = service.getLectureIdAndHide();
      expect(id, 'lecture-123');
      expect(service.isLoading, false);
      expect(service.lectureId, null);

      service.completeLoading(lectureId: 'test-id');
      expect(service.isLoading, false);
      expect(service.isCompleted, false);
    });

    test('setError() handles custom and default error messages', () {
      service.startLoading('Test Lecture', 1);
      service.setError(errorTitle: 'Error!', errorMessage: 'Failed!');

      expect(service.hasError, true);
      expect(service.errorTitle, 'Error!');
      expect(service.errorMessage, 'Failed!');

      service.hideLoading();
      service.startLoading('Test Lecture', 1);
      service.setError();

      expect(service.hasError, true);
      expect(service.errorTitle, null);
      expect(service.errorMessage, null);
    });

    test('cancelLoading() calls callback and hides after 1 second', () {
      fakeAsync((async) {
        bool onCancelCalled = false;
        service.setOnCancel(() => onCancelCalled = true);
        service.startLoading('Test Lecture', 1);

        service.cancelLoading();

        expect(onCancelCalled, true);
        expect(service.isCancelled, true);
        expect(service.message, '강의 생성을 취소하는 중..');
        expect(service.isLoading, true);

        async.elapse(Duration(seconds: 1));
        expect(service.isLoading, false);
      });
    });

    test('hideLoading() resets state and clears SharedPreferences', () async {
      service.startLoading('Test Lecture', 1);
      await Future.delayed(Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('lecture_loading_is_loading'), true);

      service.hideLoading();

      expect(service.isLoading, false);
      expect(service.lectureTitle, '');
      expect(service.isCompleted, false);
      expect(service.hasError, false);

      await Future.delayed(Duration(milliseconds: 100));
      final clearedPrefs = await SharedPreferences.getInstance();
      expect(clearedPrefs.getBool('lecture_loading_is_loading'), null);
    });
  });

  group('UI State (Bubble)', () {
    test('bubble state management works correctly', () {
      service.startLoading('Test Lecture', 1);
      expect(service.isCollapsed, false);

      service.collapseToBubble(alignRight: true);
      expect(service.isCollapsed, true);
      expect(service.bubbleOnRight, true);

      service.collapseToBubble(alignRight: false);
      expect(service.isCollapsed, true);
      expect(service.bubbleOnRight, false);

      service.expandFromBubble();
      expect(service.isCollapsed, false);

      service.hideLoading();
      service.collapseToBubble(alignRight: true);
      expect(service.isCollapsed, false);

      service.startLoading('Test Lecture', 1);
      service.expandFromBubble();
      expect(service.isCollapsed, false);

      service.updateBubblePosition(100.0, 200.0);
      expect(service.bubbleX, 24.0);
      expect(service.bubbleY, 24.0);
    });

    test('updateBubblePosition() saves position', () async {
      service.startLoading('Test Lecture', 1);
      service.collapseToBubble(alignRight: true);
      service.updateBubblePosition(120.5, 300.0);

      expect(service.bubbleX, 120.5);
      expect(service.bubbleY, 300.0);

      await Future.delayed(Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('lecture_loading_bubble_x'), 120.5);
      expect(prefs.getDouble('lecture_loading_bubble_y'), 300.0);
    });
  });
}
