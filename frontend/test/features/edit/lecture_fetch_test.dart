import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
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
  group('Lecture Fetch Helpers', () {
    test('PDF Splitting', () async {
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

    test('Requesting Lecture', () async {
      Future<File> tempFile(String name, List<int> bytes) async {
        final dir = await Directory.systemTemp.createTemp('req_lect_');
        final f = File('${dir.path}/$name');
        await f.writeAsBytes(bytes, flush: true);
        return f;
      }

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

      // You likely have a real AudioFileEntry type; mock a minimal one:
      final audioEntry = AudioFileEntry.fromPath(
        audio.path,
      ); // adapt to your ctor

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
      expect(progressEvents[0]['p'], 10);
      expect(progressEvents[1]['p'], 45);
      expect(progressEvents[2]['p'], 100);
      expect(progressEvents[2]['msg'], 'Done');
    });

    test('Downloading Result (Success)', () async {
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

    test('Downloading Result (Fail)', () async {
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

    List<int> makeZip(Map<String, List<int>> filesAndBytes) {
      final archive = Archive();
      filesAndBytes.forEach((name, bytes) {
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      });
      return ZipEncoder().encode(archive);
    }

    test('Unzipping Result (Success)', () async {
      final pdfBytes  = utf8.encode('PDFDATA');
      final jsonBytes = utf8.encode('{"hello":"world"}');
      final zipBytes  = makeZip({
        'slides/lec.pdf': pdfBytes,
        'timestamp.json': jsonBytes,
      });

      final tempRoot = await Directory.systemTemp.createTemp('unzip_ok_');
      final docsDir  = Directory('${tempRoot.path}/docs')..createSync(recursive: true);
      final zipFile  = File('${tempRoot.path}/in.zip')..writeAsBytesSync(zipBytes);

      // Act
      await unzipResult(
        zipFile.path,
        'MyLecture',
        3,
        documentsDirOverride: docsDir,
        deleteZip: true,
      );

      // Assert: files are renamed to MyLecture_3.<ext> in docsDir
      final outPdf  = File('${docsDir.path}/MyLecture_3.pdf');
      final outJson = File('${docsDir.path}/MyLecture_3.json');

      expect(outPdf.existsSync(),  isTrue);
      expect(outJson.existsSync(), isTrue);
      expect(await outPdf.readAsBytes(),  pdfBytes);
      expect(await outJson.readAsBytes(), jsonBytes);

      // Zip deleted
      expect(File(zipFile.path).existsSync(), isFalse);
    });

    test('Unzipping Result (Fail)', () async {
      final missing = File('/does/not/exist.zip').path;
      await expectLater(
        () => unzipResult(missing, 'A', 0, deleteZip: false),
        throwsA(isA<Exception>()),
      );
    });
  });
}
