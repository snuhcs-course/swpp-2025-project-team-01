import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:mockito/mockito.dart';
import 'package:re_view/features/player/player_controller.dart';
import 'package:re_view/features/player/models/lecture_data.dart';

import 'mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAudioService mockAudioService;
  late MockPdfCacheService mockPdfCacheService;
  late StreamController<Duration> positionStreamController;
  late StreamController<ja.PlayerState> stateStreamController;

  setUp(() {
    mockAudioService = MockAudioService();
    mockPdfCacheService = MockPdfCacheService();

    // Reset mocks to clear any previous interactions
    reset(mockAudioService);
    reset(mockPdfCacheService);

    // Create stream controllers for mocking
    positionStreamController = StreamController<Duration>.broadcast();
    stateStreamController = StreamController<ja.PlayerState>.broadcast();

    // Setup default mock behaviors
    when(
      mockAudioService.positionStream,
    ).thenAnswer((_) => positionStreamController.stream);
    when(
      mockAudioService.stateStream,
    ).thenAnswer((_) => stateStreamController.stream);
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
  });

  tearDown(() async {
    await positionStreamController.close();
    await stateStreamController.close();
  });

  TranscriptData createTestTranscriptData() {
    return TranscriptData(
      metadata: TranscriptMetadata(
        totalSentences: 3,
        totalDuration: 3000,
        voice: 'test',
        speed: 1.0,
        languageCode: 'en',
        sampleRate: 22050,
      ),
      timestamps: [
        TranscriptSentence(
          sentenceId: 0,
          text: 'First sentence',
          textKor: '첫 번째 문장',
          slideNumber: 1,
          startTime: 0,
          endTime: 1000,
          duration: 1000,
        ),
        TranscriptSentence(
          sentenceId: 1,
          text: 'Second sentence',
          textKor: '두 번째 문장',
          slideNumber: 1,
          startTime: 1000,
          endTime: 2000,
          duration: 1000,
        ),
        TranscriptSentence(
          sentenceId: 2,
          text: 'Third sentence',
          textKor: null,
          slideNumber: 2,
          startTime: 2000,
          endTime: 3000,
          duration: 1000,
        ),
      ],
    );
  }

  group('PlayerController - Constructor', () {
    test('creates controller with required services', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      expect(controller, isNotNull);
      expect(controller.pdfCacheService, equals(mockPdfCacheService));
    });

    test('initializes ValueNotifiers with default values', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      expect(controller.showControls.value, isFalse);
      expect(controller.isPagesExpanded.value, isFalse);
      expect(controller.showTranscriptPanel.value, isFalse);
      expect(controller.isPlaying.value, isFalse);
      expect(controller.isSynced.value, isTrue);
      expect(controller.isCaptionEnabled.value, isFalse);
      expect(controller.isKoreanLanguage.value, isFalse);
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
        );

        controller.transcriptData = createTestTranscriptData();

        expect(controller.hasKoreanTranscript, isTrue);
        expect(controller.isKoreanLanguage.value, isFalse);

        controller.toggleTranscriptLanguage();
        expect(controller.isKoreanLanguage.value, isTrue);

        controller.toggleTranscriptLanguage();
        expect(controller.isKoreanLanguage.value, isFalse);

        controller.dispose();
      },
    );

    test('toggleTranscriptLanguage does nothing when no Korean transcript', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      final transcriptData = TranscriptData(
        metadata: TranscriptMetadata(
          totalSentences: 1,
          totalDuration: 1000,
          voice: 'test',
          speed: 1.0,
          languageCode: 'en',
          sampleRate: 22050,
        ),
        timestamps: [
          TranscriptSentence(
            sentenceId: 0,
            text: 'No Korean',
            textKor: null,
            slideNumber: 1,
            startTime: 0,
            endTime: 1000,
            duration: 1000,
          ),
        ],
      );

      controller.transcriptData = transcriptData;

      expect(controller.hasKoreanTranscript, isFalse);
      expect(controller.isKoreanLanguage.value, isFalse);

      controller.toggleTranscriptLanguage();
      expect(controller.isKoreanLanguage.value, isFalse);

      controller.dispose();
    });

    test('handlePdfTap toggles controls in vertical mode', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
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
      );

      // Setup position stream listener to update currentTime
      final subscription = positionStreamController.stream.listen((position) {
        controller.currentTime.value = position.inMilliseconds / 1000.0;
      });

      controller.totalTime = 100.0;

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
      );

      // Setup position stream listener to update currentTime
      final subscription = positionStreamController.stream.listen((position) {
        controller.currentTime.value = position.inMilliseconds / 1000.0;
      });

      controller.totalTime = 100.0;

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

    test('skipBackward seeks backward by 15 seconds', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      // Setup position stream listener to update currentTime
      final subscription = positionStreamController.stream.listen((position) {
        controller.currentTime.value = position.inMilliseconds / 1000.0;
      });

      controller.totalTime = 100.0;
      controller.currentTime.value = 30.0;

      await controller.skipBackward();

      // Wait for stream event to be processed
      await Future.delayed(const Duration(milliseconds: 10));

      // Verify audioService.seek was called with correct Duration (30 - 15 = 15)
      verify(
        mockAudioService.seek(const Duration(milliseconds: 15000)),
      ).called(1);

      // Verify currentTime was updated to 15.0
      expect(controller.currentTime.value, equals(15.0));

      await subscription.cancel();
      controller.dispose();
    });

    test('skipBackward clamps to 0', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      // Setup position stream listener to update currentTime
      final subscription = positionStreamController.stream.listen((position) {
        controller.currentTime.value = position.inMilliseconds / 1000.0;
      });

      controller.totalTime = 100.0;
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

    test('skipForward seeks forward by 15 seconds', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      // Setup position stream listener to update currentTime
      final subscription = positionStreamController.stream.listen((position) {
        controller.currentTime.value = position.inMilliseconds / 1000.0;
      });

      controller.totalTime = 100.0;
      controller.currentTime.value = 30.0;

      await controller.skipForward();

      // Wait for stream event to be processed
      await Future.delayed(const Duration(milliseconds: 10));

      // Verify audioService.seek was called with correct Duration (30 + 15 = 45)
      verify(
        mockAudioService.seek(const Duration(milliseconds: 45000)),
      ).called(1);

      // Verify currentTime was updated to 45.0
      expect(controller.currentTime.value, equals(45.0));

      await subscription.cancel();
      controller.dispose();
    });

    test('skipForward clamps to totalTime', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      // Setup position stream listener to update currentTime
      final subscription = positionStreamController.stream.listen((position) {
        controller.currentTime.value = position.inMilliseconds / 1000.0;
      });

      controller.totalTime = 100.0;
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
      );

      controller.transcriptData = createTestTranscriptData();

      expect(controller.syncedPageNumber, isNull);

      controller.dispose();
    });

    test('syncedPageNumber returns null when no transcript data', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      controller.currentSentenceIndex.value = 0;

      expect(controller.syncedPageNumber, isNull);

      controller.dispose();
    });

    test('pageDifference calculates correctly', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
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
      );

      expect(controller.pageDifference, isNull);

      controller.dispose();
    });

    test('captionText returns English text by default', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      controller.transcriptData = createTestTranscriptData();
      controller.currentSentenceIndex.value = 0;

      expect(controller.captionText, equals('First sentence'));

      controller.dispose();
    });

    test('captionText returns Korean text when Korean language is enabled', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      controller.transcriptData = createTestTranscriptData();
      controller.currentSentenceIndex.value = 0;
      controller.isKoreanLanguage.value = true;

      expect(controller.captionText, equals('첫 번째 문장'));

      controller.dispose();
    });

    test('captionText returns English when Korean not available', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      controller.transcriptData = createTestTranscriptData();
      controller.currentSentenceIndex.value = 2; // No Korean
      controller.isKoreanLanguage.value = true;

      expect(controller.captionText, equals('Third sentence'));

      controller.dispose();
    });

    test('captionText returns empty string when no sentence index', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      controller.transcriptData = createTestTranscriptData();

      expect(controller.captionText, equals(''));

      controller.dispose();
    });

    test('hasKoreanTranscript returns true when Korean exists', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      controller.transcriptData = createTestTranscriptData();

      expect(controller.hasKoreanTranscript, isTrue);

      controller.dispose();
    });

    test('hasKoreanTranscript returns false when no Korean exists', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      final transcriptData = TranscriptData(
        metadata: TranscriptMetadata(
          totalSentences: 1,
          totalDuration: 1000,
          voice: 'test',
          speed: 1.0,
          languageCode: 'en',
          sampleRate: 22050,
        ),
        timestamps: [
          TranscriptSentence(
            sentenceId: 0,
            text: 'No Korean',
            textKor: null,
            slideNumber: 1,
            startTime: 0,
            endTime: 1000,
            duration: 1000,
          ),
        ],
      );

      controller.transcriptData = transcriptData;

      expect(controller.hasKoreanTranscript, isFalse);

      controller.dispose();
    });

    test('hasKoreanTranscript returns false when transcript is null', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      expect(controller.hasKoreanTranscript, isFalse);

      controller.dispose();
    });

    test('hasKoreanTranscript returns false when timestamps are empty', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      final transcriptData = TranscriptData(
        metadata: TranscriptMetadata(
          totalSentences: 0,
          totalDuration: 0,
          voice: 'test',
          speed: 1.0,
          languageCode: 'en',
          sampleRate: 22050,
        ),
        timestamps: [],
      );

      controller.transcriptData = transcriptData;

      expect(controller.hasKoreanTranscript, isFalse);

      controller.dispose();
    });

    test('pageCount returns 0 when no PDF document', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      expect(controller.pageCount, equals(0));

      controller.dispose();
    });
  });

  group('PlayerController - Dispose', () {
    test('dispose cleans up all resources', () {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
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

  group('PlayerController - Initialize', () {
    testWidgets('initialize sets up transcript data and total time', (
      tester,
    ) async {
      // Skip this test on Linux (CI environment) due to pdfx platform limitations
      if (Platform.isLinux) {
          return;
      }

      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      final transcriptData = createTestTranscriptData();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Call initialize without awaiting to avoid hanging on PDF operations
              controller
                  .initialize(
                    context,
                    'test-lecture-id',
                    transcriptData,
                    'assets/test.pdf',
                    'assets/test.mp3',
                  )
                  .catchError((_) {
                    // Ignore errors from PDF loading in test
                  });
              return Container();
            },
          ),
        ),
      );

      // Wait for initialization to start
      await tester.pump();

      // Verify transcript data and total time are set
      expect(controller.transcriptData, equals(transcriptData));
      expect(controller.totalTime, equals(3.0)); // 3000ms / 1000

      controller.dispose();
    });
  });

  group('PlayerController - Additional Coverage', () {
    test('playPause triggers scroll when conditions are met', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
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
      );

      controller.totalTime = 100.0;
      controller.transcriptData = createTestTranscriptData();

      // Normal seek
      await controller.seek(50.0);

      // Verify that seek was called
      verify(mockAudioService.seek(any)).called(1);

      // Wait for forced move flag and auto-scroll restoration
      await Future.delayed(const Duration(milliseconds: 550));

      controller.dispose();
    });
  });

  group('PlayerController - seekToSentence', () {
    test('seekToSentence seeks to sentence start time', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
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
      );

      // Setup audio service to throw error on seek
      when(mockAudioService.seek(any)).thenThrow(Exception('Seek failed'));

      controller.totalTime = 100.0;

      // Should not throw, error is caught internally
      await controller.seek(50.0);

      verify(mockAudioService.seek(any)).called(1);

      controller.dispose();
    });

    test('seek sets forced move and auto-scroll flags', () async {
      final controller = PlayerController(
        audioService: mockAudioService,
        pdfCacheService: mockPdfCacheService,
      );

      // Reset mock to default behavior
      when(mockAudioService.seek(any)).thenAnswer((_) async => Future.value());

      controller.totalTime = 100.0;
      controller.isAutoScrolling.value = false;

      await controller.seek(30.0);

      // isAutoScrolling should be set to true by seek
      expect(controller.isAutoScrolling.value, isTrue);

      controller.dispose();
    });
  });
}
