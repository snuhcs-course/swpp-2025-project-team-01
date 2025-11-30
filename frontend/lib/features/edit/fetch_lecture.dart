import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:re_view/core/lecture_loading_service.dart';
import 'package:re_view/data/hive_manager.dart';
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
  int audioCount,
  String serverAddress,
  String port,
  Future<void> Function(double, String, String, int, int) onProgress,
  String langCode,
  bool isRetry, {
  http.Client? fakeClient, // for testing
  Uri? endpointOverride, // for testing
  http.Client? clientToClose, // client that can be closed externally
}) async {
  final http.Client client;
  if (fakeClient != null) {
    client = fakeClient;
  } else if (clientToClose != null) {
    client = clientToClose;
  } else {
    client = http.Client();
  }
  final endpoint =
      endpointOverride ??
      Uri.parse('http://$serverAddress:$port/api/synchronize/stream');

  final req = http.MultipartRequest('POST', endpoint);

  final File slideFile;

  // Skip file handling when testing
  if (fakeClient == null) {
    if (audioCount == 1) {
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

    req.fields['lang'] = langCode;
    req.fields['tts_gender'] = HiveManager.instance.settings.ttsGender == '남성'
        ? 'm'
        : 'f';
  }

  // Use the injected client to send
  bool didArrive = false;
  try {
    final streamed = await client
        .send(req)
        .timeout(
          endpointOverride != null
              ? const Duration(seconds: 1) // Fast timeout for testing
              : const Duration(minutes: 5),
          onTimeout: () {
            throw Exception(
              'Server connection timeout - Please check if server is running',
            );
          },
        );
    didArrive = true;
    // read chunked SSE-style body
    final stream = streamed.stream
        .transform(utf8.decoder)
        .timeout(
          endpointOverride != null
              ? const Duration(milliseconds: 100) // Fast timeout for testing
              : const Duration(seconds: 30), // 30초 동안 업데이트가 없으면 타임아웃
          onTimeout: (sink) {
            debugPrint(
              'Stream timeout - No updates from server for 30 seconds',
            );
            sink.addError(Exception('서버로부터 응답이 없습니다'));
          },
        );

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
            LectureLoadingService.instance.addJobId(jobId);

            // 서버가 0-100 범위로 보낼 수 있으므로 변환
            final rawProgress = data['progress'];
            final progress = rawProgress is int
                ? (rawProgress / 100.0)
                : (rawProgress as double) > 1.0
                ? rawProgress / 100.0
                : rawProgress;

            final message = data['message'] as String;

            await onProgress(progress, message, titleText, order, audioCount);

            if (data['status'] == 'completed') {
              return jobId;
            } else if (data['status'] == 'failed') {
              LectureLoadingService.instance.setError();
              return null;
            }
          }
        }
      }
    } catch (e) {
      // 취소 확인
      if (LectureLoadingService.instance.isCancelled) {
        await Future.delayed(Duration(seconds: 1));
        return null;
      }

      debugPrint('SSE issue triggered');
      // Use fakeClient if provided (for testing), otherwise create new client
      final pollingClient = fakeClient ?? http.Client();
      final shouldCloseClient = fakeClient == null;

      if (jobId == null) {
        if (shouldCloseClient) {
          pollingClient.close();
        }
        return null;
      }
      while (true) {
        final status = await getJobStatus(
          jobId,
          serverAddress,
          port,
          pollingClient,
        );
        if (status == null || status.$1 == 'failed') {
          debugPrint('Error during lecture request stream processing: $e');
          LectureLoadingService.instance.setError();
          if (shouldCloseClient) {
            pollingClient.close();
          }
          return null;
        } else if (status.$1 == 'completed') {
          if (shouldCloseClient) {
            pollingClient.close();
          }
          return jobId;
        }

        await onProgress(status.$2, 'message', titleText, order, audioCount);
      }
    }

    return jobId;
  } catch (e) {
    debugPrint('Error during lecture request: $e');
    if (!didArrive && !isRetry) {
      final jobId = await requestLecture(
        slidePath,
        audioFileEntry,
        titleText,
        order,
        audioCount,
        serverAddress,
        port,
        onProgress,
        langCode,
        true,
      );
      return jobId;
    }
    LectureLoadingService.instance.setError();
    return null;
  }
}

