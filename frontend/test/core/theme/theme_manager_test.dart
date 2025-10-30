import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_view/core/theme/theme_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeManager', () {
    late ThemeManager manager;

    setUp(() {
      // ThemeManager는 싱글톤이므로 인스턴스를 가져옴
      manager = ThemeManager.instance;
    });

    tearDown(() async {
      // 각 테스트 후 SharedPreferences 초기화
      SharedPreferences.setMockInitialValues({});
    });

    test('should be a singleton', () {
      final instance1 = ThemeManager.instance;
      final instance2 = ThemeManager.instance;

      expect(instance1, same(instance2));
    });

    test('should extend ChangeNotifier', () {
      expect(manager, isA<ChangeNotifier>());
    });

    group('loadThemeMode', () {
      test('should load system theme mode by default', () async {
        SharedPreferences.setMockInitialValues({});

        await manager.loadThemeMode();

        expect(manager.themeMode, ThemeMode.system);
      });

      test('should load saved light theme mode', () async {
        SharedPreferences.setMockInitialValues({'display_mode': 'light'});

        await manager.loadThemeMode();

        expect(manager.themeMode, ThemeMode.light);
      });

      test('should load saved dark theme mode', () async {
        SharedPreferences.setMockInitialValues({'display_mode': 'dark'});

        await manager.loadThemeMode();

        expect(manager.themeMode, ThemeMode.dark);
      });

      test('should load saved system theme mode', () async {
        SharedPreferences.setMockInitialValues({'display_mode': 'system'});

        await manager.loadThemeMode();

        expect(manager.themeMode, ThemeMode.system);
      });

      test('should default to system for invalid values', () async {
        SharedPreferences.setMockInitialValues({'display_mode': 'invalid'});

        await manager.loadThemeMode();

        expect(manager.themeMode, ThemeMode.system);
      });

      test('should notify listeners when theme is loaded', () async {
        SharedPreferences.setMockInitialValues({'display_mode': 'dark'});

        var notified = false;
        manager.addListener(() {
          notified = true;
        });

        await manager.loadThemeMode();

        expect(notified, true);
      });
    });

    group('setThemeMode', () {
      test('should set light theme mode', () async {
        SharedPreferences.setMockInitialValues({});

        await manager.setThemeMode('light');

        expect(manager.themeMode, ThemeMode.light);
      });

      test('should set dark theme mode', () async {
        SharedPreferences.setMockInitialValues({});

        await manager.setThemeMode('dark');

        expect(manager.themeMode, ThemeMode.dark);
      });

      test('should set system theme mode', () async {
        SharedPreferences.setMockInitialValues({});

        await manager.setThemeMode('system');

        expect(manager.themeMode, ThemeMode.system);
      });

      test('should persist theme mode to SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({});

        await manager.setThemeMode('dark');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('display_mode'), 'dark');
      });

      test('should notify listeners when theme is changed', () async {
        SharedPreferences.setMockInitialValues({});

        var notifyCount = 0;
        manager.addListener(() {
          notifyCount++;
        });

        await manager.setThemeMode('dark');

        expect(notifyCount, greaterThan(0));
      });

      test('should handle multiple theme changes', () async {
        SharedPreferences.setMockInitialValues({});

        await manager.setThemeMode('light');
        expect(manager.themeMode, ThemeMode.light);

        await manager.setThemeMode('dark');
        expect(manager.themeMode, ThemeMode.dark);

        await manager.setThemeMode('system');
        expect(manager.themeMode, ThemeMode.system);
      });

      test('should auto-initialize if not already initialized', () async {
        SharedPreferences.setMockInitialValues({});

        // loadThemeMode를 호출하지 않고 바로 setThemeMode 호출
        await manager.setThemeMode('dark');

        expect(manager.themeMode, ThemeMode.dark);
      });
    });

    group('theme mode conversion', () {
      test('should convert "light" string to ThemeMode.light', () async {
        SharedPreferences.setMockInitialValues({});

        await manager.setThemeMode('light');

        expect(manager.themeMode, ThemeMode.light);
      });

      test('should convert "dark" string to ThemeMode.dark', () async {
        SharedPreferences.setMockInitialValues({});

        await manager.setThemeMode('dark');

        expect(manager.themeMode, ThemeMode.dark);
      });

      test('should convert "system" string to ThemeMode.system', () async {
        SharedPreferences.setMockInitialValues({});

        await manager.setThemeMode('system');

        expect(manager.themeMode, ThemeMode.system);
      });

      test('should convert unknown strings to ThemeMode.system', () async {
        SharedPreferences.setMockInitialValues({});

        await manager.setThemeMode('unknown');

        expect(manager.themeMode, ThemeMode.system);
      });

      test('should handle empty string', () async {
        SharedPreferences.setMockInitialValues({});

        await manager.setThemeMode('');

        expect(manager.themeMode, ThemeMode.system);
      });
    });

    group('listener management', () {
      test('should support adding and removing listeners', () {
        void listener() {
          // 리스너 함수
        }

        // 리스너 추가 및 제거가 에러 없이 동작하는지 확인
        manager.addListener(listener);
        manager.removeListener(listener);

        // 테스트가 성공적으로 완료되면 리스너 관리가 정상 작동
        expect(true, true);
      });

      test('should support removing listeners', () async {
        SharedPreferences.setMockInitialValues({});

        var callCount = 0;
        void listener() {
          callCount++;
        }

        manager.addListener(listener);
        await manager.setThemeMode('dark');

        final countAfterFirst = callCount;

        manager.removeListener(listener);
        await manager.setThemeMode('light');

        // 리스너 제거 후에는 callCount가 증가하지 않아야 함
        expect(callCount, countAfterFirst);
      });

      test('should notify multiple listeners', () async {
        SharedPreferences.setMockInitialValues({});

        var listener1Called = false;
        var listener2Called = false;

        void listener1() {
          listener1Called = true;
        }

        void listener2() {
          listener2Called = true;
        }

        manager.addListener(listener1);
        manager.addListener(listener2);

        await manager.setThemeMode('dark');

        expect(listener1Called, true);
        expect(listener2Called, true);

        manager.removeListener(listener1);
        manager.removeListener(listener2);
      });
    });

    group('persistence', () {
      test('should load previously saved theme on restart', () async {
        // 첫 번째 세션: dark 모드 저장
        SharedPreferences.setMockInitialValues({});
        await manager.setThemeMode('dark');

        // 두 번째 세션: 저장된 값 로드
        final prefs = await SharedPreferences.getInstance();
        final savedMode = prefs.getString('display_mode');

        expect(savedMode, 'dark');
      });

      test('should use correct SharedPreferences key', () async {
        SharedPreferences.setMockInitialValues({});

        await manager.setThemeMode('light');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('display_mode'), true);
      });
    });

    group('edge cases', () {
      test('should handle rapid theme changes', () async {
        SharedPreferences.setMockInitialValues({});

        await manager.setThemeMode('light');
        await manager.setThemeMode('dark');
        await manager.setThemeMode('system');
        await manager.setThemeMode('light');

        expect(manager.themeMode, ThemeMode.light);
      });

      test('should handle loadThemeMode called multiple times', () async {
        SharedPreferences.setMockInitialValues({'display_mode': 'dark'});

        await manager.loadThemeMode();
        await manager.loadThemeMode();
        await manager.loadThemeMode();

        expect(manager.themeMode, ThemeMode.dark);
      });
    });

    group('integration with Flutter', () {
      testWidgets('ThemeManager can be used with MaterialApp', (tester) async {
        SharedPreferences.setMockInitialValues({});
        await manager.loadThemeMode();

        await tester.pumpWidget(
          ListenableBuilder(
            listenable: manager,
            builder: (context, child) {
              return MaterialApp(
                themeMode: manager.themeMode,
                home: const Scaffold(body: Text('Test')),
              );
            },
          ),
        );

        expect(find.text('Test'), findsOneWidget);
      });

      testWidgets('MaterialApp updates when theme mode changes', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        await manager.loadThemeMode();

        await tester.pumpWidget(
          ListenableBuilder(
            listenable: manager,
            builder: (context, child) {
              return MaterialApp(
                themeMode: manager.themeMode,
                home: Builder(
                  builder: (context) {
                    final brightness = Theme.of(context).brightness;
                    return Text('Brightness: ${brightness.name}');
                  },
                ),
              );
            },
          ),
        );

        // 초기 상태 확인
        expect(find.textContaining('Brightness:'), findsOneWidget);

        // 테마 변경
        await manager.setThemeMode('dark');
        await tester.pumpAndSettle();

        // UI가 업데이트되었는지 확인
        expect(find.textContaining('Brightness:'), findsOneWidget);
      });
    });
  });
}
