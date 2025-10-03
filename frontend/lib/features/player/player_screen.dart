// 세로/가로 전환 가능한 최소 플레이어 스켈레톤
import 'package:flutter/material.dart';
import '../../core/utils.dart';

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
  double _currentTime = 132.0;
  final double _totalTime = 4056.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (_, o) {
          final isPortrait = o == Orientation.portrait;
          return isPortrait ? _portrait() : _landscape();
        },
      ),
    );
  }

  Widget _portrait() {
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
            Container(
              color: Colors.black87,
              child: const Center(
                child: Text(
                  'PDF 페이지',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 메인화면으로 나가기
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                ),
                const Spacer(),
                // 싱크 맞추기
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSynced = !_isSynced;
                    });
                  },
                  icon: Icon(
                    _isSynced ? Icons.sync : Icons.sync_disabled,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // 중앙 재생 컨트롤
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 15초 뒤로
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentTime = (_currentTime - 15).clamp(0, _totalTime);
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '15',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              // 재생/정지
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                },
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(width: 40),
              // 15초 앞으로
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentTime = (_currentTime + 15).clamp(0, _totalTime);
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '15',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // 하단 타임라인 슬라이더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // 슬라이더
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFE3E3E3),
                    thumbColor: const Color(0xFFFFFDFD),
                    overlayColor: Colors.white.withValues(alpha: 0.3),
                  ),
                  child: Slider(
                    value: _currentTime,
                    min: 0,
                    max: _totalTime,
                    onChanged: (value) {
                      setState(() {
                        _currentTime = value;
                      });
                    },
                  ),
                ),
                // 시간 표시
                Padding(
                  padding: const EdgeInsets.only(left: 1, right: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDuration(_currentTime.toInt()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '-${formatDuration((_totalTime - _currentTime).toInt())}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
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
    return Container(
      height: 150,
      color: const Color(0xFFEEEEEE),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 12, // TODO: 실제 페이지 수로 대체
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // TODO: 페이지 선택 기능
            },
            child: Container(
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTranscriptArea() {
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
          // TODO: 실제 transcript 데이터로 대체
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                'Transcript 내용이 여기에 표시됩니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _landscape() {
    return GestureDetector(
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
          // PDF/비디오 전체 화면 영역
          Container(
            color: Colors.black87,
            child: const Center(
              child: Text(
                'PDF 페이지',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),

          // 비디오 컨트롤 오버레이
          if (_showControls && !_isPagesExpanded) _buildLandscapeVideoControls(),

          // 하단 슬라이드 토글 바
          if (_isPagesExpanded)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildLandscapeToggleBar(),
            ),

          // 슬라이드가 펼쳐졌을 때 우상단 싱크 버튼
          if (_isPagesExpanded)
            Positioned(
              top: 12,
              right: 16,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _isSynced = !_isSynced;
                  });
                },
                icon: Icon(
                  _isSynced ? Icons.sync : Icons.sync_disabled,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLandscapeVideoControls() {
    return Container(
      color: const Color(0x4D1D1D1D), // rgba(29, 29, 29, 0.3)
      child: Column(
        children: [
          // 상단 컨트롤 바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 메인화면으로 나가기
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                ),
                const Spacer(),
                // 자막 토글 버튼
                IconButton(
                  onPressed: () {
                    // TODO: 자막 토글 기능
                  },
                  icon: const Icon(Icons.closed_caption, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 8),
                // 싱크 맞추기
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSynced = !_isSynced;
                    });
                  },
                  icon: Icon(
                    _isSynced ? Icons.sync : Icons.sync_disabled,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // 중앙 재생 컨트롤
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 15초 뒤로
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentTime = (_currentTime - 15).clamp(0, _totalTime);
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '15',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              // 재생/정지
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                },
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(width: 40),
              // 15초 앞으로
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentTime = (_currentTime + 15).clamp(0, _totalTime);
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '15',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // 하단 타임라인 슬라이더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // 슬라이더
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFE3E3E3),
                    thumbColor: const Color(0xFFFFFDFD),
                    overlayColor: Colors.white.withValues(alpha: 0.3),
                  ),
                  child: Slider(
                    value: _currentTime,
                    min: 0,
                    max: _totalTime,
                    onChanged: (value) {
                      setState(() {
                        _currentTime = value;
                      });
                    },
                  ),
                ),
                // 시간 표시
                Padding(
                  padding: const EdgeInsets.only(left: 1, right: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDuration(_currentTime.toInt()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '-${formatDuration((_totalTime - _currentTime).toInt())}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeToggleBar() {
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
              itemCount: 12, // TODO: 실제 페이지 수로 대체
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // TODO: 페이지 선택 기능
                  },
                  child: Container(
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
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
}
