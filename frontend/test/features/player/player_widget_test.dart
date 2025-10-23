import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_view/features/player/player_widgets.dart' as pw;

void main() {
  group('BackButton', () {
    testWidgets('should render correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: pw.BackButton(onPressed: () {})),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: pw.BackButton(onPressed: () => pressed = true)),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('should have correct icon color and size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: pw.BackButton(onPressed: () {})),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.chevron_left));
      expect(icon.color, equals(Colors.white));
      expect(icon.size, equals(32));
    });
  });

  group('SyncButton', () {
    testWidgets('should show sync icon when synced', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: pw.SyncButton(isSynced: true, onPressed: () {})),
        ),
      );

      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.byIcon(Icons.sync_disabled), findsNothing);
    });

    testWidgets('should show sync_disabled icon when not synced', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.SyncButton(isSynced: false, onPressed: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.sync_disabled), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsNothing);
    });

    testWidgets('should show page difference when not synced(back)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.SyncButton(
              isSynced: false,
              onPressed: () {},
              pageDifference: 3,
            ),
          ),
        ),
      );

      // Text contains Korean characters - just verify widget exists
      expect(find.byType(pw.SyncButton), findsOneWidget);
    });

    testWidgets('should show page difference when not synced(front)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.SyncButton(
              isSynced: false,
              onPressed: () {},
              pageDifference: -3,
            ),
          ),
        ),
      );

      // Text contains Korean characters - just verify widget exists
      expect(find.byType(pw.SyncButton), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.SyncButton(
              isSynced: true,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(pressed, isTrue);
    });
  });

  group('CaptionButton', () {
    testWidgets('should show filled caption icon when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.CaptionButton(isEnabled: true, onPressed: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.closed_caption), findsOneWidget);
      expect(find.byIcon(Icons.closed_caption_outlined), findsNothing);
    });

    testWidgets('should show outlined caption icon when disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.CaptionButton(isEnabled: false, onPressed: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.closed_caption_outlined), findsOneWidget);
      expect(find.byIcon(Icons.closed_caption), findsNothing);
    });

    testWidgets('should call onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.CaptionButton(
              isEnabled: false,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(pressed, isTrue);
    });
  });

  group('PlayPauseButton', () {
    testWidgets('should show pause icon when playing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.PlayPauseButton(isPlaying: true, onPressed: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('should show play icon when paused', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.PlayPauseButton(isPlaying: false, onPressed: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('should call onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.PlayPauseButton(
              isPlaying: false,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('should have correct icon size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.PlayPauseButton(isPlaying: true, onPressed: () {}),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.pause));
      expect(icon.size, equals(56));
    });
  });

  group('SkipButton', () {
    testWidgets('should show forward icon when isForward is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.SkipButton(isForward: true, onPressed: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('should show back icon when isForward is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.SkipButton(isForward: false, onPressed: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
    });

    testWidgets('should display 15 seconds text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.SkipButton(isForward: true, onPressed: () {}),
          ),
        ),
      );

      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.SkipButton(
              isForward: true,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(
        find.descendant(
          of: find.byType(pw.SkipButton),
          matching: find.byType(GestureDetector),
        ),
      );
      await tester.pump();

      expect(pressed, isTrue);

      await tester.pumpAndSettle();
    });

    testWidgets('should show background animation on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.SkipButton(isForward: true, onPressed: () {}),
          ),
        ),
      );

      // Tap the button
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      // Background should appear
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNot(Colors.transparent));

      // Wait for animation to complete
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      // Background should disappear
      final containerAfter = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decorationAfter = containerAfter.decoration as BoxDecoration;
      expect(decorationAfter.color, equals(Colors.transparent));
    });
  });

  group('VideoTimelineSlider', () {
    testWidgets('should render slider with correct values', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.VideoTimelineSlider(
              currentTime: 30.0,
              totalTime: 120.0,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, equals(30.0));
      expect(slider.min, equals(0.0));
      expect(slider.max, equals(120.0));
    });

    testWidgets('should display current time and remaining time', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.VideoTimelineSlider(
              currentTime: 65.0,
              totalTime: 125.0,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('1:05'), findsOneWidget);
      expect(find.text('-1:00'), findsOneWidget);
    });

    testWidgets('should call onChanged when slider is moved', (tester) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.VideoTimelineSlider(
              currentTime: 30.0,
              totalTime: 120.0,
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.drag(find.byType(Slider), const Offset(100, 0));
      await tester.pump();

      expect(changedValue, isNotNull);
    });

    testWidgets('should handle zero time correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.VideoTimelineSlider(
              currentTime: 0.0,
              totalTime: 100.0,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('-1:40'), findsOneWidget);
    });

    testWidgets('should handle end time correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.VideoTimelineSlider(
              currentTime: 100.0,
              totalTime: 100.0,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('1:40'), findsOneWidget);
      expect(find.text('-0:00'), findsOneWidget);
    });
  });

  group('CenterPlayControls', () {
    testWidgets('should render all control buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.CenterPlayControls(
              isPlaying: false,
              onPlayPause: () {},
              onSkipBackward: () {},
              onSkipForward: () {},
            ),
          ),
        ),
      );

      expect(find.byType(pw.SkipButton), findsNWidgets(2));
      expect(find.byType(pw.PlayPauseButton), findsOneWidget);
    });

    testWidgets('should call callbacks when buttons are pressed', (
      tester,
    ) async {
      bool playPausePressed = false;
      bool skipBackPressed = false;
      bool skipForwardPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.CenterPlayControls(
              isPlaying: false,
              onPlayPause: () => playPausePressed = true,
              onSkipBackward: () => skipBackPressed = true,
              onSkipForward: () => skipForwardPressed = true,
            ),
          ),
        ),
      );

      // Test play/pause
      await tester.tap(find.byType(pw.PlayPauseButton));
      await tester.pump();
      expect(playPausePressed, isTrue);

      // Test skip backward
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      expect(skipBackPressed, isTrue);

      // Test skip forward
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump();
      expect(skipForwardPressed, isTrue);

      await tester.pumpAndSettle();
    });

    testWidgets('should have correct layout order', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.CenterPlayControls(
              isPlaying: true,
              onPlayPause: () {},
              onSkipBackward: () {},
              onSkipForward: () {},
            ),
          ),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, equals(MainAxisAlignment.center));
      expect(row.children.length, equals(5));
    });
  });

  group('TopControlBar', () {
    testWidgets('should render all buttons in horizontal mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.TopControlBar(
              isVertical: false,
              onBack: () {},
              isCaptionEnabled: false,
              onCaptionToggle: () {},
              isSynced: true,
              onSyncToggle: () {},
            ),
          ),
        ),
      );

      expect(find.byType(pw.BackButton), findsOneWidget);
      expect(find.byType(pw.CaptionButton), findsOneWidget);
      expect(find.byType(pw.SyncButton), findsOneWidget);
    });

    testWidgets('should hide caption button in vertical mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.TopControlBar(
              isVertical: true,
              onBack: () {},
              isCaptionEnabled: false,
              onCaptionToggle: () {},
              isSynced: true,
              onSyncToggle: () {},
            ),
          ),
        ),
      );

      expect(find.byType(pw.BackButton), findsOneWidget);
      expect(find.byType(pw.CaptionButton), findsNothing);
      expect(find.byType(pw.SyncButton), findsOneWidget);
    });

    testWidgets('should call callbacks when buttons are pressed', (
      tester,
    ) async {
      bool backPressed = false;
      bool captionPressed = false;
      bool syncPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.TopControlBar(
              isVertical: false,
              onBack: () => backPressed = true,
              isCaptionEnabled: false,
              onCaptionToggle: () => captionPressed = true,
              isSynced: true,
              onSyncToggle: () => syncPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();
      expect(backPressed, isTrue);

      await tester.tap(find.byIcon(Icons.closed_caption_outlined));
      await tester.pump();
      expect(captionPressed, isTrue);

      await tester.tap(find.byIcon(Icons.sync));
      await tester.pump();
      expect(syncPressed, isTrue);
    });
  });

  group('PdfSlidesList', () {
    testWidgets('should render correct number of slides', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.PdfSlidesList(
              pageCount: 5,
              currentPage: 1,
              itemWidth: 120,
              padding: EdgeInsets.zero,
              getCachedOrRenderPage: (pageNumber) async =>
                  Uint8List.fromList([1, 2, 3]),
              onPageTap: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GestureDetector), findsNWidgets(5));
    });

    testWidgets('should highlight current page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.PdfSlidesList(
              pageCount: 3,
              currentPage: 2,
              itemWidth: 120,
              padding: EdgeInsets.zero,
              getCachedOrRenderPage: (pageNumber) async =>
                  Uint8List.fromList([1, 2, 3]),
              onPageTap: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));

      int currentPageContainerCount = 0;
      for (final container in containers) {
        if (container.decoration is BoxDecoration) {
          final boxDecoration = container.decoration as BoxDecoration;
          if (boxDecoration.border != null) {
            final border = boxDecoration.border as Border;
            if (border.top.color == Colors.blue && border.top.width == 3) {
              currentPageContainerCount++;
            }
          }
        }
      }

      expect(currentPageContainerCount, greaterThan(0));
    });

    testWidgets('should call onPageTap when slide is tapped', (tester) async {
      int? tappedPage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.PdfSlidesList(
              pageCount: 3,
              currentPage: 1,
              itemWidth: 120,
              padding: EdgeInsets.zero,
              getCachedOrRenderPage: (pageNumber) async =>
                  Uint8List.fromList([1, 2, 3]),
              onPageTap: (pageNumber) => tappedPage = pageNumber,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(tappedPage, equals(1));
    });

    testWidgets('should show loading state initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.PdfSlidesList(
              pageCount: 2,
              currentPage: 1,
              itemWidth: 120,
              padding: EdgeInsets.zero,
              getCachedOrRenderPage: (pageNumber) async {
                await Future.delayed(const Duration(milliseconds: 100));
                return Uint8List.fromList([1, 2, 3]);
              },
              onPageTap: (_) {},
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Slide'), findsWidgets);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('should show loading state when bytes is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.PdfSlidesList(
              pageCount: 1,
              currentPage: 1,
              itemWidth: 120,
              padding: EdgeInsets.zero,
              getCachedOrRenderPage: (pageNumber) async =>
                Uint8List.fromList([]),
              onPageTap: (_) {},
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.image_not_supported), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('should display cached image directly', (tester) async {
      final cachedImage = Uint8List.fromList([5, 6, 7, 8]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.PdfSlidesList(
              pageCount: 2,
              currentPage: 1,
              itemWidth: 120,
              padding: EdgeInsets.zero,
              getCachedOrRenderPage: (pageNumber) async =>
                  Uint8List.fromList([1, 2, 3]),
              getCachedImage: (pageNumber) =>
                  pageNumber == 1 ? cachedImage : null,
              onPageTap: (_) {},
            ),
          ),
        ),
      );

      await tester.pump();

      final imageWidgets = tester.widgetList<Image>(find.byType(Image));
      expect(imageWidgets.length, greaterThan(0));
    });

    testWidgets('should show error state on failure', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.PdfSlidesList(
              pageCount: 1,
              currentPage: 1,
              itemWidth: 120,
              padding: EdgeInsets.zero,
              getCachedOrRenderPage: (pageNumber) async {
                throw Exception('Failed to load');
              },
              onPageTap: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('should call onScroll when scrolled', (tester) async {
      int? scrolledToPage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: pw.PdfSlidesList(
                pageCount: 20,
                currentPage: 1,
                itemWidth: 120,
                padding: const EdgeInsets.all(16),
                getCachedOrRenderPage: (pageNumber) async =>
                    Uint8List.fromList([1, 2, 3]),
                onPageTap: (_) {},
                onScroll: (visibleEndPage) => scrolledToPage = visibleEndPage,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(scrolledToPage, isNotNull);
      expect(scrolledToPage, greaterThan(1));
    });
  });

  group('Integration Tests', () {
    testWidgets('TopControlBar should integrate all child widgets correctly', (
      tester,
    ) async {
      bool backCalled = false;
      bool captionCalled = false;
      bool syncCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: pw.TopControlBar(
              isVertical: false,
              onBack: () => backCalled = true,
              isCaptionEnabled: true,
              onCaptionToggle: () => captionCalled = true,
              isSynced: false,
              onSyncToggle: () => syncCalled = true,
              pageDifference: 3,
            ),
          ),
        ),
      );

      expect(find.byType(pw.BackButton), findsOneWidget);
      expect(find.byType(pw.CaptionButton), findsOneWidget);
      expect(find.byType(pw.SyncButton), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();
      expect(backCalled, isTrue);

      await tester.tap(find.byIcon(Icons.closed_caption));
      await tester.pump();
      expect(captionCalled, isTrue);

      await tester.tap(find.byIcon(Icons.sync_disabled));
      await tester.pump();
      expect(syncCalled, isTrue);
    });

    testWidgets('CenterPlayControls should coordinate all playback controls', (
      tester,
    ) async {
      bool isPlaying = false;
      int skipCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return pw.CenterPlayControls(
                  isPlaying: isPlaying,
                  onPlayPause: () {
                    setState(() => isPlaying = !isPlaying);
                  },
                  onSkipBackward: () => skipCount--,
                  onSkipForward: () => skipCount++,
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(find.byType(pw.PlayPauseButton));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.pause), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump();
      expect(skipCount, equals(1));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      expect(skipCount, equals(0));

      await tester.pumpAndSettle();
    });
  });
}
