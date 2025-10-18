import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:convert';
import 'dart:async';
import 'package:scroll_to_index/scroll_to_index.dart';

import 'package:re_view/features/player/player_widgets.dart';
import 'package:re_view/features/player/models/lecture_data.dart';
import 'package:re_view/features/player/services/audio_service.dart';
import 'package:re_view/features/player/core/pdf_cache_service.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, this.args});

  final Object? args;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _showControls = false;
  bool _isPagesExpanded = false;
  bool _isPlaying = false;
  bool _isSynced = true;
  bool _isCaptionEnabled = false;
  bool _showTranscriptPanel = false; // 가로 모드에서 우측 패널 표시 여부

  // 오디오 및 데이터 관련
  final AudioService _audioService = AudioService();
  LectureMetadata? _lectureMetadata;
  TranscriptData? _transcriptData;
  double _currentTime = 0.0;
  double _totalTime = 0.0;
  int? _currentSentenceIndex;

  // PDF 관련
  PdfController? _pdfController;
  PdfDocument? _pdfDocument;
  int _currentPage = 1;

  // PDF 페이지 이미지 캐싱 서비스
  final PdfCacheService _pdfCacheService = PdfCacheService();

  // Transcript 스크롤 관련
  late AutoScrollController _transcriptScrollController;
  bool _isAutoScrolling = true;
  Timer? _scrollTimer;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _transcriptScrollController = AutoScrollController(
      viewportBoundaryGetter: () =>
          Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).size.height / 2),
      axis: Axis.vertical,
    );
    _loadLectureData();
    _setupAudioListeners();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _audioService.dispose();
    _pdfController?.dispose();
    _transcriptScrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _transcriptScrollController.addListener(() {
      // 사용자가 스크롤 중임을 표시 (자동 스크롤 비활성화)
      if (_isAutoScrolling) {
        if (mounted) {
          setState(() {
            _isAutoScrolling = false;
          });
        }
      }

      // 기존 타이머 취소
      _scrollTimer?.cancel();

      // 1초 후에 자동 스크롤 재개
      _scrollTimer = Timer(const Duration(milliseconds: 1000), () {
        if (!_isAutoScrolling) {
          if (mounted) {
            setState(() {
              _isAutoScrolling = true;
            });
          }
        }

        // 영상이 재생 중일 때만 스크롤
        if (_isPlaying) {
          _scrollToCurrentSentence();
        }
      });
    });
  }

  Future<void> _loadLectureData() async {
    try {
      // lectureId 가져오기
      final map = (widget.args is Map) ? widget.args as Map : const {};
      final lectureId = map['lectureId'] ?? 'lec_demo_001';

      // meta.json 로드
      final metaJson = await rootBundle.loadString(
        'assets/lectures/$lectureId/meta.json',
      );

      try {
        final metaData = json.decode(metaJson) as Map<String, dynamic>;
        _lectureMetadata = LectureMetadata.fromJson(metaData);
      } catch (e) {
        throw FormatException('Invalid metadata format');
      }

      // transcript.json 로드
      final transcriptJson = await rootBundle.loadString(
        'assets/lectures/$lectureId/transcript.json',
      );

      try {
        final transcriptJsonData =
            json.decode(transcriptJson) as Map<String, dynamic>;
        _transcriptData = TranscriptData.fromJson(transcriptJsonData);
      } catch (e) {
        throw FormatException('Invalid metadata format');
      }

      setState(() {
        _totalTime = _transcriptData!.metadata.totalDuration;
      });

      // PDF 문서 먼저 로드
      final pdfPath = 'assets/lectures/$lectureId/${lectureId}_slides.pdf';
      await _loadFullPdfDocument(pdfPath);

      setState(() {
        _isLoading = false;
      });

      // 오디오 파일 로드 및 자동 재생
      await _audioService.loadAudio(
        'lectures/$lectureId/lecture_with_slides.opus',
      );

      await _audioService.play();

      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupAudioListeners() {
    // 재생 위치 변경 리스너
    _audioService.positionStream.listen((position) {
      _currentTime = position.inMilliseconds / 1000.0;
      _updateCurrentSentence();
    });

    // 재생 상태 변경 리스너
    _audioService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  void _updateCurrentSentence() {
    if (_transcriptData == null || !mounted) {
      return;
    }

    for (int i = 0; i < _transcriptData!.timestamps.length; i++) {
      final sentence = _transcriptData!.timestamps[i];
      if (_currentTime >= sentence.startTime &&
          _currentTime < sentence.endTime) {
        if (_currentSentenceIndex != i) {
          // 모든 상태 변경을 하나의 setState로 통합
          final shouldUpdatePage = _isSynced && _currentPage != sentence.slideNumber;

          setState(() {
            _currentSentenceIndex = i;
            if (shouldUpdatePage) {
              _currentPage = sentence.slideNumber;
            }
          });

          // setState 밖에서 실행
          if (shouldUpdatePage) {
            _pdfController?.jumpToPage(sentence.slideNumber);
          }

          // 사용자가 스크롤 중이 아니고, 영상이 재생 중일 때만 자동으로 스크롤
          if (_isAutoScrolling && _isPlaying) {
            _scrollToCurrentSentence();
          }
        }
        return;
      }
    }
  }

  // Sync되었을 때의 페이지 번호를 반환 (현재 오디오 시간 기준)
  int? _getSyncedPageNumber() {
    if (_transcriptData == null || _currentSentenceIndex == null) {
      return null;
    }
    return _transcriptData!.timestamps[_currentSentenceIndex!].slideNumber;
  }

  // 페이지 차이를 계산 (syncedPage - currentPage)
  int? _getPageDifference() {
    final syncedPage = _getSyncedPageNumber();
    if (syncedPage == null) {
      return null;
    }
    return syncedPage - _currentPage;
  }

  // 전체 PDF 문서 로드
  Future<void> _loadFullPdfDocument(String pdfPath) async {
    try {
      // 전체 PDF 문서 로드
      _pdfDocument = await PdfDocument.openAsset(pdfPath);
      _pdfCacheService.setPdfDocument(_pdfDocument);

      if (mounted) {
        final controller = PdfController(
          document: Future.value(_pdfDocument!),
        );

        setState(() {
          _pdfController = controller;
        });
      }
    } catch (e) {
      //print('Error loading PDF document: $e');
    }
  }

  // 슬라이드 리스트 스크롤 시 호출되는 핸들러
  void _handleSlidesListScroll(int visibleEndPage) {
    // 스크롤 시 자동 캐싱을 하지 않음 - 보수적으로 접근
    // FutureBuilder가 필요한 페이지만 요청하도록 함
  }

  Future<void> _scrollToCurrentSentence() async {
    if (_currentSentenceIndex == null || _transcriptData == null) {
      return;
    }

    if (!_transcriptScrollController.hasClients) {
      return;
    }

    // 영상이 재생 중이 아니면 스크롤하지 않음
    if (!_isPlaying) {
      return;
    }

    // AutoScrollController를 사용하여 자동 스크롤 (빠른 애니메이션)
    await _transcriptScrollController.scrollToIndex(
      _currentSentenceIndex!,
      preferPosition: AutoScrollPosition.middle,
      duration: const Duration(milliseconds: 150),
    );
  }

  void _seekToSentence(int index) {
    if (_transcriptData == null) {
      return;
    }
    final sentence = _transcriptData!.timestamps[index];
    _audioService.seek(
      Duration(milliseconds: (sentence.startTime * 1000).toInt()),
    );
  }

  void _seekToSlide(int slideNumber) {
    if (_transcriptData == null) {
      return;
    }

    // 해당 슬라이드 번호가 처음 나오는 transcript 찾기
    for (int i = 0; i < _transcriptData!.timestamps.length; i++) {
      final sentence = _transcriptData!.timestamps[i];
      if (sentence.slideNumber == slideNumber) {
        // 오디오를 해당 시간으로 이동
        _audioService
            .seek(Duration(milliseconds: (sentence.startTime * 1000).toInt()))
            .then((_) {
              if (!mounted) {
                return;
              }
              _scrollTimer?.cancel();

              // 사용자 스크롤 상태 해제하여 자동 스크롤 활성화
              setState(() {
                _isAutoScrolling = true;
                _currentSentenceIndex = i; // 현재 문장 인덱스 업데이트
              });
              _scrollToCurrentSentence();
            });

        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: OrientationBuilder(
        builder: (_, o) {
          final isPortrait = o == Orientation.portrait;
          return isPortrait ? _buildVerticalLayout() : _buildHorizontalLayout();
        },
      ),
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      children: [
        // PDF 영역 (16:9 비율)
        _buildPdfArea(),

        // 페이지 펼치기 버튼
        _buildExpandButton(),

        // 펼쳐지는 페이지 목록
        if (_isPagesExpanded) _buildPagesList(),

        // Transcript 영역
        Expanded(child: _buildTranscriptArea()),
      ],
    );
  }

  Widget _buildPdfArea() {
    final screenWidth = MediaQuery.of(context).size.width;
    final pdfHeight = screenWidth * 9 / 16; // 16:9 비율

    return SizedBox(
      width: screenWidth,
      height: pdfHeight,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            // PDF 내용 영역
            if (_pdfController != null)
              PdfView(
                controller: _pdfController!,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });

                  // 페이지 변경 시 캐싱은 FutureBuilder에서 필요할 때만 수행됨
                  // 여기서는 명시적으로 캐싱하지 않음 (보수적 접근)
                },
              )
            else
              // 로딩 중
              Container(
                color: Colors.black87,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),

            // 비디오 컨트롤 오버레이
            if (_showControls) _buildVideoControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    return Container(
      color: const Color(0x4D1D1D1D), // rgba(29, 29, 29, 0.3)
      child: Column(
        children: [
          // 상단 컨트롤 바
          TopControlBarPortrait(
            onBack: () => Navigator.pop(context),
            isSynced: _isSynced,
            onSyncToggle: () => setState(() => _isSynced = !_isSynced),
            pageDifference: _getPageDifference(),
          ),

          const Spacer(),

          // 중앙 재생 컨트롤
          CenterPlayControls(
            isPlaying: _isPlaying,
            onPlayPause: () {
              if (_isPlaying) {
                _audioService.pause();
              } else {
                _audioService.play();
              }
            },
            onSkipBackward: () {
              final newTime = (_currentTime - 15).clamp(0, _totalTime);
              _audioService.seek(
                Duration(milliseconds: (newTime * 1000).toInt()),
              );
            },
            onSkipForward: () {
              final newTime = (_currentTime + 15).clamp(0, _totalTime);
              _audioService.seek(
                Duration(milliseconds: (newTime * 1000).toInt()),
              );
            },
          ),

          const Spacer(),

          // 하단 타임라인 슬라이더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: VideoTimelineSlider(
              currentTime: _currentTime,
              totalTime: _totalTime,
              onChanged: (value) {
                // 슬라이더를 움직일 때 사용자 스크롤 상태 해제
                setState(() {
                  _isAutoScrolling = true;
                });
                _scrollTimer?.cancel();
                _audioService.seek(
                  Duration(milliseconds: (value * 1000).toInt()),
                );

                // 약간의 딜레이 후 스크롤 (seek가 완료되고 _currentSentenceIndex가 업데이트될 때까지 대기)
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (_isAutoScrolling) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToCurrentSentence();
                    });
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPagesExpanded = !_isPagesExpanded;
        });
      },
      child: Container(
        width: double.infinity,
        height: 40,
        color: const Color(0xFFF5F5F5),
        child: Center(
          child: Icon(
            _isPagesExpanded
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            color: Colors.grey[700],
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildPagesList() {
    final pageCount = _lectureMetadata?.slides ?? 10;

    return Container(
      height: 150,
      color: const Color(0xFFEEEEEE),
      child: PdfSlidesList(
        pageCount: pageCount,
        currentPage: _currentPage,
        itemWidth: 180,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        getCachedOrRenderPage: _pdfCacheService.getCachedOrRenderPage,
        getCachedImage: _pdfCacheService.getCachedImageDirect,
        onPageTap: (pageNumber) {
          _pdfController?.jumpToPage(pageNumber);
          setState(() {
            _currentPage = pageNumber;
          });
          // 캐시되지 않은 페이지라면 즉시 캐싱 시작 (동시 렌더링 제한 준수)
          if (_pdfCacheService.getCachedImageDirect(pageNumber) == null) {
            _pdfCacheService.getCachedOrRenderPage(pageNumber);
          }
          // 해당 슬라이드 번호가 처음 나오는 transcript 찾기
          _seekToSlide(pageNumber);
        },
        onScroll: _handleSlidesListScroll, // 스크롤 시 자동 캐싱
      ),
    );
  }

  Widget _buildTranscriptArea() {
    if (_transcriptData == null) {
      return Container(
        width: double.infinity,
        color: const Color(0xFFFAFAFA),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: double.infinity,
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transcript',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              controller: _transcriptScrollController,
              itemCount: _transcriptData!.timestamps.length,
              itemBuilder: (context, index) {
                final sentence = _transcriptData!.timestamps[index];
                final isCurrentSentence = _currentSentenceIndex == index;

                return AutoScrollTag(
                  key: ValueKey(index),
                  controller: _transcriptScrollController,
                  index: index,
                  child: GestureDetector(
                    onTap: () => _seekToSentence(index),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        sentence.text,
                        style: TextStyle(
                          fontSize: isCurrentSentence ? 18 : 14,
                          fontWeight: isCurrentSentence
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrentSentence
                              ? Colors.black
                              : Colors.grey[600],
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final transcriptPanelWidth = screenWidth * 0.3;

    return Row(
      children: [
        // 메인 비디오 영역
        Expanded(
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              // 위로 스와이프 감지 (delta.dy < 0)
              if (details.delta.dy < -5 && !_isPagesExpanded) {
                setState(() {
                  _isPagesExpanded = true;
                });
              }
            },
            onTap: () {
              setState(() {
                if (_isPagesExpanded) {
                  // 페이지가 펼쳐진 상태에서 클릭하면 모두 닫기
                  _isPagesExpanded = false;
                } else {
                  // 컨트롤 토글
                  _showControls = !_showControls;
                }
              });
            },
            child: Stack(
              children: [
                // PDF 내용 영역
                if (_pdfController != null)
                  PdfView(
                    controller: _pdfController!,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });

                      // 페이지 변경 시 캐싱은 FutureBuilder에서 필요할 때만 수행됨
                      // 여기서는 명시적으로 캐싱하지 않음 (보수적 접근)
                    },
                  )
                else
                  // 로딩 중
                  Container(
                    color: Colors.black87,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),

                // 자막 표시 (자막 기능이 켜져 있을 때만)
                if (_isCaptionEnabled && !_showTranscriptPanel)
                  _buildCaptionOverlay(),

                // 비디오 컨트롤 오버레이
                if (_showControls && !_isPagesExpanded)
                  _buildHorizontalVideoControls(),

                // 하단 슬라이드 토글 바
                if (_isPagesExpanded)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildHorizontalToggleBar(),
                  ),

                // 슬라이드가 펼쳐졌을 때 우상단 싱크 버튼
                if (_isPagesExpanded)
                  Positioned(
                    top: 12,
                    right: 16,
                    child: SyncButton(
                      isSynced: _isSynced,
                      onPressed: () => setState(() => _isSynced = !_isSynced),
                      pageDifference: _getPageDifference(),
                    ),
                  ),

                // 우측 화살표 버튼 (Transcript 패널 토글)
                if (!_showTranscriptPanel)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showTranscriptPanel = true;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 우측 Transcript 패널
        if (_showTranscriptPanel)
          Container(
            width: transcriptPanelWidth,
            color: const Color(0xFFFAFAFA),
            child: Stack(
              children: [
                // Transcript 내용
                _buildTranscriptArea(),

                // 닫기 버튼 (좌측 화살표)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showTranscriptPanel = false;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHorizontalVideoControls() {
    return Container(
      color: const Color(0x4D1D1D1D), // rgba(29, 29, 29, 0.3)
      child: Column(
        children: [
          // 상단 컨트롤 바
          TopControlBarLandscape(
            onBack: () => Navigator.pop(context),
            isCaptionEnabled: _isCaptionEnabled,
            onCaptionToggle: () =>
                setState(() => _isCaptionEnabled = !_isCaptionEnabled),
            isSynced: _isSynced,
            onSyncToggle: () => setState(() => _isSynced = !_isSynced),
            pageDifference: _getPageDifference(),
          ),

          const Spacer(),

          // 중앙 재생 컨트롤
          CenterPlayControls(
            isPlaying: _isPlaying,
            onPlayPause: () {
              if (_isPlaying) {
                _audioService.pause();
              } else {
                _audioService.play();
              }
            },
            onSkipBackward: () {
              final newTime = (_currentTime - 15).clamp(0, _totalTime);
              _audioService.seek(
                Duration(milliseconds: (newTime * 1000).toInt()),
              );
            },
            onSkipForward: () {
              final newTime = (_currentTime + 15).clamp(0, _totalTime);
              _audioService.seek(
                Duration(milliseconds: (newTime * 1000).toInt()),
              );
            },
          ),

          const Spacer(),

          // 하단 타임라인 슬라이더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: VideoTimelineSlider(
              currentTime: _currentTime,
              totalTime: _totalTime,
              onChanged: (value) {
                // 슬라이더를 움직일 때 사용자 스크롤 상태 해제
                setState(() {
                  _isAutoScrolling = true;
                });
                _scrollTimer?.cancel();
                _audioService.seek(
                  Duration(milliseconds: (value * 1000).toInt()),
                );

                // 약간의 딜레이 후 스크롤 (seek가 완료되고 _currentSentenceIndex가 업데이트될 때까지 대기)
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (_isAutoScrolling) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToCurrentSentence();
                    });
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalToggleBar() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          // 토글 버튼
          GestureDetector(
            onTap: () {
              setState(() {
                _isPagesExpanded = false;
              });
            },
            child: Container(
              height: 40,
              color: Colors.transparent,
              child: Center(
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          // 슬라이드 목록
          Expanded(
            child: PdfSlidesList(
              pageCount: _lectureMetadata?.slides ?? 10,
              currentPage: _currentPage,
              itemWidth: 150,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              getCachedOrRenderPage: _pdfCacheService.getCachedOrRenderPage,
              getCachedImage: _pdfCacheService.getCachedImageDirect,
              onPageTap: (pageNumber) {
                _pdfController?.jumpToPage(pageNumber);
                setState(() {
                  _currentPage = pageNumber;
                });
                // 캐시되지 않은 페이지라면 즉시 캐싱 시작 (동시 렌더링 제한 준수)
                if (_pdfCacheService.getCachedImageDirect(pageNumber) == null) {
                  _pdfCacheService.getCachedOrRenderPage(pageNumber);
                }
                // 해당 슬라이드 번호가 처음 나오는 transcript 찾기
                _seekToSlide(pageNumber);
              },
              onScroll: _handleSlidesListScroll, // 스크롤 시 자동 캐싱
            ),
          ),
        ],
      ),
    );
  }

  // 자막 오버레이 위젯
  Widget _buildCaptionOverlay() {
    // 현재 재생 중인 문장 텍스트 가져오기
    String captionText = '';
    if (_currentSentenceIndex != null && _transcriptData != null) {
      captionText = _transcriptData!.timestamps[_currentSentenceIndex!].text;
    }

    // 텍스트가 없으면 아무것도 표시하지 않음
    if (captionText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: _showControls ? 80 : 20, // 컨트롤이 표시되면 스크롤바 위로 이동
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            captionText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
