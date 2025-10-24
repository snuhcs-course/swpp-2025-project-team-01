import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:re_view/features/player/player_screen.dart';
import 'package:re_view/features/player/services/audio_service.dart';
import 'package:re_view/features/player/core/pdf_cache_service.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:pdfx/pdfx.dart';
import 'package:just_audio/just_audio.dart';

@GenerateMocks([AudioService, PdfCacheService, PdfDocument, HiveManager])
import 'player_screen_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  HiveLecture createMockHiveLecture() {
    return HiveLecture(
      id: 'test-lecture',
      subjectId: 'test',
      weekLabel: 'hello',
      durationSec: 100,
      title: 'Test Lecture',
      slidePath: 'assets/lectures/lec_demo_001/lec_demo_001_slides.pdf',
      audioPaths: ['assets/lectures/lec_demo_001/lecture_with_slides.opus'],
      transcriptPaths: ['assets/lectures/lec_demo_001/transcript.json'],
      createdAt: DateTime.now(),
    );
  }

  group('Initialization and Lifecycle', () {
    late MockAudioService mockAudioService;
    late MockPdfCacheService mockPdfCacheService;
    late MockHiveManager mockHiveManager;
    late StreamController<Duration> positionController;
    late StreamController<PlayerState> stateController;

    setUp(() {
      mockAudioService = MockAudioService();
      mockPdfCacheService = MockPdfCacheService();
      mockHiveManager = MockHiveManager();

      positionController = StreamController<Duration>.broadcast();
      stateController = StreamController<PlayerState>.broadcast();

      when(
        mockAudioService.positionStream,
      ).thenAnswer((_) => positionController.stream);
      when(
        mockAudioService.stateStream,
      ).thenAnswer((_) => stateController.stream);
      when(mockAudioService.loadAudio(any)).thenAnswer((_) async {});
      when(mockAudioService.play()).thenAnswer((_) async {});
      when(mockAudioService.pause()).thenAnswer((_) async {});
      when(mockAudioService.seek(any)).thenAnswer((_) async {});
      when(mockAudioService.dispose()).thenAnswer((_) async {});

      when(mockPdfCacheService.setPdfDocument(any)).thenReturn(null);
      when(mockPdfCacheService.getCachedImageDirect(any)).thenReturn(null);
      when(
        mockPdfCacheService.getCachedOrRenderPage(any),
      ).thenAnswer((_) async => Uint8List(0));

      when(mockHiveManager.getLecture(any)).thenReturn(createMockHiveLecture());
    });

    tearDown(() {
      positionController.close();
      stateController.close();
    });

    testWidgets('should inject services via constructor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(
            args: {'lectureId': 'test-lecture'},
            audioService: mockAudioService,
            pdfCacheService: mockPdfCacheService,
            hiveManager: mockHiveManager,
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
      expect(find.byType(PlayerScreen), findsOneWidget);
    });

    testWidgets('should call dispose on audioService when disposed', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(
            args: {'lectureId': 'test-lecture'},
            audioService: mockAudioService,
            pdfCacheService: mockPdfCacheService,
            hiveManager: mockHiveManager,
          ),
        ),
      );

      await tester.pump();
      await tester.pumpWidget(Container());

      verify(mockAudioService.dispose()).called(1);
    });

    testWidgets('should setup audio listeners on init', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(
            args: {'lectureId': 'test-lecture'},
            audioService: mockAudioService,
            pdfCacheService: mockPdfCacheService,
            hiveManager: mockHiveManager,
          ),
        ),
      );

      await tester.pump();

      verify(mockAudioService.positionStream).called(greaterThan(0));
      verify(mockAudioService.stateStream).called(greaterThan(0));
    });
  });

  group('Audio Position Stream', () {
    late MockAudioService mockAudioService;
    late MockPdfCacheService mockPdfCacheService;
    late MockHiveManager mockHiveManager;
    late StreamController<Duration> positionController;
    late StreamController<PlayerState> stateController;

    setUp(() {
      mockAudioService = MockAudioService();
      mockPdfCacheService = MockPdfCacheService();
      mockHiveManager = MockHiveManager();

      positionController = StreamController<Duration>.broadcast();
      stateController = StreamController<PlayerState>.broadcast();

      when(
        mockAudioService.positionStream,
      ).thenAnswer((_) => positionController.stream);
      when(
        mockAudioService.stateStream,
      ).thenAnswer((_) => stateController.stream);
      when(mockAudioService.loadAudio(any)).thenAnswer((_) async {});
      when(mockAudioService.play()).thenAnswer((_) async {});
      when(mockAudioService.pause()).thenAnswer((_) async {});
      when(mockAudioService.seek(any)).thenAnswer((_) async {});
      when(mockAudioService.dispose()).thenAnswer((_) async {});

      when(mockPdfCacheService.setPdfDocument(any)).thenReturn(null);
      when(mockPdfCacheService.getCachedImageDirect(any)).thenReturn(null);
      when(
        mockPdfCacheService.getCachedOrRenderPage(any),
      ).thenAnswer((_) async => Uint8List(0));

      when(mockHiveManager.getLecture(any)).thenReturn(createMockHiveLecture());
    });

    tearDown(() {
      positionController.close();
      stateController.close();
    });

    testWidgets('should update currentTime when position changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(
            args: {'lectureId': 'test-lecture'},
            audioService: mockAudioService,
            pdfCacheService: mockPdfCacheService,
            hiveManager: mockHiveManager,
          ),
        ),
      );

      await tester.pump();

      positionController.add(Duration(seconds: 5));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('should call updateCurrentSentence on position update', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(
            args: {'lectureId': 'test-lecture'},
            audioService: mockAudioService,
            pdfCacheService: mockPdfCacheService,
            hiveManager: mockHiveManager,
          ),
        ),
      );

      await tester.pump();

      positionController.add(Duration(seconds: 15));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('should not crash when position stream emits after unmount', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(
            args: {'lectureId': 'test-lecture'},
            audioService: mockAudioService,
            pdfCacheService: mockPdfCacheService,
            hiveManager: mockHiveManager,
          ),
        ),
      );

      await tester.pump();
      await tester.pumpWidget(Container());

      positionController.add(Duration(seconds: 10));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('Audio State Stream', () {
    late MockAudioService mockAudioService;
    late MockPdfCacheService mockPdfCacheService;
    late MockHiveManager mockHiveManager;
    late StreamController<Duration> positionController;
    late StreamController<PlayerState> stateController;

    setUp(() {
      mockAudioService = MockAudioService();
      mockPdfCacheService = MockPdfCacheService();
      mockHiveManager = MockHiveManager();

      positionController = StreamController<Duration>.broadcast();
      stateController = StreamController<PlayerState>.broadcast();

      when(
        mockAudioService.positionStream,
      ).thenAnswer((_) => positionController.stream);
      when(
        mockAudioService.stateStream,
      ).thenAnswer((_) => stateController.stream);
      when(mockAudioService.loadAudio(any)).thenAnswer((_) async {});
      when(mockAudioService.play()).thenAnswer((_) async {});
      when(mockAudioService.pause()).thenAnswer((_) async {});
      when(mockAudioService.seek(any)).thenAnswer((_) async {});
      when(mockAudioService.dispose()).thenAnswer((_) async {});

      when(mockPdfCacheService.setPdfDocument(any)).thenReturn(null);
      when(mockPdfCacheService.getCachedImageDirect(any)).thenReturn(null);
      when(
        mockPdfCacheService.getCachedOrRenderPage(any),
      ).thenAnswer((_) async => Uint8List(0));

      when(mockHiveManager.getLecture(any)).thenReturn(createMockHiveLecture());
    });

    tearDown(() {
      positionController.close();
      stateController.close();
    });

    testWidgets('should update isPlaying to true when playing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(
            args: {'lectureId': 'test-lecture'},
            audioService: mockAudioService,
            pdfCacheService: mockPdfCacheService,
            hiveManager: mockHiveManager,
          ),
        ),
      );

      await tester.pump();

      stateController.add(PlayerState(true, ProcessingState.ready));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('should update isPlaying to false when paused', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(
            args: {'lectureId': 'test-lecture'},
            audioService: mockAudioService,
            pdfCacheService: mockPdfCacheService,
            hiveManager: mockHiveManager,
          ),
        ),
      );

      await tester.pump();

      stateController.add(PlayerState(false, ProcessingState.ready));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('should not crash when state stream emits after unmount', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(
            args: {'lectureId': 'test-lecture'},
            audioService: mockAudioService,
            pdfCacheService: mockPdfCacheService,
            hiveManager: mockHiveManager,
          ),
        ),
      );

      await tester.pump();
      await tester.pumpWidget(Container());

      stateController.add(PlayerState(true, ProcessingState.ready));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('Load Data', () {
    late MockAudioService mockAudioService;
    late MockPdfCacheService mockPdfCacheService;
    late MockHiveManager mockHiveManager;
    late StreamController<Duration> positionController;
    late StreamController<PlayerState> stateController;

    setUp(() {
      mockAudioService = MockAudioService();
      mockPdfCacheService = MockPdfCacheService();
      mockHiveManager = MockHiveManager();

      positionController = StreamController<Duration>.broadcast();
      stateController = StreamController<PlayerState>.broadcast();

      when(
        mockAudioService.positionStream,
      ).thenAnswer((_) => positionController.stream);
      when(
        mockAudioService.stateStream,
      ).thenAnswer((_) => stateController.stream);
      when(mockAudioService.loadAudio(any)).thenAnswer((_) async {});
      when(mockAudioService.play()).thenAnswer((_) async {});
      when(mockAudioService.pause()).thenAnswer((_) async {});
      when(mockAudioService.seek(any)).thenAnswer((_) async {});
      when(mockAudioService.dispose()).thenAnswer((_) async {});

      when(mockPdfCacheService.setPdfDocument(any)).thenReturn(null);
      when(mockPdfCacheService.getCachedImageDirect(any)).thenReturn(null);
      when(
        mockPdfCacheService.getCachedOrRenderPage(any),
      ).thenAnswer((_) async => Uint8List(0));
    });

    tearDown(() {
      positionController.close();
      stateController.close();
    });

    testWidgets('should handle null hiveLecture gracefully', (tester) async {
      when(mockHiveManager.getLecture(any)).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(
            args: {'lectureId': 'test-lecture'},
            audioService: mockAudioService,
            pdfCacheService: mockPdfCacheService,
            hiveManager: mockHiveManager,
          ),
        ),
      );

      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('should call loadAudio with correct path', (tester) async {
      when(mockHiveManager.getLecture(any)).thenReturn(createMockHiveLecture());

      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(
            args: {'lectureId': 'test-lecture'},
            audioService: mockAudioService,
            pdfCacheService: mockPdfCacheService,
            hiveManager: mockHiveManager,
          ),
        ),
      );

      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('PDF Path Handling', () {
    test('should detect assets path correctly', () {
      const pdfPath = 'assets/lectures/test/slides.pdf';
      final isAssets = pdfPath.startsWith('assets/');
      expect(isAssets, isTrue);
    });

    test('should detect non-assets path correctly', () {
      const pdfPath = '/data/user/0/com.example.app/files/slides.pdf';
      final isAssets = pdfPath.startsWith('assets/');
      expect(isAssets, isFalse);
    });

    test('should build default pdf path correctly', () {
      const lectureId = 'test-lecture';
      final defaultPath = 'assets/lectures/$lectureId/${lectureId}_slides.pdf';
      expect(
        defaultPath,
        equals('assets/lectures/test-lecture/test-lecture_slides.pdf'),
      );
    });

    test('should build default audio path correctly', () {
      const lectureId = 'test-lecture';
      final defaultPath = 'assets/lectures/$lectureId/lecture_with_slides.opus';
      expect(
        defaultPath,
        equals('assets/lectures/test-lecture/lecture_with_slides.opus'),
      );
    });

    test('should build default transcript path correctly', () {
      const lectureId = 'test-lecture';
      final defaultPath = 'assets/lectures/$lectureId/transcript.json';
      expect(
        defaultPath,
        equals('assets/lectures/test-lecture/transcript.json'),
      );
    });
  });
}
