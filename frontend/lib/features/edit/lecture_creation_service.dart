import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:re_view/features/edit/fetch_lecture.dart';
import 'package:re_view/features/edit/lecture_form_screen.dart';

/// 서비스가 반환할 결과 (성공 시)
class CreationResult {
  CreationResult({
    required this.audioPath,
    required this.jsonPath,
    required this.duration,
  });

  final String audioPath;
  final String jsonPath;
  final int duration;
}

/// 강의 생성 로직을 처리하는 서비스 클래스
///
/// 테스트 시 이 클래스를 상속하거나 Fake 객체로 대체하여 사용
class LectureCreationService {
  // HTTP 클라이언트를 서비스가 내부적으로 소유
  http.Client? _client;

  Future<CreationResult?> createLecture({
    required String slidePath,
    required List<AudioFileEntry> audioEntries,
    required String title,
    required String serverAddress,
    required String port,
  }) async {
    // 클라이언트를 이 메서드 내부에서 생성
    _client = http.Client();

    final audioPaths = <String>[];
    final jsonPaths = <String>[];

    try {
      for (int i = 1; i <= audioEntries.length; i++) {
        final audioFileEntry = audioEntries[i - 1];

        // 내부 _client를 사용
        final jobId = await requestLecture(
          slidePath,
          audioFileEntry,
          title,
          i,
          audioEntries.length == 1,
          serverAddress,
          port,
          onProgress, // fetch_lecture.dart에서 import
          clientToClose: _client!,
        );

        if (jobId == null) {
          // 취소되었거나 실패함
          return null;
        }

        final zipPath = await downloadResult(
          jobId,
          title,
          i,
          serverAddress,
          port,
        );

        if (zipPath == null) {
          throw Exception('Lecture download failed.');
        }

        final filePaths = await unzipResult(zipPath, title, i);
        if (filePaths == null) {
          throw Exception('Lecture unzip failed.');
        }
        audioPaths.add(filePaths[0]);
        jsonPaths.add(filePaths[1]);
      }

      // 음성 파일이 여러 개일 경우 통합 처리
      String? audioPath;
      String? jsonPath;
      int? duration;

      if (audioEntries.length > 1) {
        audioPath = await concatenateAudioFiles(audioPaths, title);
        jsonPath = await concatenateJsonFiles(jsonPaths, title);
        if (audioPath == null || jsonPath == null) {
          throw Exception('File concatenation failed.');
        }
      } else {
        audioPath = audioPaths[0];
        jsonPath = jsonPaths[0];
      }

      final jsonFile = File(jsonPath);
      final jsonData =
          jsonDecode(await jsonFile.readAsString()) as Map<String, dynamic>;
      final metadata = jsonData['metadata'] as Map<String, dynamic>;
      duration = metadata['total_duration'] as int;

      // 성공 결과를 반환
      return CreationResult(
        audioPath: audioPath,
        jsonPath: jsonPath,
        duration: duration,
      );
    } catch (e) {
      // 에러 발생 시 재전파
      rethrow;
    } finally {
      // 작업이 성공하든 실패하든 항상 클라이언트 정리
      _client?.close();
      _client = null;
    }
  }

  // 취소 메서드 구현
  void cancelCreation() {
    _client?.close(); // 진행 중인 HTTP 요청을 강제 종료
    _client = null;
  }
}
