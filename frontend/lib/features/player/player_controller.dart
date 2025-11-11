import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import 'package:re_view/core/thumbnail_cache_manager.dart';
import 'package:re_view/features/player/models/lecture_data.dart';
import 'package:re_view/features/player/services/audio_service.dart';
import 'package:re_view/features/player/services/pdf_cache_service.dart';

/// PlayerController: 플레이어의 모든 상태와 로직을 관리
/// ValueNotifier를 사용하여 각 상태 변경시 필요한 위젯만 rebuild
class PlayerController extends ChangeNotifier {
  PlayerController({
    required AudioService audioService,
    required PdfCacheService pdfCacheService,
  }) : _audioService = audioService,
       _pdfCacheService = pdfCacheService;

  final AudioService _audioService;
  final PdfCacheService _pdfCacheService;

  // ========== ValueNotifier로 관리되는 상태들 (자주 변경됨) ==========

  /// UI 제어 상태
  final ValueNotifier<bool> showControls = ValueNotifier(false);
  final ValueNotifier<bool> isPagesExpanded = ValueNotifier(false);
  final ValueNotifier<bool> showTranscriptPanel = ValueNotifier(false);
  final ValueNotifier<bool> isFullscreen = ValueNotifier(false);

  /// 재생 상태
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<bool> isSynced = ValueNotifier(true);
  final ValueNotifier<bool> isCaptionEnabled = ValueNotifier(false);
  final ValueNotifier<bool> isKoreanLanguage = ValueNotifier(false);
  final ValueNotifier<bool> isOriginalAudio = ValueNotifier(false);

  /// 재생 위치 및 페이지
  final ValueNotifier<double> currentTime = ValueNotifier(0.0);
  final ValueNotifier<int> currentPage = ValueNotifier(1);
  final ValueNotifier<int?> currentSentenceIndex = ValueNotifier(null);

  /// 스크롤 제어
  final ValueNotifier<bool> isAutoScrolling = ValueNotifier(true);

  // ========== 불변 또는 거의 변하지 않는 데이터 ==========

  PdfController? pdfController;
  PdfDocument? pdfDocument;
  TranscriptData? transcriptData;
  double ttsTotalDuration = 0.0;
  double originalTotalDuration = 0.0;
  AutoScrollController? transcriptScrollController;
  double? pdfAspectRatio; // PDF 페이지의 가로/세로 비율 (width/height)

  // PDF 뷰와 Transcript의 상태를 유지하기 위한 GlobalKey
  final GlobalKey pdfViewKey = GlobalKey();
  final GlobalKey transcriptAreaKey = GlobalKey();

  PdfCacheService get pdfCacheService => _pdfCacheService;
  int get pageCount => pdfDocument?.pagesCount ?? 0;

  // ========== 계산된 값 ==========

  /// Sync되었을 때의 페이지 번호 (현재 오디오 시간 기준)
  int? get syncedPageNumber {
    if (transcriptData == null || currentSentenceIndex.value == null) {
      return null;
    }
    return transcriptData!.timestamps[currentSentenceIndex.value!].slideNumber;
  }

  /// 페이지 차이 (syncedPage - currentPage)
  int? get pageDifference {
    final syncedPage = syncedPageNumber;
    if (syncedPage == null) {
      return null;
    }
    return syncedPage - currentPage.value;
  }

  /// 현재 자막 텍스트
  String get captionText {
    if (currentSentenceIndex.value == null || transcriptData == null) {
      return '';
    }
    final sentence = transcriptData!.timestamps[currentSentenceIndex.value!];
    if (isKoreanLanguage.value && sentence.textKor != null) {
      return sentence.textKor!;
    }
    return sentence.textEng;
  }

  /// 한국어 transcript가 있는지 확인
  bool get hasKoreanTranscript {
    if (transcriptData == null || transcriptData!.timestamps.isEmpty) {
      return false;
    }
    return transcriptData!.timestamps.any(
      (sentence) => sentence.textKor != null,
    );
  }

  // ========== 내부 상태 ==========

  bool _isForcedMove = false; // seek 등으로 강제 이동 중인지 표시
  bool _isSeeking = false; // seek 작업 진행 중인지 표시
  bool _isDisposed = false; // dispose 여부 확인
  Timer? _scrollTimer;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<dynamic>? _stateSubscription;

  // 오디오 경로 저장
  String? _originalAudioPath;
  String? _audioPath;

  // 현재 sentence의 타이밍 정보 추적
  int _currentOriginalStartTime = 0;
  int _currentStartTime = 0;

  // 더블탭 위치 저장
  double _doubleTapX = 0;

  // ========== 초기화 메서드 ==========

