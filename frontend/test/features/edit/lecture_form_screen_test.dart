import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/core/lecture_loading_service.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/features/edit/lecture_form_screen.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

import 'lecture_form_screen_test.mocks.dart';

// ------------------------------------------------------------------
// Mock 클래스 생성
// ------------------------------------------------------------------

// Mock FileReadingService
class MockFileReadingService implements FileReadingService {
  final Map<String, Uint8List> _byteResponses = {};
  final Map<String, String> _stringResponses = {};
  final Set<String> _throwOnRead = {};

  void onReadAsBytes(String path, Uint8List response) {
    _byteResponses[path] = response;
  }

  void onReadAsString(String path, String response) {
    _stringResponses[path] = response;
  }

  void shouldThrow(String path) {
    _throwOnRead.add(path);
  }

  @override
  Future<Uint8List> readAsBytes(String path) {
    if (_throwOnRead.contains(path)) {
      throw FileSystemException('Mock file system exception', path);
    }
    if (_byteResponses.containsKey(path)) {
      return Future.value(_byteResponses[path]);
    }
    if (_stringResponses.containsKey(path)) {
      return Future.value(
        Uint8List.fromList(utf8.encode(_stringResponses[path]!)),
      );
    }
    throw FileSystemException('File not found in mock', path);
  }

  @override
  Future<String> readAsString(String path) {
    if (_throwOnRead.contains(path)) {
      throw FileSystemException('Mock file system exception', path);
    }
    if (_stringResponses.containsKey(path)) {
      return Future.value(_stringResponses[path]);
    }
    if (_byteResponses.containsKey(path)) {
      return Future.value(utf8.decode(_byteResponses[path]!));
    }
    throw FileSystemException('File not found in mock', path);
  }

  void clear() {
    _byteResponses.clear();
    _stringResponses.clear();
    _throwOnRead.clear();
  }
}

