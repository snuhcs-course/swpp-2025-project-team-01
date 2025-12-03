import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/features/home/custom_drawer.dart';

void main() {
  // Helper to create test app with routes and localization
  Widget createTestApp({
    required Widget home,
    Locale locale = const Locale('en', 'US'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
      routes: {
        Routes.lectureForm: (context) =>
            const Scaffold(body: Text('Lecture Form Screen')),
        Routes.tagsEdit: (context) =>
            const Scaffold(body: Text('Tags Edit Screen')),
        Routes.settings: (context) =>
            const Scaffold(body: Text('Settings Screen')),
      },
    );
  }

  group('CustomDrawer Widget Creation', () {
    testWidgets('should create CustomDrawer widget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            drawer: const CustomDrawer(reduceMotion: false),
            body: const Center(child: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open drawer to verify it exists
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
    });

    testWidgets('should contain ListView widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            drawer: const CustomDrawer(reduceMotion: false),
            body: const Center(child: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open drawer
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('CustomDrawer as Drawer (Normal Mode) - English', () {
    testWidgets('should display all menu items in English', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            drawer: const CustomDrawer(reduceMotion: false),
            body: const Center(child: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the drawer
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      // Check if menu items are displayed
      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Create Lecture'), findsOneWidget);
      expect(find.text('Edit Tags'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(3));
    });

    testWidgets('should display menu items in correct order', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            drawer: const CustomDrawer(reduceMotion: false),
            body: const Center(child: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the drawer
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      // Find ListTiles
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      expect(listTiles.length, 4);

      // Check order
      expect((listTiles.elementAt(0).title as Text).data, 'Create Lecture');
      expect((listTiles.elementAt(1).title as Text).data, 'Edit Tags');
      expect((listTiles.elementAt(2).title as Text).data, 'Archive');
      expect((listTiles.elementAt(3).title as Text).data, 'Settings');
    });

    testWidgets('should have correct padding for menu title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            drawer: const CustomDrawer(reduceMotion: false),
            body: const Center(child: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the drawer
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      // Find the Padding widget containing "Menu"
      final menuText = find.text('Menu');
      final paddingWidget = tester.widget<Padding>(
        find.ancestor(of: menuText, matching: find.byType(Padding)).first,
      );

      expect(
        paddingWidget.padding,
        const EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 16.0),
      );
    });

    testWidgets('should navigate to lecture form from drawer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            drawer: const CustomDrawer(reduceMotion: false),
            body: const Center(child: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the drawer
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      // Tap on "Create Lecture"
      await tester.tap(find.text('Create Lecture'));
      await tester.pumpAndSettle();

      // Should navigate to lecture form screen
      expect(find.text('Lecture Form Screen'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('should navigate to tags edit from drawer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            drawer: const CustomDrawer(reduceMotion: false),
            body: const Center(child: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the drawer
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      // Tap on "Edit Tags"
      await tester.tap(find.text('Edit Tags'));
      await tester.pumpAndSettle();

      // Should navigate to tags edit screen
      expect(find.text('Tags Edit Screen'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('should navigate to settings from drawer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            drawer: const CustomDrawer(reduceMotion: false),
            body: const Center(child: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the drawer
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      // Tap on "Settings"
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Should navigate to settings screen
      expect(find.text('Settings Screen'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('should have ListView with zero padding', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            drawer: const CustomDrawer(reduceMotion: false),
            body: const Center(child: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the drawer
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.padding, EdgeInsets.zero);
    });
  });

  group('CustomDrawer as Drawer (Normal Mode) - Korean', () {
    testWidgets('should display all menu items in Korean', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          locale: const Locale('ko', 'KR'),
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            drawer: const CustomDrawer(reduceMotion: false),
            body: const Center(child: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the drawer
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      // Check if menu items are displayed in Korean
      expect(find.text('메뉴'), findsOneWidget);
      expect(find.text('강의 생성'), findsOneWidget);
      expect(find.text('태그 수정'), findsOneWidget);
      expect(find.text('설정'), findsOneWidget);
    });

    testWidgets('should navigate correctly with Korean locale', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          locale: const Locale('ko', 'KR'),
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            drawer: const CustomDrawer(reduceMotion: false),
            body: const Center(child: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the drawer
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      // Tap on "강의 생성"
      await tester.tap(find.text('강의 생성'));
      await tester.pumpAndSettle();

      // Should navigate to lecture form screen
      expect(find.text('Lecture Form Screen'), findsOneWidget);
    });
  });

  group('CustomDrawer.open (Reduced Motion Mode) - English', () {
    testWidgets('should display menu when open is called with reduceMotion', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.open(context, true),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap button to show drawer via overlay
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Should show menu items (indicating overlay is open)
      expect(find.text('Menu'), findsOneWidget);
    });

    testWidgets('should display all menu items in overlay', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.open(context, true),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show overlay
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Should show menu items
      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Create Lecture'), findsOneWidget);
      expect(find.text('Edit Tags'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(3));
    });

    testWidgets('should position overlay to left side', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.open(context, true),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show overlay
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Check positioning - find the Positioned widget
      final positionedWidgets = tester.widgetList<Positioned>(
        find.byType(Positioned),
      );
      final drawerPositioned = positionedWidgets.firstWhere(
        (pos) => pos.left == 0 && pos.top == 0 && pos.bottom == 0,
      );
      expect(drawerPositioned.left, 0);
      expect(drawerPositioned.top, 0);
      expect(drawerPositioned.bottom, 0);
    });

    testWidgets('should use Flutter standard drawer width calculation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.open(context, true),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show overlay
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Get screen width
      final screenWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;

      // Calculate expected width using Flutter's standard drawer logic
      // min(screenWidth - 56, 304)
      const double defaultWidth = 304.0;
      const double edgeWidth = 56.0;
      final double maxWidth = screenWidth - edgeWidth;
      final expectedWidth = maxWidth < defaultWidth ? maxWidth : defaultWidth;

      // Find SizedBox containing the drawer content
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final drawerSizedBox = sizedBoxes.firstWhere((box) => box.width != null);

      // Check width matches Flutter's standard calculation
      expect(drawerSizedBox.width, expectedWidth);
    });

    testWidgets('should have Material with elevation 16', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.open(context, true),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show overlay
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Find Material widgets
      final materials = tester.widgetList<Material>(find.byType(Material));
      // Find the Material that has elevation 16
      final drawerMaterial = materials.firstWhere((m) => m.elevation == 16);

      expect(drawerMaterial.elevation, 16);
    });

    testWidgets('should wrap content in SafeArea', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.open(context, true),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show overlay
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // SafeArea exists (there may be multiple in the widget tree)
      expect(find.byType(SafeArea), findsWidgets);

      // Verify the drawer content is wrapped in SafeArea by checking if Menu is a descendant
      final safeAreaWithMenu = find.ancestor(
        of: find.text('Menu'),
        matching: find.byType(SafeArea),
      );
      expect(safeAreaWithMenu, findsWidgets);
    });

    testWidgets('should navigate to lecture form from overlay', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.open(context, true),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show overlay
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Tap on "Create Lecture"
      await tester.tap(find.text('Create Lecture'));
      await tester.pumpAndSettle();

      // Should navigate to lecture form screen and close overlay
      expect(find.text('Lecture Form Screen'), findsOneWidget);
      expect(find.text('Menu'), findsNothing);
    });

    testWidgets('should navigate to tags edit from overlay', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.open(context, true),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show overlay
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Tap on "Edit Tags"
      await tester.tap(find.text('Edit Tags'));
      await tester.pumpAndSettle();

      // Should navigate and close overlay
      expect(find.text('Tags Edit Screen'), findsOneWidget);
      expect(find.text('Menu'), findsNothing);
    });

    testWidgets('should navigate to settings from overlay', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.open(context, true),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show overlay
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Tap on "Settings"
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Should navigate and close overlay
      expect(find.text('Settings Screen'), findsOneWidget);
      expect(find.text('Menu'), findsNothing);
    });

    testWidgets('should dismiss overlay when tapping barrier', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.open(context, true),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show overlay
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Verify overlay is open
      expect(find.text('Menu'), findsOneWidget);

      // Tap outside the overlay (on the barrier)
      await tester.tapAt(const Offset(600, 300)); // Right side of screen
      await tester.pumpAndSettle();

      // Overlay should be dismissed
      expect(find.text('Menu'), findsNothing);
      expect(find.text('Show Drawer'), findsOneWidget);
    });

    testWidgets('should display overlay with background barrier', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.open(context, true),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show overlay
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // GestureDetector with Container should exist as barrier
      expect(find.byType(GestureDetector), findsWidgets);

      // Menu should be visible
      expect(find.text('Menu'), findsOneWidget);
    });
  });

  group('CustomDrawer.open (Reduced Motion Mode) - Korean', () {
    testWidgets('should display menu items in Korean in overlay', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          locale: const Locale('ko', 'KR'),
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.open(context, true),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show overlay
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Check Korean text
      expect(find.text('메뉴'), findsOneWidget);
      expect(find.text('강의 생성'), findsOneWidget);
      expect(find.text('태그 수정'), findsOneWidget);
      expect(find.text('설정'), findsOneWidget);
    });

    testWidgets('should navigate correctly from Korean overlay', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          locale: const Locale('ko', 'KR'),
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.open(context, true),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show overlay
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Tap on "설정"
      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();

      // Should navigate to settings
      expect(find.text('Settings Screen'), findsOneWidget);
      expect(find.text('메뉴'), findsNothing);
    });
  });

  group('CustomDrawer Edge Cases', () {
    testWidgets('should handle multiple drawer opens and closes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            drawer: const CustomDrawer(reduceMotion: false),
            body: const Center(child: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ScaffoldState state = tester.firstState(find.byType(Scaffold));

      // Open and close multiple times
      for (int i = 0; i < 3; i++) {
        state.openDrawer();
        await tester.pumpAndSettle();
        expect(find.text('Menu'), findsOneWidget);

        state.closeDrawer();
        await tester.pumpAndSettle();
        expect(find.text('Menu'), findsNothing);
      }
    });

    testWidgets('should handle multiple overlay shows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.open(context, true),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show and dismiss multiple times
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Show Drawer'));
        await tester.pumpAndSettle();
        expect(find.text('Menu'), findsOneWidget);

        // Dismiss by tapping barrier
        await tester.tapAt(const Offset(600, 300));
        await tester.pumpAndSettle();
        expect(find.text('Menu'), findsNothing);
      }
    });

    testWidgets('should maintain menu title style', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Scaffold(
            drawer: const CustomDrawer(reduceMotion: false),
            body: const Center(child: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      final menuText = tester.widget<Text>(find.text('Menu'));
      expect(menuText.style?.fontSize, 20);
      expect(menuText.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('should render all ListTiles as tappable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Scaffold(
            drawer: const CustomDrawer(reduceMotion: false),
            body: const Center(child: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      // Verify all ListTiles have onTap callbacks
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      for (final tile in listTiles) {
        expect(tile.onTap, isNotNull);
      }
    });
  });
}