  Future<void> initialize(
    BuildContext context,
    String lectureId,
    TranscriptData transcriptData,
    String pdfPath,
    String audioPath,
    String originalAudioPath,
  ) async {
    this.transcriptData = transcriptData;
    ttsTotalDuration = transcriptData.ttsTotalDuration.toDouble() / 1000;
    originalTotalDuration = transcriptData.originalTotalDuration.toDouble() / 1000;

    // 오디오 경로 저장
    _audioPath = audioPath;
    _originalAudioPath = originalAudioPath;

    // Transcript 스크롤 컨트롤러 초기화
    final screenHeight = MediaQuery.of(context).size.height;
    transcriptScrollController = AutoScrollController(
      viewportBoundaryGetter: () => Rect.fromLTRB(0, 0, 0, screenHeight / 2),
      axis: Axis.vertical,
    );

    // PDF 문서 로드 (transcript의 첫 슬라이드를 초기 페이지로 설정)
    final initialPage = transcriptData.timestamps[0].slideNumber;
    await _loadPdfDocument(pdfPath, lectureId, initialPage);

    // 오디오 리스너 설정
    _setupAudioListeners();

    // 스크롤 리스너 설정
    _setupScrollListener();

    // 오디오 로드 (재생은 외부에서 startPlayback() 호출)
    await _audioService.loadAudio(audioPath);
  }

  Future<void> _loadPdfDocument(
    String pdfPath,
    String lectureId,
    int initialPage,
  ) async {
    pdfDocument = pdfPath.startsWith('assets/')
        ? await PdfDocument.openAsset(pdfPath)
        : await PdfDocument.openFile(pdfPath);

    _pdfCacheService.setPdfDocument(pdfDocument);

    // Pre-populate first page from ThumbnailCacheManager if available
    final thumbnailCache = ThumbnailCacheManager.instance;
    final cachedThumbnail = thumbnailCache.get(lectureId);

    if (cachedThumbnail != null) {
      _pdfCacheService.setCachedImage(1, cachedThumbnail.image.bytes);
      pdfAspectRatio = cachedThumbnail.aspectRatio;
      debugPrint(
        '✅ First page pre-loaded from thumbnail cache for $lectureId (aspect ratio: $pdfAspectRatio)',
      );
    }

    // PdfController 생성 시 초기 페이지 설정
    pdfController = PdfController(
      document: Future.value(pdfDocument!),
      initialPage: initialPage,
    );

    // currentPage도 초기 페이지로 설정
    currentPage.value = initialPage;
  }

  void _setupAudioListeners() {
    // 재생 위치 변경 리스너
    _positionSubscription = _audioService.positionStream.listen((position) {
      currentTime.value = position.inMilliseconds / 1000.0;
      updateCurrentSentence(true, currentTime.value);
    });

    // 재생 상태 변경 리스너
    _stateSubscription = _audioService.stateStream.listen((state) {
      isPlaying.value = state.playing;
    });
  }

  void _setupScrollListener() {
    transcriptScrollController?.addListener(() {
      // 사용자가 스크롤 중임을 표시 (자동 스크롤 비활성화)
      if (isAutoScrolling.value) {
        isAutoScrolling.value = false;
      }

      // 기존 타이머 취소
      _scrollTimer?.cancel();

      // 1초 후에 자동 스크롤 재개
      _scrollTimer = Timer(const Duration(milliseconds: 1000), () {
        if (!isAutoScrolling.value) {
          isAutoScrolling.value = true;
        }

        // 영상이 재생 중일 때만 스크롤
        if (isPlaying.value) {
          scrollToCurrentSentence();
        }
      });
    });
  }

  // ========== UI 제어 메서드 ==========

  void toggleControls() {
    showControls.value = !showControls.value;
  }

  void togglePages() {
    isPagesExpanded.value = !isPagesExpanded.value;
  }

  void toggleSync() {
    isSynced.value = !isSynced.value;
  }

  void toggleCaption() {
    isCaptionEnabled.value = !isCaptionEnabled.value;
  }

  void toggleTranscriptPanel() {
    showTranscriptPanel.value = !showTranscriptPanel.value;
  }

  void toggleTranscriptLanguage() {
    if (hasKoreanTranscript) {
      isKoreanLanguage.value = !isKoreanLanguage.value;
    }
  }

