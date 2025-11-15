import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:re_view/shared/widgets.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/core/lecture_loading_service.dart';

import 'widgets_test.mocks.dart';

/// Simple interface used to bridge void callbacks into Mockito.
abstract class CallbackHandler {
  void call();
}

/// Bool callback for SelectableTagPill.onSelected
abstract class BoolCallbackHandler {
  void call(bool value);
}

@GenerateMocks([
  CallbackHandler,
  BoolCallbackHandler,
  HiveTag,
  LectureLoadingService,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrimaryButton', () {
    testWidgets('renders label and triggers onPressed', (tester) async {
      final mockHandler = MockCallbackHandler();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Create lecture',
              onPressed: mockHandler.call,
            ),
          ),
        ),
      );

      // Label is shown
      expect(find.text('Create lecture'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Tap the button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify that the callback was called exactly once
      verify(mockHandler.call()).called(1);
      verifyNoMoreInteractions(mockHandler);
    });

    testWidgets('can be rendered disabled when onPressed is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrimaryButton(label: 'Disabled', onPressed: null),
          ),
        ),
      );

      final elevated = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(elevated.onPressed, isNull);
    });
  });

  group('EmptyState', () {
    testWidgets('displays the given message', (tester) async {
      const message = 'No lectures yet';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EmptyState(message: message)),
        ),
      );

      expect(find.text(message), findsOneWidget);
      expect(find.byType(Center), findsOneWidget);
    });
  });

  group('LoadingOverlay', () {
    testWidgets('shows default message when none is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LoadingOverlay())),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Processing...'), findsOneWidget);
    });

    testWidgets('shows custom message when provided', (tester) async {
      const message = 'Creating lecture...';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingOverlay(message: message)),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(message), findsOneWidget);
    });
  });

  group('TagPill', () {
    testWidgets('uses prefix + tag.name by default', (tester) async {
      final mockTag = MockHiveTag();
      when(mockTag.name).thenReturn('Math');
      when(mockTag.color).thenReturn(0xFF00FF00); // arbitrary green

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: TagPill(tag: mockTag)),
          ),
        ),
      );

      // default label is "#<name>"
      expect(find.text('#Math'), findsOneWidget);

      final chip = tester.widget<Chip>(find.byType(Chip));
      expect(chip.backgroundColor, const Color(0xFF00FF00));
    });

    testWidgets('uses custom label and textColor when provided', (
      tester,
    ) async {
      final mockTag = MockHiveTag();
      when(mockTag.name).thenReturn('Science');
      when(mockTag.color).thenReturn(0xFF123456);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TagPill(
                tag: mockTag,
                label: 'Custom tag',
                textColor: Colors.red,
              ),
            ),
          ),
        ),
      );

      // Custom label should be used instead of "#Science"
      expect(find.text('Custom tag'), findsOneWidget);
      expect(find.text('#Science'), findsNothing);

      // Confirm textColor override is applied
      final text = tester.widget<Text>(find.text('Custom tag'));
      expect(text.style?.color, Colors.red);

      final chip = tester.widget<Chip>(find.byType(Chip));
      expect(chip.backgroundColor, const Color(0xFF123456));
    });
  });

  group('SelectableTagPill', () {
    testWidgets('passes selected flag into ChoiceChip', (tester) async {
      final mockTag = MockHiveTag();
      when(mockTag.name).thenReturn('Physics');
      when(mockTag.color).thenReturn(0xFFABCDEF);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SelectableTagPill(
                tag: mockTag,
                selected: true,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final chip = tester.widget<ChoiceChip>(find.byType(ChoiceChip));
      expect(chip.selected, isTrue);
    });

    testWidgets('invokes onSelected callback when tapped', (tester) async {
      final mockTag = MockHiveTag();
      final mockBoolHandler = MockBoolCallbackHandler();

      when(mockTag.name).thenReturn('Biology');
      when(mockTag.color).thenReturn(0xFFAA00AA);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SelectableTagPill(
                tag: mockTag,
                selected: false,
                onSelected: mockBoolHandler.call,
              ),
            ),
          ),
        ),
      );

      // Tap the chip
      await tester.tap(find.byType(ChoiceChip));
      await tester.pumpAndSettle();

      // ChoiceChip toggles selected from false -> true, so expect true.
      verify(mockBoolHandler.call(true)).called(1);
      verifyNoMoreInteractions(mockBoolHandler);
    });

    testWidgets('still builds correctly when showCheckmark is false', (
      tester,
    ) async {
      final mockTag = MockHiveTag();
      when(mockTag.name).thenReturn('Chemistry');
      when(mockTag.color).thenReturn(0xFF00AAFF);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SelectableTagPill(
                tag: mockTag,
                selected: false,
                showCheckmark: false,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      // Just ensure the widget builds and has a ChoiceChip
      expect(find.byType(ChoiceChip), findsOneWidget);
      expect(find.text('#Chemistry'), findsOneWidget);
    });
  });

  group('SubjectPanelHeader', () {
    testWidgets('tapping header calls onToggleExpanded', (tester) async {
      final mockHandler = MockCallbackHandler();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubjectPanelHeader(
              title: 'Biochemistry',
              tags: const <HiveTag>[], // empty so TagPill doesn’t build
              expanded: false,
              onToggleExpanded: mockHandler.call,
            ),
          ),
        ),
      );

      // Tap the whole header
      await tester.tap(find.byType(SubjectPanelHeader));
      await tester.pumpAndSettle();

      verify(mockHandler.call()).called(1);
      verifyNoMoreInteractions(mockHandler);
    });

    testWidgets('long press calls onLongPress when provided', (tester) async {
      final mockLongPress = MockCallbackHandler();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubjectPanelHeader(
              title: 'Genetics',
              tags: const <HiveTag>[],
              expanded: false,
              onToggleExpanded: () {},
              onLongPress: mockLongPress.call,
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(SubjectPanelHeader));
      await tester.pumpAndSettle();

      verify(mockLongPress.call()).called(1);
      verifyNoMoreInteractions(mockLongPress);
    });

    testWidgets(
      'edit icon is visible when showEdit=true and calls onEditSubject',
      (tester) async {
        final mockEdit = MockCallbackHandler();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SubjectPanelHeader(
                title: 'Thermodynamics',
                tags: const <HiveTag>[],
                expanded: true,
                onToggleExpanded: () {},
                showEdit: true,
                onEditSubject: mockEdit.call,
              ),
            ),
          ),
        );

        // There should be an edit icon
        final editFinder = find.byIcon(Icons.edit);
        expect(editFinder, findsOneWidget);

        // Tap the edit icon
        await tester.tap(editFinder);
        await tester.pumpAndSettle();

        verify(mockEdit.call()).called(1);
        verifyNoMoreInteractions(mockEdit);
      },
    );

    testWidgets(
      'favorite icon calls onToggleFavorite when favoriteOrDrag is star',
      (tester) async {
        final mockFavorite = MockCallbackHandler();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SubjectPanelHeader(
                title: 'Algebra',
                tags: const <HiveTag>[],
                expanded: false,
                onToggleExpanded: () {},
                favoriteOrDrag: Icons.star,
                onToggleFavorite: mockFavorite.call,
              ),
            ),
          ),
        );

        final favButtonFinder = find.widgetWithIcon(IconButton, Icons.star);
        expect(favButtonFinder, findsOneWidget);

        await tester.tap(favButtonFinder);
        await tester.pumpAndSettle();

        verify(mockFavorite.call()).called(1);
        verifyNoMoreInteractions(mockFavorite);
      },
    );

    testWidgets(
      'shows drag handle when favoriteOrDrag is drag_indicator and reorderIndex provided',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReorderableListView(
                children: [
                  SubjectPanelHeader(
                    key: const ValueKey('subject-0'),
                    title: 'Calculus',
                    tags: const <HiveTag>[],
                    expanded: false,
                    onToggleExpanded: () {},
                    favoriteOrDrag: Icons.drag_indicator,
                    reorderIndex: 0,
                  ),
                ],
                onReorder: (oldIndex, newIndex) {},
              ),
            ),
          ),
        );

        // Drag handle should be wrapped with ReorderableDelayedDragStartListener
        expect(
          find.byType(ReorderableDelayedDragStartListener),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders tags via TagPill when tags are not empty', (
      tester,
    ) async {
      final mockTag1 = MockHiveTag();
      final mockTag2 = MockHiveTag();

      when(mockTag1.name).thenReturn('Tag1');
      when(mockTag1.color).thenReturn(0xFF0000FF);
      when(mockTag2.name).thenReturn('Tag2');
      when(mockTag2.color).thenReturn(0xFF00FFFF);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubjectPanelHeader(
              title: 'Tagged Subject',
              tags: [mockTag1, mockTag2],
              expanded: true,
              onToggleExpanded: () {},
            ),
          ),
        ),
      );

      // TagPill should be built for each tag
      expect(find.byType(TagPill), findsNWidgets(2));
      expect(find.text('#Tag1'), findsOneWidget);
      expect(find.text('#Tag2'), findsOneWidget);
    });
  });

  group('LectureLoadingBar', () {
    testWidgets('renders nothing when service is not loading', (tester) async {
      // Rely on default state of the singleton (isLoading == false).
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LectureLoadingBar())),
      );

      // No AnimatedSwitcher (expanded/collapsed UI) should be built.
      expect(find.byType(AnimatedSwitcher), findsNothing);
      // The bar itself should still exist in the tree.
      expect(find.byType(LectureLoadingBar), findsOneWidget);
    });
  });

  group('CollapsedBubbleOverlay', () {
    late MockLectureLoadingService mockService;

    setUp(() {
      mockService = MockLectureLoadingService();

      when(mockService.bubbleX).thenReturn(32.0);
      when(mockService.bubbleY).thenReturn(48.0);
      when(mockService.progress).thenReturn(0.5);
    });

    testWidgets('positions bubble using service.bubbleX/bubbleY', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CollapsedBubbleOverlay(service: mockService)),
        ),
      );

      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.left, 32.0);
      expect(positioned.bottom, 48.0);
    });

    testWidgets('clamps progress value between 0 and 1 (upper bound)', (
      tester,
    ) async {
      when(mockService.progress).thenReturn(1.5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CollapsedBubbleOverlay(service: mockService)),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, 1.0);
    });

    testWidgets('clamps progress value between 0 and 1 (lower bound)', (
      tester,
    ) async {
      when(mockService.progress).thenReturn(-0.4);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CollapsedBubbleOverlay(service: mockService)),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, 0.0);
    });

    testWidgets('tap on bubble calls service.expandFromBubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CollapsedBubbleOverlay(service: mockService)),
        ),
      );

      // The bubble is wrapped in a GestureDetector inside the Positioned.
      final gestureFinder = find.byType(GestureDetector);
      expect(gestureFinder, findsOneWidget);

      await tester.tap(gestureFinder);
      await tester.pumpAndSettle();

      verify(mockService.expandFromBubble()).called(1);
      verifyNoMoreInteractions(mockService);
    });

    testWidgets(
      'drag updates visual position and calls updateBubblePosition on pan end',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: CollapsedBubbleOverlay(service: mockService)),
          ),
        );

        final gestureFinder = find.byType(GestureDetector);
        expect(gestureFinder, findsOneWidget);

        // Drag the bubble a bit to the right and up.
        await tester.drag(gestureFinder, const Offset(40, -20));
        await tester.pumpAndSettle();

        // After drag completes, onPanEnd should call updateBubblePosition.
        verify(mockService.updateBubblePosition(any, any)).called(1);

        // The Positioned widget should reflect a moved bubble (within screen bounds).
        final positioned = tester.widget<Positioned>(find.byType(Positioned));
        expect(positioned.left, greaterThan(0.0));
        expect(positioned.bottom, greaterThan(0.0));
      },
    );
  });

  group('ExpandedLoadingOverlay and inner views', () {
    late MockLectureLoadingService mockService;

    setUp(() {
      mockService = MockLectureLoadingService();

      // common defaults
      when(mockService.isCompleted).thenReturn(false);
      when(mockService.hasError).thenReturn(false);
      when(mockService.lectureTitle).thenReturn('My lecture');
      when(mockService.message).thenReturn('Processing…');
      when(mockService.progress).thenReturn(0.4);
    });

    /// Helper to build the overlay in a proper `BuildContext`.
    Future<void> pumpWithService(
      WidgetTester tester,
      LectureLoadingService service,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ExpandedLoadingOverlay(
                  service: service,
                  context: context,
                );
              },
            ),
          ),
        ),
      );
      await tester
          .pump(); // let initial build + AnimatedSwitcher settle a frame
    }

    Future<void> pumpOverlay(WidgetTester tester) async {
      final rootKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              key: rootKey,
              builder: (ctx) => ExpandedLoadingOverlay(
                service: mockService,
                context: ctx, // used only by CompletedView
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('wraps content in rounded card with dark background and shadow', (
      tester,
    ) async {
      final mockService = MockLectureLoadingService();
      when(mockService.isCompleted).thenReturn(false);
      when(mockService.hasError).thenReturn(false);
      when(mockService.lectureTitle).thenReturn('My Lecture');
      when(mockService.message).thenReturn('Preparing…');
      when(mockService.progress).thenReturn(0.3);

      await pumpWithService(tester, mockService);

      // Rounded card is implemented as a ClipRRect with radius 24.
      final clipFinder = find.byWidgetPredicate((widget) {
        if (widget is ClipRRect) {
          final radius = widget.borderRadius;
          return radius == BorderRadius.circular(24);
        }
        return false;
      });
      expect(clipFinder, findsOneWidget);

      // Inside it there should be a DecoratedBox with the dark background color
      // and at least one boxShadow.
      final decoratedFinder = find.byWidgetPredicate((widget) {
        if (widget is DecoratedBox && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.color == const Color(0xFF1A1A1A) &&
              (box.boxShadow?.isNotEmpty ?? false);
        }
        return false;
      });
      expect(decoratedFinder, findsOneWidget);

      // And the leaf content sits inside a transparent Material.
      final materialFinder = find.descendant(
        of: decoratedFinder,
        matching: find.byType(Material),
      );
      expect(materialFinder, findsOneWidget);
      final material = tester.widget<Material>(materialFinder);
      expect(material.type, MaterialType.transparency);
    });

    testWidgets(
      'shows loading view with clamped progress and message when not completed and no error',
      (tester) async {
        // Arrange service so that we stay in the loading state
        when(mockService.isCompleted).thenReturn(false);
        when(mockService.hasError).thenReturn(false);
        when(mockService.lectureTitle).thenReturn(''); // force fallback title
        when(mockService.message).thenReturn('Uploading PDF…');
        when(
          mockService.progress,
        ).thenReturn(1.5); // > 1.0 -> should be clamped

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                // Use Builder so we can pass a real BuildContext into ExpandedLoadingOverlay
                builder: (context) {
                  return ExpandedLoadingOverlay(
                    service: mockService,
                    context: context,
                  );
                },
              ),
            ),
          ),
        );

        // Let AnimatedSwitcher finish
        await tester.pumpAndSettle();

        // We should be in the loading branch
        expect(find.byKey(const ValueKey('loading')), findsOneWidget);

        final creatingHeaderIsEnglish = find
            .text('Creating Lecture…')
            .evaluate()
            .isNotEmpty;
        final creatingHeaderIsKorean = find
            .text('강의 생성 중…')
            .evaluate()
            .isNotEmpty;
        expect(creatingHeaderIsEnglish || creatingHeaderIsKorean, isTrue);

        // Message text should match the service.message
        expect(find.text('Uploading PDF…'), findsOneWidget);

        // Progress is clamped to 100% inside _FancyProgressBar -> percent text
        expect(find.text('100%'), findsOneWidget);

        final richTexts = tester
            .widgetList<RichText>(find.byType(RichText))
            .toList();
        expect(richTexts, isNotEmpty);

        final titleRich = richTexts.firstWhere((rt) {
          final text = (rt.text as TextSpan).toPlainText();
          return text.contains('Lecture:') ||
              text.contains('강의명:') ||
              text.contains('제목 없음') ||
              text.contains('Untitled');
        }, orElse: () => richTexts.first);

        final fullText = (titleRich.text as TextSpan).toPlainText();

        final hasFallbackTitle =
            fullText.contains('제목 없음') || fullText.contains('Untitled');
        expect(hasFallbackTitle, isTrue);
      },
    );

    testWidgets(
      'shows completed view when service.isCompleted is true (and no error)',
      (tester) async {
        final mockService = MockLectureLoadingService();
        when(mockService.isCompleted).thenReturn(true);
        when(mockService.hasError).thenReturn(false);
        when(mockService.lectureTitle).thenReturn('Finished Lecture');
        when(mockService.message).thenReturn('Done');
        when(mockService.progress).thenReturn(1.0);

        await pumpWithService(tester, mockService);

        // Only completed view should be active.
        expect(find.byKey(const ValueKey('completed')), findsOneWidget);
        expect(find.byKey(const ValueKey('loading')), findsNothing);
        expect(find.byKey(const ValueKey('error')), findsNothing);

        // Header text: either English or Korean version.
        final english = find.text('Lecture Created!');
        final korean = find.text('강의 생성 완료!');
        final hasHeader =
            english.evaluate().isNotEmpty || korean.evaluate().isNotEmpty;
        expect(hasHeader, isTrue);
      },
    );

    testWidgets(
      'shows error view and uses provided errorTitle/errorMessage when service.hasError is true',
      (tester) async {
        final mockService = MockLectureLoadingService();
        when(mockService.isCompleted).thenReturn(true); // should be ignored
        when(mockService.hasError).thenReturn(true);
        when(mockService.errorTitle).thenReturn('Oops!');
        when(
          mockService.errorMessage,
        ).thenReturn('Something went wrong while creating the lecture.');
        when(mockService.lectureTitle).thenReturn('Should not matter');
        when(mockService.message).thenReturn('Also ignored');
        when(mockService.progress).thenReturn(0.5);

        await pumpWithService(tester, mockService);

        // Error view should take precedence.
        expect(find.byKey(const ValueKey('error')), findsOneWidget);
        expect(find.byKey(const ValueKey('completed')), findsNothing);
        expect(find.byKey(const ValueKey('loading')), findsNothing);

        // Error title and message come from the service and are visible.
        expect(find.text('Oops!'), findsOneWidget);
        expect(
          find.text('Something went wrong while creating the lecture.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'horizontal swipe to the left collapses overlay to bubble (alignRight=false)',
      (tester) async {
        await pumpOverlay(tester);

        // find the *inner* GestureDetector
        final gesture = find
            .descendant(
              of: find.byType(ExpandedLoadingOverlay),
              matching: find.byType(GestureDetector),
            )
            .first;

        final detector = tester.widget<GestureDetector>(gesture);
        expect(detector.onHorizontalDragEnd, isNotNull);

        // simulate a fast swipe to the left
        detector.onHorizontalDragEnd!(
          DragEndDetails(
            velocity: const Velocity(
              pixelsPerSecond: Offset(-300.0, 0.0), // abs(dx) > 200
            ),
          ),
        );

        // Now collapseToBubble should have been called with alignRight=false
        verify(mockService.collapseToBubble(alignRight: false)).called(1);
      },
    );

    testWidgets(
      'horizontal swipe to the right collapses overlay to bubble (alignRight=true)',
      (tester) async {
        await pumpOverlay(tester);

        final gesture = find
            .descendant(
              of: find.byType(ExpandedLoadingOverlay),
              matching: find.byType(GestureDetector),
            )
            .first;

        final detector = tester.widget<GestureDetector>(gesture);
        expect(detector.onHorizontalDragEnd, isNotNull);

        detector.onHorizontalDragEnd!(
          DragEndDetails(
            velocity: const Velocity(pixelsPerSecond: Offset(300.0, 0.0)),
          ),
        );

        verify(mockService.collapseToBubble(alignRight: true)).called(1);
      },
    );
  });

  group('DialogHeaderTitle', () {
    testWidgets('shows the given title with correct text style', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DialogHeaderTitle(title: 'Dialog title')),
        ),
      );

      final titleFinder = find.text('Dialog title');
      expect(titleFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(titleFinder);
      final style = textWidget.style;
      expect(style, isNotNull);
      expect(style!.fontSize, 18);
      expect(style.color, Colors.white);
    });

    testWidgets('uses light theme header color and rounded top corners', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(body: DialogHeaderTitle(title: 'Light header')),
        ),
      );

      final containerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.color == const Color(0xFF1D1D1D);
        }
        return false;
      });

      expect(containerFinder, findsOneWidget);

      final container = tester.widget<Container>(containerFinder);
      final box = container.decoration as BoxDecoration;
      final radius = box.borderRadius as BorderRadius;
      expect(radius.topLeft, const Radius.circular(28));
      expect(radius.topRight, const Radius.circular(28));
    });

    testWidgets('uses dark theme header color in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(body: DialogHeaderTitle(title: 'Dark header')),
        ),
      );

      final containerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.color == const Color.fromARGB(255, 88, 88, 86);
        }
        return false;
      });

      expect(containerFinder, findsOneWidget);
    });

    testWidgets('invokes provided onClose callback when close icon is tapped', (
      tester,
    ) async {
      final mockHandler = MockCallbackHandler();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogHeaderTitle(
              title: 'Closable',
              onClose: mockHandler.call,
            ),
          ),
        ),
      );

      final closeFinder = find.byIcon(Icons.close);
      expect(closeFinder, findsOneWidget);

      await tester.tap(closeFinder);
      await tester.pumpAndSettle();

      verify(mockHandler.call()).called(1);
      verifyNoMoreInteractions(mockHandler);
    });

    testWidgets('default onClose pops the route when onClose is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const Scaffold(
                            body: DialogHeaderTitle(title: 'Dialog'),
                          ),
                        ),
                      );
                    },
                    child: const Text('Open dialog'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Open the "dialog" route that contains DialogHeaderTitle.
      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();
      expect(find.byType(DialogHeaderTitle), findsOneWidget);

      // Tap the close icon – should pop back to the first route.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(DialogHeaderTitle), findsNothing);
      expect(find.text('Open dialog'), findsOneWidget);
    });
  });
}
