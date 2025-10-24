import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:re_view/core/lecture_loading_service.dart';
import 'package:re_view/features/edit/lecture_form_screen.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

/// Returns a new PDF (bytes) containing pages [start]..[end] (1-based, inclusive).
Future<void> splitPdfRange(
  String inputFile, {
  required int start,
  required int end,
  required int order,
}) async {
  final inputBytes = await File(inputFile).readAsBytes();

  final src = PdfDocument(inputBytes: inputBytes);

  try {
    final pageCount = src.pages.count;

    if (pageCount == 0) {
      throw StateError('Source PDF has no pages.');
    }

    // normalize & clamp (1-based -> 0-based)
    final s = (start < 1) ? 0 : start - 1;
    final e = (end > pageCount) ? pageCount - 1 : end - 1;
    if (s > e) {
      throw ArgumentError('Invalid range: start ($start) > end ($end).');
    }

    final out = PdfDocument();
    out.pageSettings.margins.all = 0;
    try {
      for (int i = s; i <= e; i++) {
        if (i >= pageCount) {
          throw RangeError('Page index $i out of range (pageCount=$pageCount)');
        }
        final srcPage = src.pages[i];
        final template = srcPage.createTemplate();
        final width = template.size.width;
        final height = template.size.height;

        // Match page size in the destination
        final bool portrait = width <= height;
        out.pageSettings.orientation = portrait
            ? PdfPageOrientation.portrait
            : PdfPageOrientation.landscape;
        out.pageSettings.size = portrait
            ? Size(math.min(width, height), math.max(width, height))
            : Size(math.max(width, height), math.min(width, height));

        // Add a new page and draw the source page template onto it
        final newPage = out.pages.add();
        final bounds = Size(
          newPage.getClientSize().width,
          newPage.getClientSize().height,
        );
        newPage.graphics.drawPdfTemplate(template, Offset.zero, bounds);
      }

      final List<int> bytes = await out.save();
      final outputPath = inputFile.replaceFirst(
        RegExp(r'\.pdf$', caseSensitive: false),
        '_tmp$order.pdf',
      );
      await File(outputPath).writeAsBytes(bytes, flush: true);
    } finally {
      out.dispose();
    }
  } finally {
    src.dispose();
  }
}

/// Send lecture generation requests (stream)
Future<String?> requestLecture(
  String slidePath,
  AudioFileEntry audioFileEntry,
  String titleText,
  int order,
  bool isSingleAudio,
  String serverAddress,
  String port,
  Future<void> Function(double, String, String) onProgress, {
  http.Client? fakeClient, // for testing
  Uri? endpointOverride, // for testing
  http.Client? clientToClose, // client that can be closed externally
}) async {
  final http.Client client;
  final bool shouldCloseClient;
  if (fakeClient != null) {
    client = fakeClient;
    shouldCloseClient = false;
  } else if (clientToClose != null) {
    client = clientToClose;
    shouldCloseClient = false;
  } else {
    client = http.Client();
    shouldCloseClient = true;
  }
  final endpoint =
      endpointOverride ??
      Uri.parse('http://$serverAddress:$port/api/synchronize/stream');

  final req = http.MultipartRequest('POST', endpoint);

  final File slideFile;

  // Skip file handling when testing
  if (fakeClient == null) {
    if (isSingleAudio) {
      slideFile = File(slidePath);
    } else {
      // 다중 오디오 모드: 페이지 범위 파싱
      final startText = audioFileEntry.startPageController.text.trim();
      final endText = audioFileEntry.endPageController.text.trim();

      if (startText.isEmpty || endText.isEmpty) {
        throw ArgumentError(
          'Page range required for multiple audio files. '
          'Start: "$startText", End: "$endText"',
        );
      }

      final pdfStart = int.parse(startText);
      final pdfEnd = int.parse(endText);

      await splitPdfRange(
        slidePath,
        start: pdfStart,
        end: pdfEnd,
        order: order,
      );

      final splitSlideFilePath = slidePath.replaceFirst(
        RegExp(r'\.pdf$', caseSensitive: false),
        '_tmp$order.pdf',
      );
      slideFile = File(splitSlideFilePath);
    }

    req.files.add(
      await http.MultipartFile.fromPath(
        'lecture_note',
        slideFile.path,
        filename: path.basename(slideFile.path),
        contentType: MediaType('application', 'pdf'),
      ),
    );

    final audioFilePath = audioFileEntry.filePath;
    if (audioFilePath == null) {
      return null;
    }
    req.files.add(
      await http.MultipartFile.fromPath(
        'audio',
        audioFilePath,
        filename: path.basename(audioFilePath),
        contentType: MediaType('audio', 'm4a'),
      ),
    );
  }

  // Use the injected client to send
  final streamed = await client
      .send(req)
      .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
            'Server connection timeout - Please check if server is running',
          );
        },
      );

  // read chunked SSE-style body
  final stream = streamed.stream.transform(utf8.decoder);

  String? jobId;
  try {
    await for (final chunk in stream) {
      // 취소 확인
      if (LectureLoadingService.instance.isCancelled) {
        return null;
      }

      final lines = chunk.split('\n');
      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final jsonData = line.substring(6);
          final data = jsonDecode(jsonData) as Map<String, dynamic>;

          jobId = data['job_id'] as String;

          // 서버가 0-100 범위로 보낼 수 있으므로 변환
          final rawProgress = data['progress'];
          final progress = rawProgress is int
              ? (rawProgress / 100.0)
              : (rawProgress as double) > 1.0
              ? rawProgress / 100.0
              : rawProgress;

          final message = data['message'] as String;

          await onProgress(progress, message, titleText);

          if (data['status'] == 'completed') {
            return jobId;
          } else if (data['status'] == 'failed') {
            return null;
          }
        }
      }
    }
  } finally {
    if (shouldCloseClient) {
      client.close();
    }
  }

  return jobId;
}