Future<(String, double)?> getJobStatus(
  String jobId,
  String serverAddress,
  String port,
  http.Client client,
) async {
  final statusEndpoint = Uri.parse(
    'http://$serverAddress:$port/api/synchronize/status/$jobId',
  );
  final statusResponse = await client.get(statusEndpoint);
  if (statusResponse.statusCode == 200) {
    final jsonData = jsonDecode(statusResponse.body) as Map<String, dynamic>;
    final String status = jsonData['status'] as String;
    jobId = jsonData['job_id'] as String;

    // 서버가 0-100 범위로 보낼 수 있으므로 변환
    final rawProgress = jsonData['progress'];
    final progress = rawProgress is int
        ? (rawProgress / 100.0)
        : (rawProgress as double) > 1.0
        ? rawProgress / 100.0
        : rawProgress;
    await Future.delayed(const Duration(seconds: 2));
    return (status, progress);
  } else {
    return null;
  }
}

Future<String?> downloadResult(
  String jobId,
  String titleText,
  int order,
  String serverAddress,
  String port,
  bool isRetry, {
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
      debugPrint('Failed to download result: ${response.statusCode}');
      LectureLoadingService.instance.setError();
      return null;
    }
  } catch (e) {
    debugPrint('Error during download: $e');
    if (!isRetry) {
      final savePath = await downloadResult(
        jobId,
        titleText,
        order,
        serverAddress,
        port,
        true,
      );
      return savePath;
    }
    LectureLoadingService.instance.setError();
    return null;
  }
}

Future<List<String>?> unzipResult(
  String zipPath,
  String titleText,
  String lectureId,
  int order, {
  Directory? documentsDirOverride, // for testing
  bool deleteZip = true, // for test assertions
  Future<void> Function(File)? deleteZipOverride, // for testing deletion
}) async {
  final zipFile = File(zipPath);
  if (!zipFile.existsSync()) {
    throw Exception('Zip file not found: $zipPath');
  }

  final resultPaths = <String>['opus', 'json'];
  final bytes = zipFile.readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  // 앱의 영구 저장소 디렉토리 가져오기
  final documentsDir =
      documentsDirOverride ?? await getApplicationDocumentsDirectory();
  final outputDir = documentsDir.path;

  for (final file in archive) {
    final extension = path.extension(file.name);
    final filePath = '$outputDir/$lectureId/${titleText}_$order$extension';

    if (file.isFile) {
      // Make sure the parent directory exists
      await Directory(File(filePath).parent.path).create(recursive: true);
      // Write the file content
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(file.content as List<int>);

      if (extension == '.opus') {
        resultPaths[0] = filePath;
      } else {
        resultPaths[1] = filePath;
      }
    } else {
      // It's a directory — just create it
      await Directory(filePath).create(recursive: true);
    }
  }

  // Unzip 완료 후 zip 파일 삭제
  if (deleteZip) {
    try {
      if (deleteZipOverride != null) {
        await deleteZipOverride(zipFile);
      } else {
        await zipFile.delete();
      }
    } catch (e) {
      debugPrint('Zip file deletion failed: $e');
    }
  }

  // Invalid response
  if (resultPaths.length != 2) {
    return null;
  }

  return resultPaths;
}

Future<List<String>?> fetchLecture(
  String slidePath,
  AudioFileEntry audioFileEntry,
  String titleText,
  String lectureId,
  int order,
  int audioCount,
  String serverAddress,
  String port,
  String langCode, {
  http.Client? fakeClient, // for testing
  Uri? endpointOverride, // for testing
  http.Client? clientToClose, // client that can be closed externally
}) async {
  debugPrint('🚀 Starting lecture request $order/$audioCount');
  final jobId = await requestLecture(
    slidePath,
    audioFileEntry,
    titleText,
    order,
    audioCount,
    serverAddress,
    port,
    onProgress,
    langCode,
    false,
    fakeClient: fakeClient,
    endpointOverride: endpointOverride,
    clientToClose: clientToClose,
  );

  if (jobId == null) {
    return null;
  }

  final zipPath = await downloadResult(
    jobId,
    titleText,
    order,
    serverAddress,
    port,
    false,
  );

  if (zipPath == null) {
    return null;
  }

  try {
    final filePaths = await unzipResult(zipPath, titleText, lectureId, order);

    if (filePaths == null) {
      LectureLoadingService.instance.setError();
      return null;
    }

    // Clean up split PDF files if they were created (multi-audio mode)
    if (audioCount > 1) {
      try {
        final splitPdfPath = slidePath.replaceFirst(
          RegExp(r'\.pdf$', caseSensitive: false),
          '_tmp$order.pdf',
        );
        final splitPdfFile = File(splitPdfPath);
        if (splitPdfFile.existsSync()) {
          await splitPdfFile.delete();
          debugPrint('Deleted split PDF: $splitPdfPath');
        }
      } catch (e) {
        debugPrint('Failed to delete split PDF: $e');
      }
    }

    return filePaths;
  } catch (e) {
    debugPrint('Error during unzip: $e');
    LectureLoadingService.instance.setError();
    return null;
  }
}

