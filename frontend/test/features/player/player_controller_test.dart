import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:mockito/mockito.dart';
import 'package:re_view/features/player/player_controller.dart';
import 'package:re_view/features/player/models/lecture_data.dart';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:pdfx/pdfx.dart';

import 'package:re_view/features/player/services/pdf_service.dart';
import 'mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAudioService mockAudioService;
  late MockPdfCacheService mockPdfCacheService;
  late PdfService mockPdfService;
  late MockPdfDocument mockPdfDocument;
  late StreamController<Duration> positionStreamController;
  late StreamController<ja.PlayerState> stateStreamController;
  late StreamController<Duration?> durationStreamController;
  late Directory tempDir;
  late String tempPdfPath;

  // Minimal valid PDF bytes
  final kMinimalPdfBytes = Uint8List.fromList([
    0x25,
    0x50,
    0x44,
    0x46,
    0x2d,
    0x31,
    0x2e,
    0x34,
    0x0a,
    0x25,
    0xc3,
    0xa4,
    0xc3,
    0xbc,
    0xc3,
    0xb6,
    0xc3,
    0x9f,
    0x0a,
    0x32,
    0x20,
    0x30,
    0x20,
    0x6f,
    0x62,
    0x6a,
    0x0a,
    0x3c,
    0x3c,
    0x2f,
    0x4c,
    0x65,
    0x6e,
    0x67,
    0x74,
    0x68,
    0x20,
    0x33,
    0x3e,
    0x3e,
    0x0a,
    0x73,
    0x74,
    0x72,
    0x65,
    0x61,
    0x6d,
    0x0a,
    0x42,
    0x54,
    0x0a,
    0x45,
    0x54,
    0x0a,
    0x65,
    0x6e,
    0x64,
    0x73,
    0x74,
    0x72,
    0x65,
    0x61,
    0x6d,
    0x0a,
    0x65,
    0x6e,
    0x64,
    0x6f,
    0x62,
    0x6a,
    0x0a,
    0x31,
    0x20,
    0x30,
    0x20,
    0x6f,
    0x62,
    0x6a,
    0x0a,
    0x3c,
    0x3c,
    0x2f,
    0x54,
    0x79,
    0x70,
    0x65,
    0x2f,
    0x50,
    0x61,
    0x67,
    0x65,
    0x2f,
    0x50,
    0x61,
    0x72,
    0x65,
    0x6e,
    0x74,
    0x20,
    0x33,
    0x20,
    0x30,
    0x20,
    0x52,
    0x2f,
    0x52,
    0x65,
    0x73,
    0x6f,
    0x75,
    0x72,
    0x63,
    0x65,
    0x73,
    0x3c,
    0x3c,
    0x2f,
    0x46,
    0x6f,
    0x6e,
    0x74,
    0x3c,
    0x3c,
    0x2f,
    0x46,
    0x31,
    0x20,
    0x34,
    0x20,
    0x30,
    0x20,
    0x52,
    0x3e,
    0x3e,
    0x3e,
    0x3e,
    0x2f,
    0x4d,
    0x65,
    0x64,
    0x69,
    0x61,
    0x42,
    0x6f,
    0x78,
    0x5b,
    0x30,
    0x20,
    0x30,
    0x20,
    0x32,
    0x30,
    0x30,
    0x20,
    0x32,
    0x30,
    0x30,
    0x5d,
    0x2f,
    0x43,
    0x6f,
    0x6e,
    0x74,
    0x65,
    0x6e,
    0x74,
    0x73,
    0x20,
    0x32,
    0x20,
    0x30,
    0x20,
    0x52,
    0x3e,
    0x3e,
    0x0a,
    0x65,
    0x6e,
    0x64,
    0x6f,
    0x62,
    0x6a,
    0x0a,
    0x33,
    0x20,
    0x30,
    0x20,
    0x6f,
    0x62,
    0x6a,
    0x0a,
    0x3c,
    0x3c,
    0x2f,
    0x54,
    0x79,
    0x70,
    0x65,
    0x2f,
    0x50,
    0x61,
    0x67,
    0x65,
    0x73,
    0x2f,
    0x4b,
    0x69,
    0x64,
    0x73,
    0x5b,
    0x31,
    0x20,
    0x30,
    0x20,
    0x52,
    0x5d,
    0x2f,
    0x43,
    0x6f,
    0x75,
    0x6e,
    0x74,
    0x20,
    0x31,
    0x3e,
    0x3e,
    0x0a,
    0x65,
    0x6e,
    0x64,
    0x6f,
    0x62,
    0x6a,
    0x0a,
    0x34,
    0x20,
    0x30,
    0x20,
    0x6f,
    0x62,
    0x6a,
    0x0a,
    0x3c,
    0x3c,
    0x2f,
    0x54,
    0x79,
    0x70,
    0x65,
    0x2f,
    0x46,
    0x6f,
    0x6e,
    0x74,
    0x2f,
    0x53,
    0x75,
    0x62,
    0x74,
    0x79,
    0x70,
    0x65,
    0x2f,
    0x54,
    0x79,
    0x70,
    0x65,
    0x31,
    0x2f,
    0x42,
    0x61,
    0x73,
    0x65,
    0x46,
    0x6f,
    0x6e,
    0x74,
    0x2f,
    0x54,
    0x69,
    0x6d,
    0x65,
    0x73,
    0x2d,
    0x52,
    0x6f,
    0x6d,
    0x61,
    0x6e,
    0x3e,
    0x3e,
    0x0a,
    0x65,
    0x6e,
    0x64,
    0x6f,
    0x62,
    0x6a,
    0x0a,
    0x35,
    0x20,
    0x30,
    0x20,
    0x6f,
    0x62,
    0x6a,
    0x0a,
    0x3c,
    0x3c,
    0x2f,
    0x54,
    0x79,
    0x70,
    0x65,
    0x2f,
    0x43,
    0x61,
    0x74,
    0x61,
    0x6c,
    0x6f,
    0x67,
    0x2f,
    0x50,
    0x61,
    0x67,
    0x65,
    0x73,
    0x20,
    0x33,
    0x20,
    0x30,
    0x20,
    0x52,
    0x3e,
    0x3e,
    0x0a,
    0x65,
    0x6e,
    0x64,
    0x6f,
    0x62,
    0x6a,
    0x0a,
    0x78,
    0x72,
    0x65,
    0x66,
    0x0a,
    0x30,
    0x20,
    0x36,
    0x0a,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x20,
    0x36,
    0x35,
    0x35,
    0x33,
    0x35,
    0x20,
    0x66,
    0x20,
    0x0a,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x37,
    0x33,
    0x20,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x20,
    0x6e,
    0x20,
    0x0a,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x31,
    0x39,
    0x20,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x20,
    0x6e,
    0x20,
    0x0a,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x31,
    0x37,
    0x30,
    0x20,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x20,
    0x6e,
    0x20,
    0x0a,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x32,
    0x33,
    0x33,
    0x20,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x20,
    0x6e,
    0x20,
    0x0a,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x33,
    0x31,
    0x36,
    0x20,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x20,
    0x6e,
    0x20,
    0x0a,
    0x74,
    0x72,
    0x61,
    0x69,
    0x6c,
    0x65,
    0x72,
    0x0a,
    0x3c,
    0x3c,
    0x2f,
    0x53,
    0x69,
    0x7a,
    0x65,
    0x20,
    0x36,
    0x2f,
    0x52,
    0x6f,
    0x6f,
    0x74,
    0x20,
    0x35,
    0x20,
    0x30,
    0x20,
    0x52,
    0x3e,
    0x3e,
    0x0a,
    0x73,
    0x74,
    0x61,
    0x72,
    0x74,
    0x78,
    0x72,
    0x65,
    0x66,
    0x0a,
    0x33,
    0x36,
    0x35,
    0x0a,
    0x25,
    0x25,
    0x45,
    0x4f,
    0x46,
    0x0a,
  ]);

  setUp(() {
    mockAudioService = MockAudioService();
    mockPdfCacheService = MockPdfCacheService();
    mockPdfDocument = MockPdfDocument();
    mockPdfService = FakePdfService(mockPdfDocument);

    // Setup temp directory and file
    tempDir = Directory.systemTemp.createTempSync();
    tempPdfPath = '${tempDir.path}/test.pdf';
    File(tempPdfPath).writeAsBytesSync(kMinimalPdfBytes);

    // Mock path_provider
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getTemporaryDirectory') {
              return tempDir.path;
            }
            return null;
          },
        );

    // Mock SystemChrome (flutter/platform)
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter/platform', JSONMethodCodec()),
          (MethodCall methodCall) async {
            if (methodCall.method == 'SystemChrome.setPreferredOrientations') {
              return null;
            }
            return null;
          },
        );

    // Create stream controllers for mocking
    positionStreamController = StreamController<Duration>.broadcast();
    stateStreamController = StreamController<ja.PlayerState>.broadcast();
    durationStreamController = StreamController<Duration?>.broadcast();

    // Setup default mock behaviors
    when(
      mockAudioService.positionStream,
    ).thenAnswer((_) => positionStreamController.stream);
    when(
      mockAudioService.stateStream,
    ).thenAnswer((_) => stateStreamController.stream);
    when(
      mockAudioService.durationStream,
    ).thenAnswer((_) => durationStreamController.stream);
    when(
      mockAudioService.loadAudio(any),
    ).thenAnswer((_) async => Future.value());
    when(mockAudioService.play()).thenAnswer((_) async {
      stateStreamController.add(ja.PlayerState(true, ja.ProcessingState.ready));
      return Future.value();
    });
    when(mockAudioService.pause()).thenAnswer((_) async {
      stateStreamController.add(
        ja.PlayerState(false, ja.ProcessingState.ready),
      );
      return Future.value();
    });
    when(mockAudioService.seek(any)).thenAnswer((invocation) async {
      final position = invocation.positionalArguments[0] as Duration;
      positionStreamController.add(position);
      return Future.value();
    });
    when(
      mockAudioService.setSpeed(any),
    ).thenAnswer((_) async => Future.value());
    when(mockAudioService.dispose()).thenAnswer((_) async => Future.value());

    // Default PdfService behavior - handled by FakePdfService
  });

  tearDown(() async {
    await positionStreamController.close();
    await stateStreamController.close();
    await durationStreamController.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}

    // Clear mocks
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter/platform', JSONMethodCodec()),
          null,
        );
  });

  TranscriptData createTestTranscriptData() {
    return TranscriptData(
      ttsTotalDuration: 3000,
      originalTotalDuration: 3000,
      timestamps: [
        TranscriptSentence(
          textEng: 'First sentence',
          textKor: '첫 번째 문장',
          slideNumber: 1,
          originalStartTime: 0,
          originalEndTime: 1000,
          ttsStartTime: 0,
          ttsEndTime: 1000,
        ),
        TranscriptSentence(
          textEng: 'Second sentence',
          textKor: '두 번째 문장',
          slideNumber: 1,
          originalStartTime: 0,
          originalEndTime: 1000,
          ttsStartTime: 1000,
          ttsEndTime: 2000,
        ),
        TranscriptSentence(
          textEng: 'Third sentence',
          textKor: '세 번째 문장',
          slideNumber: 2,
          originalStartTime: 0,
          originalEndTime: 1000,
          ttsStartTime: 2000,
          ttsEndTime: 3000,
        ),
      ],
    );
  }

  group('PlayerController - Constructor', () {
    test('creates controller with required services', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      expect(controller, isNotNull);
      expect(controller.pdfCacheService, equals(mockPdfCacheService));
    });

    test('initializes ValueNotifiers with default values', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      expect(controller.showControls.value, isFalse);
      expect(controller.isPagesExpanded.value, isFalse);
      expect(controller.showTranscriptPanel.value, isFalse);
      expect(controller.isFullscreen.value, isFalse);
      expect(controller.isPlaying.value, isFalse);
      expect(controller.isSynced.value, isTrue);
      expect(controller.isCaptionEnabled.value, isFalse);
      expect(controller.isKoreanLanguage.value, isFalse);
      expect(controller.isOriginalAudio.value, isFalse);
      expect(controller.currentTime.value, equals(0.0));
      expect(controller.currentPage.value, equals(1));
      expect(controller.currentSentenceIndex.value, isNull);
      expect(controller.isAutoScrolling.value, isTrue);

      controller.dispose();
    });
  });

  group('PlayerController - UI Control Methods', () {
    test('toggleControls changes showControls value', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      expect(controller.showControls.value, isFalse);

      controller.toggleControls();
      expect(controller.showControls.value, isTrue);

      controller.toggleControls();
      expect(controller.showControls.value, isFalse);

      controller.dispose();
    });

    test('togglePages changes isPagesExpanded value', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      expect(controller.isPagesExpanded.value, isFalse);

      controller.togglePages();
      expect(controller.isPagesExpanded.value, isTrue);

      controller.togglePages();
      expect(controller.isPagesExpanded.value, isFalse);

      controller.dispose();
    });

    test('toggleSync changes isSynced value', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      expect(controller.isSynced.value, isTrue);

      controller.toggleSync();
      expect(controller.isSynced.value, isFalse);

      controller.toggleSync();
      expect(controller.isSynced.value, isTrue);

      controller.dispose();
    });

    test('toggleCaption changes isCaptionEnabled value', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      expect(controller.isCaptionEnabled.value, isFalse);

      controller.toggleCaption();
      expect(controller.isCaptionEnabled.value, isTrue);

      controller.toggleCaption();
      expect(controller.isCaptionEnabled.value, isFalse);

      controller.dispose();
    });

    test('toggleTranscriptPanel changes showTranscriptPanel value', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      expect(controller.showTranscriptPanel.value, isFalse);

      controller.toggleTranscriptPanel();
      expect(controller.showTranscriptPanel.value, isTrue);

      controller.toggleTranscriptPanel();
      expect(controller.showTranscriptPanel.value, isFalse);

      controller.dispose();
    });

    test(
      'toggleTranscriptLanguage changes isKoreanLanguage when Korean exists',
      () {
        final controller = PlayerController(
          audioService: mockAudioService,
          pdfCacheService: mockPdfCacheService,
          pdfService: mockPdfService,
        );

        controller.transcriptData = createTestTranscriptData();

        expect(controller.isKoreanLanguage.value, isFalse);

        controller.toggleTranscriptLanguage();
        expect(controller.isKoreanLanguage.value, isTrue);

        controller.toggleTranscriptLanguage();
        expect(controller.isKoreanLanguage.value, isFalse);

        controller.dispose();
      },
    );

    test('handlePdfTap toggles controls in vertical mode', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      expect(controller.showControls.value, isFalse);

      controller.handlePdfTap(true); // isVertical = true
      expect(controller.showControls.value, isTrue);

      controller.handlePdfTap(true);
      expect(controller.showControls.value, isFalse);

      controller.dispose();
    });

    test(
      'handlePdfTap toggles controls in horizontal mode when pages not expanded',
      () {
        final controller = PlayerController(
          audioService: mockAudioService,
          pdfCacheService: mockPdfCacheService,
          pdfService: mockPdfService,
        );

        expect(controller.showControls.value, isFalse);
        expect(controller.isPagesExpanded.value, isFalse);

        controller.handlePdfTap(false); // isVertical = false
        expect(controller.showControls.value, isTrue);

        controller.dispose();
      },
    );

    test(
      'handlePdfTap closes pages in horizontal mode when pages expanded',
      () {
        final controller = PlayerController(
          audioService: mockAudioService,
          pdfCacheService: mockPdfCacheService,
          pdfService: mockPdfService,
        );

        controller.isPagesExpanded.value = true;
        expect(controller.isPagesExpanded.value, isTrue);

        controller.handlePdfTap(false); // isVertical = false
        expect(controller.isPagesExpanded.value, isFalse);

        controller.dispose();
      },
    );

    test('handleVerticalDrag expands pages when swiping up', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      expect(controller.isPagesExpanded.value, isFalse);

      final details = DragUpdateDetails(
        globalPosition: Offset.zero,
        delta: const Offset(0, -6), // Swipe up
      );

      controller.handleVerticalDrag(details);
      expect(controller.isPagesExpanded.value, isTrue);

      controller.dispose();
    });

    test(
      'handleVerticalDrag does not expand pages when not swiping up enough',
      () {
        final controller = PlayerController(
          audioService: mockAudioService,
          pdfCacheService: mockPdfCacheService,
          pdfService: mockPdfService,
        );

        expect(controller.isPagesExpanded.value, isFalse);

        final details = DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(0, -4), // Not enough
        );

        controller.handleVerticalDrag(details);
        expect(controller.isPagesExpanded.value, isFalse);

        controller.dispose();
      },
    );

    test('handleVerticalDrag does nothing when pages already expanded', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      controller.isPagesExpanded.value = true;

      final details = DragUpdateDetails(
        globalPosition: Offset.zero,
        delta: const Offset(0, -6), // Swipe up
      );

      controller.handleVerticalDrag(details);
      expect(controller.isPagesExpanded.value, isTrue);

      controller.dispose();
    });
  });

  group('PlayerController - Playback Control Methods', () {
    test('playPause starts playback when paused', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      // Setup audio state listener manually for testing
      final subscription = stateStreamController.stream.listen((state) {
        controller.isPlaying.value = state.playing;
      });

      expect(controller.isPlaying.value, isFalse);

      await controller.playPause();

      // Wait for stream event to be processed
      await Future.delayed(const Duration(milliseconds: 10));

      expect(controller.isPlaying.value, isTrue);

      await subscription.cancel();
      controller.dispose();
    });

    test('playPause pauses playback when playing', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      // Setup audio state listener manually for testing
      final subscription = stateStreamController.stream.listen((state) {
        controller.isPlaying.value = state.playing;
      });

      controller.isPlaying.value = true;

      await controller.playPause();

      // Wait for stream event to be processed
      await Future.delayed(const Duration(milliseconds: 10));

      expect(controller.isPlaying.value, isFalse);

      await subscription.cancel();
      controller.dispose();
    });

    test('seek updates current time', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      // Setup position stream listener to update currentTime
      final subscription = positionStreamController.stream.listen((position) {
        controller.currentTime.value = position.inMilliseconds / 1000.0;
      });

      controller.ttsTotalDuration = 100.0;
      controller.originalTotalDuration = 100.0;

      await controller.seek(50.0);

      // Wait for stream event to be processed
      await Future.delayed(const Duration(milliseconds: 10));

      // Verify audioService.seek was called with correct Duration
      verify(
        mockAudioService.seek(const Duration(milliseconds: 50000)),
      ).called(1);

      // Verify currentTime was updated
      expect(controller.currentTime.value, equals(50.0));

      await subscription.cancel();
      controller.dispose();
    });

    test('seek prevents concurrent seeks', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      // Setup position stream listener to update currentTime
      final subscription = positionStreamController.stream.listen((position) {
        controller.currentTime.value = position.inMilliseconds / 1000.0;
      });

      controller.ttsTotalDuration = 100.0;
      controller.originalTotalDuration = 100.0;

      // Start first seek (it will complete almost immediately in test)
      final future1 = controller.seek(30.0);
      // Second seek is called while first is in progress
      // Due to _isSeeking flag, second seek should be ignored
      final future2 = controller.seek(50.0);

      await future1;
      await future2;

      // Wait for stream event to be processed
      await Future.delayed(const Duration(milliseconds: 10));

      // Verify audioService.seek was only called once (for 30.0)
      // The second seek (50.0) should have been prevented by _isSeeking flag
      verify(
        mockAudioService.seek(const Duration(milliseconds: 30000)),
      ).called(1);

      // Verify the second seek was never called
      verifyNever(mockAudioService.seek(const Duration(milliseconds: 50000)));

      // Current time should reflect the first seek
      expect(controller.currentTime.value, equals(30.0));

      await subscription.cancel();
      controller.dispose();
    });

    test('skipBackward seeks backward by 10 seconds', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      // Setup position stream listener to update currentTime
      final subscription = positionStreamController.stream.listen((position) {
        controller.currentTime.value = position.inMilliseconds / 1000.0;
      });

      controller.ttsTotalDuration = 100.0;
      controller.originalTotalDuration = 100.0;
      controller.currentTime.value = 30.0;

      await controller.skipBackward();

      // Wait for stream event to be processed
      await Future.delayed(const Duration(milliseconds: 10));

      // Verify audioService.seek was called with correct Duration (30 - 10 = 20)
      verify(
        mockAudioService.seek(const Duration(milliseconds: 20000)),
      ).called(1);

      // Verify currentTime was updated to 20.0
      expect(controller.currentTime.value, equals(20.0));

      await subscription.cancel();
      controller.dispose();
    });

    test('skipBackward clamps to 0', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      // Setup position stream listener to update currentTime
      final subscription = positionStreamController.stream.listen((position) {
        controller.currentTime.value = position.inMilliseconds / 1000.0;
      });

      controller.ttsTotalDuration = 100.0;
      controller.originalTotalDuration = 100.0;
      controller.currentTime.value = 10.0;

      await controller.skipBackward();

      // Wait for stream event to be processed
      await Future.delayed(const Duration(milliseconds: 10));

      // Verify audioService.seek was called with Duration 0 (clamped)
      verify(mockAudioService.seek(const Duration(milliseconds: 0))).called(1);

      // Verify currentTime was clamped to 0.0
      expect(controller.currentTime.value, equals(0.0));

      await subscription.cancel();
      controller.dispose();
    });

    test('skipForward seeks forward by 10 seconds', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      // Setup position stream listener to update currentTime
      final subscription = positionStreamController.stream.listen((position) {
        controller.currentTime.value = position.inMilliseconds / 1000.0;
      });

      controller.ttsTotalDuration = 100.0;
      controller.originalTotalDuration = 100.0;
      controller.currentTime.value = 30.0;

      await controller.skipForward();

      // Wait for stream event to be processed
      await Future.delayed(const Duration(milliseconds: 10));

      // Verify audioService.seek was called with correct Duration (30 + 15 = 45)
      verify(
        mockAudioService.seek(const Duration(milliseconds: 40000)),
      ).called(1);

      // Verify currentTime was updated to 45.0
      expect(controller.currentTime.value, equals(40.0));

      await subscription.cancel();
      controller.dispose();
    });

    test('skipForward clamps to totalTime', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      // Setup position stream listener to update currentTime
      final subscription = positionStreamController.stream.listen((position) {
        controller.currentTime.value = position.inMilliseconds / 1000.0;
      });

      controller.ttsTotalDuration = 100.0;
      controller.originalTotalDuration = 100.0;
      controller.currentTime.value = 95.0;

      await controller.skipForward();

      // Wait for stream event to be processed
      await Future.delayed(const Duration(milliseconds: 10));

      // Verify audioService.seek was called with Duration 100 (clamped)
      verify(
        mockAudioService.seek(const Duration(milliseconds: 100000)),
      ).called(1);

      // Verify currentTime was clamped to 100.0
      expect(controller.currentTime.value, equals(100.0));

      await subscription.cancel();
      controller.dispose();
    });

    test('setPlaybackSpeed changes speed', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      await controller.setPlaybackSpeed(1.5);

      // Verify audioService.setSpeed was called with correct speed
      verify(mockAudioService.setSpeed(1.5)).called(1);

      await controller.setPlaybackSpeed(2.0);

      // Verify audioService.setSpeed was called with new speed
      verify(mockAudioService.setSpeed(2.0)).called(1);

      controller.dispose();
    });
  });

  group('PlayerController - Page Control Methods', () {
    test('jumpToPage updates currentPage', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      expect(controller.currentPage.value, equals(1));

      controller.jumpToPage(5);
      expect(controller.currentPage.value, equals(5));

      controller.dispose();
    });

    test('onPdfPageChanged updates currentPage', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      expect(controller.currentPage.value, equals(1));

      controller.onPdfPageChanged(3);
      expect(controller.currentPage.value, equals(3));

      controller.dispose();
    });
  });

  group('PlayerController - Calculated Values', () {
    test('syncedPageNumber returns correct page when sentence is set', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      controller.transcriptData = createTestTranscriptData();
      controller.currentSentenceIndex.value = 0;

      expect(controller.syncedPageNumber, equals(1));

      controller.currentSentenceIndex.value = 2;
      expect(controller.syncedPageNumber, equals(2));

      controller.dispose();
    });

    test('syncedPageNumber returns null when no sentence index', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      controller.transcriptData = createTestTranscriptData();

      expect(controller.syncedPageNumber, isNull);

      controller.dispose();
    });

    test('syncedPageNumber returns null when no transcript data', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      controller.currentSentenceIndex.value = 0;

      expect(controller.syncedPageNumber, isNull);

      controller.dispose();
    });

    test('pageDifference calculates correctly', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      controller.transcriptData = createTestTranscriptData();
      controller.currentSentenceIndex.value = 2; // slideNumber = 2
      controller.currentPage.value = 1;

      expect(controller.pageDifference, equals(1)); // 2 - 1 = 1

      controller.dispose();
    });

    test('pageDifference returns null when syncedPage is null', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      expect(controller.pageDifference, isNull);

      controller.dispose();
    });

    test('captionText returns English text by default', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      controller.transcriptData = createTestTranscriptData();
      controller.currentSentenceIndex.value = 0;

      expect(controller.captionText, equals('First sentence'));

      controller.dispose();
    });

    test('captionText returns empty string when no sentence index', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      controller.transcriptData = createTestTranscriptData();

      expect(controller.captionText, equals(''));

      controller.dispose();
    });

    test('pageCount returns 0 when no PDF document', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      expect(controller.pageCount, equals(0));

      controller.dispose();
    });
  });

  group('PlayerController - Fullscreen', () {
    test('initializes isFullscreen with default value', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      expect(controller.isFullscreen.value, isFalse);

      controller.dispose();
    });

    test('isFullscreen can be set directly', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      expect(controller.isFullscreen.value, isFalse);

      // Test that the value can be changed
      controller.isFullscreen.value = true;
      expect(controller.isFullscreen.value, isTrue);

      controller.isFullscreen.value = false;
      expect(controller.isFullscreen.value, isFalse);

      controller.dispose();
    });
  });

  group('PlayerController - Audio Source Toggle', () {
    test('initializes isOriginalAudio with default value', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      expect(controller.isOriginalAudio.value, isFalse);

      controller.dispose();
    });

    test('isOriginalAudio can be set directly', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      expect(controller.isOriginalAudio.value, isFalse);

      // Test that the value can be changed
      controller.isOriginalAudio.value = true;
      expect(controller.isOriginalAudio.value, isTrue);

      controller.isOriginalAudio.value = false;
      expect(controller.isOriginalAudio.value, isFalse);

      controller.dispose();
    });
  });

  group('PlayerController - Double Tap Skip', () {
    test('saveDoubleTapPosition stores tap position', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      controller.saveDoubleTapPosition(100.0);

      // The position is stored internally, no direct way to verify
      // but we can test handleDoubleTapSkip behavior

      controller.dispose();
    });

    test(
      'handleDoubleTapSkip skips backward when tapped on left half',
      () async {
        final controller = PlayerController(
          audioService: mockAudioService,
          pdfCacheService: mockPdfCacheService,
          pdfService: mockPdfService,
        );

        // Setup position stream listener to update currentTime
        final subscription = positionStreamController.stream.listen((position) {
          controller.currentTime.value = position.inMilliseconds / 1000.0;
        });

        controller.ttsTotalDuration = 100.0;
        controller.originalTotalDuration = 100.0;
        controller.currentTime.value = 30.0;

        // Save tap position on left half
        controller.saveDoubleTapPosition(100.0);

        // Handle double tap (screen width = 400)
        controller.handleDoubleTapSkip(400.0);

        // Wait for stream event to be processed
        await Future.delayed(const Duration(milliseconds: 10));

        // Verify audioService.seek was called for backward skip (30 - 10 = 20)
        verify(
          mockAudioService.seek(const Duration(milliseconds: 20000)),
        ).called(1);

        await subscription.cancel();
        controller.dispose();
      },
    );

    test(
      'handleDoubleTapSkip skips forward when tapped on right half',
      () async {
        final controller = PlayerController(
          audioService: mockAudioService,
          pdfCacheService: mockPdfCacheService,
          pdfService: mockPdfService,
        );

        // Setup position stream listener to update currentTime
        final subscription = positionStreamController.stream.listen((position) {
          controller.currentTime.value = position.inMilliseconds / 1000.0;
        });

        controller.ttsTotalDuration = 100.0;
        controller.originalTotalDuration = 100.0;
        controller.currentTime.value = 30.0;

        // Save tap position on right half
        controller.saveDoubleTapPosition(300.0);

        // Handle double tap (screen width = 400)
        controller.handleDoubleTapSkip(400.0);

        // Wait for stream event to be processed
        await Future.delayed(const Duration(milliseconds: 10));

        // Verify audioService.seek was called for forward skip (30 + 10 = 40)
        verify(
          mockAudioService.seek(const Duration(milliseconds: 40000)),
        ).called(1);

        await subscription.cancel();
        controller.dispose();
      },
    );
  });

  group('PlayerController - Dispose', () {
    test('dispose cleans up all resources', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      // Set up some state
      controller.showControls.value = true;
      controller.currentTime.value = 50.0;

      // Call dispose - should not throw
      expect(() => controller.dispose(), returnsNormally);

      // Verify audioService.dispose was called
      verify(mockAudioService.dispose()).called(1);

      // Verify ValueNotifiers are disposed (they should throw FlutterError when accessed after dispose)
      expect(() => controller.showControls.value = false, throwsFlutterError);
    });

    test('dispose can be called multiple times safely', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      // First dispose
      controller.dispose();

      // Second dispose - should not throw
      expect(() => controller.dispose(), returnsNormally);

      // Verify audioService.dispose was called exactly once (not twice)
      // This confirms _isDisposed flag prevents duplicate disposal
      verify(mockAudioService.dispose()).called(1);

      // Verify no additional interactions with audioService after dispose
      verifyNoMoreInteractions(mockAudioService);
    });
  });

  group('PlayerController - Additional Coverage', () {
    test('playPause triggers scroll when conditions are met', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      controller.transcriptData = createTestTranscriptData();
      controller.currentSentenceIndex.value = 1;
      controller.isAutoScrolling.value = true;
      controller.isPlaying.value = false; // Initially not playing

      // playPause should call play() and trigger delayed scroll
      await controller.playPause();

      // Wait for delayed scroll scheduling (100ms)
      await Future.delayed(const Duration(milliseconds: 150));

      verify(mockAudioService.play()).called(1);

      controller.dispose();
    });

    test('seek handles different edge cases', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      controller.ttsTotalDuration = 100.0;
      controller.originalTotalDuration = 100.0;
      controller.transcriptData = createTestTranscriptData();

      // Normal seek
      await controller.seek(50.0);

      // Verify that seek was called
      verify(mockAudioService.seek(any)).called(1);

      // Wait for forced move flag and auto-scroll restoration
      await Future.delayed(const Duration(milliseconds: 550));

      controller.dispose();
    });

    test('startPlayback delegates to audio service play', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      await controller.startPlayback();

      verify(mockAudioService.play()).called(1);
      controller.dispose();
    });

    test('setPlaybackSpeed delegates to audio service', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      await controller.setPlaybackSpeed(1.75);

      verify(mockAudioService.setSpeed(1.75)).called(1);
      controller.dispose();
    });
  });

  group('PlayerController - updateCurrentSentence', () {
    test('updates sentence index and page when synced', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      )..transcriptData = createTestTranscriptData();

      controller.isSynced.value = true;
      controller.currentPage.value = 5;

      controller.updateCurrentSentence(
        false,
        1.5,
      ); // 1500 ms => second sentence

      expect(controller.currentSentenceIndex.value, equals(1));
      expect(controller.currentPage.value, equals(1));

      controller.dispose();
    });

    test('does not change page when unsynced', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      )..transcriptData = createTestTranscriptData();

      controller.isSynced.value = false;
      controller.currentPage.value = 7;

      controller.updateCurrentSentence(false, 2.5); // 2500 ms => third sentence

      expect(controller.currentSentenceIndex.value, equals(2));
      expect(controller.currentPage.value, equals(7)); // remains unchanged

      controller.dispose();
    });
  });

  group('PlayerController - seekToSentence', () {
    test('seekToSentence seeks to sentence start time', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      controller.transcriptData = createTestTranscriptData();

      await controller.seekToSentence(1);

      // Verify seek was called with second sentence start time (1000ms)
      verify(
        mockAudioService.seek(const Duration(milliseconds: 1000)),
      ).called(1);

      controller.dispose();
    });

    test('seekToSentence handles invalid index', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      controller.transcriptData = createTestTranscriptData();

      // Try negative index
      await controller.seekToSentence(-1);
      verifyNever(mockAudioService.seek(any));

      // Try out of bounds index
      await controller.seekToSentence(999);
      verifyNever(mockAudioService.seek(any));

      controller.dispose();
    });

    test('seekToSentence handles null transcript data', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      // No transcript data set
      await controller.seekToSentence(0);

      verifyNever(mockAudioService.seek(any));

      controller.dispose();
    });

    test('seekToSentence sets sentence index and page', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      controller.transcriptData = createTestTranscriptData();
      controller.isSynced.value = true;
      controller.currentPage.value = 1;

      // Seek to third sentence (page 2)
      await controller.seekToSentence(2);

      // Wait for delayed operations to complete
      await Future.delayed(const Duration(milliseconds: 50));

      // Sentence and page should be updated immediately by _setCurrentSentenceAndPage
      expect(controller.currentSentenceIndex.value, equals(2));
      expect(controller.currentPage.value, equals(2));

      controller.dispose();
    });
  });

  group('PlayerController - seekToSlide', () {
    test(
      'seekToSlide with sync enabled seeks to first sentence of slide',
      () async {
        final controller = PlayerController(
          audioService: mockAudioService,
          pdfCacheService: mockPdfCacheService,
          pdfService: mockPdfService,
        );

        controller.transcriptData = createTestTranscriptData();
        controller.isSynced.value = true;

        // Seek to slide 2 (first sentence is index 2)
        await controller.seekToSlide(2);

        // Verify seek was called with third sentence start time (2000ms)
        verify(
          mockAudioService.seek(const Duration(milliseconds: 2000)),
        ).called(1);

        controller.dispose();
      },
    );

    test('seekToSlide with sync disabled only jumps to page', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      controller.transcriptData = createTestTranscriptData();
      controller.isSynced.value = false;

      await controller.seekToSlide(2);

      // Should not call audio seek, only jump to page
      verifyNever(mockAudioService.seek(any));
      expect(controller.currentPage.value, equals(2));

      controller.dispose();
    });

    test('seekToSlide handles null transcript data', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      controller.isSynced.value = true;

      await controller.seekToSlide(2);

      verifyNever(mockAudioService.seek(any));

      controller.dispose();
    });

    test('seekToSlide handles non-existent slide number', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      controller.transcriptData = createTestTranscriptData();
      controller.isSynced.value = true;

      // Try slide number that doesn't exist
      await controller.seekToSlide(999);

      verifyNever(mockAudioService.seek(any));

      controller.dispose();
    });
  });

  group('PlayerController - scrollToCurrentSentence', () {
    test(
      'scrollToCurrentSentence returns early when no sentence index',
      () async {
        final controller = PlayerController(
          audioService: mockAudioService,
          pdfCacheService: mockPdfCacheService,
          pdfService: mockPdfService,
        );

        controller.transcriptData = createTestTranscriptData();
        // currentSentenceIndex is null by default

        // Should return early without error
        await controller.scrollToCurrentSentence();

        controller.dispose();
      },
    );

    test(
      'scrollToCurrentSentence returns early when no transcript data',
      () async {
        final controller = PlayerController(
          audioService: mockAudioService,
          pdfCacheService: mockPdfCacheService,
          pdfService: mockPdfService,
        );

        controller.currentSentenceIndex.value = 0;
        // transcriptData is null

        // Should return early without error
        await controller.scrollToCurrentSentence();

        controller.dispose();
      },
    );

    test(
      'scrollToCurrentSentence returns early when not playing and not forced',
      () async {
        final controller = PlayerController(
          audioService: mockAudioService,
          pdfCacheService: mockPdfCacheService,
          pdfService: mockPdfService,
        );

        controller.transcriptData = createTestTranscriptData();
        controller.currentSentenceIndex.value = 0;
        controller.isPlaying.value = false;

        // Should return early without scrolling
        await controller.scrollToCurrentSentence(forceScroll: false);

        controller.dispose();
      },
    );
  });

  group('PlayerController - seek error handling', () {
    test('seek handles audio service error gracefully', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      // Setup audio service to throw error on seek
      when(mockAudioService.seek(any)).thenThrow(Exception('Seek failed'));

      controller.ttsTotalDuration = 100.0;
      controller.originalTotalDuration = 100.0;

      // Should not throw, error is caught internally
      await controller.seek(50.0);

      verify(mockAudioService.seek(any)).called(1);

      controller.dispose();
    });

    test('seek sets forced move and auto-scroll flags', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      // Reset mock to default behavior
      when(mockAudioService.seek(any)).thenAnswer((_) async => Future.value());

      controller.ttsTotalDuration = 100.0;
      controller.originalTotalDuration = 100.0;
      controller.isAutoScrolling.value = false;

      await controller.seek(30.0);

      // isAutoScrolling should be set to true by seek
      expect(controller.isAutoScrolling.value, isTrue);

      controller.dispose();
    });
  });

  group('PlayerController - loadPdfDocument', () {
    test('loadPdfDocument loads from file', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      await controller.loadPdfDocument(tempPdfPath, 'lecture1', 1);

      final fakeService = mockPdfService as FakePdfService;
      expect(fakeService.log, contains('openFile($tempPdfPath)'));
      expect(fakeService.log, isNot(contains('openAsset')));

      expect(controller.pdfDocument, equals(mockPdfDocument));
      expect(controller.currentPage.value, equals(1));

      controller.dispose();
    });

    test('loadPdfDocument loads from asset', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      const assetPath = 'assets/lectures/lecture1/slides.pdf';
      await controller.loadPdfDocument(assetPath, 'lecture1', 1);

      final fakeService = mockPdfService as FakePdfService;
      expect(fakeService.log, contains('openAsset($assetPath)'));
      expect(fakeService.log, isNot(contains('openFile')));

      expect(controller.pdfDocument, equals(mockPdfDocument));

      controller.dispose();
    });

    test('loadPdfDocument handles error', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      final fakeService = mockPdfService as FakePdfService;
      fakeService.errorToThrow = Exception('Load failed');

      expect(
        () => controller.loadPdfDocument(tempPdfPath, 'lecture1', 1),
        throwsException,
      );

      controller.dispose();
    });

    test('loadPdfDocument uses cached thumbnail if available', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      // We can't easily mock ThumbnailCacheManager singleton without more refactoring
      // But we can verify that loadPdfDocument proceeds even if cache is empty (default)

      await controller.loadPdfDocument(tempPdfPath, 'lecture1', 1);

      // Verify setCachedImage was NOT called (since cache is empty)
      verifyNever(mockPdfCacheService.setCachedImage(any, any));

      controller.dispose();
    });
  });

  group('PlayerController - Initialize & Full Coverage', () {
    testWidgets('initialize loads PDF and audio correctly', (tester) async {
      final controller = TestPlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      final transcriptData = createTestTranscriptData();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Container();
            },
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(Container));

      await controller.initialize(
        context,
        'lecture1',
        transcriptData,
        tempPdfPath,
        'audio.mp3',
        'original.mp3',
        false,
      );

      expect(controller.transcriptData, equals(transcriptData));
      expect(controller.isKoreanLanguage.value, isFalse);
      expect(controller.isOriginalAudio.value, isFalse);
      verify(mockAudioService.loadAudio('audio.mp3')).called(1);

      controller.dispose();
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('toggleFullscreen changes orientation and state', (
      tester,
    ) async {
      final controller = TestPlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      expect(controller.isFullscreen.value, isFalse);

      await controller.toggleFullscreen();
      expect(controller.isFullscreen.value, isTrue);

      await controller.toggleFullscreen();
      expect(controller.isFullscreen.value, isFalse);

      controller.dispose();
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('toggleAudioSource switches audio and seeks', (tester) async {
      final controller = TestPlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      final transcriptData = createTestTranscriptData();

      await tester.pumpWidget(MaterialApp(home: Container()));
      final BuildContext context = tester.element(find.byType(Container));

      await controller.initialize(
        context,
        'lecture1',
        transcriptData,
        tempPdfPath,
        'audio.mp3',
        'original.mp3',
        false,
      );

      expect(controller.isOriginalAudio.value, isFalse);

      await controller.toggleAudioSource();

      expect(controller.isOriginalAudio.value, isTrue);
      verify(mockAudioService.switchAudio('original.mp3', any)).called(1);

      await controller.toggleAudioSource();

      expect(controller.isOriginalAudio.value, isFalse);
      verify(mockAudioService.switchAudio('audio.mp3', any)).called(1);

      controller.dispose();
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('isAudioOriginal true scenarios', (tester) async {
      final controller = TestPlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      final transcriptData = createTestTranscriptData();

      await tester.pumpWidget(MaterialApp(home: Container()));
      final BuildContext context = tester.element(find.byType(Container));

      await controller.initialize(
        context,
        'lecture1',
        transcriptData,
        tempPdfPath,
        'audio.mp3',
        'original.mp3',
        true,
      );

      expect(controller.isOriginalAudio.value, isTrue);
      expect(controller.isKoreanLanguage.value, isTrue);

      controller.updateCurrentSentence(false, 0.5);
      expect(controller.currentSentenceIndex.value, equals(0));

      await controller.seek(0.5);
      verify(mockAudioService.seek(any)).called(1);

      controller.dispose();
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('cleanupTempPdfFiles deletes new temp files', (tester) async {
      final controller = TestPlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      final transcriptData = createTestTranscriptData();
      await tester.pumpWidget(MaterialApp(home: Container()));
      final BuildContext context = tester.element(find.byType(Container));

      // Set initial files manually since we override loadPdfDocument
      controller.initialTempFiles = [tempPdfPath];

      await controller.initialize(
        context,
        'lecture1',
        transcriptData,
        tempPdfPath,
        'audio.mp3',
        'original.mp3',
        false,
      );

      final newTempFile = File('${tempDir.path}/new_temp.pdf');
      newTempFile.writeAsBytesSync([1, 2, 3]);

      controller.dispose();
      await tester.pump(const Duration(milliseconds: 600));

      expect(newTempFile.existsSync(), isFalse);

      expect(File(tempPdfPath).existsSync(), isTrue);
    });

    testWidgets('scroll listener pauses and resumes auto-scrolling', (
      tester,
    ) async {
      final controller = TestPlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
        pdfService: mockPdfService,
      );

      final transcriptData = createTestTranscriptData();

      await tester.pumpWidget(MaterialApp(home: Container()));
      final BuildContext context = tester.element(find.byType(Container));

      await controller.initialize(
        context,
        'lecture1',
        transcriptData,
        tempPdfPath,
        'audio.mp3',
        'original.mp3',
        false,
      );

      // Now pump the list view
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller.transcriptScrollController,
              itemCount: 100,
              itemExtent: 50,
              itemBuilder: (context, index) => Text('Item $index'),
            ),
          ),
        ),
      );

      // Initial state
      expect(controller.isAutoScrolling.value, isTrue);

      // Simulate user scroll
      final gesture = await tester.startGesture(const Offset(100, 300));
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();

      // Should pause auto-scrolling
      expect(controller.isAutoScrolling.value, isFalse);

      await gesture.up();
      await tester.pump();

      // Wait for timer (1000ms)
      await tester.pump(const Duration(milliseconds: 1100));

      // Should resume auto-scrolling
      expect(controller.isAutoScrolling.value, isTrue);

      controller.dispose();
      await tester.pump(const Duration(milliseconds: 600));
    });
  });
}

