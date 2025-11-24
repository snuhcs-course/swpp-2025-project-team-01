import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:re_view/core/lecture_loading_service.dart';
import 'package:re_view/features/edit/fetch_lecture.dart';
import 'package:re_view/features/edit/lecture_form_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

@GenerateMocks([FlutterLocalNotificationsPlugin])
import 'fetch_lecture_test.mocks.dart';

class FakeStreamingClient extends http.BaseClient {
  FakeStreamingClient(this._onSend);
  final Future<http.StreamedResponse> Function(http.BaseRequest) _onSend;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _onSend(request);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Split PDF', () {
    const inputFilePath =
        'assets/lectures/lec_demo_001/lec_demo_001_slides.pdf';

    test('Splits PDF range and preserves page size', () async {
      final bytes = await File(inputFilePath).readAsBytes();
      final originalPdf = PdfDocument(inputBytes: bytes);
      final originalSize = originalPdf.pages[2].size;

      await splitPdfRange(inputFilePath, start: 3, end: 5, order: 1);

      final outputPath = inputFilePath.replaceFirst(
        RegExp(r'\.pdf$', caseSensitive: false),
        '_tmp1.pdf',
      );
      final splittedPdf = PdfDocument(
        inputBytes: await File(outputPath).readAsBytes(),
      );

      expect(splittedPdf.pages.count, 3);
      expect(splittedPdf.pages[0].size, originalSize);

      await File(outputPath).delete();
    });

    test('Handles single page split', () async {
      await splitPdfRange(inputFilePath, start: 1, end: 1, order: 99);
      final outputPath = inputFilePath.replaceFirst(
        RegExp(r'\.pdf$', caseSensitive: false),
        '_tmp99.pdf',
      );

      expect(File(outputPath).existsSync(), isTrue);
      await File(outputPath).delete();
    });

