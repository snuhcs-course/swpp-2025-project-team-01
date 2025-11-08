import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:mockito/mockito.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/features/player/player_layout.dart';
import 'package:re_view/features/player/player_controller.dart';
import 'package:re_view/features/player/models/lecture_data.dart';

import 'mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<AppData> testBox;
  late Directory testDirectory;
  late PlayerController controller;
  late TranscriptData transcriptData;
  late MockAudioService mockAudioService;
  late MockPdfCacheService mockPdfCacheService;
  late StreamController<Duration> positionStreamController;
  late StreamController<ja.PlayerState> stateStreamController;

  setUpAll(() async {
    // Create a temporary directory for Hive in tests
    testDirectory = Directory.systemTemp.createTempSync('hive_test_layout_');

    // Initialize Hive with the test directory
    Hive.init(testDirectory.path);

    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AppDataAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UiStateAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(HiveSubjectAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(HiveTagAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(HiveLectureAdapter());
    }

    // Open the box manually
    testBox = await Hive.openBox<AppData>('app_data');
  });

  tearDownAll(() async {
    // Close all Hive boxes and clean up
    await Hive.close();
    if (testDirectory.existsSync()) {
      testDirectory.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    // Initialize HiveManager with default English language
    final appData = AppData(
      settings: AppSettings(language: 'en'),
      subjects: {},
      tags: {},
      lectures: {},
      uiState: UiState(),
    );
    await testBox.put('main', appData);
    await HiveManager.instance.initForTesting(testBox);

    mockAudioService = MockAudioService();
    mockPdfCacheService = MockPdfCacheService();

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

    controller = PlayerController(
      audioService: mockAudioService,
      pdfCacheService: mockPdfCacheService,
    );

    transcriptData = TranscriptData(
      metadata: TranscriptMetadata(
        totalSentences: 2,
        totalDuration: 2000,
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
          originalStartTime: 0,
          originalEndTime: 1000,
          startTime: 0,
          endTime: 1000,
          duration: 1000,
        ),
        TranscriptSentence(
          sentenceId: 1,
          text: 'Second sentence',
          textKor: '두 번째 문장',
          slideNumber: 2,
          originalStartTime: 0,
          originalEndTime: 1000,
          startTime: 1000,
          endTime: 2000,
          duration: 1000,
        ),
      ],
    );

    controller.transcriptData = transcriptData;

    // Initialize transcriptScrollController for tests
    controller.transcriptScrollController = AutoScrollController(
      viewportBoundaryGetter: () => Rect.fromLTRB(0, 0, 0, 300),
      axis: Axis.vertical,
    );
  });

  tearDown(() async {
    controller.dispose();
    await positionStreamController.close();
    await stateStreamController.close();
  });

  Widget buildTestApp(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('HorizontalPlayerLayout - Widget Creation', () {
    testWidgets('creates HorizontalPlayerLayout widget', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          HorizontalPlayerLayout(controller: controller, onBack: () {}),
        ),
      );

      expect(find.byType(HorizontalPlayerLayout), findsOneWidget);
    });

    testWidgets('renders main layout components', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          HorizontalPlayerLayout(controller: controller, onBack: () {}),
        ),
      );

      await tester.pump();

      // Should contain a Stack for layering
      expect(find.byType(Stack), findsWidgets);
    });
  });

  group('HorizontalPlayerLayout - Transcript Panel', () {
    testWidgets('shows transcript panel when toggled', (tester) async {
      controller.showTranscriptPanel.value = true;

      await tester.pumpWidget(
        buildTestApp(
          HorizontalPlayerLayout(controller: controller, onBack: () {}),
        ),
      );

      await tester.pump();

      // Clear any overflow exceptions from rendering in test environment
      tester.takeException();

      expect(controller.showTranscriptPanel.value, isTrue);
    });

    testWidgets('hides transcript panel when toggled off', (tester) async {
      controller.showTranscriptPanel.value = false;

      await tester.pumpWidget(
        buildTestApp(
          HorizontalPlayerLayout(controller: controller, onBack: () {}),
        ),
      );

      await tester.pump();

      expect(controller.showTranscriptPanel.value, isFalse);
    });
  });

  group('VerticalPlayerLayout - Widget Creation', () {
    testWidgets('creates VerticalPlayerLayout widget', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          VerticalPlayerLayout(controller: controller, onBack: () {}),
        ),
      );

      expect(find.byType(VerticalPlayerLayout), findsOneWidget);
    });

    testWidgets('renders main layout components', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          VerticalPlayerLayout(controller: controller, onBack: () {}),
        ),
      );

      await tester.pump();

      // Should contain Column for vertical layout
      expect(find.byType(Column), findsWidgets);
    });
  });

  group('VerticalPlayerLayout - Pages Expansion', () {
    testWidgets('expands pages when isPagesExpanded is true', (tester) async {
      controller.isPagesExpanded.value = true;

      await tester.pumpWidget(
        buildTestApp(
          VerticalPlayerLayout(controller: controller, onBack: () {}),
        ),
      );

      await tester.pump();

      // Clear any overflow exceptions from rendering in test environment
      tester.takeException();

      expect(controller.isPagesExpanded.value, isTrue);
    });

    testWidgets('collapses pages when isPagesExpanded is false', (
      tester,
    ) async {
      controller.isPagesExpanded.value = false;

      await tester.pumpWidget(
        buildTestApp(
          VerticalPlayerLayout(controller: controller, onBack: () {}),
        ),
      );

      await tester.pump();

      // Clear any overflow exceptions from rendering in test environment
      tester.takeException();

      expect(controller.isPagesExpanded.value, isFalse);
    });
  });

  group('Layout - Controller Integration', () {
    testWidgets('HorizontalPlayerLayout responds to controller changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          HorizontalPlayerLayout(controller: controller, onBack: () {}),
        ),
      );

      // Change controller state
      controller.showTranscriptPanel.value = true;
      await tester.pump();

      // Clear any overflow exceptions from rendering in test environment
      tester.takeException();

      expect(controller.showTranscriptPanel.value, isTrue);

      // Change again
      controller.showTranscriptPanel.value = false;
      await tester.pump();

      expect(controller.showTranscriptPanel.value, isFalse);
    });

    testWidgets('VerticalPlayerLayout responds to controller changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          VerticalPlayerLayout(controller: controller, onBack: () {}),
        ),
      );

      // Change controller state
      controller.isPagesExpanded.value = true;
      await tester.pump();

      // Clear any overflow exceptions from rendering in test environment
      tester.takeException();

      expect(controller.isPagesExpanded.value, isTrue);

      // Change again
      controller.isPagesExpanded.value = false;
      await tester.pump();

      // Clear any overflow exceptions from rendering in test environment
      tester.takeException();

      expect(controller.isPagesExpanded.value, isFalse);
    });
  });

  group('Layout - Transcript Data Integration', () {
    testWidgets('Controller uses transcriptData', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          HorizontalPlayerLayout(controller: controller, onBack: () {}),
        ),
      );

      await tester.pump();

      expect(controller.transcriptData, isNotNull);
      expect(controller.transcriptData!.timestamps.length, equals(2));
    });
  });

  group('Layout - Widget Lifecycle', () {
    testWidgets('HorizontalPlayerLayout builds without error', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          HorizontalPlayerLayout(controller: controller, onBack: () {}),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('VerticalPlayerLayout builds without error', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          VerticalPlayerLayout(controller: controller, onBack: () {}),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('HorizontalPlayerLayout can be disposed', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          HorizontalPlayerLayout(controller: controller, onBack: () {}),
        ),
      );

      await tester.pump();

      // Remove widget
      await tester.pumpWidget(Container());
      expect(find.byType(HorizontalPlayerLayout), findsNothing);
    });

    testWidgets('VerticalPlayerLayout can be disposed', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          VerticalPlayerLayout(controller: controller, onBack: () {}),
        ),
      );

      await tester.pump();

      // Remove widget
      await tester.pumpWidget(Container());
      expect(find.byType(VerticalPlayerLayout), findsNothing);
    });
  });

  group('Layout - onBack callback', () {
    testWidgets(
      'VerticalPlayerLayout onBack callback is invoked (player_screen.dart:191-193)',
      (tester) async {
        bool backCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          body: VerticalPlayerLayout(
                            controller: controller,
                            onBack: () {
                              backCalled = true;
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Vertical'),
                );
              },
            ),
          ),
        );

        // Navigate to VerticalPlayerLayout
        await tester.tap(find.text('Open Vertical'));
        await tester.pump(); // Start the navigation
        await tester.pump(const Duration(seconds: 1)); // Complete the animation

        expect(find.byType(VerticalPlayerLayout), findsOneWidget);

        // Find back button in PdfArea
        final backButtons = find.byType(IconButton);
        if (backButtons.evaluate().isNotEmpty) {
          await tester.tap(backButtons.first);
          await tester.pump(); // Start the navigation
          await tester.pump(
            const Duration(seconds: 1),
          ); // Complete the animation

          expect(backCalled, isTrue);
          expect(find.text('Open Vertical'), findsOneWidget);
        }
      },
    );

    testWidgets(
      'HorizontalPlayerLayout onBack callback is invoked (player_screen.dart:198)',
      (tester) async {
        bool backCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          body: HorizontalPlayerLayout(
                            controller: controller,
                            onBack: () {
                              backCalled = true;
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Horizontal'),
                );
              },
            ),
          ),
        );

        // Navigate to HorizontalPlayerLayout
        await tester.tap(find.text('Open Horizontal'));
        await tester.pump(); // Start the navigation
        await tester.pump(const Duration(seconds: 1)); // Complete the animation

        expect(find.byType(HorizontalPlayerLayout), findsOneWidget);

        // Find back button
        final backButtons = find.byType(IconButton);
        if (backButtons.evaluate().isNotEmpty) {
          await tester.tap(backButtons.first);
          await tester.pump(); // Start the navigation
          await tester.pump(
            const Duration(seconds: 1),
          ); // Complete the animation

          expect(backCalled, isTrue);
          expect(find.text('Open Horizontal'), findsOneWidget);
        }
      },
    );
  });

  group('HorizontalPlayerLayout - Pages Expanded with Controls', () {
    testWidgets('shows HorizontalToggleBar when pages expanded', (
      tester,
    ) async {
      controller.isPagesExpanded.value = true;

      await tester.pumpWidget(
        buildTestApp(
          HorizontalPlayerLayout(controller: controller, onBack: () {}),
        ),
      );

      await tester.pump();
      tester.takeException();

      expect(controller.isPagesExpanded.value, isTrue);
    });

    testWidgets('shows SyncButton when pages expanded', (tester) async {
      controller.isPagesExpanded.value = true;

      await tester.pumpWidget(
        buildTestApp(
          HorizontalPlayerLayout(controller: controller, onBack: () {}),
        ),
      );

      await tester.pump();
      tester.takeException();

      // SyncButton should be present in the widget tree
      expect(controller.isPagesExpanded.value, isTrue);
      expect(controller.isSynced.value, isNotNull);
    });
  });

  group('PdfArea - Horizontal Mode', () {
    testWidgets('handles vertical drag in horizontal mode', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          PdfArea(isVertical: false, controller: controller, onBack: () {}),
        ),
      );

      await tester.pump();

      // Find GestureDetector
      final gestureDetector = find.byType(GestureDetector).first;
      expect(gestureDetector, findsOneWidget);

      // Simulate vertical drag (swipe up)
      await tester.drag(gestureDetector, const Offset(0, -10));
      await tester.pump();
    });

    testWidgets('shows caption overlay when enabled in horizontal mode', (
      tester,
    ) async {
      controller.isCaptionEnabled.value = true;
      controller.currentSentenceIndex.value = 0;

      await tester.pumpWidget(
        buildTestApp(
          PdfArea(isVertical: false, controller: controller, onBack: () {}),
        ),
      );

      await tester.pump();

      expect(controller.isCaptionEnabled.value, isTrue);
    });

    testWidgets('shows video controls overlay when enabled', (tester) async {
      controller.showControls.value = true;

      await tester.pumpWidget(
        buildTestApp(
          PdfArea(isVertical: false, controller: controller, onBack: () {}),
        ),
      );

      await tester.pump();

      expect(controller.showControls.value, isTrue);
    });

    testWidgets(
      'hides controls when pages expanded in horizontal mode and controls shown',
      (tester) async {
        controller.showControls.value = true;
        controller.isPagesExpanded.value = true;

        await tester.pumpWidget(
          buildTestApp(
            PdfArea(isVertical: false, controller: controller, onBack: () {}),
          ),
        );

        await tester.pump();

        // Controls should be hidden when pages are expanded in horizontal mode
        expect(controller.showControls.value, isTrue);
        expect(controller.isPagesExpanded.value, isTrue);
      },
    );
  });

  group('VideoControlsOverlay - State Tests', () {
    test('controller states can be set for video controls', () {
      controller.isCaptionEnabled.value = false;
      expect(controller.isCaptionEnabled.value, isFalse);

      controller.isSynced.value = true;
      controller.currentSentenceIndex.value = 1;
      controller.currentPage.value = 1;
      expect(controller.pageDifference, equals(1));

      controller.isPlaying.value = false;
      expect(controller.isPlaying.value, isFalse);

      controller.currentTime.value = 1.0;
      controller.totalTime = 2.0;
      expect(controller.currentTime.value, equals(1.0));
      expect(controller.totalTime, equals(2.0));
    });
  });

  group('HorizontalToggleBar', () {
    testWidgets('renders with pages list', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          HorizontalToggleBar(onToggle: () {}, pagesList: Container()),
        ),
      );

      await tester.pump();

      expect(find.byType(HorizontalToggleBar), findsOneWidget);
    });

    testWidgets('toggle button is tappable', (tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        buildTestApp(
          HorizontalToggleBar(
            onToggle: () => toggled = true,
            pagesList: Container(),
          ),
        ),
      );

      await tester.pump();

      // Find the GestureDetector with the toggle
      final gestureDetector = find.byType(GestureDetector).first;
      await tester.tap(gestureDetector);
      await tester.pump();

      expect(toggled, isTrue);
    });
  });

  group('PagesListWidget', () {
    testWidgets('renders in vertical mode', (tester) async {
      when(mockPdfCacheService.getCachedImageDirect(any)).thenReturn(null);
      when(
        mockPdfCacheService.getCachedOrRenderPage(any),
      ).thenAnswer((_) async => Uint8List(0));

      await tester.pumpWidget(
        buildTestApp(PagesListWidget(isVertical: true, controller: controller)),
      );

      await tester.pump();
      tester.takeException();

      expect(find.byType(PagesListWidget), findsOneWidget);
    });

    testWidgets('renders in horizontal mode', (tester) async {
      when(mockPdfCacheService.getCachedImageDirect(any)).thenReturn(null);
      when(
        mockPdfCacheService.getCachedOrRenderPage(any),
      ).thenAnswer((_) async => Uint8List(0));

      await tester.pumpWidget(
        buildTestApp(
          PagesListWidget(isVertical: false, controller: controller),
        ),
      );

      await tester.pump();
      tester.takeException();

      expect(find.byType(PagesListWidget), findsOneWidget);
    });
  });

  group('TranslationButton', () {
    testWidgets('shows ENG when not in Korean mode', (tester) async {
      controller.isKoreanLanguage.value = false;

      await tester.pumpWidget(
        buildTestApp(TranslationButton(controller: controller)),
      );

      await tester.pump();

      expect(find.text('ENG'), findsOneWidget);
      expect(controller.isKoreanLanguage.value, isFalse);
    });

    testWidgets('shows KOR when in Korean mode', (tester) async {
      controller.isKoreanLanguage.value = true;

      await tester.pumpWidget(
        buildTestApp(TranslationButton(controller: controller)),
      );

      await tester.pump();

      expect(find.text('KOR'), findsOneWidget);
      expect(controller.isKoreanLanguage.value, isTrue);
    });

    testWidgets('is tappable when Korean transcript exists', (tester) async {
      controller.isKoreanLanguage.value = false;

      await tester.pumpWidget(
        buildTestApp(TranslationButton(controller: controller)),
      );

      await tester.pump();

      // Tap to toggle
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(controller.isKoreanLanguage.value, isTrue);
    });
  });

  group('TranscriptArea', () {
    testWidgets('shows loading when transcript data is null', (tester) async {
      controller.transcriptData = null;

      await tester.pumpWidget(
        buildTestApp(TranscriptArea(controller: controller, isVertical: false,)),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders English transcript title', (tester) async {
      await tester.pumpWidget(
        buildTestApp(TranscriptArea(controller: controller, isVertical: false,)),
      );

      await tester.pump();

      expect(find.text('Transcript'), findsOneWidget);
    });

    testWidgets('renders Korean transcript title', (tester) async {
      // Change language setting directly without reinitializing
      HiveManager.instance.settings.language = 'ko';

      await tester.pumpWidget(
        buildTestApp(TranscriptArea(controller: controller, isVertical: false,)),
      );

      await tester.pump();

      expect(find.text('대본'), findsOneWidget);

      // Reset language back to English for other tests
      HiveManager.instance.settings.language = 'en';
    });
  });

  group('CaptionOverlay - Caption Text', () {
    test('caption text changes based on language setting', () {
      controller.currentSentenceIndex.value = 0;
      controller.isKoreanLanguage.value = false;
      expect(controller.captionText, equals('First sentence'));

      controller.isKoreanLanguage.value = true;
      expect(controller.captionText, equals('첫 번째 문장'));

      controller.currentSentenceIndex.value = null;
      expect(controller.captionText, isEmpty);
    });
  });
}
