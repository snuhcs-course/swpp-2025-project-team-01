import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import '../../core/utils.dart';
import 'player_widgets.dart';
import 'models/lecture_data.dart';
import 'services/audio_service.dart';

class PlayerScreen extends StatefulWidget {
  final Object? args;
  const PlayerScreen({super.key, this.args});

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

  // Transcript 스크롤 관련
  final ScrollController _transcriptScrollController = ScrollController();
  bool _isUserScrolling = false;
  bool _isAutoScrolling = false;
  Timer? _scrollTimer;
  final Map<int, GlobalKey> _sentenceKeys = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLectureData();
    _setupAudioListeners();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _audioService.dispose();
    _pdfController?.dispose();
    _transcriptScrollController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  void _setupScrollListener() {
    _transcriptScrollController.addListener(() {
      // 자동 스크롤 중이면 무시
      if (_isAutoScrolling) return;

      // 사용자가 스크롤 중임을 표시
      if (!_isUserScrolling) {
        if (mounted) {
          setState(() {
            _isUserScrolling = true;
          });
        }
      }

      // 기존 타이머 취소
      _scrollTimer?.cancel();

      // 0.5초 후에 자동 스크롤 재개
      _scrollTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isUserScrolling = false;
          });
        }
        // PostFrameCallback을 사용하여 다음 프레임에서 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCurrentSentence();
        });
      });
    });
  }

  Future<void> _loadLectureData() async {
    try {
      // lectureId 가져오기
      final map = (widget.args is Map) ? widget.args as Map : const {};
      final lectureId = map['lectureId'] ?? 'lec_demo_001';

      // meta.json 로드
      final metaJson = await rootBundle.loadString('assets/lectures/$lectureId/meta.json');
      final metaData = json.decode(metaJson);
      _lectureMetadata = LectureMetadata.fromJson(metaData);

      // transcript.json 로드
      final transcriptJson = await rootBundle.loadString('assets/lectures/$lectureId/transcript.json');
      final transcriptJsonData = json.decode(transcriptJson);
      _transcriptData = TranscriptData.fromJson(transcriptJsonData);

      // PDF 로드
      final pdfPath = 'assets/lectures/$lectureId/${lectureId}_slides.pdf';
      _pdfDocument = await PdfDocument.openAsset(pdfPath);
      _pdfController = PdfController(
        document: PdfDocument.openAsset(pdfPath),
      );

      setState(() {
        _totalTime = _transcriptData!.metadata.totalDuration;
        _isLoading = false;
      });

      // 오디오 파일 로드 및 자동 재생
      await _audioService.loadAudio('lectures/$lectureId/lecture_with_slides.opus');

      // 약간의 딜레이 후 재생 (오디오 로드 완료 대기)
      await Future.delayed(const Duration(milliseconds: 500));
      await _audioService.play();

      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      print('Error loading lecture data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupAudioListeners() {
    // 재생 위치 변경 리스너
    _audioService.positionStream.listen((position) {
      setState(() {
        _currentTime = position.inMilliseconds / 1000.0;
        _updateCurrentSentence();
      });
    });

    // 재생 상태 변경 리스너
    _audioService.stateStream.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
  }

  void _updateCurrentSentence() {
    if (_transcriptData == null) return;

    for (int i = 0; i < _transcriptData!.timestamps.length; i++) {
      final sentence = _transcriptData!.timestamps[i];
      if (_currentTime >= sentence.startTime && _currentTime < sentence.endTime) {
        if (_currentSentenceIndex != i) {
          setState(() {
            _currentSentenceIndex = i;
          });

          // 슬라이드 번호가 변경되었으면 PDF 페이지도 변경
          if (_currentPage != sentence.slideNumber) {
            _currentPage = sentence.slideNumber;
            _pdfController?.jumpToPage(sentence.slideNumber);
          }

          // 사용자가 스크롤 중이 아니면 자동으로 스크롤
          if (!_isUserScrolling) {
            // PostFrameCallback을 사용하여 다음 프레임에서 스크롤
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToCurrentSentence();
            });
          }
        }
        return;
      }
    }
  }

  Future<void> _scrollToCurrentSentence() async {
    if (_currentSentenceIndex == null || _transcriptData == null) return;
    if (!_transcriptScrollController.hasClients) return;

    // GlobalKey를 사용하여 정확한 위치 계산
    final key = _sentenceKeys[_currentSentenceIndex!];
    if (key?.currentContext == null) return;

    final RenderBox? renderBox = key!.currentContext!.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // 아이템의 위치 계산
    final itemPosition = renderBox.localToGlobal(Offset.zero);
    final itemHeight = renderBox.size.height;

    // ScrollController의 현재 위치
    final scrollOffset = _transcriptScrollController.offset;
    final viewportHeight = _transcriptScrollController.position.viewportDimension;

    // ListView 컨테이너의 위치를 찾아야 함
    final scrollContext = _transcriptScrollController.position.context.storageContext;
    final RenderBox? scrollRenderBox = scrollContext.findRenderObject() as RenderBox?;
    if (scrollRenderBox == null) return;

    final scrollPosition = scrollRenderBox.localToGlobal(Offset.zero);

    // 아이템의 상대적 위치 계산
    final relativePosition = itemPosition.dy - scrollPosition.dy;

    // 현재 문장을 viewport의 중앙에 배치
    final targetOffset = scrollOffset + relativePosition - (viewportHeight / 2) + (itemHeight / 2);

    // 자동 스크롤 시작
    _isAutoScrolling = true;

    await _transcriptScrollController.animateTo(
      targetOffset.clamp(0.0, _transcriptScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    // 자동 스크롤 종료
    _isAutoScrolling = false;
  }

  void _seekToSentence(int index) {
    if (_transcriptData == null) return;
    final sentence = _transcriptData!.timestamps[index];
    _audioService.seek(Duration(milliseconds: (sentence.startTime * 1000).toInt()));
  }

  void _seekToSlide(int slideNumber) {
    if (_transcriptData == null) return;

    // 해당 슬라이드 번호가 처음 나오는 transcript 찾기
    for (int i = 0; i < _transcriptData!.timestamps.length; i++) {
      final sentence = _transcriptData!.timestamps[i];
      if (sentence.slideNumber == slideNumber) {
        // 오디오를 해당 시간으로 이동
        _audioService.seek(Duration(milliseconds: (sentence.startTime * 1000).toInt()));

        // 사용자 스크롤 상태 해제하여 자동 스크롤 활성화
        setState(() {
          _isUserScrolling = false;
        });
        _scrollTimer?.cancel();

        return;
      }
    }
  }

  Future<Uint8List> _renderPdfPage(int pageNumber) async {
    if (_pdfDocument == null) {
      throw Exception('PDF document not loaded');
    }

    final page = await _pdfDocument!.getPage(pageNumber);
    final pageImage = await page.render(
      width: page.width * 2,
      height: page.height * 2,
      format: PdfPageImageFormat.png,
    );
    await page.close();

    return pageImage!.bytes;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
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
                onDocumentLoaded: (document) {
                  print('PDF loaded: ${document.pagesCount} pages');
                },
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
              )
            else
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
              _audioService.seek(Duration(milliseconds: (newTime * 1000).toInt()));
            },
            onSkipForward: () {
              final newTime = (_currentTime + 15).clamp(0, _totalTime);
              _audioService.seek(Duration(milliseconds: (newTime * 1000).toInt()));
            },
          ),

          const Spacer(),

          // 하단 타임라인 슬라이더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: VideoTimelineSlider(
              currentTime: _currentTime,
              totalTime: _totalTime,
              onChanged: (value) {
                // 슬라이더를 움직일 때 사용자 스크롤 상태 해제
                setState(() {
                  _isUserScrolling = false;
                });
                _scrollTimer?.cancel();
                _audioService.seek(Duration(milliseconds: (value * 1000).toInt()));

                // 약간의 딜레이 후 스크롤 (seek가 완료되고 _currentSentenceIndex가 업데이트될 때까지 대기)
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (!_isUserScrolling) {
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
            _isPagesExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        scrollDirection: Axis.horizontal,
        itemCount: pageCount,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final pageNumber = index + 1;
          final isCurrentPage = _currentPage == pageNumber;

          return GestureDetector(
            onTap: () {
              _pdfController?.jumpToPage(pageNumber);
              setState(() {
                _currentPage = pageNumber;
              });

              // 해당 슬라이드 번호가 처음 나오는 transcript 찾기
              _seekToSlide(pageNumber);
            },
            child: Container(
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: isCurrentPage ? Colors.blue : Colors.grey[300]!,
                  width: isCurrentPage ? 3 : 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FutureBuilder<Uint8List>(
                future: _renderPdfPage(pageNumber),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.contain,
                    );
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Slide',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$pageNumber',
                          style: TextStyle(
                            color: isCurrentPage ? Colors.blue : Colors.grey[800],
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTranscriptArea() {
    if (_transcriptData == null) {
      return Container(
        width: double.infinity,
        color: const Color(0xFFFAFAFA),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
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

                // GlobalKey 생성 및 저장
                _sentenceKeys.putIfAbsent(index, () => GlobalKey());

                return GestureDetector(
                  key: _sentenceKeys[index],
                  onTap: () => _seekToSentence(index),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      sentence.text,
                      style: TextStyle(
                        fontSize: isCurrentSentence ? 18 : 14,
                        fontWeight: isCurrentSentence ? FontWeight.bold : FontWeight.normal,
                        color: isCurrentSentence ? Colors.black : Colors.grey[600],
                        height: 1.6,
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
                    onDocumentLoaded: (document) {
                      print('PDF loaded: ${document.pagesCount} pages');
                    },
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                  )
                else
                  Container(
                    color: Colors.black87,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),

                // 비디오 컨트롤 오버레이
                if (_showControls && !_isPagesExpanded) _buildHorizontalVideoControls(),

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
            onCaptionToggle: () => setState(() => _isCaptionEnabled = !_isCaptionEnabled),
            isSynced: _isSynced,
            onSyncToggle: () => setState(() => _isSynced = !_isSynced),
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
              _audioService.seek(Duration(milliseconds: (newTime * 1000).toInt()));
            },
            onSkipForward: () {
              final newTime = (_currentTime + 15).clamp(0, _totalTime);
              _audioService.seek(Duration(milliseconds: (newTime * 1000).toInt()));
            },
          ),

          const Spacer(),

          // 하단 타임라인 슬라이더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: VideoTimelineSlider(
              currentTime: _currentTime,
              totalTime: _totalTime,
              onChanged: (value) {
                // 슬라이더를 움직일 때 사용자 스크롤 상태 해제
                setState(() {
                  _isUserScrolling = false;
                });
                _scrollTimer?.cancel();
                _audioService.seek(Duration(milliseconds: (value * 1000).toInt()));

                // 약간의 딜레이 후 스크롤 (seek가 완료되고 _currentSentenceIndex가 업데이트될 때까지 대기)
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (!_isUserScrolling) {
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
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              scrollDirection: Axis.horizontal,
              itemCount: _lectureMetadata?.slides ?? 10,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final pageNumber = index + 1;
                final isCurrentPage = _currentPage == pageNumber;

                return GestureDetector(
                  onTap: () {
                    _pdfController?.jumpToPage(pageNumber);
                    setState(() {
                      _currentPage = pageNumber;
                    });
                  },
                  child: Container(
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: isCurrentPage ? Colors.blue : Colors.grey[300]!,
                        width: isCurrentPage ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FutureBuilder<Uint8List>(
                      future: _renderPdfPage(pageNumber),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.contain,
                          );
                        }
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Slide',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$pageNumber',
                                style: TextStyle(
                                  color: isCurrentPage ? Colors.blue : Colors.grey[700],
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
}