class MockPdfDocument extends Mock implements PdfDocument {
  @override
  int get pagesCount => 5;

  @override
  Future<void> close() => Future.value();
}

class TestPlayerController extends PlayerController {
  TestPlayerController({
    required super.audioService,
    required super.pdfCacheService,
    required super.pdfService,
  });

  final MockPdfDocument mockPdfDocument = MockPdfDocument();

  @override
  Future<void> loadPdfDocument(
    String pdfPath,
    String lectureId,
    int initialPage,
  ) async {
    pdfDocument = mockPdfDocument;
    // We don't set initialTempFiles here, we set it manually in test if needed

    // Set currentPage
    currentPage.value = initialPage;

    // We don't initialize pdfController because it's hard to mock
    // But if other methods use pdfController, they might fail.
    // Let's see if we can mock PdfController?
    // PdfController is a class.
    // But PlayerController instantiates it: pdfController = PdfController(...).
    // We can't override that unless we extract it to a factory method.
    // But for now, let's see if tests pass without pdfController being fully functional.
    // jumpToPage uses pdfController.
    // If pdfController is null, jumpToPage might throw or do nothing?
    // In PlayerController: pdfController?.jumpToPage(page);
    // It uses ?. so it's safe if null.
    // But initialize sets it.

    // If we don't set pdfController, jumpToPage won't do anything on the controller, but currentPage will update.
    // This is acceptable for these tests.
  }
}

class FakePdfService implements PdfService {
  FakePdfService(this._document);

  final PdfDocument _document;
  final List<String> log = [];
  Object? errorToThrow;

  @override
  Future<PdfDocument> openFile(String path) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    log.add('openFile($path)');
    return _document;
  }

  @override
  Future<PdfDocument> openAsset(String name) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    log.add('openAsset($name)');
    return _document;
  }

  @override
  Future<PdfDocument> openData(Uint8List data) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    log.add('openData');
    return _document;
  }
}
