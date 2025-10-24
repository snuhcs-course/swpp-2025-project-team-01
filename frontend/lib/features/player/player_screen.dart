import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';

import 'package:re_view/features/player/player_layout.dart';
import 'package:re_view/features/player/player_controller.dart';
import 'package:re_view/features/player/models/lecture_data.dart';
import 'package:re_view/features/player/services/audio_service.dart';
import 'package:re_view/features/player/services/pdf_cache_service.dart';
import 'package:re_view/data/hive_manager.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    this.args,
    AudioService? audioService,
    PdfCacheService? pdfCacheService,
    HiveManager? hiveManager,
  }) : _audioService = audioService,
       _pdfCacheService = pdfCacheService,
       _hiveManager = hiveManager;

  final Object? args;
  final AudioService? _audioService;
  final PdfCacheService? _pdfCacheService;
  final HiveManager? _hiveManager;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final PlayerController _controller;
  late final HiveManager _hiveManager;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 의존성 주입
    final audioService = widget._audioService ?? AudioService();
    final pdfCacheService = widget._pdfCacheService ?? PdfCacheService();
    _hiveManager = widget._hiveManager ?? HiveManager.instance;

    _controller = PlayerController(
      audioService: audioService,
      pdfCacheService: pdfCacheService,
    );

    _loadLectureData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 에러 발생 시 SnackBar를 표시하고 이전 페이지로 돌아가기
  void _handleError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );

    // SnackBar가 표시된 후 이전 페이지로 이동
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _loadLectureData() async {
    try {
      // 1. lectureId 검증
      final map = (widget.args is Map) ? widget.args as Map : const {};
      final lectureId = map['lectureId'] as String?;

      if (lectureId == null || lectureId.isEmpty) {
        _handleError('강의 ID가 없습니다.');
        return;
      }

      // 2. Hive에서 강의 데이터 검증
      final hiveLecture = _hiveManager.getLecture(lectureId);

      if (hiveLecture == null) {
        _handleError('강의를 찾을 수 없습니다.');
        return;
      }

      // 3. transcript.json 로드
      final transcriptPath = hiveLecture.transcriptPaths?.isNotEmpty == true
          ? hiveLecture.transcriptPaths!.first
          : 'assets/lectures/$lectureId/transcript.json';

      String? transcriptJson;
      try {
        transcriptJson = transcriptPath.startsWith('assets/')
            ? await rootBundle.loadString(transcriptPath)
            : await File(transcriptPath).readAsString();
      } catch (e) {
        _handleError('자막 파일을 불러올 수 없습니다.');
        return;
      }

      // 4. JSON 파싱
      TranscriptData? transcriptData;
      try {
        final transcriptJsonData =
            json.decode(transcriptJson) as Map<String, dynamic>;
        transcriptData = TranscriptData.fromJson(transcriptJsonData);
      } catch (e) {
        _handleError('자막 데이터 형식이 올바르지 않습니다.');
        return;
      }

      // 5. PDF 및 오디오 경로 설정
      final pdfPath =
          hiveLecture.slidePath ??
          'assets/lectures/$lectureId/${lectureId}_slides.pdf';

      final audioPath =
          hiveLecture.audioPaths?.isNotEmpty == true &&
              hiveLecture.audioPaths!.first != null
          ? hiveLecture.audioPaths!.first!
          : 'assets/lectures/$lectureId/lecture_with_slides.opus';

      // 6. Controller 초기화
      if (!mounted) {
        return;
      }

      try {
        await _controller.initialize(
          context,
          lectureId,
          transcriptData,
          pdfPath,
          audioPath,
        );
      } catch (e) {
        _handleError('플레이어 초기화에 실패했습니다.');
        return;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // 예상하지 못한 에러 처리
      _handleError('알 수 없는 오류가 발생했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: OrientationBuilder(
        builder: (_, orientation) {
          final isVertical = orientation == Orientation.portrait;
          if (isVertical) {
            return VerticalPlayerLayout(
              controller: _controller,
              onBack: () => Navigator.pop(context),
            );
          } else {
            return HorizontalPlayerLayout(
              controller: _controller,
              onBack: () => Navigator.pop(context),
            );
          }
        },
      ),
    );
  }
}
