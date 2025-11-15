import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';

import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/core/device_orientation_helper.dart';
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

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  late final PlayerController _controller;
  late final HiveManager _hiveManager;
  bool _isLoading = true;
  bool _wasPlayingBeforePause = false;
  late final bool _isTablet;

  @override
  void initState() {
    super.initState();

    // 앱 라이프사이클 옵저버 등록
    WidgetsBinding.instance.addObserver(this);

    // 의존성 주입
    final audioService = widget._audioService ?? AudioService();
    final pdfCacheService = widget._pdfCacheService ?? PdfCacheService();
    _hiveManager = widget._hiveManager ?? HiveManager.instance;

    _controller = PlayerController(
      audioService: audioService,
      pdfCacheService: pdfCacheService,
    );

    // 프레임이 빌드된 이후에 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // 태블릿 여부 캐시 (dispose에서 사용)
        _isTablet = isTabletDevice(context);

        // 태블릿일 때만 방향 고정 (자유 회전 허용)
        // 폰일 때는 기본 세로 상태 유지 (toggleFullscreen으로 전환)
        if (_isTablet) {
          lockToCurrentOrientation(context);
        }

        _loadLectureData();
      }
    });
  }

  @override
  void dispose() {
    // 앱 라이프사이클 옵저버 제거
    WidgetsBinding.instance.removeObserver(this);

    // 오디오 및 리소스 정리 (가장 중요!)
    _controller.dispose();

    // 폰에서 PlayerScreen을 나갈 때 세로 모드로 복원
    if (!_isTablet) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 앱이 백그라운드로 가면 자동으로 일시정지
    if (state == AppLifecycleState.paused) {
      _wasPlayingBeforePause = _controller.isPlaying.value;
      if (_wasPlayingBeforePause) {
        _controller.playPause();
      }
    }
    // 앱이 다시 포그라운드로 돌아오면 자동으로 재개
    else if (state == AppLifecycleState.resumed) {
      if (_wasPlayingBeforePause) {
        _controller.playPause();
        _wasPlayingBeforePause = false;
      }
    }
  }

  /// 에러 발생 시 SnackBar를 표시하고 이전 페이지로 돌아가기
  void _handleError(String message) {
    if (!mounted) {
      return;
    }

    // 로딩 상태 종료
    setState(() {
      _isLoading = false;
    });

    // ScaffoldMessenger가 준비된 후에 실행되도록 보장
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

      // SnackBar가 화면에 렌더링된 후 이전 페이지로 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    });
  }

  Future<void> _loadLectureData() async {
    try {
      // 1. lectureId 검증
      final map = (widget.args is Map) ? widget.args as Map : const {};
      final lectureId = map['lectureId'] as String?;

      if (lectureId == null || lectureId.isEmpty) {
        if (!mounted) {
          return;
        }
        final l10n = AppLocalizations.of(context);
        _handleError(l10n.lectureIdMissing);
        return;
      }

      // 2. Hive에서 강의 데이터 검증
      final hiveLecture = _hiveManager.getLecture(lectureId);

      if (hiveLecture == null) {
        if (!mounted) {
          return;
        }
        final l10n = AppLocalizations.of(context);
        _handleError(l10n.lectureNotFound);
        return;
      }

      // Load lecture from Hive and store Korean status
      final isKoreanLecture = hiveLecture.langCode == 'ko';

      // transcript.json 로드 (HiveLecture에서 경로 가져오기)
      final transcriptPath =
          hiveLecture.jsonPath ?? 'assets/lectures/$lectureId/transcript.json';

      String? transcriptJson;
      try {
        transcriptJson = transcriptPath.startsWith('assets/')
            ? await rootBundle.loadString(transcriptPath)
            : await File(transcriptPath).readAsString();
      } catch (e) {
        if (!mounted) {
          return;
        }
        final l10n = AppLocalizations.of(context);
        _handleError(l10n.failedToLoadTranscript);
        return;
      }

      // 4. JSON 파싱
      TranscriptData? transcriptData;
      try {
        final transcriptJsonData = json.decode(transcriptJson);
        transcriptData = TranscriptData.fromJson(transcriptJsonData);
      } catch (e) {
        if (!mounted) {
          return;
        }
        debugPrint(e.toString());
        final l10n = AppLocalizations.of(context);
        _handleError(l10n.invalidTranscriptFormat);
        return;
      }

      // 5. PDF 및 오디오 경로 설정
      final pdfPath =
          hiveLecture.slidePath ??
          'assets/lectures/$lectureId/${lectureId}_slides.pdf';

      final originalAudioPath = hiveLecture.originalAudioPath;

      final ttsAudioPath = isKoreanLecture
          ? hiveLecture.originalAudioPath
          : hiveLecture.ttsAudioPath;

      debugPrint('$isKoreanLecture $originalAudioPath, $ttsAudioPath');

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
          ttsAudioPath,
          originalAudioPath,
          isKoreanLecture,
        );
      } catch (e) {
        if (!mounted) {
          return;
        }
        final l10n = AppLocalizations.of(context);
        _handleError(l10n.failedToInitializePlayer);
        return;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // OrientationBuilder와 PdfView가 완전히 mount된 후 재생 시작
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _controller.startPlayback();
          }
        });
      }
    } catch (e) {
      // 예상하지 못한 에러 처리
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context);
      _handleError(l10n.unknownError);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final highContrast = _hiveManager.settings.accessibilityHighContrast;

    final playerContent = Container(
      color: Colors.black,
      child: SafeArea(
        child: isTabletDevice(context)
            ? OrientationBuilder(
                builder: (context, orientation) {
                  if (orientation == Orientation.landscape) {
                    return HorizontalPlayerLayout(
                      controller: _controller,
                      onBack: () => Navigator.pop(context),
                    );
                  } else {
                    return VerticalPlayerLayout(
                      controller: _controller,
                      onBack: () => Navigator.pop(context),
                    );
                  }
                },
              )
            : ValueListenableBuilder<bool>(
                valueListenable: _controller.isFullscreen,
                builder: (_, isFullscreen, __) {
                  if (isFullscreen) {
                    return HorizontalPlayerLayout(
                      controller: _controller,
                      onBack: () => Navigator.pop(context),
                    );
                  } else {
                    return VerticalPlayerLayout(
                      controller: _controller,
                      onBack: () => Navigator.pop(context),
                    );
                  }
                },
              ),
      ),
    );

    return Scaffold(
      body: highContrast
          ? ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                // 대비 증가 (색상 반전 없음)
                // contrast = 1.8, offset = 128 * (1 - 1.8) = -102.4
                1.8, 0, 0, 0, -102.4, // Red 채널
                0, 1.8, 0, 0, -102.4, // Green 채널
                0, 0, 1.8, 0, -102.4, // Blue 채널
                0, 0, 0, 1, 0, // Alpha 채널 (투명도 유지)
              ]),
              child: playerContent,
            )
          : playerContent,
    );
  }
}
