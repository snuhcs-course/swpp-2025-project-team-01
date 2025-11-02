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
        Routes.subjectsEdit: (context) =>
            const Scaffold(body: Text('Subjects Edit Screen')),
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
            drawer: const CustomDrawer(),
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
            drawer: const CustomDrawer(),
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
            drawer: const CustomDrawer(),
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
      expect(find.text('Create Lecture'), findsOneWidget);
      expect(find.text('Edit Subjects'), findsOneWidget);
      expect(find.text('Edit Tags'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('should display menu items in correct order', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            drawer: const CustomDrawer(),
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
      expect((listTiles.elementAt(1).title as Text).data, 'Edit Subjects');
      expect((listTiles.elementAt(2).title as Text).data, 'Edit Tags');
      expect((listTiles.elementAt(3).title as Text).data, 'Settings');
    });

    testWidgets('should have correct padding for menu title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            drawer: const CustomDrawer(),
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
            drawer: const CustomDrawer(),
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

    testWidgets('should navigate to subjects edit from drawer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            drawer: const CustomDrawer(),
            body: const Center(child: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the drawer
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      // Tap on "Edit Subjects"
      await tester.tap(find.text('Edit Subjects'));
      await tester.pumpAndSettle();

      // Should navigate to subjects edit screen
      expect(find.text('Subjects Edit Screen'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('should navigate to tags edit from drawer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            drawer: const CustomDrawer(),
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
            drawer: const CustomDrawer(),
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
            drawer: const CustomDrawer(),
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
            drawer: const CustomDrawer(),
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
      expect(find.text('과목 수정'), findsOneWidget);
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
            drawer: const CustomDrawer(),
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

  group('CustomDrawer.showAsDialog (Reduced Motion Mode) - English', () {
    testWidgets('should display menu when showAsDialog is called', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.showAsDialog(context),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap button to show drawer as dialog
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Should show menu items (indicating dialog is open)
      expect(find.text('Menu'), findsOneWidget);
    });

    testWidgets('should display all menu items in dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.showAsDialog(context),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show dialog
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Should show menu items
      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Create Lecture'), findsOneWidget);
      expect(find.text('Edit Subjects'), findsOneWidget);
      expect(find.text('Edit Tags'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('should align dialog to left side', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.showAsDialog(context),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show dialog
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Check alignment - find the Align widget that contains the drawer content
      final aligns = tester.widgetList<Align>(find.byType(Align));
      final drawerAlign = aligns.firstWhere(
        (align) => align.alignment == Alignment.centerLeft,
        orElse: () => aligns.first,
      );
      expect(drawerAlign.alignment, Alignment.centerLeft);
    });

    testWidgets('should have correct width (75% of screen)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.showAsDialog(context),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show dialog
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Get screen width
      final screenWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;

      // Find SizedBox containing the drawer content
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final drawerSizedBox = sizedBoxes.firstWhere(
        (box) => box.width != null && box.height == double.infinity,
      );

      expect(drawerSizedBox.width, screenWidth * 0.75);
      expect(drawerSizedBox.height, double.infinity);
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
                  onPressed: () => CustomDrawer.showAsDialog(context),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show dialog
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
                  onPressed: () => CustomDrawer.showAsDialog(context),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show dialog
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

    testWidgets('should navigate to lecture form from dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.showAsDialog(context),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show dialog
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Tap on "Create Lecture"
      await tester.tap(find.text('Create Lecture'));
      await tester.pumpAndSettle();

      // Should navigate to lecture form screen and close dialog
      expect(find.text('Lecture Form Screen'), findsOneWidget);
      expect(find.text('Menu'), findsNothing);
    });

    testWidgets('should navigate to subjects edit from dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.showAsDialog(context),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show dialog
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Tap on "Edit Subjects"
      await tester.tap(find.text('Edit Subjects'));
      await tester.pumpAndSettle();

      // Should navigate and close dialog
      expect(find.text('Subjects Edit Screen'), findsOneWidget);
      expect(find.text('Menu'), findsNothing);
    });

    testWidgets('should navigate to tags edit from dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.showAsDialog(context),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show dialog
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Tap on "Edit Tags"
      await tester.tap(find.text('Edit Tags'));
      await tester.pumpAndSettle();

      // Should navigate and close dialog
      expect(find.text('Tags Edit Screen'), findsOneWidget);
      expect(find.text('Menu'), findsNothing);
    });

    testWidgets('should navigate to settings from dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.showAsDialog(context),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show dialog
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Tap on "Settings"
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Should navigate and close dialog
      expect(find.text('Settings Screen'), findsOneWidget);
      expect(find.text('Menu'), findsNothing);
    });

    testWidgets('should dismiss dialog when tapping barrier', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.showAsDialog(context),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show dialog
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.text('Menu'), findsOneWidget);

      // Tap outside the dialog (on the barrier)
      await tester.tapAt(const Offset(600, 300)); // Right side of screen
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Menu'), findsNothing);
      expect(find.text('Show Drawer'), findsOneWidget);
    });

    testWidgets('should display dialog with barrier', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.showAsDialog(context),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show dialog
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Dialog barrier should exist (ModalBarrier is present when dialog is shown)
      expect(find.byType(ModalBarrier), findsWidgets);

      // Menu should be visible
      expect(find.text('Menu'), findsOneWidget);
    });
  });

  group('CustomDrawer.showAsDialog (Reduced Motion Mode) - Korean', () {
    testWidgets('should display menu items in Korean in dialog', (
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
                  onPressed: () => CustomDrawer.showAsDialog(context),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show dialog
      await tester.tap(find.text('Show Drawer'));
      await tester.pumpAndSettle();

      // Check Korean text
      expect(find.text('메뉴'), findsOneWidget);
      expect(find.text('강의 생성'), findsOneWidget);
      expect(find.text('과목 수정'), findsOneWidget);
      expect(find.text('태그 수정'), findsOneWidget);
      expect(find.text('설정'), findsOneWidget);
    });

    testWidgets('should navigate correctly from Korean dialog', (
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
                  onPressed: () => CustomDrawer.showAsDialog(context),
                  child: const Text('Show Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Show dialog
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
            drawer: const CustomDrawer(),
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

    testWidgets('should handle multiple dialog shows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CustomDrawer.showAsDialog(context),
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
            drawer: const CustomDrawer(),
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
            drawer: const CustomDrawer(),
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