@GenerateMocks([HiveManager, LectureLoadingService, FilePicker, Uuid])
void main() {
  // --- 위젯 테스트 설정 (Setup) ---
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHiveManager mockHiveManager;
  late MockLectureLoadingService mockLectureLoadingService;
  late MockFilePicker mockFilePicker;
  late MockUuid mockUuid;
  late MockFileReadingService mockFileReadingService;

  const fakeLectureId = 'test-lecture-id';

  // Mock 구현
  Future<List<String>?> mockFetchLecture(
    String slidePath,
    AudioFileEntry audioFileEntry,
    String titleText,
    String lectureId,
    int part,
    int totalParts,
    String serverAddress,
    String port,
    String langCode, {
    http.Client? clientToClose,
  }) async {
    final fakeTtsPath = '/fake/tts_${lectureId}_$part.opus';
    final fakeJsonPath = '/fake/data_${lectureId}_$part.json';

    return [fakeTtsPath, fakeJsonPath];
  }

  Future<String?> mockConcatenateAudioFiles(
    List<String> audioPaths,
    String titleText,
    String lectureId, {
    Directory? dirOverride,
  }) async {
    return '/fake/${lectureId}_concat.opus';
  }

  Future<String?> mockConcatenateJsonFiles(
    List<String> jsonPaths,
    List<int> pdfStarts,
    String titleText,
    String lectureId, {
    Directory? dirOverride,
  }) async {
    return '/fake/${lectureId}_concat.json';
  }

  http.Client mockHttpClientFactory() => http.Client();

  final mockFlutterBackground = _MockFlutterBackground();

  PdfDocument mockPdfDocumentFactory(List<int> inputBytes) =>
      _MockPdfDocument();

  setUp(() {
    mockHiveManager = MockHiveManager();
    mockLectureLoadingService = MockLectureLoadingService();
    mockFilePicker = MockFilePicker();
    mockUuid = MockUuid();
    mockFileReadingService = MockFileReadingService();

    // 기본 모킹 설정
    final fakeSubject = HiveSubject(
      id: 'subj-1',
      title: 'Test Subject',
      lectureIds: [],
    );
    when(mockHiveManager.getSubjects()).thenReturn([fakeSubject]);
    when(mockHiveManager.getSubject(any)).thenReturn(fakeSubject);
    when(mockHiveManager.addLecture(any)).thenAnswer((invocation) async {});
    when(
      mockHiveManager.updateSubject(any, lectureIds: anyNamed('lectureIds')),
    ).thenAnswer((_) async {});
    when(mockUuid.v4()).thenReturn(fakeLectureId);

    // LectureLoadingService 기본 설정
    when(
      mockLectureLoadingService.startLoading(any, any),
    ).thenAnswer((_) async {});
    when(
      mockLectureLoadingService.completeLoading(
        lectureId: anyNamed('lectureId'),
      ),
    ).thenAnswer((_) {});
    when(mockLectureLoadingService.setOnCancel(any)).thenAnswer((_) {});
    when(mockLectureLoadingService.hideLoading()).thenAnswer((_) {});
    when(
      mockLectureLoadingService.updateProgress(any, any, any),
    ).thenAnswer((_) {});
  });

  // --- 테스트용 헬퍼 함수: 위젯 빌드 ---
  Widget createTestableWidget(
    Widget child, {
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: child,
      onGenerateRoute: (settings) {
        if (settings.name == Routes.home || settings.name == '/home') {
          return MaterialPageRoute(
            builder: (_) =>
                const Scaffold(body: Center(child: Text('Home Screen'))),
          );
        }
        return null;
      },
    );
  }

  // --- 테스트용 헬퍼 함수: 화면 펌핑 ---
  Future<void> pumpScreen(
    WidgetTester tester, {
    FetchLectureCallback? fetchLectureCallback,
    ConcatenateAudioFilesCallback? concatenateAudioFilesCallback,
    ConcatenateJsonFilesCallback? concatenateJsonFilesCallback,
    HttpClientFactory? httpClientFactory,
    FlutterBackgroundInterface? flutterBackground,
    PdfDocumentFactory? pdfDocumentFactory,
    FileReadingService? fileReadingService,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      createTestableWidget(
        LectureFormScreen(
          hiveManager: mockHiveManager,
          lectureLoadingService: mockLectureLoadingService,
          filePicker: mockFilePicker,
          uuid: mockUuid,
          fetchLectureCallback: fetchLectureCallback ?? mockFetchLecture,
          concatenateAudioFilesCallback:
              concatenateAudioFilesCallback ?? mockConcatenateAudioFiles,
          concatenateJsonFilesCallback:
              concatenateJsonFilesCallback ?? mockConcatenateJsonFiles,
          httpClientFactory: httpClientFactory ?? mockHttpClientFactory,
          flutterBackground: flutterBackground ?? mockFlutterBackground,
          pdfDocumentFactory: pdfDocumentFactory ?? mockPdfDocumentFactory,
          fileReadingService: fileReadingService ?? mockFileReadingService,
        ),
        locale: locale,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('1. UI Initial State Verification', () {
    testWidgets('Verify initial UI elements are rendered correctly', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('Create Lecture'), findsOneWidget);
      expect(find.text('Select Subject'), findsOneWidget);
      expect(find.text('Lecture Week'), findsOneWidget);
      expect(find.text('Lecture Title'), findsOneWidget);
      expect(find.text('Lecture Slides (.pdf)'), findsOneWidget);
      expect(find.text('Lecture Audio'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Create'), findsOneWidget);
    });

    testWidgets('Verify subject dropdown displays correctly', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(DropdownButton<String?>), findsOneWidget);
      expect(find.text('Not Selected'), findsOneWidget);
    });

    testWidgets('Verify initial audio entry is shown', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('Page Range'), findsOneWidget);
      expect(find.text('Add'), findsNWidgets(2));
    });
  });

  group('2. User Interaction - Text Input', () {
    testWidgets('Can input week and title text', (tester) async {
      await pumpScreen(tester);

      final weekField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Ex. Week 1-1',
      );
      await tester.enterText(weekField, 'Week 1');
      expect(find.text('Week 1'), findsOneWidget);

      final titleField = find.byType(TextField).at(1);
      await tester.enterText(titleField, 'Test Lecture');
      expect(find.text('Test Lecture'), findsOneWidget);
    });

    testWidgets('Can input page range', (tester) async {
      await pumpScreen(tester);

      final startPageField = find.byType(TextField).at(2);
      await tester.enterText(startPageField, '1');
      expect(find.text('1'), findsOneWidget);

      final endPageField = find.byType(TextField).at(3);
      await tester.enterText(endPageField, '10');
      expect(find.text('10'), findsOneWidget);
    });
  });

  group('3. Validation', () {
    testWidgets('Shows error when week is empty', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter lecture week'), findsOneWidget);
    });

    testWidgets('Shows error when title is empty', (tester) async {
      await pumpScreen(tester);

      final weekField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Ex. Week 1-1',
      );
      await tester.enterText(weekField, 'Week 1');

      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter lecture title'), findsOneWidget);
    });

    testWidgets('Shows error when PDF is not uploaded', (tester) async {
      await pumpScreen(tester);

      final weekField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Ex. Week 1-1',
      );
      await tester.enterText(weekField, 'Week 1');

      final titleField = find.byType(TextField).at(1);
      await tester.enterText(titleField, 'Test Title');

      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      expect(find.text('Please upload slide PDF'), findsOneWidget);
    });

    testWidgets('Shows error when audio file is not uploaded', (tester) async {
      const pdfPath = '/fake/test.pdf';

      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.pdf', path: pdfPath, size: 100),
        ]),
      );

      mockFileReadingService.onReadAsBytes(pdfPath, Uint8List(0));

      await pumpScreen(tester);

      final weekField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Ex. Week 1-1',
      );
      await tester.enterText(weekField, 'Week 1');

      final titleField = find.byType(TextField).at(1);
      await tester.enterText(titleField, 'Test Title');

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add').first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Add').first);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please upload at least one audio file'),
        findsOneWidget,
      );
    });

    testWidgets('Shows error when page range is empty', (tester) async {
      const pdfPath = '/fake/test.pdf';
      const audioPath = '/fake/test.m4a';

      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.pdf', path: pdfPath, size: 100),
        ]),
      );

      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['m4a', 'm4b'],
          allowMultiple: false,
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.m4a', path: audioPath, size: 100),
        ]),
      );

      mockFileReadingService.onReadAsBytes(pdfPath, Uint8List(0));

      await pumpScreen(tester);

      final weekField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Ex. Week 1-1',
      );
      await tester.enterText(weekField, 'Week 1');

      final titleField = find.byType(TextField).at(1);
      await tester.enterText(titleField, 'Test Title');

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add').first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Add').first);
      await tester.pumpAndSettle();

      final addButtons = find.widgetWithText(OutlinedButton, 'Add');
      await tester.ensureVisible(addButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(2), '');
      await tester.enterText(find.byType(TextField).at(3), '');

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Please enter page range'), findsOneWidget);
    });
  });

  group('4. Dependency Injection', () {
    testWidgets('Uses injected FileReadingService', (tester) async {
      await pumpScreen(tester);
      expect(mockFileReadingService, isNotNull);
    });

    testWidgets('Uses injected HiveManager', (tester) async {
      await pumpScreen(tester);

      verify(mockHiveManager.getSubjects()).called(greaterThan(0));
    });

    testWidgets('Uses injected FilePicker', (tester) async {
      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        ),
      ).thenAnswer((_) async => null);

      await pumpScreen(tester);

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Add').first);
      await tester.pumpAndSettle();

      verify(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        ),
      ).called(1);
    });

    testWidgets('Uses injected Uuid', (tester) async {
      await pumpScreen(tester);
      expect(mockUuid, isNotNull);
    });

    testWidgets('Uses injected LectureLoadingService', (tester) async {
      await pumpScreen(tester);
      expect(mockLectureLoadingService, isNotNull);
    });

    testWidgets('Uses injected fetchLectureCallback', (tester) async {
      var called = false;
      Future<List<String>?> customFetch(
        String slidePath,
        AudioFileEntry audioFileEntry,
        String titleText,
        String lectureId,
        int part,
        int totalParts,
        String serverAddress,
        String port,
        String langCode, {
        http.Client? clientToClose,
      }) async {
        called = true;
        return mockFetchLecture(
          slidePath,
          audioFileEntry,
          titleText,
          lectureId,
          part,
          totalParts,
          serverAddress,
          port,
          langCode,
          clientToClose: clientToClose,
        );
      }

      await pumpScreen(tester, fetchLectureCallback: customFetch);
      expect(called, isFalse);
    });

    testWidgets('Uses injected concatenateAudioFilesCallback', (tester) async {
      var called = false;
      Future<String?> customConcat(
        List<String> audioPaths,
        String titleText,
        String lectureId, {
        Directory? dirOverride,
      }) async {
        called = true;
        return mockConcatenateAudioFiles(
          audioPaths,
          titleText,
          lectureId,
          dirOverride: dirOverride,
        );
      }

      await pumpScreen(tester, concatenateAudioFilesCallback: customConcat);
      expect(called, isFalse);
    });

    testWidgets('Uses injected httpClientFactory', (tester) async {
      var called = false;
      http.Client customFactory() {
        called = true;
        return http.Client();
      }

      await pumpScreen(tester, httpClientFactory: customFactory);
      expect(called, isFalse);
    });

    testWidgets('Uses injected flutterBackground', (tester) async {
      final customBg = _MockFlutterBackground();
      await pumpScreen(tester, flutterBackground: customBg);
      expect(customBg, isNotNull);
    });

    testWidgets('Uses injected pdfDocumentFactory', (tester) async {
      var called = false;
      PdfDocument customFactory(List<int> inputBytes) {
        called = true;
        return _MockPdfDocument();
      }

      await pumpScreen(tester, pdfDocumentFactory: customFactory);
      expect(called, isFalse);
    });
  });

  group('5. Subject Selection', () {
    testWidgets('Can select a subject from dropdown', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();

      expect(find.text('Test Subject').hitTestable(), findsOneWidget);

      await tester.tap(find.text('Test Subject').last);
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<String?>>(
        find.byType(DropdownButton<String?>),
      );
      expect(dropdown.value, equals('subj-1'));
    });

    testWidgets('Dropdown shows all subjects', (tester) async {
      final subjects = [
        HiveSubject(id: 's1', title: 'Math', lectureIds: []),
        HiveSubject(id: 's2', title: 'Physics', lectureIds: []),
        HiveSubject(id: 's3', title: 'Chemistry', lectureIds: []),
      ];
      when(mockHiveManager.getSubjects()).thenReturn(subjects);

      await pumpScreen(tester);

      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();

      expect(find.text('Math').hitTestable(), findsOneWidget);
      expect(find.text('Physics').hitTestable(), findsOneWidget);
      expect(find.text('Chemistry').hitTestable(), findsOneWidget);
    });
  });

  group('6. Audio Entry Management', () {
    const audioPath = '/fake/test.m4a';

    testWidgets('Auto-adds new field when file is uploaded to last field', (
      tester,
    ) async {
      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['m4a', 'm4b'],
          allowMultiple: false,
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.m4a', path: audioPath, size: 100),
        ]),
      );

      await pumpScreen(tester);

      expect(find.text('Page Range'), findsOneWidget);

      final addButtons = find.widgetWithText(OutlinedButton, 'Add');
      await tester.ensureVisible(addButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      expect(find.text('Change'), findsOneWidget);
      expect(find.text('Page Range'), findsNWidgets(2));
      expect(find.text('Add'), findsNWidgets(2));
    });

    testWidgets('Remove button not shown for single audio entry', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('Page Range'), findsOneWidget);

      expect(find.text('Remove'), findsNothing);
    });

    testWidgets(
      'Remove button shown only when file exists and multiple fields',
      (tester) async {
        when(
          mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['m4a', 'm4b'],
            allowMultiple: false,
          ),
        ).thenAnswer(
          (_) async => FilePickerResult([
            PlatformFile(name: 'test.m4a', path: audioPath, size: 100),
          ]),
        );

        await pumpScreen(tester);

        final addButtons = find.widgetWithText(OutlinedButton, 'Add');
        await tester.ensureVisible(addButtons.last);
        await tester.pumpAndSettle();
        await tester.tap(addButtons.last);
        await tester.pumpAndSettle();

        expect(find.text('Page Range'), findsNWidgets(2));
        expect(find.text('Remove'), findsOneWidget);
      },
    );

    testWidgets('Can remove audio entry immediately without confirmation', (
      tester,
    ) async {
      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['m4a', 'm4b'],
          allowMultiple: false,
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.m4a', path: audioPath, size: 100),
        ]),
      );

      await pumpScreen(tester);

      final addButtons = find.widgetWithText(OutlinedButton, 'Add');
      await tester.ensureVisible(addButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      expect(find.text('Page Range'), findsNWidgets(2));
      expect(find.text('test.m4a'), findsOneWidget);

      await tester.ensureVisible(find.text('Remove'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.text('test.m4a'), findsNothing);
      expect(find.text('Page Range'), findsOneWidget);
    });
  });

  group('7. File Picking - PDF', () {
    const pdfPath = '/fake/test.pdf';
    const invalidPdfPath = '/fake/invalid.pdf';

    testWidgets('Can pick PDF slide file successfully', (tester) async {
      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.pdf', path: pdfPath, size: 100),
        ]),
      );

      final fakePdfBytes = Uint8List.fromList(utf8.encode('fake pdf content'));
      mockFileReadingService.onReadAsBytes(pdfPath, fakePdfBytes);

      PdfDocument mockPdfFactory(List<int> bytes) {
        expect(bytes, equals(fakePdfBytes));
        return _MockPdfDocument();
      }

      await pumpScreen(tester, pdfDocumentFactory: mockPdfFactory);

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add').first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Add').first);
      await tester.pumpAndSettle();

      verify(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        ),
      ).called(1);

      expect(find.text('test.pdf'), findsOneWidget);

      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      final startPageField = textFields.elementAt(2);
      final endPageField = textFields.elementAt(3);
      expect(startPageField.controller?.text, '1');
      expect(endPageField.controller?.text, '10');
    });

    testWidgets('Handles PDF pick cancellation gracefully', (tester) async {
      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        ),
      ).thenAnswer((_) async => null);

      await pumpScreen(tester);

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add').first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Add').first);
      await tester.pumpAndSettle();

      expect(find.text('...'), findsAtLeastNWidgets(1));
    });

    testWidgets('Handles PDF processing error gracefully', (tester) async {
      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'invalid.pdf', path: invalidPdfPath, size: 100),
        ]),
      );

      mockFileReadingService.onReadAsBytes(
        invalidPdfPath,
        Uint8List.fromList(utf8.encode('invalid content')),
      );

      PdfDocument errorPdfFactory(List<int> inputBytes) {
        throw Exception('Invalid PDF');
      }

      await pumpScreen(tester, pdfDocumentFactory: errorPdfFactory);

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add').first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Add').first);
      await tester.pumpAndSettle();

      expect(find.text('Could not determine PDF page count'), findsOneWidget);
      expect(find.text('invalid.pdf'), findsOneWidget);
    });
  });

  group('8. File Picking - Audio', () {
    const audioPath = '/fake/test.m4a';
    const nonAudioPath = '/fake/test.mp3';

    testWidgets('Can pick m4a audio file successfully', (tester) async {
      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['m4a', 'm4b'],
          allowMultiple: false,
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.m4a', path: audioPath, size: 100),
        ]),
      );

      await pumpScreen(tester);

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add').first,
      );
      await tester.pumpAndSettle();
      final addButtons = find.widgetWithText(OutlinedButton, 'Add');

      await tester.ensureVisible(addButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      verify(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['m4a', 'm4b'],
          allowMultiple: false,
        ),
      ).called(1);

      expect(find.text('test.m4a'), findsOneWidget);
    });

    testWidgets('Rejects non-m4a files with error message', (tester) async {
      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['m4a', 'm4b'],
          allowMultiple: false,
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.mp3', path: nonAudioPath, size: 100),
        ]),
      );

      await pumpScreen(tester);

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add').first,
      );
      await tester.pumpAndSettle();
      final addButtons = find.widgetWithText(OutlinedButton, 'Add');
      await tester.ensureVisible(addButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      expect(find.text('Only m4a files are allowed'), findsOneWidget);
    });

    testWidgets('Handles audio pick cancellation gracefully', (tester) async {
      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['m4a', 'm4b'],
          allowMultiple: false,
        ),
      ).thenAnswer((_) async => null);

      await pumpScreen(tester);

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add').first,
      );
      await tester.pumpAndSettle();
      final addButtons = find.widgetWithText(OutlinedButton, 'Add');
      await tester.ensureVisible(addButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      expect(find.text('...'), findsAtLeastNWidgets(1));
    });
  });
  group('9. Create Lecture - Full Flow', () {
    const pdfPath = '/fake/slides.pdf';
    const audioPath = '/fake/audio.m4a';
    const audio1Path = '/fake/audio1.m4a';
    const audio2Path = '/fake/audio2.m4a';

    testWidgets('Successfully creates lecture with single audio file', (
      tester,
    ) async {
      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'slides.pdf', path: pdfPath, size: 100),
        ]),
      );

      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['m4a', 'm4b'],
          allowMultiple: false,
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'audio.m4a', path: audioPath, size: 100),
        ]),
      );

      mockFileReadingService.onReadAsBytes(pdfPath, Uint8List(0));
      final fakeJsonPath = '/fake/data_${fakeLectureId}_1.json';
      mockFileReadingService.onReadAsString(
        fakeJsonPath,
        '{"metadata": {"total_duration": 120, "total_sentences": 10}, "timestamps": []}',
      );

      await pumpScreen(tester);

      final weekField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Ex. Week 1-1',
      );
      await tester.enterText(weekField, 'Week 1');
      await tester.pumpAndSettle();

      final titleField = find.byType(TextField).at(1);
      await tester.enterText(titleField, 'Test Lecture');
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add').first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Add').first);
      await tester.pumpAndSettle();

      expect(find.text('slides.pdf'), findsOneWidget);

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add').first,
      );
      await tester.pumpAndSettle();
      final addButtons = find.widgetWithText(OutlinedButton, 'Add');

      await tester.ensureVisible(addButtons.last);
      await tester.pumpAndSettle();

      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      expect(find.text('audio.m4a'), findsOneWidget);

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Create'));

      await tester.pump();

      verify(
        mockLectureLoadingService.startLoading('Test-Lecture', 1),
      ).called(1);
      verify(mockLectureLoadingService.setOnCancel(any)).called(1);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('Successfully creates lecture with multiple audio files', (
      tester,
    ) async {
      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'slides.pdf', path: pdfPath, size: 100),
        ]),
      );

      var audioCallCount = 0;
      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['m4a', 'm4b'],
          allowMultiple: false,
        ),
      ).thenAnswer((_) async {
        audioCallCount++;
        return FilePickerResult([
          PlatformFile(
            name: 'audio$audioCallCount.m4a',
            path: audioCallCount == 1 ? audio1Path : audio2Path,
            size: 100,
          ),
        ]);
      });

      mockFileReadingService.onReadAsBytes(pdfPath, Uint8List(0));
      mockFileReadingService.onReadAsString(
        '/fake/data_${fakeLectureId}_1.json',
        '{"metadata": {"total_duration": 120, "total_sentences": 10}, "timestamps": []}',
      );
      mockFileReadingService.onReadAsString(
        '/fake/data_${fakeLectureId}_2.json',
        '{"metadata": {"total_duration": 120, "total_sentences": 10}, "timestamps": []}',
      );
      mockFileReadingService.onReadAsString(
        '/fake/${fakeLectureId}_concat.json',
        '{"metadata": {"total_duration": 240, "total_sentences": 20}, "timestamps": []}',
      );

      await pumpScreen(tester);

      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Ex. Week 1-1',
        ),
        'Week 1',
      );
      await tester.enterText(find.byType(TextField).at(1), 'Multi Audio Test');

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add').first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Add').first);
      await tester.pumpAndSettle();

      var addButtons = find.widgetWithText(OutlinedButton, 'Add');

      await tester.ensureVisible(addButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(2), '1');
      await tester.enterText(find.byType(TextField).at(3), '5');

      addButtons = find.widgetWithText(OutlinedButton, 'Add');
      await tester.ensureVisible(addButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(4), '6');
      await tester.enterText(find.byType(TextField).at(5), '10');

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));

      await tester.pump();
      verify(
        mockLectureLoadingService.startLoading('Multi-Audio-Test', 2),
      ).called(1);

      await tester.pump();
      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('Shows validation error for invalid page range', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Ex. Week 1-1',
        ),
        'Week 1',
      );
      await tester.enterText(find.byType(TextField).at(1), 'Test');

      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.pdf', path: pdfPath, size: 1),
        ]),
      );
      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['m4a', 'm4b'],
          allowMultiple: false,
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.m4a', path: audioPath, size: 1),
        ]),
      );
      mockFileReadingService.onReadAsBytes(pdfPath, Uint8List(0));

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add').first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Add').first);
      await tester.pumpAndSettle();

      final addButtons = find.widgetWithText(OutlinedButton, 'Add');

      await tester.ensureVisible(addButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(2), '10');
      await tester.enterText(find.byType(TextField).at(3), '5');

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      expect(
        find.text('Start page cannot be greater than end page for audio 1'),
        findsOneWidget,
      );
    });

    testWidgets('Shows error when page range exceeds PDF pages', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Ex. Week 1-1',
        ),
        'Week 1',
      );
      await tester.enterText(find.byType(TextField).at(1), 'Test');

      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.pdf', path: pdfPath, size: 1),
        ]),
      );
      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['m4a', 'm4b'],
          allowMultiple: false,
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.m4a', path: audioPath, size: 1),
        ]),
      );
      mockFileReadingService.onReadAsBytes(pdfPath, Uint8List(0));

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add').first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Add').first);
      await tester.pumpAndSettle();

      final addButtons = find.widgetWithText(OutlinedButton, 'Add');

      await tester.ensureVisible(addButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(2), '1');
      await tester.enterText(find.byType(TextField).at(3), '20');

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      expect(find.textContaining('exceeds total PDF pages'), findsOneWidget);
    });

    testWidgets('Handles lecture creation error gracefully', (tester) async {
      Future<List<String>?> failingFetch(
        String slidePath,
        AudioFileEntry audioFileEntry,
        String titleText,
        String lectureId,
        int part,
        int totalParts,
        String serverAddress,
        String port,
        String langCode, {
        http.Client? clientToClose,
      }) async {
        return null;
      }

      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.pdf', path: pdfPath, size: 1),
        ]),
      );
      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['m4a', 'm4b'],
          allowMultiple: false,
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.m4a', path: audioPath, size: 1),
        ]),
      );
      mockFileReadingService.onReadAsBytes(pdfPath, Uint8List(0));

      await pumpScreen(tester, fetchLectureCallback: failingFetch);

      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Ex. Week 1-1',
        ),
        'Week 1',
      );
      await tester.enterText(find.byType(TextField).at(1), 'Test');

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add').first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Add').first);
      await tester.pumpAndSettle();

      final addButtons = find.widgetWithText(OutlinedButton, 'Add');

      await tester.ensureVisible(addButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);

      verifyNever(mockHiveManager.addLecture(any));
    });
  });

  group('10. Additional Validation Tests', () {
    testWidgets('Shows error for non-numeric page numbers', (tester) async {
      const pdfPath = '/fake/test.pdf';
      const audioPath = '/fake/test.m4a';

      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.pdf', path: pdfPath, size: 1),
        ]),
      );
      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['m4a', 'm4b'],
          allowMultiple: false,
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.m4a', path: audioPath, size: 1),
        ]),
      );
      mockFileReadingService.onReadAsBytes(pdfPath, Uint8List(0));

      await pumpScreen(tester);

      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Ex. Week 1-1',
        ),
        'Week 1',
      );
      await tester.enterText(find.byType(TextField).at(1), 'Test');

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add').first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Add').first);
      await tester.pumpAndSettle();

      final addButtons = find.widgetWithText(OutlinedButton, 'Add');
      await tester.ensureVisible(addButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(2), 'abc');
      await tester.enterText(find.byType(TextField).at(3), '10');

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      expect(
        find.text('Page numbers for audio 1 must be numbers'),
        findsOneWidget,
      );
    });

    testWidgets('Shows error for page numbers less than 1', (tester) async {
      const pdfPath = '/fake/test.pdf';
      const audioPath = '/fake/test.m4a';

      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.pdf', path: pdfPath, size: 1),
        ]),
      );
      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['m4a', 'm4b'],
          allowMultiple: false,
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.m4a', path: audioPath, size: 1),
        ]),
      );
      mockFileReadingService.onReadAsBytes(pdfPath, Uint8List(0));

      await pumpScreen(tester);

      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Ex. Week 1-1',
        ),
        'Week 1',
      );
      await tester.enterText(find.byType(TextField).at(1), 'Test');

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add').first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Add').first);
      await tester.pumpAndSettle();

      final addButtons = find.widgetWithText(OutlinedButton, 'Add');
      await tester.ensureVisible(addButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(2), '0');
      await tester.enterText(find.byType(TextField).at(3), '10');

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      expect(
        find.text('Page numbers for audio 1 must be at least 1'),
        findsOneWidget,
      );
    });

    testWidgets('Shows error when start page exceeds PDF pages', (
      tester,
    ) async {
      const pdfPath = '/fake/test.pdf';
      const audioPath = '/fake/test.m4a';

      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.pdf', path: pdfPath, size: 1),
        ]),
      );
      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['m4a', 'm4b'],
          allowMultiple: false,
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'test.m4a', path: audioPath, size: 1),
        ]),
      );
      mockFileReadingService.onReadAsBytes(pdfPath, Uint8List(0));

      await pumpScreen(tester);

      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Ex. Week 1-1',
        ),
        'Week 1',
      );
      await tester.enterText(find.byType(TextField).at(1), 'Test');

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add').first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Add').first);
      await tester.pumpAndSettle();

      final addButtons = find.widgetWithText(OutlinedButton, 'Add');
      await tester.ensureVisible(addButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(2), '11');
      await tester.enterText(find.byType(TextField).at(3), '15');

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      expect(find.textContaining('exceeds total PDF pages'), findsOneWidget);
    });

    testWidgets(
      'Shows error when end page exceeds PDF pages with pdfTotalPages',
      (tester) async {
        const pdfPath = '/fake/test.pdf';
        const audioPath = '/fake/test.m4a';

        when(
          mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          ),
        ).thenAnswer(
          (_) async => FilePickerResult([
            PlatformFile(name: 'test.pdf', path: pdfPath, size: 1),
          ]),
        );
        when(
          mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['m4a', 'm4b'],
            allowMultiple: false,
          ),
        ).thenAnswer(
          (_) async => FilePickerResult([
            PlatformFile(name: 'test.m4a', path: audioPath, size: 1),
          ]),
        );
        mockFileReadingService.onReadAsBytes(pdfPath, Uint8List(0));

        await pumpScreen(tester);

        await tester.enterText(
          find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.hintText == 'Ex. Week 1-1',
          ),
          'Week 1',
        );
        await tester.enterText(find.byType(TextField).at(1), 'Test');

        await tester.ensureVisible(
          find.widgetWithText(OutlinedButton, 'Add').first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(OutlinedButton, 'Add').first);
        await tester.pumpAndSettle();

        final addButtons = find.widgetWithText(OutlinedButton, 'Add');
        await tester.ensureVisible(addButtons.last);
        await tester.pumpAndSettle();
        await tester.tap(addButtons.last);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(2), '5');
        await tester.enterText(find.byType(TextField).at(3), '15');

        await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Create'));
        await tester.pumpAndSettle();

        expect(
          find.text('End page (15) for audio 1 exceeds total PDF pages (10)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Shows error when end page exceeds fallback total pages (multi-audio without PDF page count)',
      (tester) async {
        const pdfPath = '/fake/test.pdf';
        const audio1Path = '/fake/audio1.m4a';
        const audio2Path = '/fake/audio2.m4a';

        when(
          mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          ),
        ).thenAnswer(
          (_) async => FilePickerResult([
            PlatformFile(name: 'test.pdf', path: pdfPath, size: 1),
          ]),
        );

        var audioCallCount = 0;
        when(
          mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['m4a', 'm4b'],
            allowMultiple: false,
          ),
        ).thenAnswer((_) async {
          audioCallCount++;
          return FilePickerResult([
            PlatformFile(
              name: 'audio$audioCallCount.m4a',
              path: audioCallCount == 1 ? audio1Path : audio2Path,
              size: 100,
            ),
          ]);
        });

        mockFileReadingService.onReadAsBytes(pdfPath, Uint8List(0));

        PdfDocument errorPdfFactory(List<int> inputBytes) {
          throw Exception('Invalid PDF');
        }

        await pumpScreen(tester, pdfDocumentFactory: errorPdfFactory);

        await tester.enterText(
          find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.hintText == 'Ex. Week 1-1',
          ),
          'Week 1',
        );
        await tester.enterText(find.byType(TextField).at(1), 'Test');

        await tester.ensureVisible(
          find.widgetWithText(OutlinedButton, 'Add').first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(OutlinedButton, 'Add').first);
        await tester.pumpAndSettle();

        var addButtons = find.widgetWithText(OutlinedButton, 'Add');
        await tester.ensureVisible(addButtons.last);
        await tester.pumpAndSettle();
        await tester.tap(addButtons.last);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(2), '1');
        await tester.enterText(find.byType(TextField).at(3), '5');

        addButtons = find.widgetWithText(OutlinedButton, 'Add');
        await tester.ensureVisible(addButtons.last);
        await tester.pumpAndSettle();
        await tester.tap(addButtons.last);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(4), '6');
        await tester.enterText(find.byType(TextField).at(5), '10');

        await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Create'));
        await tester.pumpAndSettle();

        expect(
          find.text('End page (10) for audio 2 exceeds total PDF pages (5)'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Tests FlutterBackground wrapper methods', (tester) async {
      final wrapper = DefaultFlutterBackgroundWrapper();

      expect(wrapper, isNotNull);
      expect(wrapper.initialize, isNotNull);
      expect(wrapper.enableBackgroundExecution, isNotNull);
      expect(wrapper.disableBackgroundExecution, isNotNull);
    });

    testWidgets('Tests cancel callback is set correctly', (tester) async {
      const pdfPath = '/fake/slides.pdf';
      const audioPath = '/fake/audio.m4a';

      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'slides.pdf', path: pdfPath, size: 100),
        ]),
      );

      when(
        mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['m4a', 'm4b'],
          allowMultiple: false,
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(name: 'audio.m4a', path: audioPath, size: 100),
        ]),
      );

      mockFileReadingService.onReadAsBytes(pdfPath, Uint8List(0));
      final fakeJsonPath = '/fake/data_${fakeLectureId}_1.json';
      mockFileReadingService.onReadAsString(
        fakeJsonPath,
        '{"metadata": {"total_duration": 120, "total_sentences": 10}, "timestamps": []}',
      );

      await pumpScreen(tester);

      final weekField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Ex. Week 1-1',
      );
      await tester.enterText(weekField, 'Week 1');

      final titleField = find.byType(TextField).at(1);
      await tester.enterText(titleField, 'Test Lecture');

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Add').first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Add').first);
      await tester.pumpAndSettle();

      final addButtons = find.widgetWithText(OutlinedButton, 'Add');
      await tester.ensureVisible(addButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));

      await tester.pump();

      verify(mockLectureLoadingService.setOnCancel(any)).called(1);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
    });
  });
}

// Mock FlutterBackgroundInterface
class _MockFlutterBackground implements FlutterBackgroundInterface {
  @override
  Future<bool> initialize({
    required FlutterBackgroundAndroidConfig androidConfig,
  }) async => true;

  @override
  Future<bool> enableBackgroundExecution() async => true;

  @override
  Future<bool> disableBackgroundExecution() async => true;
}

// Mock PdfDocument
class _MockPdfDocument extends PdfDocument {
  _MockPdfDocument() : super();

  @override
  PdfPageCollection get pages => _MockPdfPageCollection();

  @override
  void dispose() {}
}

class _MockPdfPageCollection implements PdfPageCollection {
  @override
  int get count => 10;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}