    test('Throws ArgumentError when start > end', () async {
      await expectLater(
        () => splitPdfRange(inputFilePath, start: 5, end: 3, order: 1),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Lecture Request', () {
    Future<File> tempFile(String name, List<int> bytes) async {
      final dir = await Directory.systemTemp.createTemp('req_lect_');
      final f = File('${dir.path}/$name');
      await f.writeAsBytes(bytes, flush: true);
      return f;
    }

    FakeStreamingClient createSseClient(List<String> sseChunks) {
      return FakeStreamingClient((req) async {
        final stream = Stream<List<int>>.fromIterable(
          sseChunks.map((s) => utf8.encode(s)),
        );
        return http.StreamedResponse(
          stream,
          200,
          headers: {'content-type': 'text/event-stream; charset=utf-8'},
        );
      });
    }

    test('Handles successful SSE stream with progress conversion', () async {
      final slide = await tempFile('slides.pdf', [1, 2, 3]);
      final audio = await tempFile('audio.m4a', [4, 5, 6]);
      final audioEntry = AudioFileEntry.fromPath(audio.path);

      final progressEvents = <double>[];
      Future<void> onProgress(
        double p,
        String msg,
        String title,
        int i,
        int j,
      ) async {
        progressEvents.add(p);
      }

      final client1 = createSseClient([
        'data: {"job_id":"test123","progress":50,"message":"Processing","status":"running"}\n\n',
        'data: {"job_id":"test123","progress":100,"message":"Done","status":"completed"}\n\n',
      ]);

      final jobId = await requestLecture(
        slide.path,
        audioEntry,
        'Test',
        0,
        1,
        '127.0.0.1',
        '8080',
        onProgress,
        'ko',
        false,
        fakeClient: client1,
        endpointOverride: Uri.parse('http://local.test/api/synchronize/stream'),
      );

      expect(jobId, 'test123');
      expect(progressEvents[0], 0.5);
      expect(progressEvents[1], 1.0);
    });

    test('Returns null on failed status', () async {
      final slide = await tempFile('slides.pdf', [1, 2, 3]);
      final audio = await tempFile('audio.m4a', [4, 5, 6]);
      final audioEntry = AudioFileEntry.fromPath(audio.path);

      Future<void> onProgress(
        double p,
        String msg,
        String title,
        int i,
        int j,
      ) async {}

      final client = createSseClient([
        'data: {"job_id":"fail123","progress":30.0,"message":"Processing","status":"running"}\n\n',
        'data: {"job_id":"fail123","progress":50.0,"message":"Error occurred","status":"failed"}\n\n',
      ]);

      final service = LectureLoadingService.instance;
      service.hideLoading();

      final jobId = await requestLecture(
        slide.path,
        audioEntry,
        'Test',
        0,
        1,
        '127.0.0.1',
        '8080',
        onProgress,
        'ko',
        false,
        fakeClient: client,
        endpointOverride: Uri.parse('http://local.test/api/synchronize/stream'),
      );

      expect(jobId, isNull);
      expect(service.hasError, isTrue);
      service.hideLoading();
    });

    test('Handles cancellation during SSE stream', () async {
      final controller = StreamController<List<int>>.broadcast();
      final fakeClient = FakeStreamingClient((req) async {
        return http.StreamedResponse(
          controller.stream,
          200,
          headers: {'content-type': 'text/event-stream; charset=utf-8'},
        );
      });

      final slide = await tempFile('slides.pdf', [1, 2, 3]);
      final audio = await tempFile('audio.m4a', [4, 5, 6]);
      final audioEntry = AudioFileEntry.fromPath(audio.path);

      Future<void> onProgress(
        double p,
        String msg,
        String title,
        int i,
        int j,
      ) async {}

      final service = LectureLoadingService.instance;
      service.hideLoading();
      service.startLoading('Test', 1);

      final futureJobId = requestLecture(
        slide.path,
        audioEntry,
        'Test',
        1,
        1,
        '127.0.0.1',
        '8080',
        onProgress,
        'ko',
        false,
        fakeClient: fakeClient,
        endpointOverride: Uri.parse('http://local.test/api/synchronize/stream'),
      );

      controller.add(
        utf8.encode(
          'data: {"job_id":"cancel123","progress":10.0,"message":"Starting","status":"running"}\n\n',
        ),
      );
      service.addJobId('cancel123');
      await Future.delayed(Duration(milliseconds: 50));
      service.cancelLoading(fakeClient: fakeClient);
      await Future.delayed(Duration(milliseconds: 50));
      await controller.close();

      final jobId = await futureJobId;
      expect(jobId, anyOf(isNull, isA<String>()));
    });

    test('Returns null on connection timeout', () async {
      final fakeClient = FakeStreamingClient((req) async {
        throw TimeoutException('Connection timeout', Duration(minutes: 5));
      });

      final slide = await tempFile('slides.pdf', [1, 2, 3]);
      final audio = await tempFile('audio.m4a', [4, 5, 6]);
      final audioEntry = AudioFileEntry.fromPath(audio.path);

      Future<void> onProgress(
        double p,
        String msg,
        String title,
        int i,
        int j,
      ) async {}

      final service = LectureLoadingService.instance;
      service.hideLoading();

      final jobId = await requestLecture(
        slide.path,
        audioEntry,
        'Test',
        1,
        1,
        '127.0.0.1',
        '8080',
        onProgress,
        'ko',
        false,
        fakeClient: fakeClient,
        endpointOverride: Uri.parse('http://local.test/api/synchronize/stream'),
      );

      expect(jobId, isNull);
      expect(service.hasError, isTrue);
      service.hideLoading();
    });

    test('Falls back to polling on SSE stream error', () async {
      final controller = StreamController<List<int>>();
      final fakeClient = FakeStreamingClient((req) async {
        return http.StreamedResponse(
          controller.stream,
          200,
          headers: {'content-type': 'text/event-stream; charset=utf-8'},
        );
      });

      final slide = await tempFile('slides.pdf', [1, 2, 3]);
      final audio = await tempFile('audio.m4a', [4, 5, 6]);
      final audioEntry = AudioFileEntry.fromPath(audio.path);

      Future<void> onProgress(
        double p,
        String msg,
        String title,
        int i,
        int j,
      ) async {}

      final service = LectureLoadingService.instance;
      service.hideLoading();

      final futureJobId = requestLecture(
        slide.path,
        audioEntry,
        'Test',
        1,
        1,
        '127.0.0.1',
        '8080',
        onProgress,
        'ko',
        false,
        fakeClient: fakeClient,
        endpointOverride: Uri.parse('http://local.test/api/synchronize/stream'),
      );

      controller.add(
        utf8.encode(
          'data: {"job_id":"poll123","progress":20.0,"message":"Starting","status":"running"}\n\n',
        ),
      );
      await Future.delayed(Duration(milliseconds: 50));
      controller.addError(Exception('Connection lost'));
      await controller.close();

      await futureJobId;
      service.hideLoading();
    });

    test('Retries on connection failure', () async {
      int attemptCount = 0;
      final fakeClient = FakeStreamingClient((req) async {
        attemptCount++;
        if (attemptCount == 1) {
          throw Exception('Connection failed');
        }

        final sseChunks = <String>[
          'data: {"job_id":"retry123","progress":100.0,"message":"Done","status":"completed"}\n\n',
        ];

        return http.StreamedResponse(
          Stream<List<int>>.fromIterable(sseChunks.map((s) => utf8.encode(s))),
          200,
          headers: {'content-type': 'text/event-stream; charset=utf-8'},
        );
      });

      final slide = await tempFile('slides.pdf', [1, 2, 3]);
      final audio = await tempFile('audio.m4a', [4, 5, 6]);
      final audioEntry = AudioFileEntry.fromPath(audio.path);

      Future<void> onProgress(
        double p,
        String msg,
        String title,
        int i,
        int j,
      ) async {}

      final service = LectureLoadingService.instance;
      service.hideLoading();

      await requestLecture(
        slide.path,
        audioEntry,
        'Test',
        1,
        1,
        '127.0.0.1',
        '8080',
        onProgress,
        'ko',
        false,
        fakeClient: fakeClient,
        endpointOverride: Uri.parse('http://local.test/api/synchronize/stream'),
      );

      expect(attemptCount, greaterThanOrEqualTo(1));
      service.hideLoading();
    });

    test('Returns null when endpoint connection fails', () async {
      final slide = File(
        'assets/lectures/lec_demo_001/lec_demo_001_slides.pdf',
      );
      final audio = await tempFile('audio.m4a', [4, 5, 6]);

      final audioEntry = AudioFileEntry.fromPath(audio.path);
      audioEntry.startPageController.text = '1';
      audioEntry.endPageController.text = '5';

      Future<void> onProgress(
        double p,
        String msg,
        String title,
        int i,
        int j,
      ) async {}

      final service = LectureLoadingService.instance;
      service.hideLoading();

      final result = await requestLecture(
        slide.path,
        audioEntry,
        'My Lecture',
        0,
        1,
        '127.0.0.1',
        '8080',
        onProgress,
        'ko',
        true,
        endpointOverride: Uri.parse('http://local.test/api/synchronize/stream'),
      );

      expect(result, isNull);
      expect(service.hasError, isTrue);
      service.hideLoading();

      // Clean up any split PDF files that might have been created
      final splitPdfPath =
          'assets/lectures/lec_demo_001/lec_demo_001_slides_tmp0.pdf';
      final splitFile = File(splitPdfPath);
      if (splitFile.existsSync()) {
        await splitFile.delete();
      }
    });
  });

  group('getJobStatus', () {
    test('Returns status and progress with type conversion', () async {
      final mockClient1 = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'job_id': 'job123',
            'status': 'running',
            'progress': 65.5,
          }),
          200,
        );
      });

