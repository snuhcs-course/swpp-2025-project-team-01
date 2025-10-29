import 'package:flutter/material.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/features/edit/loader_service.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/features/edit/background_service.dart';
import 'package:re_view/features/edit/file_picker_service.dart';
import 'package:re_view/features/edit/lecture_creation_service.dart';

const String _serverAddress = '147.46.78.61';
const String _port = '8001';

/// 강의 생성/편집 화면
///
/// 이 화면은 사용자가 새로운 강의를 생성하거나 기존 강의를 편집할 수 있도록 합니다.
///
/// 주요 기능:
/// - 과목 선택 (드롭다운)
/// - 강의 주차 및 제목 입력
/// - 강의 슬라이드 PDF 업로드
/// - 강의 녹음 파일(들) 업로드 (단일 또는 다중)
/// - 다중 오디오 파일 모드에서 각 파일별 페이지 범위 설정
class LectureFormScreen extends StatefulWidget {
  const LectureFormScreen({
    super.key,
    this.hiveManager,
    this.filePickerService,
    this.lectureCreationService,
    this.loaderService,
    this.backgroundService,
  });

  final HiveManager? hiveManager;
  final FilePickerService? filePickerService;
  final LectureCreationService? lectureCreationService;
  final LoaderService? loaderService;
  final BackgroundService? backgroundService;

  @override
  State<LectureFormScreen> createState() => _LectureFormScreenState();
}

class _LectureFormScreenState extends State<LectureFormScreen> {
  // 데이터 저장소 인스턴스
  late final HiveManager _hive;
  late final FilePickerService _picker;
  late final LectureCreationService _creator;
  late final LoaderService _loader;
  late final BackgroundService _background;

  // 텍스트 입력 컨트롤러
  final _weekController = TextEditingController();
  final _titleController = TextEditingController();

  // 오디오 파일 리스트 스크롤 컨트롤러
  final _scrollController = ScrollController();

  // 선택된 과목 ID (null = 선택 안 함)
  String? _selectedSubjectId;

  // 업로드된 슬라이드 PDF 파일 경로
  String? _slidePdfPath;

  // 오디오 파일 엔트리 리스트 (최소 1개 시작)
  final List<AudioFileEntry> _audioFiles = [AudioFileEntry()];

  // 다중 오디오 파일 모드 활성화 여부 (2개 이상일 때 true)
  bool _isMultipleAudioMode = false;

  // 강의 생성 중 여부 (로딩 상태)
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _hive = widget.hiveManager ?? HiveManager.instance;
    _picker = widget.filePickerService ?? FilePickerService();
    _creator = widget.lectureCreationService ?? LectureCreationService();
    _loader = widget.loaderService ?? LoaderService();
    _background = widget.backgroundService ?? BackgroundService();
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위한 컨트롤러 해제
    _weekController.dispose();
    _titleController.dispose();
    _scrollController.dispose();

    // 모든 오디오 파일 엔트리 dispose
    for (final entry in _audioFiles) {
      entry.dispose();
    }

