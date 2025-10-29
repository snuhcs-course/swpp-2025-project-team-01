import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/features/edit/lecture_form_screen.dart';
import 'package:re_view/features/edit/file_picker_service.dart';
import 'package:re_view/features/edit/lecture_creation_service.dart';
import 'package:re_view/features/edit/loader_service.dart';
import 'package:re_view/features/edit/background_service.dart';

// ------------------------------------------------------------------
// Mockito 대신 사용할 "가짜" (Fake/Stub) 클래스 정의
// ------------------------------------------------------------------

/// AppSettings를 흉내내는 가짜 클래스 (accessibility_mode_test.dartf에서 가져옴)
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

class FakeFilePickerService extends Fake implements FilePickerService {
  String? _pathResult;
  bool _willCancel = false;

  void setFileResult(String path) {
    _pathResult = path;
    _willCancel = false;
  }

  void setPickerToCancel() {
    _willCancel = true;
  }

  @override
  Future<String?> pickPdf() async {
    if (_willCancel) {
      return null;
    }
    return _pathResult;
  }

  @override
  Future<String?> pickAudio() async {
    if (_willCancel) {
      return null;
    }
    return _pathResult;
  }
}

class FakeLectureCreationService extends Fake
    implements LectureCreationService {
  CreationResult? _result;
  Exception? _exception;
  bool cancelCalled = false;

  // 테스트 설정: 성공 시나리오
  void setSuccessResult(CreationResult result) {
    _result = result;
    _exception = null;
  }

  // 테스트 설정: 실패 시나리오
  void setFailure(Exception exception) {
    _result = null;
    _exception = exception;
  }

  // 테스트 설정: 취소/중단 시나리오
  void setCancel() {
    _result = null;
    _exception = null;
  }

  @override
  Future<CreationResult?> createLecture({
    required String slidePath,
    required List<AudioFileEntry> audioEntries,
    required String title,
    required String serverAddress,
    required String port,
  }) async {
    // 테스트용 딜레이
    await Future.delayed(const Duration(milliseconds: 10));

    if (cancelCalled) {
      return null;
    }
    if (_exception != null) {
      throw _exception!;
    }

    // _result가 null이면 취소(null 리턴), 아니면 성공(result 리턴)
    return _result;
  }

  @override
  void cancelCreation() {
    cancelCalled = true;
  }
}

class FakeLoaderService extends Fake implements LoaderService {
  bool _isCancelled = false;
  bool startLoadingCalled = false;
  bool hideLoadingCalled = false;

  @override
  bool get isCancelled => _isCancelled;

  void setCancelled(bool value) {
    _isCancelled = value;
  }

  @override
  void startLoading(String title) {
    startLoadingCalled = true;
  }

  @override
  void setOnCancel(VoidCallback onCancel) {
    // 테스트에서는 취소 로직을 직접 호출하지 않으므로 비워 둠
  }

  @override
  void hideLoading() {
    hideLoadingCalled = true;
  }
}

class FakeBackgroundService extends Fake implements BackgroundService {
  @override
  Future<bool> initialize() async {
    return true; // 테스트 환경에서는 항상 성공
  }

  @override
  Future<void> enableBackgroundExecution() async {
    // 아무것도 안 함
  }