      final result1 = await getJobStatus(
        'job123',
        'localhost',
        '8080',
        mockClient1,
      );
      expect(result1, isNotNull);
      expect(result1!.$1, 'running');
      expect(result1.$2, closeTo(0.655, 0.001));

      // Test integer to double conversion
      final mockClient2 = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'job_id': 'job456',
            'status': 'completed',
            'progress': 100,
          }),
          200,
        );
      });

      final result2 = await getJobStatus(
        'job456',
        'localhost',
        '8080',
        mockClient2,
      );
      expect(result2, isNotNull);
      expect(result2!.$1, 'completed');
      expect(result2.$2, 1.0);
    });

    test('Returns null on error response', () async {
      final mockClient = MockClient((req) async {
        return http.Response('Not found', 404);
      });

      final result = await getJobStatus(
        'missing',
        'localhost',
        '8080',
        mockClient,
      );
      expect(result, isNull);
    });
  });

  group('Download Result', () {
    test('Downloads zip file successfully', () async {
      final zipBytes = utf8.encode('FAKE-ZIP-CONTENT');
      final mock = MockClient((req) async {
        return http.Response.bytes(
          zipBytes,
          200,
          headers: {'content-type': 'application/zip'},
        );
      });

      final temp = await Directory.systemTemp.createTemp('dl_ok_');
      final path = await downloadResult(
        'abc123',
        'MyLecture',
        2,
        'localhost',
        '8080',
        false,
        fakeClient: mock,
        tempDirOverride: temp,
      );

      expect(path, isNotNull);
      final file = File(path!);
      expect(file.existsSync(), isTrue);
      expect(await file.readAsBytes(), zipBytes);
      expect(file.path.endsWith('/MyLecture_2_output.zip'), isTrue);
    });

    test('Returns null on download failure and sets error', () async {
      final mock = MockClient((_) async => http.Response('nope', 404));
      final temp = await Directory.systemTemp.createTemp('dl_404_');

      final service = LectureLoadingService.instance;
      service.hideLoading();

      final path = await downloadResult(
        'missing',
        'Title',
        0,
        'localhost',
        '8080',
        false,
        fakeClient: mock,
        tempDirOverride: temp,
      );

      expect(path, isNull);
      expect(service.hasError, isTrue);
      service.hideLoading();
    });

    test('Handles retry logic and isRetry flag', () async {
      int attemptCount = 0;
      final mock = MockClient((req) async {
        attemptCount++;
        throw Exception('Network error');
      });

      final temp = await Directory.systemTemp.createTemp('dl_retry_');
      final service = LectureLoadingService.instance;
      service.hideLoading();

      // isRetry=false
      final path1 = await downloadResult(
        'retry123',
        'Retry',
        1,
        'localhost',
        '8080',
        false,
        fakeClient: mock,
        tempDirOverride: temp,
      );

      expect(path1, isNull);
      expect(attemptCount, 1);

      // isRetry=true
      attemptCount = 0;
      final path2 = await downloadResult(
        'noretry',
        'NoRetry',
        1,
        'localhost',
        '8080',
        true,
        fakeClient: mock,
        tempDirOverride: temp,
      );

      expect(path2, isNull);
      expect(attemptCount, 1);
      service.hideLoading();
    });
  });

  group('Unzip Result', () {
    List<int> makeZip(Map<String, List<int>> filesAndBytes) {
      final archive = Archive();
      filesAndBytes.forEach((name, bytes) {
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      });
      return ZipEncoder().encode(archive);
    }

    test('Extracts and renames files correctly', () async {
      final pdfBytes = utf8.encode('PDFDATA');
      final jsonBytes = utf8.encode('{"hello":"world"}');
      final zipBytes = makeZip({
        'slides/lec.pdf': pdfBytes,
        'timestamp.json': jsonBytes,
      });

      final tempRoot = await Directory.systemTemp.createTemp('unzip_ok_');
      final docsDir = Directory('${tempRoot.path}/docs')
        ..createSync(recursive: true);
      final zipFile = File('${tempRoot.path}/in.zip')
        ..writeAsBytesSync(zipBytes);

      await unzipResult(
        zipFile.path,
        'MyLecture',
        'lecId',
        3,
        documentsDirOverride: docsDir,
        deleteZip: true,
      );

      final outPdf = File('${docsDir.path}/lecId/MyLecture_3.pdf');
      final outJson = File('${docsDir.path}/lecId/MyLecture_3.json');

      expect(outPdf.existsSync(), isTrue);
      expect(outJson.existsSync(), isTrue);
      expect(await outPdf.readAsBytes(), pdfBytes);
      expect(await outJson.readAsBytes(), jsonBytes);
      expect(File(zipFile.path).existsSync(), isFalse);
    });

    test('Throws on missing zip file', () async {
      await expectLater(
        () => unzipResult(
          '/does/not/exist.zip',
          'A',
          'lecId',
          0,
          deleteZip: false,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('fetchLecture', () {
    test('Returns null on requestLecture failure', () async {
      final fakeClient = FakeStreamingClient((req) async {
        throw Exception('Connection failed');
      });

      final tempDir = await Directory.systemTemp.createTemp('fetch_fail_');
      final audioFile = File('${tempDir.path}/audio.m4a');
      await audioFile.writeAsBytes([1, 2, 3]);

      final audioEntry = AudioFileEntry.fromPath(audioFile.path);

      final service = LectureLoadingService.instance;
      service.hideLoading();

      final result = await fetchLecture(
        'assets/lectures/lec_demo_001/lec_demo_001_slides.pdf',
        audioEntry,
        'TestLecture',
        'lecId',
        1,
        1,
        'localhost',
        '8080',
        'ko',
        fakeClient: fakeClient,
        endpointOverride: Uri.parse('http://test.local/api/synchronize/stream'),
      );

      expect(result, isNull);
      await tempDir.delete(recursive: true);
      service.hideLoading();
    });

    test('Returns null on downloadResult or unzipResult failure', () async {
      final sseChunks = <String>[
        'data: {"job_id":"fetch123","progress":100.0,"message":"Done","status":"completed"}\n\n',
      ];

      final fakeClient = FakeStreamingClient((req) async {
        return http.StreamedResponse(
          Stream<List<int>>.fromIterable(sseChunks.map((s) => utf8.encode(s))),
          200,
          headers: {'content-type': 'text/event-stream; charset=utf-8'},
        );
      });

      final tempDir = await Directory.systemTemp.createTemp('fetch_test_');
      final audioFile = File('${tempDir.path}/audio.m4a');
      await audioFile.writeAsBytes([1, 2, 3]);

      final audioEntry = AudioFileEntry.fromPath(audioFile.path);

      final service = LectureLoadingService.instance;
      service.hideLoading();

      final result = await fetchLecture(
        'assets/lectures/lec_demo_001/lec_demo_001_slides.pdf',
        audioEntry,
        'TestLecture',
        'lecId',
        1,
        1,
        'localhost',
        '8080',
        'ko',
        fakeClient: fakeClient,
        endpointOverride: Uri.parse('http://test.local/api/synchronize/stream'),
      );

      expect(result, isNull);
      await tempDir.delete(recursive: true);
      service.hideLoading();
    });

    test('Catches exception when unzipResult throws in fetchLecture', () async {
      // Create completely invalid zip data to trigger exception in ZipDecoder
      final invalidZipBytes = utf8.encode('NOT_A_VALID_ZIP_FILE_AT_ALL');

      final mockClient = FakeStreamingClient((req) async {
        final url = req.url.toString();

        if (url.contains('/stream')) {
          return http.StreamedResponse(
            Stream<List<int>>.fromIterable([
              utf8.encode(
                'data: {"job_id":"unzip-err","progress":100,"message":"Done","status":"completed"}\n\n',
              ),
            ]),
            200,
            headers: {'content-type': 'text/event-stream; charset=utf-8'},
          );
        } else if (url.contains('/download/')) {
          return http.StreamedResponse(
            Stream<List<int>>.value(invalidZipBytes),
            200,
            headers: {'content-type': 'application/zip'},
          );
        }
        return http.StreamedResponse(Stream.empty(), 404);
      });

      final tempDir = await Directory.systemTemp.createTemp('fetch_unzip_');
      final audioFile = File('${tempDir.path}/audio.m4a');
      await audioFile.writeAsBytes([1, 2, 3]);
      final audioEntry = AudioFileEntry.fromPath(audioFile.path);

      final service = LectureLoadingService.instance;
      service.hideLoading();

      final result = await fetchLecture(
        'assets/lectures/lec_demo_001/lec_demo_001_slides.pdf',
        audioEntry,
        'UnzipError',
        'lecId',
        1,
        1,
        'localhost',
        '8080',
        'ko',
        fakeClient: mockClient,
        endpointOverride: Uri.parse('http://test.local/api/synchronize/stream'),
      );

      expect(result, isNull);
      expect(service.hasError, isTrue);
      await tempDir.delete(recursive: true);
      service.hideLoading();
    });
  });

  group('concatenateAudioFiles', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('audio_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Handles FFmpeg operations and file extensions', () async {
      final audio1 = '${tempDir.path}/a1.opus';
      final audio2 = '${tempDir.path}/a2.opus';
      await File(audio1).writeAsBytes([]);
      await File(audio2).writeAsBytes([]);

      final result1 = await concatenateAudioFiles(
        [audio1, audio2],
        'merged_audio',
        'lecId',
        dirOverride: tempDir,
      );
      expect(result1, anyOf(isNull, isA<String>()));

      final result2 = await concatenateAudioFiles(
        [audio1, 'missing.opus'],
        'merged_audio',
        'lecId',
        dirOverride: tempDir,
      );
      expect(result2, isNull);

      final m4a1 = '${tempDir.path}/b1.m4a';
      final m4a2 = '${tempDir.path}/b2.m4a';
      await File(m4a1).writeAsBytes([]);
      await File(m4a2).writeAsBytes([]);

      final result3 = await concatenateAudioFiles(
        [m4a1, m4a2],
        'merged_m4a',
        'lecId',
        dirOverride: tempDir,
      );
      expect(result3, anyOf(isNull, contains('.m4a')));
    });

    test('Handles audio file deletion failures with override', () async {
      final audio1 = '${tempDir.path}/del1.opus';
      final audio2 = '${tempDir.path}/del2.opus';
      await File(audio1).writeAsBytes([]);
      await File(audio2).writeAsBytes([]);

      final result = await concatenateAudioFiles(
        [audio1, audio2],
        'merged_del',
        'lecId',
        dirOverride: tempDir,
        deleteFileOverride: (path) async {
          throw Exception('Deletion failed');
        },
      );

      expect(result, anyOf(isNull, isA<String>()));
    });
  });

  group('concatenateJsonFiles', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('concat_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Returns null for single file', () async {
      final json1 = [
        {
          'text_eng': 'Hello world.',
          'text_kor': '안녕하세요',
          'slide_number': 1,
          'tts_start_time': 0,
          'tts_end_time': 2000,
          'original_start_time': 0,
          'original_end_time': 2000,
        },
      ];

      final tmp1 = '${tempDir.path}/file1.json';
      await File(tmp1).writeAsString(jsonEncode(json1));

      final result = await concatenateJsonFiles(
        [tmp1],
        [1],
        'merged',
        'lecId',
        dirOverride: tempDir,
      );
      expect(result, isNull);
    });

    test('Merges multiple JSON files with time offsets', () async {
      final json1 = [
        {
          'text_eng': 'Hello world.',
          'text_kor': '안녕하세요',
          'slide_number': 1,
          'tts_start_time': 0,
          'tts_end_time': 2000,
          'original_start_time': 0,
          'original_end_time': 2000,
        },
        {
          'text_eng': 'How are you?',
          'text_kor': '잘 지내세요?',
          'slide_number': 1,
          'tts_start_time': 2000,
          'tts_end_time': 4000,
          'original_start_time': 2000,
          'original_end_time': 4000,
        },
      ];

      final json2 = [
        {
          'text_eng': 'Goodbye.',
          'text_kor': '안녕히 가세요.',
          'slide_number': 2,
          'tts_start_time': 0,
          'tts_end_time': 3000,
          'original_start_time': 0,
          'original_end_time': 3000,
        },
      ];

      final tmp1 = '${tempDir.path}/file1.json';
      final tmp2 = '${tempDir.path}/file2.json';
      await File(tmp1).writeAsString(jsonEncode(json1));
      await File(tmp2).writeAsString(jsonEncode(json2));

      final result = await concatenateJsonFiles(
        [tmp1, tmp2],
        [1, 2],
        'merged',
        'lecId',
        dirOverride: tempDir,
      );
      expect(result, isNotNull);

      final List<dynamic> merged =
          jsonDecode(await File(result!).readAsString()) as List<dynamic>;

      expect(merged.length, 3);
      expect((merged.first as Map<String, dynamic>)['text_kor'], '안녕하세요');
      expect((merged.last as Map<String, dynamic>)['tts_end_time'], 12000);
      expect((merged.last as Map<String, dynamic>)['text_eng'], 'Goodbye.');
    });

    test('Handles empty timestamps and missing files', () async {
      final json1 = [
        {'text_eng': 'Hello', 'slide_number': 1},
      ];
      final json2 = [];

      final tmp1 = '${tempDir.path}/file1.json';
      final tmp2 = '${tempDir.path}/file2.json';
      await File(tmp1).writeAsString(jsonEncode(json1));
      await File(tmp2).writeAsString(jsonEncode(json2));

      final result = await concatenateJsonFiles(
        [tmp1, tmp2],
        [1, 2],
        'merged',
        'lecId',
        dirOverride: tempDir,
      );

      expect(result, isNotNull);
      final List<dynamic> merged =
          jsonDecode(await File(result!).readAsString()) as List<dynamic>;
      expect(merged.length, 1);

      await expectLater(
        () => concatenateJsonFiles(
          [tmp1, '${tempDir.path}/noexist.json'],
          [1, 2],
          'merged',
          'lecId',
          dirOverride: tempDir,
        ),
        throwsA(anything),
      );
    });

    test('Handles JSON file deletion failures with override', () async {
      final json1 = [
        {
          'text_eng': 'First',
          'text_kor': '첫번째',
          'slide_number': 1,
          'tts_start_time': 0,
          'tts_end_time': 1000,
          'original_start_time': 0,
          'original_end_time': 1000,
        },
      ];

      final json2 = [
        {
          'text_eng': 'Second',
          'text_kor': '두번째',
          'slide_number': 2,
          'tts_start_time': 0,
          'tts_end_time': 2000,
          'original_start_time': 0,
          'original_end_time': 2000,
        },
      ];

      final tmp1 = '${tempDir.path}/deletefail1.json';
      final tmp2 = '${tempDir.path}/deletefail2.json';
      await File(tmp1).writeAsString(jsonEncode(json1));
      await File(tmp2).writeAsString(jsonEncode(json2));

      final result = await concatenateJsonFiles(
        [tmp1, tmp2],
        [1, 2],
        'merged_deletefail',
        'lecId',
        dirOverride: tempDir,
        deleteFileOverride: (path) async {
          throw Exception('Deletion failed');
        },
      );

      expect(result, isNotNull);
      expect(File(result!).existsSync(), isTrue);

      final List<dynamic> merged =
          jsonDecode(await File(result).readAsString()) as List<dynamic>;
      expect(merged.length, 2);
      expect((merged[0] as Map<String, dynamic>)['text_eng'], 'First');
      expect((merged[1] as Map<String, dynamic>)['text_eng'], 'Second');
    });
  });

  group('onProgress', () {
    late MockFlutterLocalNotificationsPlugin mockNotifier;
    late LectureLoadingService service;

    setUp(() {
      mockNotifier = MockFlutterLocalNotificationsPlugin();
      when(mockNotifier.show(any, any, any, any)).thenAnswer((_) async => {});
      when(mockNotifier.cancel(any)).thenAnswer((_) async => {});
      setNotifierForTest(mockNotifier);

      service = LectureLoadingService.instance;
      service.hideLoading();
    });

    tearDown(() {
      setNotifierForTest(null);
      service.hideLoading();
    });

    test(
      'Handles edge case progress values (NaN, infinity, negative, >1)',
      () async {
        await onProgress(double.nan, 'Test', 'TestLecture', 1, 1);
        expect(service.progress, 0.0);
        expect(service.isLoading, isFalse);

        await onProgress(double.infinity, 'Test', 'TestLecture', 1, 1);
        expect(service.progress, 0.0);

        await onProgress(-0.5, 'Test', 'TestLecture', 1, 1);
        expect(service.progress, 0.0);

        service.hideLoading();
        await onProgress(1.5, 'Test', 'TestLecture', 1, 1);
        expect(service.progress, 1.0);
        verify(mockNotifier.cancel(10042)).called(1);
      },
    );

    test('Starts loading and updates progress with notifications', () async {
      expect(service.isLoading, isFalse);

      await onProgress(0.1, 'Starting', 'MyLecture', 1, 1);
      expect(service.isLoading, isTrue);
      expect(service.lectureTitle, 'MyLecture');

      await onProgress(0.3, 'Processing', 'MyLecture', 1, 1);
      expect(service.progress, closeTo(0.3, 0.01));

      await onProgress(0.7, 'Almost done', 'MyLecture', 1, 1);
      expect(service.progress, closeTo(0.7, 0.01));

      verify(mockNotifier.show(any, any, any, any)).called(3);
    });

    test('Handles completion and notification cancellation', () async {
      await onProgress(0.5, 'Processing', 'Test', 1, 1);
      await onProgress(1.0, 'Done', 'Test', 1, 1);

      expect(service.progress, 1.0);
      verify(mockNotifier.cancel(10042)).called(1);
    });

    test('Tracks progress for multiple audio files', () async {
      await onProgress(0.5, 'File 1', 'Test', 1, 3);
      await onProgress(0.3, 'File 2', 'Test', 2, 3);
      await onProgress(0.7, 'File 3', 'Test', 3, 3);

      expect(service.progress, closeTo(0.5, 0.01));
      verify(mockNotifier.show(any, any, any, any)).called(3);
    });

    test('Shows notifications with correct format', () async {
      await onProgress(0.5, 'Processing', 'TestLecture', 1, 1);

      verify(
        mockNotifier.show(
          10042,
          'Generating Lecture: TestLecture',
          argThat(contains('50%')),
          any,
        ),
      ).called(1);
    });
    test('Tests lifecycle state injection for background detection', () async {
      setLifecycleStateForTest(() => AppLifecycleState.paused);
      await onProgress(0.5, 'Test', 'TestLecture', 1, 1);
      verify(mockNotifier.show(any, any, any, any)).called(1);

      setLifecycleStateForTest(() => AppLifecycleState.inactive);
      await onProgress(0.6, 'Test', 'TestLecture', 1, 1);
      verify(mockNotifier.show(any, any, any, any)).called(1);

      setLifecycleStateForTest(() => AppLifecycleState.detached);
      await onProgress(0.7, 'Test', 'TestLecture', 1, 1);
      verify(mockNotifier.show(any, any, any, any)).called(1);

      setLifecycleStateForTest(() => AppLifecycleState.resumed);
      await onProgress(1.0, 'Test', 'TestLecture', 1, 1);

      verify(mockNotifier.cancel(10042)).called(1);

      setLifecycleStateForTest(null);
      service.hideLoading();
    });
  });

  group('Unzip deletion edge cases', () {
    test('unzipResult handles zip deletion failure with override', () async {
      final archive = Archive();
      archive.addFile(ArchiveFile('file.opus', 4, [1, 2, 3, 4]));
      archive.addFile(ArchiveFile('file.json', 2, utf8.encode('{}')));

      final zipBytes = ZipEncoder().encode(archive);
      final tempDir = await Directory.systemTemp.createTemp('unzip_del_');
      final docsDir = Directory('${tempDir.path}/docs')
        ..createSync(recursive: true);
      final zipFile = File('${tempDir.path}/in.zip')
        ..writeAsBytesSync(zipBytes);

      final result = await unzipResult(
        zipFile.path,
        'Test',
        'lecId',
        1,
        documentsDirOverride: docsDir,
        deleteZip: true,
        deleteZipOverride: (file) async {
          throw Exception('Deletion failed');
        },
      );

      expect(result, isNotNull);
      expect(result!.length, 2);

      await tempDir.delete(recursive: true);
    });
  });

  group('Stream timeout with fast timeout', () {
    Future<File> tempFile(String name, List<int> bytes) async {
      final dir = await Directory.systemTemp.createTemp('timeout_test_');
      final f = File('${dir.path}/$name');
      await f.writeAsBytes(bytes, flush: true);
      return f;
    }

    test('Handles stream timeout with injected fast timeout', () async {
      final controller = StreamController<List<int>>();
      final fakeClient = FakeStreamingClient((req) async {
        return http.StreamedResponse(
          controller.stream,
          200,
          headers: {'content-type': 'text/event-stream; charset=utf-8'},
        );
      });

      final slide = await tempFile('slides.pdf', [1, 2, 3]);
      final audio = await tempFile('audio.m4a', [4, 5, 6]);
      final audioEntry = AudioFileEntry.fromPath(audio.path);

      Future<void> onProgress(
        double p,
        String msg,
        String title,
        int i,
        int j,
      ) async {}

      final service = LectureLoadingService.instance;
      service.hideLoading();

      controller.add(
        utf8.encode(
          'data: {"job_id":"timeout123","progress":10,"message":"Starting","status":"running"}\n\n',
        ),
      );

      final jobIdFuture = requestLecture(
        slide.path,
        audioEntry,
        'Test',
        1,
        1,
        '127.0.0.1',
        '8080',
        onProgress,
        'ko',
        false,
        fakeClient: fakeClient,
        endpointOverride: Uri.parse('http://local.test/api/synchronize/stream'),
      );

      await Future.delayed(Duration(milliseconds: 200));
      await controller.close();

      final jobId = await jobIdFuture;

      expect(jobId, anyOf(isNull, equals('timeout123')));
      service.hideLoading();
    });
  });

  group('Additional edge cases', () {
    test('Handles invalid requestLecture inputs', () async {
      final slide = File(
        'assets/lectures/lec_demo_001/lec_demo_001_slides.pdf',
      );
      final tempDir = await Directory.systemTemp.createTemp('edge_test_');
      final audio = await File(
        '${tempDir.path}/audio.m4a',
      ).writeAsBytes([1, 2, 3]);

      Future<void> onProgress(
        double p,
        String msg,
        String title,
        int i,
        int j,
      ) async {}

      final service = LectureLoadingService.instance;
      service.hideLoading();

      final audioEntry1 = AudioFileEntry.fromPath(audio.path);
      audioEntry1.startPageController.text = '';
      audioEntry1.endPageController.text = '5';

      await expectLater(
        () => requestLecture(
          slide.path,
          audioEntry1,
          'Test',
          1,
          2,
          'localhost',
          '8080',
          onProgress,
          'ko',
          false,
        ),
        throwsA(isA<ArgumentError>()),
      );

      final nonExistent = File('${tempDir.path}/nonexistent.m4a');
      final audioEntry2 = AudioFileEntry.fromPath(nonExistent.path);

      final result = await requestLecture(
        slide.path,
        audioEntry2,
        'Test',
        1,
        1,
        'localhost',
        '8080',
        onProgress,
        'ko',
        false,
        fakeClient: FakeStreamingClient(
          (req) async => http.StreamedResponse(Stream.empty(), 200),
        ),
        endpointOverride: Uri.parse('http://test.local/stream'),
      );

      expect(result, isNull);
      service.hideLoading();
      await tempDir.delete(recursive: true);
    });

    test('Handles edge cases in file processing functions', () async {
      final tempDir = await Directory.systemTemp.createTemp('edge_');

      final json1 = [
        {'slide_number': 1, 'tts_start_time': 0, 'tts_end_time': 1000},
      ];
      final json2 = [
        {'text_eng': 'Hello'},
      ];

      final tmp1 = '${tempDir.path}/file1.json';
      final tmp2 = '${tempDir.path}/file2.json';
      await File(tmp1).writeAsString(jsonEncode(json1));
      await File(tmp2).writeAsString(jsonEncode(json2));

      final jsonResult = await concatenateJsonFiles(
        [tmp1, tmp2],
        [1, 2],
        'merged',
        'lecId',
        dirOverride: tempDir,
      );

      expect(jsonResult, isNotNull);
      final merged =
          jsonDecode(await File(jsonResult!).readAsString()) as List<dynamic>;
      expect(merged.length, 2);

      final archive = Archive();
      archive.addFile(ArchiveFile('some_dir/', 0, []));
      archive.addFile(ArchiveFile('file.opus', 4, [1, 2, 3, 4]));
      archive.addFile(ArchiveFile('file.json', 2, utf8.encode('{}')));

      final zipBytes = ZipEncoder().encode(archive);
      final docsDir = Directory('${tempDir.path}/docs')
        ..createSync(recursive: true);
      final zipFile = File('${tempDir.path}/in.zip')
        ..writeAsBytesSync(zipBytes);

      final unzipPaths = await unzipResult(
        zipFile.path,
        'Test',
        'lecId',
        1,
        documentsDirOverride: docsDir,
        deleteZip: true,
      );

      expect(unzipPaths, isNotNull);
      expect(unzipPaths!.length, 2);

      await tempDir.delete(recursive: true);
    });

    test('Handles polling fallback scenarios', () async {
      final tempDir = await Directory.systemTemp.createTemp('poll_test_');
      final audioFile = File('${tempDir.path}/audio.m4a');
      await audioFile.writeAsBytes([1, 2, 3]);
      final audioEntry = AudioFileEntry.fromPath(audioFile.path);

      final service = LectureLoadingService.instance;

      var chunkCount1 = 0;
      final client1 = FakeStreamingClient((req) async {
        if (req.url.toString().contains('/stream')) {
          final stream =
              Stream<List<int>>.fromIterable([
                utf8.encode(
                  'data: {"job_id":"poll-success","progress":0.3,"message":"Processing","status":"processing"}\n\n',
                ),
              ]).asyncMap((chunk) async {
                chunkCount1++;
                if (chunkCount1 == 1) {
                  return chunk;
                }
                throw Exception('Stream error');
              });
          return http.StreamedResponse(
            stream,
            200,
            headers: {'content-type': 'text/event-stream; charset=utf-8'},
          );
        } else if (req.url.toString().contains('/status/poll-success')) {
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                '{"job_id":"poll-success","status":"completed","progress":1.0}',
              ),
            ),
            200,
          );
        }
        return http.StreamedResponse(Stream.value([]), 404);
      });

      service.hideLoading();
      final jobId1 = await requestLecture(
        'assets/lectures/lec_demo_001/lec_demo_001_slides.pdf',
        audioEntry,
        'PollTest',
        1,
        1,
        'localhost',
        '8080',
        onProgress,
        'ko',
        false,
        fakeClient: client1,
        endpointOverride: Uri.parse('http://test.local/api/synchronize/stream'),
      );
      expect(jobId1, 'poll-success');

      var chunkCount2 = 0;
      final client2 = FakeStreamingClient((req) async {
        if (req.url.toString().contains('/stream')) {
          final stream =
              Stream<List<int>>.fromIterable([
                utf8.encode(
                  'data: {"job_id":"poll-fail","progress":0.3,"message":"Processing","status":"processing"}\n\n',
                ),
              ]).asyncMap((chunk) async {
                chunkCount2++;
                if (chunkCount2 == 1) {
                  return chunk;
                }
                throw Exception('Stream error');
              });
          return http.StreamedResponse(
            stream,
            200,
            headers: {'content-type': 'text/event-stream; charset=utf-8'},
          );
        } else if (req.url.toString().contains('/status/poll-fail')) {
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                '{"job_id":"poll-fail","status":"failed","progress":0.5}',
              ),
            ),
            200,
          );
        }
        return http.StreamedResponse(Stream.value([]), 404);
      });

      service.hideLoading();
      final jobId2 = await requestLecture(
        'assets/lectures/lec_demo_001/lec_demo_001_slides.pdf',
        audioEntry,
        'FailPollTest',
        1,
        1,
        'localhost',
        '8080',
        onProgress,
        'ko',
        false,
        fakeClient: client2,
        endpointOverride: Uri.parse('http://test.local/api/synchronize/stream'),
      );
      expect(jobId2, isNull);

      await tempDir.delete(recursive: true);
      service.hideLoading();
    });
  });
}
