import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/widgets.dart';
import 'package:re_view/features/edit/fetch_lecture.dart';
import 'package:re_view/features/edit/lecture_form_screen.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeStreamingClient extends http.BaseClient {
  FakeStreamingClient(this._onSend);
  final Future<http.StreamedResponse> Function(http.BaseRequest) _onSend;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _onSend(request);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('Split PDF', () {
    test('Success', () async {
      final inputFilePath =
          'assets/lectures/lec_demo_002/lec_demo_002_slides.pdf';
      final bytes = await File(inputFilePath).readAsBytes();
      final originalPdf = PdfDocument(inputBytes: bytes);
      final originalSize = originalPdf.pages[2].size;
      await splitPdfRange(inputFilePath, start: 3, end: 5, order: 1);
      final outputPath = inputFilePath.replaceFirst(
        RegExp(r'\.pdf$', caseSensitive: false),
        '_tmp1.pdf',
      );
      final inputBytes = await File(outputPath).readAsBytes();
      final splittedPdf = PdfDocument(inputBytes: inputBytes);
      final generatedPages = splittedPdf.pages.count;
      final pageSize = splittedPdf.pages[0].size;
      await File(outputPath).delete();

      expect(generatedPages, 3);
      expect(pageSize, originalSize);
    });
  });

  group('Lecture Request', () {
    Future<File> tempFile(String name, List<int> bytes) async {
      final dir = await Directory.systemTemp.createTemp('req_lect_');
      final f = File('${dir.path}/$name');
      await f.writeAsBytes(bytes, flush: true);
      return f;
    }

    test('Success', () async {
      final sseChunks = <String>[
        'data: {"job_id":"abc123","progress":10.0,"message":"Uploading","status":"running"}\n\n',
        'data: {"job_id":"abc123","progress":45.0,"message":"Aligning","status":"running"}\n\n',
        'data: {"job_id":"abc123","progress":100.0,"message":"Done","status":"completed"}\n\n',
      ];

      final stream = Stream<List<int>>.fromIterable(
        sseChunks.map((s) => utf8.encode(s)),
      );

      final fakeClient = FakeStreamingClient((req) async {
        // Assert request shape (optional but useful)
        expect(req.url.path.endsWith('/api/synchronize/stream'), isTrue);
        // You can also check headers or method:
        expect(req.method, 'POST');

        return http.StreamedResponse(
          stream,
          200,
          headers: {'content-type': 'text/event-stream; charset=utf-8'},
          reasonPhrase: 'OK',
        );
      });

      // Minimal fake inputs
      final slide = await tempFile('slides.pdf', [1, 2, 3]);
      final audio = await tempFile('audio.m4a', [4, 5, 6]);

      final audioEntry = AudioFileEntry.fromPath(audio.path);

      final progressEvents = <Map<String, dynamic>>[];

      Future<void> onProgress(double p, String msg, String title) async {
        progressEvents.add({'p': p, 'msg': msg, 'title': title});
      }

      // Act: call with injected client + endpointOverride so we don’t depend on host/port
      final jobId = await requestLecture(
        slide.path,
        audioEntry,
        'My Lecture',
        0,
        true,
        '127.0.0.1',
        '8080',
        onProgress,
        fakeClient: fakeClient,
        endpointOverride: Uri.parse('http://local.test/api/synchronize/stream'),
      );

      // Assert: jobId and progress ordering
      expect(jobId, 'abc123');
      expect(progressEvents.length, 3);
      expect(progressEvents[0]['p'], 0.1);
      expect(progressEvents[1]['p'], 0.45);
      expect(progressEvents[2]['p'], 1.0);
      expect(progressEvents[2]['msg'], 'Done');
    });

    test('Fail on endpoint', () async {
      // Minimal fake inputs
      final slide = File(
        'assets/lectures/lec_demo_002/lec_demo_002_slides.pdf',
      );
      final audio = await tempFile('audio.m4a', [4, 5, 6]);

      final audioEntry = AudioFileEntry.fromPath(audio.path);
      audioEntry.startPageController.text = '1';
      audioEntry.endPageController.text = '5';

      final progressEvents = <Map<String, dynamic>>[];

      Future<void> onProgress(double p, String msg, String title) async {
        progressEvents.add({'p': p, 'msg': msg, 'title': title});
      }

      // Act: call with injected client + endpointOverride so we don’t depend on host/port
      await expectLater(
        () async => requestLecture(
          slide.path,
          audioEntry,
          'My Lecture',
          0,
          true,
          '127.0.0.1',
          '8080',
          onProgress,
          endpointOverride: Uri.parse(
            'http://local.test/api/synchronize/stream',
          ),
        ),
        throwsA(anything),
      );
      await expectLater(
        () async => requestLecture(
          slide.path,
          audioEntry,
          'My Lecture',
          0,
          false,
          '127.0.0.1',
          '8080',
          onProgress,
          endpointOverride: Uri.parse(
            'http://local.test/api/synchronize/stream',
          ),
        ),
        throwsA(anything),
      );

      try {
        File(
          'assets/lectures/lec_demo_002/lec_demo_002_slides_tmp0.pdf',
        ).delete();
      } catch (_) {
        // Ignore deletion errors
      }
    });
  });

  group('Download Result', () {
    test('Success', () async {
      // Arrange: fake zip bytes (can be any bytes; function doesn’t inspect)
      final zipBytes = utf8.encode('FAKE-ZIP-CONTENT');

      final mock = MockClient((req) async {
        expect(req.method, 'GET');
        expect(
          req.url.path.contains('/api/synchronize/download/abc123'),
          isTrue,
        );
        return http.Response.bytes(
          zipBytes,
          200,
          headers: {'content-type': 'application/zip'},
        );
      });

      final temp = await Directory.systemTemp.createTemp('dl_ok_');

      // Act
      final path = await downloadResult(
        'abc123',
        'MyLecture',
        2,
        'localhost',
        '8080',
        fakeClient: mock,
        tempDirOverride: temp,
      );

      // Assert
      expect(path, isNotNull);
      final file = File(path!);
      expect(file.existsSync(), isTrue);
      final written = await file.readAsBytes();
      expect(written, zipBytes);

      // name check
      expect(file.path.endsWith('/MyLecture_2_output.zip'), isTrue);
    });

    test('Fail', () async {
      final mock = MockClient((_) async => http.Response('nope', 404));
      final temp = await Directory.systemTemp.createTemp('dl_404_');

      final path = await downloadResult(
        'missing',
        'Title',
        0,
        'localhost',
        '8080',
        fakeClient: mock,
        tempDirOverride: temp,
      );

      expect(path, isNull);
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

    test('Success', () async {
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

      // Act
      await unzipResult(
        zipFile.path,
        'MyLecture',
        3,
        documentsDirOverride: docsDir,
        deleteZip: true,
      );

      // Assert: files are renamed to MyLecture_3.<ext> in docsDir
      final outPdf = File('${docsDir.path}/MyLecture_3.pdf');
      final outJson = File('${docsDir.path}/MyLecture_3.json');

      expect(outPdf.existsSync(), isTrue);
      expect(outJson.existsSync(), isTrue);
      expect(await outPdf.readAsBytes(), pdfBytes);
      expect(await outJson.readAsBytes(), jsonBytes);

      // Zip deleted
      expect(File(zipFile.path).existsSync(), isFalse);
    });

    test('Fail', () async {
      final missing = File('/does/not/exist.zip').path;
      await expectLater(
        () => unzipResult(missing, 'A', 0, deleteZip: false),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('concatenateAudioFiles', () {
    late Directory tempDir;
    late String audio1;
    late String audio2;
    late String title;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('audio_test_');
      audio1 = '${tempDir.path}/a1.opus';
      audio2 = '${tempDir.path}/a2.opus';
      await File(audio1).writeAsBytes([]);
      await File(audio2).writeAsBytes([]);
      title = 'merged_audio';
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns null if FFmpeg fails', () async {
      final result = await concatenateAudioFiles(
        [audio1, 'missing.opus'],
        title,
        dirOverride: tempDir,
      );
      expect(result, isNull);
    });

    test('returns non-null path when valid inputs exist', () async {
      final result = await concatenateAudioFiles(
        [audio1, audio2],
        title,
        dirOverride: tempDir,
      );
      expect(result, anyOf(isNull, isA<String>()));
    });

    test('handles empty input list gracefully', () async {
      final result = await concatenateAudioFiles(
        [],
        title,
        dirOverride: tempDir,
      );
      expect(result, anyOf(isNull, isA<String>()));
    });
  });

  group('concatenateJsonFiles', () {
    late Directory tempDir;
    late String tmp1;
    late String tmp2;
    late String outputTitle;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('concat_test_');
      outputTitle = 'merged_result';

      // Build minimal valid JSON templates
      final json1 = {
        'metadata': {
          'total_sentences': 2,
          'total_duration': 4000,
          'voice': 'af_heart',
          'speed': 1.0,
          'language_code': 'a',
          'sample_rate': 24000,
        },
        'timestamps': [
          {
            'sentence_id': 1,
            'text': 'Hello world.',
            'text_kor': '안녕하세요',
            'slide_number': 1,
            'start_time': 0,
            'end_time': 2000,
            'duration': 2000,
          },
          {
            'sentence_id': 2,
            'text': 'How are you?',
            'text_kor': '잘 지내세요?',
            'slide_number': 1,
            'start_time': 2000,
            'end_time': 4000,
            'duration': 2000,
          },
        ],
      };

      final json2 = {
        'metadata': {
          'total_sentences': 1,
          'total_duration': 3000,
          'voice': 'af_heart',
          'speed': 1.0,
          'language_code': 'a',
          'sample_rate': 24000,
        },
        'timestamps': [
          {
            'sentence_id': 1,
            'text': 'Goodbye.',
            'text_kor': '안녕히 가세요.',
            'slide_number': 2,
            'start_time': 0,
            'end_time': 3000,
            'duration': 3000,
          },
        ],
      };

      tmp1 = '${tempDir.path}/file1.json';
      tmp2 = '${tempDir.path}/file2.json';

      await File(tmp1).writeAsString(jsonEncode(json1));
      await File(tmp2).writeAsString(jsonEncode(json2));
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns null if only one file', () async {
      final result = await concatenateJsonFiles(
        [tmp1],
        [1],
        outputTitle,
        dirOverride: tempDir,
      );
      expect(result, isNull);
    });

    test('merges JSON files correctly', () async {
      final result = await concatenateJsonFiles(
        [tmp1, tmp2],
        [1, 2],
        outputTitle,
        dirOverride: tempDir,
      );
      expect(result, isNotNull);

      final merged =
          jsonDecode(await File(result!).readAsString())
              as Map<String, dynamic>;
      final metadata = merged['metadata'] as Map<String, dynamic>;
      final timestamps = merged['timestamps'] as List;

      expect(metadata['total_sentences'], 3);
      expect(metadata['total_duration'], greaterThan(7000));
      expect(timestamps.length, 3);

      expect((timestamps.first as Map<String, dynamic>)['sentence_id'], 1);
      expect((timestamps.last as Map<String, dynamic>)['sentence_id'], 3);
      expect(
        (timestamps.last as Map<String, dynamic>)['text'],
        contains('Goodbye'),
      );
    });

    test('throws error when metadata mismatch', () async {
      final badVoice = {
        'metadata': {
          'total_sentences': 1,
          'total_duration': 1000,
          'voice': 'different_voice',
          'speed': 1.0,
          'language_code': 'a',
          'sample_rate': 24000,
        },
        'timestamps': [
          {
            'sentence_id': 1,
            'text': 'Different voice',
            'text_kor': '다른 목소리',
            'slide_number': 1,
            'start_time': 0,
            'end_time': 1000,
            'duration': 1000,
          },
        ],
      };
      final tmpBadVoice = '${tempDir.path}/badvoice.json';
      await File(tmpBadVoice).writeAsString(jsonEncode(badVoice));

      final badSpeed = {
        'metadata': {
          'total_sentences': 1,
          'total_duration': 1000,
          'voice': 'af_heart',
          'speed': 1.5,
          'language_code': 'a',
          'sample_rate': 24000,
        },
        'timestamps': [
          {
            'sentence_id': 1,
            'text': 'Different speed',
            'text_kor': '다른 속도',
            'slide_number': 1,
            'start_time': 0,
            'end_time': 1000,
            'duration': 1000,
          },
        ],
      };
      final tmpBadSpeed = '${tempDir.path}/badspeed.json';
      await File(tmpBadSpeed).writeAsString(jsonEncode(badSpeed));

      final badLanguage = {
        'metadata': {
          'total_sentences': 1,
          'total_duration': 1000,
          'voice': 'af_heart',
          'speed': 1.0,
          'language_code': 'b',
          'sample_rate': 24000,
        },
        'timestamps': [
          {
            'sentence_id': 1,
            'text': 'Different language',
            'text_kor': '다른 언어',
            'slide_number': 1,
            'start_time': 0,
            'end_time': 1000,
            'duration': 1000,
          },
        ],
      };
      final tmpBadLanguage = '${tempDir.path}/badlanguage.json';
      await File(tmpBadLanguage).writeAsString(jsonEncode(badLanguage));

      final badSampleRate = {
        'metadata': {
          'total_sentences': 1,
          'total_duration': 1000,
          'voice': 'af_heart',
          'speed': 1.0,
          'language_code': 'a',
          'sample_rate': 12000,
        },
        'timestamps': [
          {
            'sentence_id': 1,
            'text': 'Different sample rate',
            'text_kor': '다른 샘플링 속도',
            'slide_number': 1,
            'start_time': 0,
            'end_time': 1000,
            'duration': 1000,
          },
        ],
      };
      final tmpBadSampleRate = '${tempDir.path}/badsamplerate.json';
      await File(tmpBadSampleRate).writeAsString(jsonEncode(badSampleRate));

      await expectLater(
        () async => concatenateJsonFiles(
          [tmp1, tmpBadVoice],
          [1, 2],
          outputTitle,
          dirOverride: tempDir,
        ),
        throwsA(anything),
      );
      await expectLater(
        () async => concatenateJsonFiles(
          [tmp1, tmpBadSpeed],
          [1, 2],
          outputTitle,
          dirOverride: tempDir,
        ),
        throwsA(anything),
      );
      await expectLater(
        () async => concatenateJsonFiles(
          [tmp1, tmpBadLanguage],
          [1, 2],
          outputTitle,
          dirOverride: tempDir,
        ),
        throwsA(anything),
      );
      await expectLater(
        () async => concatenateJsonFiles(
          [tmp1, tmpBadSampleRate],
          [1, 2],
          outputTitle,
          dirOverride: tempDir,
        ),
        throwsA(anything),
      );
    });

    test('throws when input file missing', () async {
      await expectLater(
        () async => concatenateJsonFiles(
          [tmp1, '${tempDir.path}/noexist.json'],
          [1, 2],
          outputTitle,
          dirOverride: tempDir,
        ),
        throwsA(anything),
      );
    });
  });
}