/// Concatenate multiple OPUS audio files into a single continuous OPUS audio file.
Future<String?> concatenateAudioFiles(
  List<String> audioPaths,
  String titleText,
  String lectureId, {
  Directory? dirOverride, // for testing
  Future<void> Function(String)? deleteFileOverride, // for testing deletion
}) async {
  final audioFileList = audioPaths.map((p) => "file '$p'").join('\n');
  final documentsDir = dirOverride ?? await getApplicationDocumentsDirectory();
  final outputDir = documentsDir.path;
  final listFile = '$outputDir/tmp_audio_list.txt';
  String audioOutputPath;
  if (path.extension(audioPaths[0]) == '.opus') {
    audioOutputPath = '$outputDir/$lectureId/$titleText.opus';
  } else {
    audioOutputPath = '$outputDir/$lectureId/$titleText.m4a';
  }

  // Concatenate the audio files
  try {
    await File(listFile).writeAsString(audioFileList);
    await FFmpegKit.execute(
      '-f concat -safe 0 -i $listFile -c copy $audioOutputPath',
    );
    await File(listFile).delete();
  } catch (_) {
    return null;
  }

  try {
    for (final audioPath in audioPaths) {
      if (deleteFileOverride != null) {
        await deleteFileOverride(audioPath);
      } else {
        await File(audioPath).delete();
      }
    }
  } catch (e) {
    debugPrint('Audio file deletion failed: $e');
  }

  return audioOutputPath;
}

/// Concatenate multiple JSONs into a single continuous JSON.
Future<String?> concatenateJsonFiles(
  List<String> jsonPaths,
  List<int> pdfStarts,
  String titleText,
  String lectureId, {
  Directory? dirOverride, // for testing
  Future<void> Function(String)? deleteFileOverride, // for testing deletion
}) async {
  const gapBetweenFiles = 5000;

  try {
    if (jsonPaths.length <= 1) {
      return null;
    }

    final documentsDir =
        dirOverride ?? await getApplicationDocumentsDirectory();
    final outputDir = documentsDir.path;
    final jsonOutputPath = '$outputDir/$lectureId/$titleText.json';

    final List<Map<String, dynamic>> mergedTimestamps = [];
    int originalTimeOffset = 0;
    int ttsTimeOffset = 0;

    for (int i = 0; i < jsonPaths.length; i++) {
      final jsonFile = File(jsonPaths[i]);
      if (!jsonFile.existsSync()) {
        throw Exception('Input JSON not found: ${jsonPaths[i]}');
      }

      // Actual start index
      final pdfStart = pdfStarts[i];

      final List<dynamic> data =
          jsonDecode(await jsonFile.readAsString()) as List<dynamic>;

      final tsList = data.cast<Map<String, dynamic>>();
      if (tsList.isEmpty) {
        continue;
      }

      // Determine how much time to offset this file by: append after current last end
      final currentTtsTimelineEnd = mergedTimestamps.isEmpty
          ? 0
          : mergedTimestamps.last['tts_end_time'] as int;
      final currentOriginalTimelineEnd = mergedTimestamps.isEmpty
          ? 0
          : mergedTimestamps.last['original_end_time'] as int;
      ttsTimeOffset = i == 0 ? 0 : currentTtsTimelineEnd + gapBetweenFiles;
      originalTimeOffset = i == 0
          ? 0
          : currentOriginalTimelineEnd + gapBetweenFiles;

      // Integrate timestamps with renumbering and offsets
      for (final ts in tsList) {
        final textEng = ts['text_eng'] as String? ?? '';
        final textKor = ts['text_kor'] as String? ?? '';
        final slideNumber = (ts['slide_number'] as num?)?.toInt() ?? 0;
        final ttsStartTime = (ts['tts_start_time'] as num?)?.toInt() ?? 0;
        final ttsEndTime =
            (ts['tts_end_time'] as num?)?.toInt() ?? ttsStartTime;
        final originalStartTime =
            (ts['original_start_time'] as num?)?.toInt() ?? 0;
        final originalEndTime = (ts['original_end_time'] as num?)?.toInt() ?? 0;

        mergedTimestamps.add({
          'text_eng': textEng,
          'text_kor': textKor,
          'slide_number': slideNumber + pdfStart - 1,
          'tts_start_time': ttsStartTime + ttsTimeOffset,
          'tts_end_time': ttsEndTime + ttsTimeOffset,
          'original_start_time': originalStartTime + originalTimeOffset,
          'original_end_time': originalEndTime + originalTimeOffset,
        });
      }
    }

    // Write final JSON
    final encoder = const JsonEncoder.withIndent('  ');
    final outFile = File(jsonOutputPath);
    await outFile.create(recursive: true);
    await outFile.writeAsString(encoder.convert(mergedTimestamps));

    try {
      for (final jsonPath in jsonPaths) {
        if (deleteFileOverride != null) {
          await deleteFileOverride(jsonPath);
        } else {
          await File(jsonPath).delete();
        }
      }
    } catch (e) {
      debugPrint('JSON file deletion failed: $e');
    }

    return jsonOutputPath;
  } catch (e) {
    rethrow;
  }
}