    super.dispose();
  }

  // AppLocalizations 캐싱
  AppLocalizations? _l10n;

  AppLocalizations get l10n {
    _l10n ??= AppLocalizations.of(context);
    return _l10n!;
  }

  @override
  Widget build(BuildContext context) {
    _l10n = AppLocalizations.of(context);
    final subjects = _hive.getSubjects();

    return Scaffold(
      // 상단 앱바 - 뒤로가기 버튼과 제목
      appBar: AppBar(
        title: Text(l10n.isKorean ? '강의 생성' : 'Create Lecture'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,

      // 스크롤 가능한 메인 콘텐츠 + 로딩 바
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========== 과목 선택 섹션 ==========
                _buildSectionTitle(l10n.isKorean ? '과목 선택' : 'Select Subject'),
                const SizedBox(height: 8),
                _buildSubjectDropdown(l10n, subjects),
                const SizedBox(height: 20),

                // ========== 강의 주차 입력 섹션 ==========
                _buildSectionTitle(l10n.isKorean ? '강의 주차' : 'Lecture Week'),
                const SizedBox(height: 8),
                _buildWeekTextField(),
                const SizedBox(height: 20),

                // ========== 강의 제목 입력 섹션 ==========
                _buildSectionTitle(l10n.isKorean ? '강의 제목' : 'Lecture Title'),
                const SizedBox(height: 8),
                _buildTitleTextField(),
                const SizedBox(height: 20),

                // ========== 강의 슬라이드 업로드 섹션 ==========
                _buildSectionTitle(
                  l10n.isKorean ? '강의 슬라이드 (.pdf)' : 'Lecture Slides (.pdf)',
                ),
                const SizedBox(height: 8),
                _buildFileUploadButton(
                  icon: Icons.attach_file,
                  label: _slidePdfPath != null
                      ? _getFileName(_slidePdfPath!)
                      : (l10n.isKorean ? '...' : '...'),
                  onTap: _pickSlidePdf,
                ),
                const SizedBox(height: 20),

                // ========== 강의 녹음 파일 업로드 섹션 ==========
                _buildAudioFilesHeader(l10n),
                const SizedBox(height: 8),
                _buildAudioFilesList(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),

      // 하단 고정 생성 버튼
      bottomNavigationBar: _buildBottomCreateButton(l10n),
    );
  }

  // ========== UI 빌더 메서드들 ==========

  /// 섹션 제목 위젯
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  /// 과목 선택 드롭다운 위젯
  /// 사용자가 강의를 소속시킬 과목을 선택하거나 "선택 안 함"을 선택할 수 있습니다.
  Widget _buildSubjectDropdown(AppLocalizations l10n, List<dynamic> subjects) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedSubjectId,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 28),
          hint: Text(
            l10n.isKorean ? '선택 안 함' : 'Not Selected',
            style: const TextStyle(fontSize: 16),
          ),
          items: [
            // "선택 안 함" 옵션
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                l10n.isKorean ? '선택 안 함' : 'Not Selected',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            // 기존 과목 리스트
            ...subjects.map(
              (s) => DropdownMenuItem<String?>(
                value: (s as dynamic).id as String,
                child: Text(
                  (s as dynamic).title as String,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedSubjectId = value;
            });
          },
        ),
      ),
    );
  }

  /// 강의 주차 입력 텍스트 필드
  Widget _buildWeekTextField() {
    return TextField(
      controller: _weekController,
      decoration: InputDecoration(
        hintText: 'Ex. Week 1-1',
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.black87, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  /// 강의 제목 입력 텍스트 필드
  Widget _buildTitleTextField() {
    return TextField(
      controller: _titleController,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.black87, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  /// 오디오 파일 섹션 헤더 (제목 + 추가/삭제 버튼)
  Widget _buildAudioFilesHeader(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildSectionTitle(
            l10n.isKorean ? '강의 녹음 파일 (오디오)' : 'Lecture Audio',
          ),
        ),
        // 오디오 파일 삭제 버튼 (2개 이상일 때만 활성화)
        IconButton(
          icon: Icon(
            Icons.remove_circle_outline,
            color: _canRemoveAudioFile()
                ? Colors.grey.shade700
                : Colors.grey.withValues(alpha: 0.3),
          ),
          onPressed: _canRemoveAudioFile() ? _removeLastAudioFile : null,
        ),
        // 오디오 파일 추가 버튼
        IconButton(
          icon: Icon(Icons.add_circle_outline, color: Colors.grey.shade700),
          onPressed: _addAudioFile,
        ),
      ],
    );
  }

  /// 오디오 파일 리스트 (다중 모드일 때 스크롤 가능)
  Widget _buildAudioFilesList() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: _isMultipleAudioMode ? 300 : double.infinity,
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: List.generate(_audioFiles.length, (index) {
            return _buildAudioFileEntry(index);
          }),
        ),
      ),
    );
  }

  /// 파일 업로드 버튼 위젯
  ///
  /// [icon]: 버튼에 표시할 아이콘
  /// [label]: 파일명 또는 플레이스홀더 텍스트
  /// [onTap]: 파일 선택 콜백
  Widget _buildFileUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 회전된 첨부 아이콘
          Transform.rotate(
            angle: 0.785, // 45도 회전
            child: Icon(
              Icons.attach_file,
              color: Colors.grey.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // 파일명 표시
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: label == '...' ? Colors.grey.shade400 : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // 추가 버튼
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              l10n.isKorean ? '추가' : 'Add',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 개별 오디오 파일 엔트리 위젯
  ///
  /// 다중 오디오 파일 모드일 때는 페이지 범위 입력 필드도 함께 표시합니다.
  Widget _buildAudioFileEntry(int index) {
    final entry = _audioFiles[index];

    return Column(
      children: [
        // 파일 업로드 버튼
        _buildFileUploadButton(
          icon: Icons.attach_file,
          label: entry.filePath != null
              ? _getFileName(entry.filePath!)
              : (l10n.isKorean ? '...' : '...'),
          onTap: () => _pickAudioFile(index),
        ),

        // 다중 오디오 파일 모드일 때 페이지 범위 입력 필드 표시
        if (_isMultipleAudioMode) ...[
          const SizedBox(height: 12),
          _buildPageRangeInputs(entry, l10n),
        ],

        // 마지막 아이템이 아니면 간격 추가
        if (index < _audioFiles.length - 1) const SizedBox(height: 12),
      ],
    );
  }

  /// 페이지 범위 입력 필드 (시작 페이지 - 끝 페이지)
  Widget _buildPageRangeInputs(AudioFileEntry entry, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: Row(
        children: [
          Text(
            l10n.isKorean ? '페이지 설정' : 'Page Range',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 16),
          // 시작 페이지 입력
          Expanded(child: _buildPageTextField(entry.startPageController)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '-',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          // 끝 페이지 입력
          Expanded(child: _buildPageTextField(entry.endPageController)),
        ],
      ),
    );
  }

  /// 페이지 번호 입력 텍스트 필드
  Widget _buildPageTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
  }

  /// 하단 고정 생성 버튼
  Widget _buildBottomCreateButton(AppLocalizations l10n) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _isCreating ? null : _createLecture,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    l10n.isKorean ? '생성하기' : 'Create',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ========== 유틸리티 메서드들 ==========

  /// 파일 경로에서 파일명만 추출
  String _getFileName(String path) {
    return path.split('/').last.split('\\').last;
  }

  /// 오디오 파일 삭제 가능 여부 확인 (2개 이상일 때만 가능)
  bool _canRemoveAudioFile() {
    return _audioFiles.length > 1;
  }

  /// 토스트 메시지 표시
  void _showToast(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // ========== 파일 선택 메서드들 ==========

  /// 슬라이드 PDF 파일 선택
  Future<void> _pickSlidePdf() async {
    final path = await _picker.pickPdf();

    if (path != null) {
      setState(() {
        _slidePdfPath = path;
      });
    }
  }

  /// 오디오 파일 선택
  Future<void> _pickAudioFile(int index) async {
    final path = await _picker.pickAudio();

    if (path != null) {
      setState(() {
        _audioFiles[index].filePath = path;
      });
    }
  }

  // ========== 오디오 파일 관리 메서드들 ==========

  /// 오디오 파일 추가
  ///
  /// 새로운 오디오 파일 엔트리를 추가합니다.
  /// 기존 파일들이 모두 업로드된 경우에만 추가 가능합니다.
  void _addAudioFile() {
    // 모든 기존 파일이 업로드되었는지 확인
    for (int i = 0; i < _audioFiles.length; i++) {
      if (_audioFiles[i].filePath == null) {
        _showToast(
          l10n.isKorean
              ? '파일을 순서대로 업로드해주세요'
              : 'Please upload the files in order',
        );
        return;
      }
    }

    setState(() {
      _audioFiles.add(AudioFileEntry());
      _isMultipleAudioMode = true;
    });

    // 스크롤을 맨 아래로 이동 (새로 추가된 파일이 보이도록)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 마지막 오디오 파일 삭제
  ///
  /// 업로드된 파일이 있으면 확인 다이얼로그를 표시합니다.
  void _removeLastAudioFile() {
    if (_audioFiles.length <= 1) {
      return;
    }

    final lastEntry = _audioFiles.last;

    // 파일이 업로드되어 있으면 경고 표시
    if (lastEntry.filePath != null) {
      _showDeleteConfirmation(() {
        setState(() {
          lastEntry.dispose();
          _audioFiles.removeLast();
          if (_audioFiles.length == 1) {
            _isMultipleAudioMode = false;
          }
        });
      });
    } else {
      // 파일이 없으면 바로 삭제
      setState(() {
        lastEntry.dispose();
        _audioFiles.removeLast();
        if (_audioFiles.length == 1) {
          _isMultipleAudioMode = false;
        }
      });
    }
  }

  /// 파일 삭제 확인 다이얼로그 표시
  void _showDeleteConfirmation(VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.isKorean ? '경고' : 'Warning'),
        content: Text(
          l10n.isKorean
              ? '업로드된 파일이 있습니다.\n삭제하시겠습니까?'
              : 'There is an uploaded file.\nDo you want to delete it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.isKorean ? '취소' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.isKorean ? '삭제' : 'Delete'),
          ),
        ],
      ),
    );
  }

  // ========== 강의 생성 메서드 ==========

  /// 강의 생성 처리
  ///
  /// 모든 필수 입력값을 검증한 후 강의를 생성합니다.
  ///
  /// 검증 항목:
  /// 1. 강의 주차 입력 여부
  /// 2. 강의 제목 입력 여부
  /// 3. 슬라이드 PDF 업로드 여부
  /// 4. 최소 1개의 오디오 파일 업로드 여부
  Future<void> _createLecture() async {
    // 1. 검증
    if (_selectedSubjectId == null) {
      _showToast(l10n.isKorean ? '과목을 선택해주세요' : 'Please select a subject');
      return;
    }
    if (_weekController.text.trim().isEmpty) {
      _showToast(l10n.isKorean ? '강의 주차를 입력해주세요' : 'Please enter lecture week');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showToast(
        l10n.isKorean ? '강의 제목을 입력해주세요' : 'Please enter lecture title',
      );
      return;
    }
    if (_slidePdfPath == null) {
      _showToast(
        l10n.isKorean ? '슬라이드 PDF를 업로드해주세요' : 'Please upload slide PDF',
      );
      return;
    }
    if (_audioFiles.isEmpty || _audioFiles[0].filePath == null) {
      _showToast(
        l10n.isKorean
            ? '오디오 파일을 최소 1개 업로드해주세요'
            : 'Please upload at least one audio file',
      );
      return;
    }

    // 2. 로딩 시작
    setState(() => _isCreating = true);
    final titleText = _titleController.text.trim();

    // [수정] Enable background execution
    bool backgroundEnabled = false;
    try {
      backgroundEnabled = await _background.initialize();
      if (backgroundEnabled) {
        await _background.enableBackgroundExecution();
      }
    } catch (e) {
      debugPrint('Failed to enable background execution: $e');
    }

    // [삭제] _httpClient = http.Client();

    // 로딩 서비스 시작 및 취소 콜백 등록
    _loader.startLoading(titleText);
    _loader.setOnCancel(() {
      _creator.cancelCreation(); // [수정]
      if (mounted) {
        setState(() => _isCreating = false);
        _showToast(
          l10n.isKorean ? '강의 생성이 취소되었습니다' : 'Lecture creation cancelled',
        );
      }
      if (backgroundEnabled) {
        _background.disableBackgroundExecution(); // [수정]
      }
    });

    try {
      // 3. 백엔드로 전송
      final subjectId = _selectedSubjectId ?? 'uncategorized';
      final weekText = _weekController.text.trim();
      final slidePath = _slidePdfPath!;
      final effectiveAudios = _audioFiles
          .where((e) => (e.filePath ?? '').isNotEmpty)
          .toList();

      // 강의 생성 진행 중에는 홈 화면으로 복귀하여 글로벌 로딩 바만 노출
      if (mounted) {
        final navigator = Navigator.of(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigator.popUntil(
            (route) => route.settings.name == Routes.home || route.isFirst,
          );
        });
      }

      // [수정] client 파라미터 제거
      final CreationResult? result = await _creator.createLecture(
        slidePath: slidePath,
        audioEntries: effectiveAudios,
        title: titleText,
        serverAddress: _serverAddress,
        port: _port,
      );

      // [수정] 사용자님 지적대로 'if (result == null)' 구조로 복원
      if (result == null) {
        // 취소되었거나 서비스 내부에서 실패/리턴됨
        _loader.hideLoading();
        if (!_loader.isCancelled && mounted) {
          _showToast(
            l10n.isKorean ? '강의 생성에 실패했습니다.' : 'Lecture generation failed.',
          );
        }
        return; // [수정] 'return' 복원
      }

      // [수정] 'else' 제거. 성공 로직이 바로 이어짐
      // 5. 강의 구조체 생성 (결과값 사용)
      final generatedLecture = HiveLecture(
        id: 'lecture_${DateTime.now().millisecondsSinceEpoch}',
        subjectId: subjectId,
        weekLabel: weekText,
        title: titleText,
        duration: result.duration,
        slidePath: _slidePdfPath,
        audioPath: result.audioPath,
        jsonPath: result.jsonPath,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 6. Hive에 강의 저장
      await _hive.addLecture(generatedLecture);

      // 7. 과목에 강의 추가
      if (_selectedSubjectId != null) {
        final subject = _hive.getSubject(_selectedSubjectId!);
        if (subject != null) {
          final updatedLectureIds = [
            ...subject.lectureIds,
            generatedLecture.id,
          ];
          await _hive.updateSubject(
            _selectedSubjectId!,
            lectureIds: updatedLectureIds,
          );
        }
      }

      // 8. 성공 메시지
      _showToast(
        l10n.isKorean ? '강의가 생성되었습니다' : 'Lecture created successfully',
      );
    } catch (e) {
      // 9. 에러 처리
      _loader.hideLoading();
      if (mounted) {
        _showToast(
          l10n.isKorean
              ? '강의 생성 실패: ${e.toString()}'
              : 'Failed to create lecture: ${e.toString()}',
        );
      }
    } finally {
      // 10. 로딩 종료 및 클라이언트 정리
      _loader.hideLoading();

      // [삭제]
      // _httpClient?.close();
      // _httpClient = null;

      // [수정] Disable background execution when task completes
      if (backgroundEnabled) {
        try {
          await _background.disableBackgroundExecution();
        } catch (e) {
          debugPrint('Failed to disable background execution: $e');
        }
      }

      // Pop이 예약되었든 아니든, 위젯이 아직 화면에 있다면 항상 로컬 스피너를 끕니다.
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}

/// 오디오 파일 엔트리 클래스
///
/// 개별 오디오 파일의 정보를 관리합니다.
/// - 파일 경로
/// - 시작 페이지 번호 (다중 파일 모드)
/// - 끝 페이지 번호 (다중 파일 모드)
class AudioFileEntry {
  AudioFileEntry();
  AudioFileEntry.fromPath(this.filePath);

  /// 선택된 오디오 파일 경로
  String? filePath;

  /// 시작 페이지 입력 컨트롤러
  final TextEditingController startPageController = TextEditingController();

  /// 끝 페이지 입력 컨트롤러
  final TextEditingController endPageController = TextEditingController();

  /// 메모리 누수 방지를 위한 컨트롤러 해제
  void dispose() {
    startPageController.dispose();
    endPageController.dispose();
  }
}
