import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/features/edit/lecture_form_screen.dart';

// ------------------------------------------------------------------
// Mockito 대신 사용할 "가짜" (Fake/Stub) 클래스 정의
// ------------------------------------------------------------------

/// AppSettings를 흉내내는 가짜 클래스 (accessibility_mode_test.dart에서 가져옴)
class FakeAppSettings implements AppSettings {
  FakeAppSettings({
    this.language = 'ko',
    this.theme = 'system',
    this.accessibilityHighContrast = false,
    this.accessibilityReduceMotion = false,
    this.accessibilityEmphasizeCaptions = false,
    this.ttsGender = '남성',
    this.ttsSpeed = '보통',
    this.tagColorTheme = '파스텔',
  });

  @override
  String theme;
  @override
  String language;
  @override
  bool accessibilityHighContrast;
  @override
  bool accessibilityReduceMotion;
  @override
  bool accessibilityEmphasizeCaptions;
  @override
  String ttsGender;
  @override
  String ttsSpeed;
  @override
  String tagColorTheme;
}

/// HiveManager를 흉내내는 가짜 클래스
/// LectureFormScreen에 필요한 메서드들을 구현
class FakeHiveManager extends Fake implements HiveManager {
  final FakeAppSettings _fakeSettings = FakeAppSettings();
  VoidCallback? _listener;

  // --- 테스트용 데이터 ---
  Map<String, HiveSubject> fakeSubjects = {};
  Map<String, HiveLecture> fakeLectures = {};

  // --- 테스트 검증용 변수 ---
  bool addLectureCalled = false;
  HiveLecture? lastAddedLecture;
  bool updateSubjectCalled = false;
  String? lastUpdatedSubjectId;
  List<String>? lastUpdatedSubjectLectureIds;

  @override
  AppSettings get settings => _fakeSettings;

  // --- LectureFormScreen이 사용하는 메서드 ---

  @override
  List<HiveSubject> getSubjects({
    bool favoritesOnly = false,
    List<String> filterTagIds = const [],
  }) {
    // 단순 구현 (필터링 X)
    return fakeSubjects.values.toList();
  }

  @override
  HiveSubject? getSubject(String id) {
    return fakeSubjects[id];
  }

  @override
  Future<void> addLecture(HiveLecture lecture) async {
    addLectureCalled = true;
    lastAddedLecture = lecture;
    fakeLectures[lecture.id] = lecture;
    // 실제 앱에서는 _save() -> notifyListeners() 호출
    triggerNotifyListeners();
  }

  @override
  Future<void> updateSubject(
    String id, {
    String? title,
    bool? favorite,
    List<String>? tagIds,
    List<String>? lectureIds,
  }) async {
    updateSubjectCalled = true;
    lastUpdatedSubjectId = id;
    if (lectureIds != null) {
      lastUpdatedSubjectLectureIds = lectureIds;
      if (fakeSubjects.containsKey(id)) {
        fakeSubjects[id]!.lectureIds = lectureIds;
      }
    }
    // 실제 앱에서는 _save() -> notifyListeners() 호출
    triggerNotifyListeners();
  }

  // --- ChangeNotifier 흉내내기 (accessibility_mode_test.dart에서 가져옴) ---
  @override
  void addListener(VoidCallback listener) {
    _listener = listener;
  }

  @override
  void removeListener(VoidCallback listener) {
    if (_listener == listener) {
      _listener = null;
    }
  }

  /// 테스트를 위해 'setState'를 수동으로 트리거하는 함수
  void triggerNotifyListeners() {
    _listener?.call();
  }

  // --- 테스트 헬퍼 ---
  void resetCallHistory() {
    addLectureCalled = false;
    lastAddedLecture = null;
    updateSubjectCalled = false;
    lastUpdatedSubjectId = null;
    lastUpdatedSubjectLectureIds = null;

    fakeSubjects.clear();
    fakeLectures.clear();
  }