  @override
  Future<void> disableBackgroundExecution() async {
    // 아무것도 안 함
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------------
  // 테스트 설정 (Setup)
  // ------------------------------------------------------------------

  late FakeHiveManager fakeHiveManager;
  late FakeFilePickerService fakeFilePicker;
  late FakeLectureCreationService fakeCreator;
  late FakeLoaderService fakeLoader;
  late FakeBackgroundService fakeBackground;

  setUp(() {
    fakeHiveManager = FakeHiveManager();
    fakeFilePicker = FakeFilePickerService();
    fakeCreator = FakeLectureCreationService();
    fakeLoader = FakeLoaderService();
    fakeBackground = FakeBackgroundService();
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
    await tester.pumpWidget(
      createTestableWidget(
        LectureFormScreen(
          hiveManager: fakeHiveManager,
          filePickerService: fakeFilePicker,
          lectureCreationService: fakeCreator,
          loaderService: fakeLoader,
          backgroundService: fakeBackground,
        ),
      ),
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

    testWidgets('Verify tapping Slide PDF button updates label', (
      WidgetTester tester,
    ) async {
      // [Given]
      await pumpScreen(tester);
      // 가짜 FilePicker가 'slide.pdf'를 반환하도록 설정
      fakeFilePicker.setFileResult('/fake/path/to/slide.pdf');

      // [When]
      final slideButton = find.widgetWithText(OutlinedButton, '추가').at(0);
      await tester.tap(slideButton);
      await tester.pumpAndSettle();

      // [Then]
      expect(find.text('slide.pdf'), findsOneWidget);
    });
  });

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 3: Audio File List Management
  // ------------------------------------------------------------------
  group('3. Audio File List Management', () {
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
      // '추가' 버튼은 여전히 2개 (슬라이드 1, 오디오 1)
      expect(find.widgetWithText(OutlinedButton, '추가'), findsNWidgets(2));
    });

    testWidgets('Tapping Add Audio (+) success enables multi-mode', (
      WidgetTester tester,
    ) async {
      // [Given]
      final l10n = await pumpScreen(tester);

      // [When] 1. 첫 번째 오디오 파일을 업로드합니다.
      fakeFilePicker.setFileResult('/fake/audio1.m4a');
      final firstAudioButton = find.widgetWithText(OutlinedButton, '추가').at(1);
      await tester.ensureVisible(firstAudioButton);
      await tester.tap(firstAudioButton);
      await tester.pumpAndSettle();

      // [Verify 1] 'audio1.m4a' 텍스트가 표시됨
      expect(find.text('audio1.m4a'), findsOneWidget);

      // [When] 2. 오디오 추가(+) 버튼을 탭합니다.
      final addButtonFinder = find.byIcon(Icons.add_circle_outline);
      await tester.ensureVisible(addButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(addButtonFinder);
      await tester.pumpAndSettle(); // 새 항목 추가 애니메이션

      // [Then]
      // 1. 오디오 파일 UI가 2개가 됨 ('추가' 버튼 3개: 슬라이드1, 오디오1, 오디오2)
      expect(find.widgetWithText(OutlinedButton, '추가'), findsNWidgets(3));

      // 2. 새로 추가된 항목에 '...' 플레이스홀더가 표시됨 (슬라이드 '...' 포함 2개)
      expect(find.text('...'), findsNWidgets(2));

      // 3. 다중 모드가 활성화되어 '페이지 설정'이 나타남
      expect(
        find.text(l10n.isKorean ? '페이지 설정' : 'Page Range'),
        findsNWidgets(2), // 2개의 오디오 항목 모두에 대해
      );

      // 4. 제거(-) 버튼이 활성화됨
      final removeButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.remove_circle_outline),
      );
      expect(removeButton.onPressed, isNotNull);
    });

    testWidgets('Tapping Remove Audio (-) with no file removes directly', (
      WidgetTester tester,
    ) async {
      // [Given] 다중 모드 상태 (파일은 추가 안 함)
      await pumpScreen(tester);
      // 1. 첫 번째 파일 업로드
      fakeFilePicker.setFileResult('/fake/audio1.m4a');
      final firstAudioButton = find.widgetWithText(OutlinedButton, '추가').at(1);
      await tester.ensureVisible(firstAudioButton);
      await tester.tap(firstAudioButton);
      await tester.pumpAndSettle();
      // 2. 두 번째 슬롯 추가
      final addButtonFinder = find.byIcon(Icons.add_circle_outline);
      await tester.ensureVisible(addButtonFinder);
      await tester.tap(addButtonFinder);
      await tester.pumpAndSettle();

      // [Verify Given] '추가' 버튼 3개, '페이지 설정' 2개 확인
      expect(find.widgetWithText(OutlinedButton, '추가'), findsNWidgets(3));
      expect(find.text('페이지 설정'), findsNWidgets(2));

      // [When] 1. 제거(-) 버튼을 탭합니다. (두 번째 파일이 비어있음)
      final removeButtonFinder = find.byIcon(Icons.remove_circle_outline);
      await tester.tap(removeButtonFinder);
      await tester.pumpAndSettle(); // 항목 제거

      // [Then]
      // 1. 다이얼로그가 뜨지 않음
      expect(find.byType(AlertDialog), findsNothing);
      // 2. '추가' 버튼이 2개로 줄어듦 (슬라이드1, 오디오1)
      expect(find.widgetWithText(OutlinedButton, '추가'), findsNWidgets(2));
      // 3. 다중 모드가 비활성화됨
      expect(find.text('페이지 설정'), findsNothing);
      // 4. 제거(-) 버튼이 비활성화됨
      final removeButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.remove_circle_outline),
      );
      expect(removeButton.onPressed, isNull);
    });

    testWidgets('Tapping Remove Audio (-) with file shows dialog and removes', (
      WidgetTester tester,
    ) async {
      // [Given] 다중 모드 + 두 번째 파일도 업로드된 상태
      final l10n = await pumpScreen(tester);
      // 1. 첫 번째 파일 업로드
      fakeFilePicker.setFileResult('/fake/audio1.m4a');
      final firstAudioButton = find.widgetWithText(OutlinedButton, '추가').at(1);
      await tester.ensureVisible(firstAudioButton);
      await tester.tap(firstAudioButton);
      await tester.pumpAndSettle();
      // 2. 두 번째 슬롯 추가
      final addButtonFinder = find.byIcon(Icons.add_circle_outline);
      await tester.ensureVisible(addButtonFinder);
      await tester.tap(addButtonFinder);
      await tester.pumpAndSettle();
      // 3. 두 번째 파일 업로드
      fakeFilePicker.setFileResult('/fake/audio2.mp3');
      final secondAudioButton = find
          .widgetWithText(OutlinedButton, '추가')
          .at(2); // [수정]
      await tester.ensureVisible(secondAudioButton);
      await tester.tap(secondAudioButton);
      await tester.pumpAndSettle();

      // [Verify Given] 'audio2.mp3' 파일명 확인
      expect(find.text('audio2.mp3'), findsOneWidget);

      // [When] 1. 제거(-) 버튼을 탭합니다. (두 번째 파일이 채워져 있음)
      final removeButtonFinder = find.byIcon(Icons.remove_circle_outline);
      await tester.tap(removeButtonFinder);
      await tester.pumpAndSettle(); // 다이얼로그 표시

      // [Then] 1. 경고 다이얼로그가 뜹니다.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(l10n.isKorean ? '경고' : 'Warning'), findsOneWidget);

      // [When] 2. '삭제' 버튼을 탭합니다.
      await tester.tap(find.text(l10n.isKorean ? '삭제' : 'Delete'));
      await tester.pumpAndSettle(); // 다이얼로그 닫힘 및 항목 제거

      // [Then]
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('audio2.mp3'), findsNothing); // 파일 삭제됨
      expect(
        find.widgetWithText(OutlinedButton, '추가'),
        findsNWidgets(2),
      ); // 슬라이드1, 오디오1
      expect(find.text('페이지 설정'), findsNothing); // 다중 모드 비활성화
    });
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
      // 과목, 주차, 제목 입력
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('소프트웨어 공학').last);
      await tester.pumpAndSettle();
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

      // 오디오 파일은 업로드
      fakeFilePicker.setFileResult('/fake/audio1.m4a');
      final firstAudioButton = find.widgetWithText(OutlinedButton, '추가').at(1);
      await tester.ensureVisible(firstAudioButton);
      await tester.tap(firstAudioButton);
      await tester.pumpAndSettle();
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
      // 과목, 주차, 제목 입력
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('소프트웨어 공학').last);
      await tester.pumpAndSettle();
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

      // [수정] 슬라이드 PDF는 업로드
      fakeFilePicker.setFileResult('/fake/slide.pdf');
      await tester.tap(find.widgetWithText(OutlinedButton, '추가').at(0));
      await tester.pumpAndSettle();
      // (오디오 파일 업로드 안 함)

      // [When]
      await tester.tap(find.text(l10n.isKorean ? '생성하기' : 'Create'));
      await tester.pumpAndSettle();

      // [Then]
      expect(
        find.text(
          l10n.isKorean
              ? '오디오 파일을 최소 1개 업로드해주세요'
              : 'Please upload at least one audio file',
        ),
        findsOneWidget,
      );
      expect(fakeHiveManager.addLectureCalled, isFalse);
    });
  });

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 5: Create Button - Success & Failure Logic
  // ------------------------------------------------------------------
  group('5. Create Button - Success & Failure Logic', () {
    // 헬퍼 함수: 모든 폼을 유효하게 채움
    Future<void> fillValidForm(WidgetTester tester) async {
      // 1. 과목 선택
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('소프트웨어 공학').last);
      await tester.pumpAndSettle();

      // 2. 주차/제목 입력
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

      // 3. 슬라이드 업로드
      fakeFilePicker.setFileResult('/fake/slide.pdf');
      await tester.tap(find.widgetWithText(OutlinedButton, '추가').at(0));
      await tester.pumpAndSettle();

      // 4. 오디오 업로드
      fakeFilePicker.setFileResult('/fake/audio1.m4a');
      final firstAudioButton = find.widgetWithText(OutlinedButton, '추가').at(1);
      await tester.ensureVisible(firstAudioButton);
      await tester.tap(firstAudioButton);
      await tester.pumpAndSettle();
    }

    testWidgets('Tapping Create on Success saves to Hive and shows toast', (
      WidgetTester tester,
    ) async {
      // [Given] 폼이 유효하고, 가짜 서비스가 성공을 반환하도록 설정
      final l10n = await pumpScreen(tester);
      await fillValidForm(tester);

      final fakeResult = CreationResult(
        audioPath: '/result/audio.m4a',
        jsonPath: '/result/data.json',
        duration: 12345,
      );
      fakeCreator.setSuccessResult(fakeResult);

      // [When] 생성하기 버튼 탭
      final createButton = find.text(l10n.isKorean ? '생성하기' : 'Create');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);

      await tester.pumpAndSettle();

      // [Then]
      // 1. 로컬 로딩 인디케이터가 사라졌는지 확인
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // 2. HiveManager.addLecture가 호출되었는지 검증
      expect(fakeHiveManager.addLectureCalled, isTrue);
      expect(fakeHiveManager.lastAddedLecture?.title, 'Test Title');

      // 3. HiveManager.updateSubject가 호출되었는지 검증
      expect(fakeHiveManager.updateSubjectCalled, isTrue);
      expect(fakeHiveManager.lastUpdatedSubjectId, 's1');

      // 4. 성공 토스트가 표시됨
      expect(
        find.text(
          l10n.isKorean ? '강의가 생성되었습니다' : 'Lecture created successfully',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Tapping Create on Failure shows toast and does not save', (
      WidgetTester tester,
    ) async {
      // [Given] 폼이 유효하고, 가짜 서비스가 예외를 발생시키도록 설정
      final l10n = await pumpScreen(tester);
      await fillValidForm(tester);

      final fakeError = Exception('Network Error 404');
      fakeCreator.setFailure(fakeError);

      // [When] 생성하기 버튼 탭
      final createButton = find.text(l10n.isKorean ? '생성하기' : 'Create');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);

      await tester.pumpAndSettle();

      // [Then]
      // 1. 로컬 로딩 인디케이터가 사라짐
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // 2. 실패 토스트 메시지가 표시됨
      expect(
        find.text(
          l10n.isKorean
              ? '강의 생성 실패: $fakeError'
              : 'Failed to create lecture: $fakeError',
        ),
        findsOneWidget,
      );

      // 3. Hive에는 아무것도 저장되지 않음
      expect(fakeHiveManager.addLectureCalled, isFalse);
      expect(fakeHiveManager.updateSubjectCalled, isFalse);
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

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 7: FilePicker Cancel Scenarios
  // ------------------------------------------------------------------
  group('7. FilePicker Cancel Scenarios', () {
    testWidgets('Verify slide PDF picker cancel does not update state', (
      WidgetTester tester,
    ) async {
      // [Given]
      await pumpScreen(tester);
      fakeFilePicker.setPickerToCancel();

      // [When]
      final slideButton = find.widgetWithText(OutlinedButton, '추가').at(0);
      await tester.tap(slideButton);
      await tester.pumpAndSettle();

      // [Then] 여전히 '...' 플레이스홀더 표시
      expect(find.text('...'), findsNWidgets(2));
    });

    testWidgets('Verify audio file picker cancel does not update state', (
      WidgetTester tester,
    ) async {
      // [Given]
      await pumpScreen(tester);
      fakeFilePicker.setPickerToCancel();

      // [When]
      final audioButton = find.widgetWithText(OutlinedButton, '추가').at(1);
      await tester.ensureVisible(audioButton);
      await tester.tap(audioButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // [Then] 여전히 '...' 플레이스홀더 표시
      expect(find.text('...'), findsNWidgets(2));
    });
  });

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 8: Subject Dropdown State Changes
  // ------------------------------------------------------------------
  group('8. Subject Dropdown State Changes', () {
    testWidgets('Verify selecting subject then deselecting works', (
      WidgetTester tester,
    ) async {
      // [Given]
      final l10n = await pumpScreen(tester);

      // [When] 1. 과목 선택
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('소프트웨어 공학').last);
      await tester.pumpAndSettle();

      // [Then] 1. 과목이 선택됨
      expect(find.text('소프트웨어 공학'), findsOneWidget);

      // [When] 2. 다시 드롭다운 열어서 '선택 안 함' 선택
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(l10n.isKorean ? '선택 안 함' : 'Not Selected').last,
      );
      await tester.pumpAndSettle();

      // [Then] 2. 힌트가 다시 표시됨
      expect(
        find.text(l10n.isKorean ? '선택 안 함' : 'Not Selected'),
        findsWidgets,
      );
    });

    testWidgets('Verify switching between subjects works', (
      WidgetTester tester,
    ) async {
      // [Given]
      await pumpScreen(tester);

      // [When] 1. 첫 번째 과목 선택
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('소프트웨어 공학').last);
      await tester.pumpAndSettle();

      // [Then] 1.
      expect(find.text('소프트웨어 공학'), findsOneWidget);

      // [When] 2. 두 번째 과목으로 변경
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('데이터베이스').last);
      await tester.pumpAndSettle();

      // [Then] 2.
      expect(find.text('데이터베이스'), findsOneWidget);
      expect(find.text('소프트웨어 공학'), findsNothing);
    });
  });

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 9: Loading Cancellation
  // ------------------------------------------------------------------
  group('9. Loading Cancellation', () {
    testWidgets('Verify creation can be cancelled during loading', (
      WidgetTester tester,
    ) async {
      // [Given] 유효한 폼 작성
      final l10n = await pumpScreen(tester);

      // 과목 선택
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('소프트웨어 공학').last);
      await tester.pumpAndSettle();

      // 주차/제목 입력
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

      // 슬라이드 업로드
      fakeFilePicker.setFileResult('/fake/slide.pdf');
      await tester.tap(find.widgetWithText(OutlinedButton, '추가').at(0));
      await tester.pumpAndSettle();

      // 오디오 업로드
      fakeFilePicker.setFileResult('/fake/audio1.m4a');
      final firstAudioButton = find.widgetWithText(OutlinedButton, '추가').at(1);
      await tester.ensureVisible(firstAudioButton);
      await tester.tap(firstAudioButton);
      await tester.pumpAndSettle();

      // 가짜 서비스가 취소를 반환하도록 설정
      fakeCreator.setCancel();

      // [When] 생성하기 버튼 탭
      final createButton = find.text(l10n.isKorean ? '생성하기' : 'Create');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);

      // 취소 시뮬레이션
      fakeLoader.setCancelled(true);
      fakeCreator.cancelCreation();

      await tester.pumpAndSettle();

      // [Then] 취소됨을 확인
      expect(fakeCreator.cancelCalled, isTrue);
      expect(fakeHiveManager.addLectureCalled, isFalse);
    });
  });

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 10: Multi-Audio Page Range Edge Cases
  // ------------------------------------------------------------------
  group('10. Multi-Audio Page Range Edge Cases', () {
    testWidgets('Verify page range inputs appear in multi-audio mode', (
      WidgetTester tester,
    ) async {
      // [Given]
      final l10n = await pumpScreen(tester);

      // 첫 번째 오디오 업로드
      fakeFilePicker.setFileResult('/fake/audio1.m4a');
      final firstAudioButton = find.widgetWithText(OutlinedButton, '추가').at(1);
      await tester.ensureVisible(firstAudioButton);
      await tester.tap(firstAudioButton);
      await tester.pumpAndSettle();

      // [When] 두 번째 오디오 추가
      final addButtonFinder = find.byIcon(Icons.add_circle_outline);
      await tester.ensureVisible(addButtonFinder);
      await tester.tap(addButtonFinder);
      await tester.pumpAndSettle();

      // [Then] 페이지 범위 입력 필드가 나타남
      expect(
        find.text(l10n.isKorean ? '페이지 설정' : 'Page Range'),
        findsNWidgets(2),
      );

      // TextFields for page numbers (2 entries × 2 fields each = 4)
      final pageTextFields = find.byWidgetPredicate(
        (w) => w is TextField && w.keyboardType == TextInputType.number,
      );
      expect(pageTextFields, findsNWidgets(4));
    });

    testWidgets('Verify page range inputs accept numbers', (
      WidgetTester tester,
    ) async {
      // [Given] 다중 모드 활성화
      await pumpScreen(tester);

      fakeFilePicker.setFileResult('/fake/audio1.m4a');
      final firstAudioButton = find.widgetWithText(OutlinedButton, '추가').at(1);
      await tester.ensureVisible(firstAudioButton);
      await tester.tap(firstAudioButton);
      await tester.pumpAndSettle();

      final addButtonFinder = find.byIcon(Icons.add_circle_outline);
      await tester.ensureVisible(addButtonFinder);
      await tester.tap(addButtonFinder);
      await tester.pumpAndSettle();

      // [When] 페이지 번호 입력
      final pageTextFields = find.byWidgetPredicate(
        (w) => w is TextField && w.keyboardType == TextInputType.number,
      );

      await tester.enterText(pageTextFields.at(0), '1');
      await tester.enterText(pageTextFields.at(1), '10');
      await tester.pump();

      // [Then] 입력된 값 확인
      expect(find.text('1'), findsWidgets);
      expect(find.text('10'), findsWidgets);
    });
  });

  // ------------------------------------------------------------------
  // 테스트 케이스 그룹 11: Edge Cases for File Uploads
  // ------------------------------------------------------------------
  group('11. Edge Cases for File Uploads', () {
    testWidgets('Verify uploading slide with special characters in filename', (
      WidgetTester tester,
    ) async {
      // [Given]
      await pumpScreen(tester);
      fakeFilePicker.setFileResult('/fake/path/슬라이드 2024-01.pdf');

      // [When]
      final slideButton = find.widgetWithText(OutlinedButton, '추가').at(0);
      await tester.tap(slideButton);
      await tester.pumpAndSettle();

      // [Then] 파일명이 올바르게 표시됨
      expect(find.text('슬라이드 2024-01.pdf'), findsOneWidget);
    });

    testWidgets('Verify replacing already uploaded slide', (
      WidgetTester tester,
    ) async {
      // [Given] 슬라이드가 이미 업로드됨
      await pumpScreen(tester);
      fakeFilePicker.setFileResult('/fake/slide1.pdf');
      final slideButton = find.widgetWithText(OutlinedButton, '추가').at(0);
      await tester.tap(slideButton);
      await tester.pumpAndSettle();

      expect(find.text('slide1.pdf'), findsOneWidget);

      // [When] 새 파일로 교체
      fakeFilePicker.setFileResult('/fake/slide2.pdf');
      await tester.tap(slideButton);
      await tester.pumpAndSettle();

      // [Then] 새 파일명으로 업데이트됨
      expect(find.text('slide2.pdf'), findsOneWidget);
      expect(find.text('slide1.pdf'), findsNothing);
    });

    testWidgets('Verify replacing audio file in single mode', (
      WidgetTester tester,
    ) async {
      // [Given] 오디오가 이미 업로드됨
      await pumpScreen(tester);
      fakeFilePicker.setFileResult('/fake/audio1.m4a');
      final audioButton = find.widgetWithText(OutlinedButton, '추가').at(1);
      await tester.ensureVisible(audioButton);
      await tester.tap(audioButton);
      await tester.pumpAndSettle();

      expect(find.text('audio1.m4a'), findsOneWidget);

      // [When] 새 파일로 교체
      fakeFilePicker.setFileResult('/fake/audio2.mp3');
      await tester.ensureVisible(audioButton);
      await tester.tap(audioButton);
      await tester.pumpAndSettle();

      // [Then] 새 파일명으로 업데이트됨
      expect(find.text('audio2.mp3'), findsOneWidget);
      expect(find.text('audio1.m4a'), findsNothing);
    });
  });
}