// Notification configurations
const _progressChannelId = 'progress_channel';
const _progressChannelName = 'Progress';
const _progressChannelDesc = 'Shows task progress';
const _progressNotificationId = 10042;
bool _notifierInitialized = false;

FlutterLocalNotificationsPlugin _notifier = FlutterLocalNotificationsPlugin();

/// For testing: allows injecting a mock notifier
@visibleForTesting
void setNotifierForTest(FlutterLocalNotificationsPlugin? notifier) {
  if (notifier != null) {
    _notifier = notifier;
    _notifierInitialized = true;
  } else {
    _notifier = FlutterLocalNotificationsPlugin();
    _notifierInitialized = false;
  }
}

/// Ensure the notifications plugin is initialized (works in bg isolates too).
Future<void> _ensureNotificationsInitialized() async {
  if (_notifierInitialized) {
    return;
  }

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );
  await _notifier.initialize(initSettings);

  // Request notification permission for Android 13+ (API 33+)
  final androidImplementation = _notifier
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  if (androidImplementation != null) {
    await androidImplementation.requestNotificationsPermission();

    // Create notification channel for Android 8.0+
    const androidChannel = AndroidNotificationChannel(
      _progressChannelId,
      _progressChannelName,
      description: _progressChannelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await androidImplementation.createNotificationChannel(androidChannel);
  }

  _notifierInitialized = true;
}

/// - First call creates the notification (progress at current value).
/// - Later calls with the SAME ID update it in place.
/// - When [progress] >= 1.0 (job done), it finalizes the notification (no progress bar).
Future<void> onProgress(
  double progress,
  String message,
  String lectureTitle,
  int order,
  int audioCount,
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
    loadingService.startLoading(lectureTitle, audioCount);
  }

  // 진행도 갱신 (완료 위젯 노출은 마지막 단계에서 처리)
  loadingService.updateProgress(progress, order, message);

  final updatedProgress = loadingService.getProgress();
  final pct = (updatedProgress * 100).round();
  final isDone = (pct == 100);

  // Always show notification during progress to keep background task alive
  // Only skip notification if completed and app is in foreground
  final isAppInBackground = _isAppInBackground();
  final shouldShowNotification = !isDone || isAppInBackground;

  if (shouldShowNotification) {
    final androidDetails = AndroidNotificationDetails(
      _progressChannelId,
      _progressChannelName,
      channelDescription: _progressChannelDesc,
      onlyAlertOnce: !isDone, // Alert when completed
      ongoing: !isDone, // Keep notification pinned during progress
      showProgress: !isDone, // Show progress bar while in progress
      maxProgress: 100,
      progress: isDone ? 0 : pct,
      indeterminate: false,
      importance:
          Importance.high, // Always high to prevent background termination
      priority: Priority.high, // Always high to keep task alive
      autoCancel: isDone, // Auto-dismiss when completed and tapped
      enableVibration: isDone, // Only vibrate on completion
      playSound: isDone, // Only sound on completion
      category: AndroidNotificationCategory.progress,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: isDone,
    );

    final title = 'Generating Lecture: $lectureTitle';
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifier.show(
      _progressNotificationId,
      isDone ? 'Lecture generation finished' : title,
      isDone ? null : '${loadingService.message} — $pct%',
      details,
    );
  } else {
    // App is in foreground and completed - dismiss notification
    await _notifier.cancel(_progressNotificationId);
  }
}

// For testing: allows injecting lifecycle state
AppLifecycleState? Function()? _lifecycleStateOverride;

@visibleForTesting
void setLifecycleStateForTest(AppLifecycleState? Function()? override) {
  _lifecycleStateOverride = override;
}

/// Check if the app is currently in background
bool _isAppInBackground() {
  try {
    // Use override for testing
    if (_lifecycleStateOverride != null) {
      final state = _lifecycleStateOverride!();
      if (state == null) {
        return false;
      }
      return state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive ||
          state == AppLifecycleState.detached;
    }

    // WidgetsBinding is available in UI isolate
    final lifecycleState = WidgetsBinding.instance.lifecycleState;

    // If lifecycleState is null, assume app is active (foreground)
    if (lifecycleState == null) {
      return false;
    }

    // App is in background if lifecycle state is paused, inactive, or detached
    return lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.inactive ||
        lifecycleState == AppLifecycleState.detached;
  } catch (e) {
    // If we can't determine lifecycle state, assume foreground (safer default)
    return false;
  }
}