  Future<void> toggleFullscreen() async {
    final willBeFullscreen = !isFullscreen.value;

    // 방향을 먼저 설정한 후 상태 변경
    if (willBeFullscreen) {
      // 가로모드 강제
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // 세로모드 강제
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    // 방향 설정이 완료된 후 상태 변경
    isFullscreen.value = willBeFullscreen;
  }

  /// 오디오 소스 전환 (Original ↔ TTS)
  Future<void> toggleAudioSource() async {
    if (_originalAudioPath == null || _audioPath == null) {
      return; // 오디오 경로가 설정되지 않음
    }

    // 강제 이동 플래그 설정 (sentence 업데이트 방지)
    _isForcedMove = true;

    // 상태 전환
    isOriginalAudio.value = !isOriginalAudio.value;

    // 반대쪽 오디오의 같은 sentence 시작 위치로 이동
    final newTimeMs = isOriginalAudio.value
        ? _currentOriginalStartTime
        : _currentStartTime;

    // 오디오 전환
    final newPath = isOriginalAudio.value ? _originalAudioPath! : _audioPath!;
    await _audioService.switchAudio(newPath, newTimeMs);

    // 강제 이동 플래그 해제
    Future.delayed(const Duration(milliseconds: 500), () {
      _isForcedMove = false;
    });
  }

  void handlePdfTap(bool isVertical) {
    if (isPagesExpanded.value && !isVertical) {
      // 가로 모드에서 페이지가 펼쳐진 상태에서 클릭하면 모두 닫기
      isPagesExpanded.value = false;
    } else {
      // 컨트롤 토글
      toggleControls();
    }
  }

  void saveDoubleTapPosition(double x) {
    _doubleTapX = x;
  }

  void handleDoubleTapSkip(double screenWidth) {
    if (_doubleTapX < screenWidth / 2) {
      skipBackward();
    } else {
      skipForward();
    }
  }

  void handleVerticalDrag(DragUpdateDetails details) {
    // 가로 모드에서만 위로 스와이프 감지
    if (details.delta.dy < -5 && !isPagesExpanded.value) {
      isPagesExpanded.value = true;
    }
  }

  // ========== 재생 제어 메서드 ==========

  /// 초기 재생 시작 (OrientationBuilder가 안정화된 후 호출)
  Future<void> startPlayback() async {
    await _audioService.play();
  }

  Future<void> playPause() async {
    if (isPlaying.value) {
      await _audioService.pause();
    } else {
      await _audioService.play();

      // 재생 시작 시 현재 위치로 스크롤하여 tracking 시작
      if (isAutoScrolling.value && currentSentenceIndex.value != null) {
        Future.delayed(const Duration(milliseconds: 100), () {
          scrollToCurrentSentence(forceScroll: true);
        });
      }
    }
  }

  Future<void> seek(double seconds) async {
    // 이미 seek 작업이 진행 중이면 무시
    if (_isSeeking) {
      return;
    }

    _isSeeking = true;
    _isForcedMove = true;
    isAutoScrolling.value = true;
    _scrollTimer?.cancel();

    try {
      await _audioService.seek(
        Duration(milliseconds: (seconds * 1000).toInt()),
      );
    } catch (e) {
      // seek 작업 실패 시 무시
      _isSeeking = false;
      return;
    } finally {
      _isSeeking = false;
    }

    // 약간의 딜레이 후 스크롤
    Future.delayed(const Duration(milliseconds: 100), () {
      if (isAutoScrolling.value) {
        scrollToCurrentSentence();
      }
    });

    // _isForcedMove 해제
    Future.delayed(const Duration(milliseconds: 500), () {
      _isForcedMove = false;
    });
  }

  Future<void> skipBackward() async {
    final newTime = (currentTime.value - 10).clamp(0, isOriginalAudio.value ? originalTotalDuration : ttsTotalDuration).toDouble();
    await seek(newTime);
  }

  Future<void> skipForward() async {
    final newTime = (currentTime.value + 10).clamp(0, isOriginalAudio.value ? originalTotalDuration : ttsTotalDuration).toDouble();
    await seek(newTime);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _audioService.setSpeed(speed);
  }

  // ========== 페이지 제어 메서드 ==========

  void jumpToPage(int page) {
    pdfController?.jumpToPage(page);
    currentPage.value = page;
  }

  void onPdfPageChanged(int page) {
    currentPage.value = page;
  }

  // ========== Transcript 제어 메서드 ==========

  void updateCurrentSentence(bool isForced, double seconds) {
    if (transcriptData == null || (isForced && _isForcedMove)) {
      return;
    }

    for (int i = 0; i < transcriptData!.timestamps.length; i++) {
      final sentence = transcriptData!.timestamps[i];

      // 현재 오디오 모드에 따라 적절한 타이밍 사용
      final startTime = isOriginalAudio.value
          ? sentence.originalStartTime
          : sentence.ttsStartTime;
      final endTime = isOriginalAudio.value
          ? sentence.originalEndTime
          : sentence.ttsEndTime;

      if (seconds * 1000 >= startTime && seconds * 1000 < endTime + 0.2) {
        // 4개의 타이밍 모두 별도 변수에 저장
        _currentOriginalStartTime = sentence.originalStartTime;
        _currentStartTime = sentence.ttsStartTime;

        _setCurrentSentenceAndPage(i, autoScroll: isForced);
        return;
      }
    }
  }

  void _setCurrentSentenceAndPage(
    int sentenceIndex, {
    bool forcePageUpdate = false,
    bool autoScroll = true,
  }) {
    if (transcriptData == null ||
        sentenceIndex < 0 ||
        sentenceIndex >= transcriptData!.timestamps.length) {
      return;
    }

    final sentence = transcriptData!.timestamps[sentenceIndex];
    final targetPage = sentence.slideNumber;

    // 상태 변경이 필요한지 확인
    final sentenceChanged = currentSentenceIndex.value != sentenceIndex;
    final shouldUpdatePage =
        forcePageUpdate || (isSynced.value && currentPage.value != targetPage);

    if (!sentenceChanged && !shouldUpdatePage) {
      return; // 변경 사항 없음
    }

    // 상태 업데이트
    if (sentenceChanged) {
      currentSentenceIndex.value = sentenceIndex;
    }
    if (shouldUpdatePage) {
      currentPage.value = targetPage;
      pdfController?.jumpToPage(targetPage.toInt());
    }

    // Transcript 자동 스크롤
    if (autoScroll && isAutoScrolling.value && isPlaying.value) {
      scrollToCurrentSentence();
    }
  }

  Future<void> scrollToCurrentSentence({bool forceScroll = false}) async {
    if (currentSentenceIndex.value == null || transcriptData == null) {
      return;
    }

    if (transcriptScrollController?.hasClients != true) {
      return;
    }

    // 강제 스크롤이 아닐 때만 재생 상태를 체크
    if (!forceScroll && !isPlaying.value) {
      return;
    }

    // AutoScrollController를 사용하여 자동 스크롤
    await transcriptScrollController!.scrollToIndex(
      currentSentenceIndex.value!,
      preferPosition: AutoScrollPosition.middle,
      duration: const Duration(milliseconds: 150),
    );
  }

  Future<void> seekToSentence(int index) async {
    if (transcriptData == null ||
        index < 0 ||
        index >= transcriptData!.timestamps.length) {
      return;
    }

    final sentence = transcriptData!.timestamps[index];

    _isForcedMove = true;
    isAutoScrolling.value = true;

    await _audioService.seek(Duration(milliseconds: isOriginalAudio.value ? sentence.originalStartTime : sentence.ttsStartTime));

    _setCurrentSentenceAndPage(
      index,
      forcePageUpdate: isSynced.value,
      autoScroll: false, // 직접 스크롤을 호출할 것이므로 false
    );

    // 정지 상태에서도 스크롤이 되도록 강제 스크롤 호출
    await scrollToCurrentSentence(forceScroll: true);

    // 강제 이동 완료
    Future.delayed(const Duration(milliseconds: 500), () {
      _isForcedMove = false;
    });
  }

  Future<void> seekToSlide(int slideNumber) async {
    if (transcriptData == null) {
      return;
    }

    // sync가 꺼져있으면 슬라이드만 이동
    if (!isSynced.value) {
      jumpToPage(slideNumber);
      return;
    }

    // sync가 켜져있으면 해당 슬라이드 번호가 처음 나오는 transcript 찾아서 이동
    for (int i = 0; i < transcriptData!.timestamps.length; i++) {
      final sentence = transcriptData!.timestamps[i];
      if (sentence.slideNumber == slideNumber) {
        _isForcedMove = true;

        await _audioService.seek(Duration(milliseconds: isOriginalAudio.value ? sentence.originalStartTime : sentence.ttsStartTime));

        _scrollTimer?.cancel();
        isAutoScrolling.value = true;

        _setCurrentSentenceAndPage(i, forcePageUpdate: true, autoScroll: true);

        // 강제 이동 완료
        Future.delayed(const Duration(milliseconds: 500), () {
          _isForcedMove = false;
        });

        return;
      }
    }
  }

  // ========== Dispose ==========

  @override
  void dispose() {
    // 이미 dispose되었으면 중복 실행 방지
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;

    showControls.dispose();
    isPagesExpanded.dispose();
    showTranscriptPanel.dispose();
    isFullscreen.dispose();
    isPlaying.dispose();
    isSynced.dispose();
    isCaptionEnabled.dispose();
    isKoreanLanguage.dispose();
    isOriginalAudio.dispose();
    currentTime.dispose();
    currentPage.dispose();
    currentSentenceIndex.dispose();
    isAutoScrolling.dispose();

    _scrollTimer?.cancel();
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();

    _audioService.dispose();
    pdfController?.dispose();
    transcriptScrollController?.dispose();

    super.dispose();
  }
}
