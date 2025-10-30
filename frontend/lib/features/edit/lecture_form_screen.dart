import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/core/lecture_loading_service.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/features/edit/fetch_lecture.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_background/flutter_background.dart';

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
  const LectureFormScreen({super.key});

  @override
  State<LectureFormScreen> createState() => _LectureFormScreenState();
}

class _LectureFormScreenState extends State<LectureFormScreen> {
  // 데이터 저장소 인스턴스
  final _hive = HiveManager.instance;

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

  // HTTP 클라이언트 (취소를 위해)
  http.Client? _httpClient;
  bool _closeClientOnDispose = true;

  @override
  void dispose() {
    // HTTP 클라이언트 정리
    if (_closeClientOnDispose) {
      _httpClient?.close();
    }

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
      // backgroundColor는 테마의 scaffoldBackgroundColor 사용

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
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        );
      },
    );
  }

  /// 과목 선택 드롭다운 위젯
  /// 사용자가 강의를 소속시킬 과목을 선택하거나 "선택 안 함"을 선택할 수 있습니다.
  Widget _buildSubjectDropdown(AppLocalizations l10n, List<dynamic> subjects) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;
        final borderColor = isDark
            ? Colors.grey.shade700
            : Colors.grey.shade300;
        final textColor = isDark ? Colors.white : Colors.black87;

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedSubjectId,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, size: 28, color: textColor),
              hint: Text(
                l10n.isKorean ? '선택 안 함' : 'Not Selected',
                style: TextStyle(fontSize: 16, color: textColor),
              ),
              dropdownColor: cardColor,
              items: [
                // "선택 안 함" 옵션
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    l10n.isKorean ? '선택 안 함' : 'Not Selected',
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                ),
                // 기존 과목 리스트
                ...subjects.map(
                  (s) => DropdownMenuItem<String?>(
                    value: (s as dynamic).id as String,
                    child: Text(
                      (s as dynamic).title as String,
                      style: TextStyle(fontSize: 16, color: textColor),
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
      },
    );
  }

  /// 강의 주차 입력 텍스트 필드
  Widget _buildWeekTextField() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;
        final borderColor = isDark
            ? Colors.grey.shade600
            : Colors.grey.shade400;
        final focusColor = isDark ? Colors.white : Colors.black87;
        final textColor = isDark ? Colors.white : Colors.black87;

        return TextField(
          controller: _weekController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Ex. Week 1-1',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: focusColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        );
      },
    );
  }

  /// 강의 제목 입력 텍스트 필드
  Widget _buildTitleTextField() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;
        final borderColor = isDark
            ? Colors.grey.shade600
            : Colors.grey.shade400;
        final focusColor = isDark ? Colors.white : Colors.black87;
        final textColor = isDark ? Colors.white : Colors.black87;

        return TextField(
          controller: _titleController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: focusColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        );
      },
    );
  }

  /// 오디오 파일 섹션 헤더 (제목 + 추가/삭제 버튼)
  Widget _buildAudioFilesHeader(AppLocalizations l10n) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final iconColor = isDark ? Colors.white70 : Colors.grey.shade700;
        final disabledColor = isDark
            ? Colors.grey.withValues(alpha: 0.3)
            : Colors.grey.withValues(alpha: 0.3);

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
                color: _canRemoveAudioFile() ? iconColor : disabledColor,
              ),
              onPressed: _canRemoveAudioFile() ? _removeLastAudioFile : null,
            ),
            // 오디오 파일 추가 버튼
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: iconColor),
              onPressed: _addAudioFile,
            ),
          ],
        );
      },
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
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;
        final borderColor = isDark
            ? Colors.grey.shade700
            : Colors.grey.shade300;
        final textColor = isDark ? Colors.white : Colors.black87;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
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
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
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
                    color: label == '...' ? Colors.grey.shade400 : textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // 추가 버튼
              OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).isKorean ? '추가' : 'Add',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white70 : Colors.grey.shade600;

        return Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Row(
            children: [
              Text(
                l10n.isKorean ? '페이지 설정' : 'Page Range',
                style: TextStyle(fontSize: 14, color: textColor),
              ),
              const SizedBox(width: 16),
              // 시작 페이지 입력
              Expanded(child: _buildPageTextField(entry.startPageController)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '-',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              // 끝 페이지 입력
              Expanded(child: _buildPageTextField(entry.endPageController)),
            ],
          ),
        );
      },
    );
  }

  /// 페이지 번호 입력 텍스트 필드
  Widget _buildPageTextField(TextEditingController controller) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;
        final borderColor = isDark
            ? Colors.grey.shade600
            : Colors.grey.shade300;
        final focusColor = isDark ? Colors.white : Colors.blue;

        return TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: focusColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
          ),
        );
      },
    );
  }

  /// 하단 고정 생성 버튼
  Widget _buildBottomCreateButton(AppLocalizations l10n) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = isDark
            ? const Color(0xFF212121) // 다크모드: 배경색과 동일
            : Colors.white; // 라이트모드: 흰색

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
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
                  backgroundColor: isDark ? Colors.white : Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isCreating ? null : _createLecture,
                child: _isCreating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(
                            isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        l10n.isKorean ? '생성하기' : 'Create',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _slidePdfPath = result.files.single.path;
      });
    }
  }

  /// 오디오 파일 선택
  Future<void> _pickAudioFile(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m4a', 'mp3', 'wav', 'aac', 'ogg', 'flac'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _audioFiles[index].filePath = result.files.single.path;
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

    // Enable background execution
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: 'Generating Lecture',
      notificationText: 'Processing: $titleText',
      notificationImportance: AndroidNotificationImportance.high,
      enableWifiLock: true,
    );

    bool backgroundEnabled = false;
    try {
      backgroundEnabled = await FlutterBackground.initialize(
        androidConfig: androidConfig,
      );
      if (backgroundEnabled) {
        await FlutterBackground.enableBackgroundExecution();
      }
    } catch (e) {
      debugPrint('Failed to enable background execution: $e');
      // Continue anyway - app will still work in foreground
    }

    // HTTP 클라이언트 생성
    _httpClient = http.Client();

    // 로딩 서비스 시작 및 취소 콜백 등록
    LectureLoadingService.instance.startLoading(titleText);
    LectureLoadingService.instance.setOnCancel(() {
      _httpClient?.close();
      _closeClientOnDispose = true;
      if (mounted) {
        setState(() => _isCreating = false);
        _showToast(
          l10n.isKorean ? '강의 생성이 취소되었습니다' : 'Lecture creation cancelled',
        );
      }
      // Disable background execution when cancelled
      if (backgroundEnabled) {
        FlutterBackground.disableBackgroundExecution();
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
        _closeClientOnDispose = false;
        final navigator = Navigator.of(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigator.popUntil(
            (route) => route.settings.name == Routes.home || route.isFirst,
          );
        });
      }

      final audioPaths = <String>[];
      final jsonPaths = <String>[];
      final pdfStarts = <int>[];

      for (int i = 1; i <= effectiveAudios.length; i++) {
        final audioFileEntry = effectiveAudios[i - 1];
        try {
          debugPrint(
            '🚀 Starting lecture request $i/${effectiveAudios.length}',
          );
          debugPrint('📤 Server: $_serverAddress:$_port');
          debugPrint('📄 Slide: $slidePath');
          debugPrint('🎵 Audio: ${audioFileEntry.filePath}');
          debugPrint('📊 isSingleAudio: ${effectiveAudios.length == 1}');
          debugPrint(
            '📝 Start page: "${audioFileEntry.startPageController.text}"',
          );
          debugPrint('📝 End page: "${audioFileEntry.endPageController.text}"');

          final jobId = await requestLecture(
            slidePath,
            audioFileEntry,
            titleText,
            i,
            effectiveAudios.length == 1 ? true : false,
            _serverAddress,
            _port,
            onProgress,
            clientToClose: _httpClient,
          );

          debugPrint('✅ Request completed with jobId: $jobId');

          if (jobId == null) {
            LectureLoadingService.instance.hideLoading();

            // 취소된 경우가 아닐 때만 실패 메시지 표시
            if (!LectureLoadingService.instance.isCancelled && mounted) {
              _showToast(
                l10n.isKorean ? '강의 생성에 실패했습니다.' : 'Lecture generation failed.',
              );
            }
            return;
          }

          final zipPath = await downloadResult(
            jobId,
            titleText,
            i,
            _serverAddress,
            _port,
          );

          if (zipPath == null) {
            LectureLoadingService.instance.hideLoading();
            _showToast(
              l10n.isKorean ? '강의 다운로드에 실패했습니다.' : 'Lecture download failed.',
            );
            return;
          }

          final filePaths = await unzipResult(zipPath, titleText, i);
          if (filePaths == null) {
            _showToast(
              l10n.isKorean ? '강의 생성에 실패했습니다.' : 'Lecture generation failed.',
            );
            return;
          }
          audioPaths.add(filePaths[0]);
          jsonPaths.add(filePaths[1]);

          // Add PDF ranges
          if (effectiveAudios.length >= 2) {
            final startText = audioFileEntry.startPageController.text.trim();
            final pdfStart = int.parse(startText);
            pdfStarts.add(pdfStart);
          }
        } catch (err) {
          LectureLoadingService.instance.hideLoading();
          _showToast(
            l10n.isKorean ? '강의 생성에 실패했습니다.' : 'Lecture generation failed.',
          );
          return;
        }
      }

      // 4. 음성 파일이 여러 개일 경우 통합 처리
      String? audioPath;
      String? jsonPath;
      int? duration;

      if (effectiveAudios.length > 1) {
        audioPath = await concatenateAudioFiles(audioPaths, titleText);
        jsonPath = await concatenateJsonFiles(jsonPaths, pdfStarts, titleText);
        if (audioPath == null || jsonPath == null) {
          _showToast(
            l10n.isKorean ? '강의 생성에 실패했습니다.' : 'Lecture generation failed.',
          );
          return;
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

      // 5. 강의 구조체 생성
      final generatedLecture = HiveLecture(
        id: 'lecture_${DateTime.now().millisecondsSinceEpoch}',
        subjectId: subjectId,
        weekLabel: weekText,
        title: titleText,
        duration: duration,
        slidePath: _slidePdfPath,
        audioPath: audioPath,
        jsonPath: jsonPath,
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

      // 7. 성공 메시지
      _showToast(
        l10n.isKorean ? '강의가 생성되었습니다' : 'Lecture created successfully',
      );
    } catch (e) {
      // 8. 에러 처리
      LectureLoadingService.instance.hideLoading();
      if (mounted) {
        _showToast(
          l10n.isKorean
              ? '강의 생성 실패: ${e.toString()}'
              : 'Failed to create lecture: ${e.toString()}',
        );
      }
    } finally {
      // 9. 로딩 종료 및 클라이언트 정리
      _httpClient?.close();
      _httpClient = null;
      _closeClientOnDispose = true;

      // Disable background execution when task completes
      if (backgroundEnabled) {
        try {
          await FlutterBackground.disableBackgroundExecution();
        } catch (e) {
          debugPrint('Failed to disable background execution: $e');
        }
      }

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