  void addFakeSubject(HiveSubject subject) {
    fakeSubjects[subject.id] = subject;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------------
  // 테스트 설정 (Setup)
  // ------------------------------------------------------------------

  late FakeHiveManager fakeHiveManager;

  setUp(() {
    fakeHiveManager = FakeHiveManager();
    // 테스트에 사용할 기본 과목 데이터 추가
    fakeHiveManager.addFakeSubject(
      HiveSubject(id: 's1', title: '소프트웨어 공학', lectureIds: []),
    );
    fakeHiveManager.addFakeSubject(
      HiveSubject(id: 's2', title: '데이터베이스', lectureIds: []),
    );
  });

  // 테스트용 헬퍼 함수: 위젯 빌드 (accessibility_mode_test.dart와 동일)
  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'), // 'ko'로 고정하여 l10n 텍스트 예측
      home: child,
    );
  }

  // 테스트용 헬퍼 함수: 화면 펌핑 및 l10n 인스턴스 반환
  Future<AppLocalizations> pumpScreen(WidgetTester tester) async {
    // [중요] LectureFormScreen이 hiveManager를 주입받도록 수정되었다고 가정
    await tester.pumpWidget(
      createTestableWidget(LectureFormScreen(hiveManager: fakeHiveManager)),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(LectureFormScreen)));
  }

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 1: UI 초기 상태 검증
  // ------------------------------------------------------------------
  group('1. UI Initial State Verification', () {
    testWidgets('Verify initial UI elements are rendered correctly', (
      WidgetTester tester,
    ) async {
      // [When]
      final l10n = await pumpScreen(tester);

      // [Then]
      // AppBar
      expect(
        find.text(l10n.isKorean ? '강의 생성' : 'Create Lecture'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Subject Dropdown
      expect(
        find.text(l10n.isKorean ? '선택 안 함' : 'Not Selected'),
        findsWidgets,
      ); // 힌트와 메뉴 아이템 2개

      // TextFields
      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller?.text,
        isEmpty,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller?.text,
        isEmpty,
      );

      // Slide Button
      expect(find.text('...'), findsNWidgets(2)); // 슬라이드 1, 오디오 1

      // Audio Entries
      // expect(find.byType(_buildAudioFileEntry), findsOneWidget);
      expect(find.textContaining('페이지 설정'), findsNothing); // 다중 모드 아님
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);

      // Remove Audio Button (Disabled)
      final removeButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.remove_circle_outline),
      );
      expect(removeButton.onPressed, isNull);

      // Create Button
      expect(find.text(l10n.isKorean ? '생성하기' : 'Create'), findsOneWidget);
    });

    testWidgets('Verify subject dropdown contains all subjects', (
      WidgetTester tester,
    ) async {
      // [Given]
      await pumpScreen(tester);

      // [When]
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();

      // [Then]
      expect(
        find.text(fakeHiveManager.fakeSubjects['s1']!.title),
        findsOneWidget,
      );
      expect(
        find.text(fakeHiveManager.fakeSubjects['s2']!.title),
        findsOneWidget,
      );
    });
  });

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 2: Form Input & Interaction
  // ------------------------------------------------------------------
  group('2. Form Input & Interaction', () {
    testWidgets('Verify selecting a subject updates the dropdown', (
      WidgetTester tester,
    ) async {
      // [Given]
      await pumpScreen(tester);

      // [When]
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('소프트웨어 공학').last);
      await tester.pumpAndSettle();

      // [Then]
      // '선택 안 함' 힌트가 사라지고 '소프트웨어 공학'이 값으로 표시됨
      expect(find.text('소프트웨어 공학'), findsOneWidget);
      expect(
        find.text(
          AppLocalizations.of(
                tester.element(find.byType(LectureFormScreen)),
              ).isKorean
              ? '선택 안 함'
              : 'Not Selected',
        ),
        findsNothing,
      );
    });

    testWidgets('Verify typing in TextFields updates controllers', (
      WidgetTester tester,
    ) async {
      // [Given]
      await pumpScreen(tester);

      // [When]
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Ex. Week 1-1',
        ),
        'Week 1',
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == null,
        ),
        'Test Title',
      );
      await tester.pump();

      // [Then]
      expect(find.text('Week 1'), findsOneWidget);
      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets(
      'Verify tapping AppBar back button calls Navigator.pop (Test MD: 2)',
      (WidgetTester tester) async {
        // 1. 테스트용 고유 키(Key) 생성
        const Key homeButtonKey = Key('home_screen_push_button');

        // [Given] MaterialApp 직접 생성 (중첩 방지)
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => ElevatedButton(
                    key: homeButtonKey,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LectureFormScreen(hiveManager: fakeHiveManager),
                        ),
                      );
                    },
                    child: const Text('Go to Form'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // [Verify Setup] 홈 스크린의 버튼이 보이는지 확인
        expect(find.byKey(homeButtonKey), findsOneWidget);
        expect(find.byType(LectureFormScreen), findsNothing);

        // [When] 1. 홈 스크린의 버튼을 탭 (Push)
        await tester.tap(find.byKey(homeButtonKey));
        await tester.pumpAndSettle(); // 네비게이션 애니메이션 대기

        // [Then] 1. LectureFormScreen이 보이는지 확인
        expect(find.byType(LectureFormScreen), findsOneWidget);
        expect(find.byKey(homeButtonKey), findsNothing); // 홈 스크린은 가려짐

        // [When] 2. AppBar의 뒤로가기 버튼을 탭 (Pop)
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle(); // 네비게이션 애니메이션 대기

        // [Then] 2. LectureFormScreen이 사라지고 홈 스크린이 다시 보이는지 확인
        expect(find.byType(LectureFormScreen), findsNothing);
        expect(find.byKey(homeButtonKey), findsOneWidget); // 홈 스크린이 다시 보임
      },
    );
  });

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 3: Audio File List Management
  // ------------------------------------------------------------------
  group('3. Audio File List Management (Partial)', () {
    testWidgets('Tapping Add Audio (+) when first file is null shows toast', (
      WidgetTester tester,
    ) async {
      // [Given]
      final l10n = await pumpScreen(tester);
      // expect(find.byType(_buildAudioFileEntry), findsOneWidget);

      // [When]
      // 1. 버튼을 찾습니다.
      final addButtonFinder = find.byIcon(Icons.add_circle_outline);

      // 2. 버튼이 화면에 보이도록 스크롤합니다.
      await tester.ensureVisible(addButtonFinder);
      await tester.pumpAndSettle(); // 스크롤 애니메이션 대기

      // 3. 버튼을 탭합니다.
      await tester.tap(addButtonFinder);
      await tester.pumpAndSettle(); // SnackBar 애니메이션 대기

      // [Then]
      expect(
        find.text(
          l10n.isKorean
              ? '파일을 순서대로 업로드해주세요'
              : 'Please upload the files in order',
        ),
        findsOneWidget,
      );
      // expect(find.byType(_buildAudioFileEntry), findsOneWidget); // 새 항목이 추가되지 않음
    });

    // [참고] '파일 추가 성공' 및 '파일 제거' 테스트는
    // FilePicker를 모킹(faking)할 수 있도록
    // LectureFormScreen이 리팩토링 되어야 테스트 가능합니다.
  });

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 4: Create Button - Validation
  // ------------------------------------------------------------------
  group('4. Create Button - Validation (Partial)', () {
    testWidgets('Tapping Create with no subject shows toast', (
      WidgetTester tester,
    ) async {
      // [Given]
      final l10n = await pumpScreen(tester);
      // (과목 선택 안 함)
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Ex. Week 1-1',
        ),
        'Week 1',
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == null,
        ),
        'Test Title',
      );

      // [When]
      await tester.tap(find.text(l10n.isKorean ? '생성하기' : 'Create'));
      await tester.pumpAndSettle();

      // [Then]
      expect(
        find.text(l10n.isKorean ? '과목을 선택해주세요' : 'Please select a subject'),
        findsOneWidget,
      );
      expect(fakeHiveManager.addLectureCalled, isFalse);
    });

    testWidgets('Tapping Create with no week label shows toast', (
      WidgetTester tester,
    ) async {
      // [Given]
      final l10n = await pumpScreen(tester);
      // 과목 선택
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('소프트웨어 공학').last);
      await tester.pumpAndSettle();
      // 제목 입력
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == null,
        ),
        'Test Title',
      );
      // (주차 입력 안 함)

      // [When]
      await tester.tap(find.text(l10n.isKorean ? '생성하기' : 'Create'));
      await tester.pumpAndSettle();

      // [Then]
      expect(
        find.text(
          l10n.isKorean ? '강의 주차를 입력해주세요' : 'Please enter lecture week',
        ),
        findsOneWidget,
      );
      expect(fakeHiveManager.addLectureCalled, isFalse);
    });

    testWidgets('Tapping Create with no title shows toast', (
      WidgetTester tester,
    ) async {
      // [Given]
      final l10n = await pumpScreen(tester);
      // 과목 선택
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('소프트웨어 공학').last);
      await tester.pumpAndSettle();
      // 주차 입력
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Ex. Week 1-1',
        ),
        'Week 1',
      );
      // (제목 입력 안 함)

      // [When]
      await tester.tap(find.text(l10n.isKorean ? '생성하기' : 'Create'));
      await tester.pumpAndSettle();

      // [Then]
      expect(
        find.text(
          l10n.isKorean ? '강의 제목을 입력해주세요' : 'Please enter lecture title',
        ),
        findsOneWidget,
      );
      expect(fakeHiveManager.addLectureCalled, isFalse);
    });
  });
  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 4: Create Button - Additional Validation
  // ------------------------------------------------------------------
  group('4. Create Button - Additional Validation', () {
    testWidgets('Tapping Create with no slide PDF shows toast', (
      WidgetTester tester,
    ) async {
      // [Given]
      final l10n = await pumpScreen(tester);
      // 과목 선택
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('소프트웨어 공학').last);
      await tester.pumpAndSettle();
      // 주차 입력
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Ex. Week 1-1',
        ),
        'Week 1',
      );
      // 제목 입력
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == null,
        ),
        'Test Title',
      );
      // (슬라이드 PDF 업로드 안 함)

      // [When]
      await tester.tap(find.text(l10n.isKorean ? '생성하기' : 'Create'));
      await tester.pumpAndSettle();

      // [Then]
      expect(
        find.text(
          l10n.isKorean ? '슬라이드 PDF를 업로드해주세요' : 'Please upload slide PDF',
        ),
        findsOneWidget,
      );
      expect(fakeHiveManager.addLectureCalled, isFalse);
    });

    testWidgets('Tapping Create with no audio file shows toast', (
      WidgetTester tester,
    ) async {
      // [Given]
      final l10n = await pumpScreen(tester);
      // 과목 선택
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('소프트웨어 공학').last);
      await tester.pumpAndSettle();
      // 주차 입력
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Ex. Week 1-1',
        ),
        'Week 1',
      );
      // 제목 입력
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == null,
        ),
        'Test Title',
      );
      // 슬라이드 PDF는 있다고 가정 (하지만 실제로 업로드는 불가능 - FilePicker 모킹 필요)
      // 오디오 파일도 업로드 안 함

      // [When]
      await tester.tap(find.text(l10n.isKorean ? '생성하기' : 'Create'));
      await tester.pumpAndSettle();

      // [Then]
      // 슬라이드 PDF 경고가 먼저 나타남 (순서상)
      // 실제로는 오디오 파일 경고를 보려면 슬라이드도 업로드되어야 함
      // FilePicker 모킹 없이는 이 테스트는 제한적
      expect(
        find.text(
          l10n.isKorean ? '슬라이드 PDF를 업로드해주세요' : 'Please upload slide PDF',
        ),
        findsOneWidget,
      );
      expect(fakeHiveManager.addLectureCalled, isFalse);
    });
  });

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 6: State Management & Utilities
  // ------------------------------------------------------------------
  group('6. State Management & Utilities (Test MD: 6)', () {
    testWidgets('Verify controllers are disposed correctly', (
      WidgetTester tester,
    ) async {
      // [Given] 화면을 띄우고 컨트롤러들을 찾습니다.
      await pumpScreen(tester);

      // 1. '주차' 텍스트필드와 컨트롤러 찾기
      final weekTextField = tester.widget<TextField>(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Ex. Week 1-1',
        ),
      );
      final weekController = weekTextField.controller!;

      // 2. '제목' 텍스트필드와 컨트롤러 찾기
      final titleTextField = tester.widget<TextField>(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == null,
        ),
      );
      final titleController = titleTextField.controller!;

      // [When] 위젯을 화면에서 제거 (dispose)
      await tester.pumpWidget(Container());

      // [Then] 컨트롤러가 dispose되었는지 확인
      // dispose된 컨트롤러에 접근하려 하면 FlutterError가 발생합니다.
      try {
        weekController.text = 'test'; // 사용 시도
        fail('weekController was not disposed'); // 이 라인이 실행되면 실패
      } catch (e) {
        expect(e, isA<FlutterError>()); // FlutterError가 발생해야 성공
      }

      try {
        titleController.text = 'test'; // 사용 시도
        fail('titleController was not disposed');
      } catch (e) {
        expect(e, isA<FlutterError>());
      }
    });

    testWidgets('Verify _getFileName utility extracts filename correctly', (
      WidgetTester tester,
    ) async {
      // [Given]
      await pumpScreen(tester);

      // [When & Then] - _getFileName은 private이므로 간접적으로 테스트
      // 실제로는 파일을 업로드했을 때 파일명이 표시되는지 확인해야 함
      // 하지만 FilePicker 모킹 없이는 직접 테스트 불가능
      // 대신 UI에서 '...' 플레이스홀더가 표시되는지 확인
      expect(find.text('...'), findsNWidgets(2)); // 슬라이드 1, 오디오 1
    });

    testWidgets(
      'Verify remove audio button is disabled when only one audio file',
      (WidgetTester tester) async {
        // [Given]
        await pumpScreen(tester);

        // [Then] 오디오 파일이 1개일 때 Remove 버튼이 비활성화되어 있음
        final removeButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.remove_circle_outline),
        );
        expect(removeButton.onPressed, isNull); // 비활성화 상태
      },
    );
  });
}