Future<String?> downloadResult(
  String jobId,
  String titleText,
  int order,
  String serverAddress,
  String port, {
  http.Client? fakeClient, // for testing
  Directory? tempDirOverride, // for testing
}) async {
  final client = fakeClient ?? http.Client();
  try {
    final uri = Uri.parse(
      'http://$serverAddress:$port/api/synchronize/download/$jobId',
    );
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      // 앱의 임시 디렉토리 가져오기 (Android/iOS 모두 쓰기 가능)
      final directory = tempDirOverride ?? await getTemporaryDirectory();
      final savePath = '${directory.path}/${titleText}_${order}_output.zip';

      final file = File(savePath);
      await file.writeAsBytes(response.bodyBytes);

      return savePath;
    } else {
      return null;
    }
  } finally {
    if (fakeClient == null) {
      client.close();
    }
  }
}

Future<void> unzipResult(
  String zipPath,
  String titleText,
  int order, {
  Directory? documentsDirOverride, // for testing
  bool deleteZip = true, // for test assertions
}) async {
  final zipFile = File(zipPath);
  if (!zipFile.existsSync()) {
    throw Exception('Zip file not found: $zipPath');
  }

  final bytes = zipFile.readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  // 앱의 영구 저장소 디렉토리 가져오기
  final documentsDir =
      documentsDirOverride ?? await getApplicationDocumentsDirectory();
  final outputDir = documentsDir.path;

  for (final file in archive) {
    final extension = path.extension(file.name);
    final filePath = '$outputDir/${titleText}_$order$extension';

    if (file.isFile) {
      // Make sure the parent directory exists
      await Directory(File(filePath).parent.path).create(recursive: true);
      // Write the file content
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(file.content as List<int>);
    } else {
      // It's a directory — just create it
      await Directory(filePath).create(recursive: true);
    }
  }

  // Unzip 완료 후 zip 파일 삭제
  if (deleteZip) {
    try {
      await zipFile.delete();
    } catch (_) {
      // Ignore deletion errors
    }
  }
}

// Notification configurations
const _progressChannelId = 'progress_channel';
const _progressChannelName = 'Progress';
const _progressChannelDesc = 'Shows task progress';
const _progressNotificationId = 10042;
bool _notifierInitialized = false;

final FlutterLocalNotificationsPlugin _notifier =
    FlutterLocalNotificationsPlugin();

/// Ensure the notifications plugin is initialized (works in bg isolates too).
Future<void> _ensureNotificationsInitialized() async {
  if (_notifierInitialized) {
    return;
  }

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  // Note: No callbacks required for simple local updates.
  await _notifier.initialize(initSettings);

  _notifierInitialized = true;
}

/// - First call creates the notification (progress at current value).
/// - Later calls with the SAME ID update it in place.
/// - When [progress] >= 1.0 (job done), it finalizes the notification (no progress bar).
Future<void> onProgress(
  double progress,
  String message,
  String lectureTitle,
) async {
  await _ensureNotificationsInitialized();

  // Normalize
  if (progress.isNaN || progress.isInfinite) {
    progress = 0.0;
  }
  progress = progress.clamp(0.0, 1.0);

  // Update loading service for bottom loading bar UI
  final loadingService = LectureLoadingService.instance;
  if (!loadingService.isLoading && progress > 0) {
    // First progress update - start loading
    loadingService.startLoading(lectureTitle);
  }

  if (progress >= 1.0) {
    // Completed
    loadingService.completeLoading();
  } else {
    // In progress
    loadingService.updateProgress(progress, message);
  }

  final pct = (progress * 100).round();
  final isDone = progress >= 1.0;

  final androidDetails = AndroidNotificationDetails(
    _progressChannelId,
    _progressChannelName,
    channelDescription: _progressChannelDesc,
    onlyAlertOnce: true,
    ongoing: !isDone, // keep pinned until done
    showProgress: !isDone, // show bar while in progress
    maxProgress: 100,
    progress: isDone ? 0 : pct, // ignored when showProgress=false
    indeterminate: false,
  );

  final title = 'Generating Lecture: $lectureTitle';
  final details = NotificationDetails(android: androidDetails);

  await _notifier.show(
    _progressNotificationId,
    isDone ? 'Lecture generation finished' : title,
    isDone ? (message.isEmpty ? 'Completed' : message) : '$message — $pct%',
    details,
  );
}
