import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/core/lecture_loading_service.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/features/edit/fetch_lecture.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_background/flutter_background.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

// coverage:ignore-start

// 제거 버튼 색상
const Color _removeButtonColor = Color.fromARGB(255, 231, 76, 60);

abstract class FileReadingService {
  Future<Uint8List> readAsBytes(String path);
  Future<String> readAsString(String path);
}

class FileReadingServiceImpl implements FileReadingService {
  const FileReadingServiceImpl();

  @override
  Future<Uint8List> readAsBytes(String path) {
    return File(path).readAsBytes();
  }

  @override
  Future<String> readAsString(String path) {
    return File(path).readAsString();
  }
}

const String _serverAddress = '147.46.78.61';
const String _port = '8001';

typedef FetchLectureCallback =
    Future<List<String>?> Function(
      String slidePath,
      AudioFileEntry audioFileEntry,
      String titleText,
      String lectureId,
      int part,
      int totalParts,
      String serverAddress,
      String port,
      String langCode, {
      http.Client? clientToClose,
    });

typedef ConcatenateAudioFilesCallback =
    Future<String?> Function(
      List<String> audioPaths,
      String titleText,
      String lectureId, {
      Directory? dirOverride,
    });

typedef ConcatenateJsonFilesCallback =
    Future<String?> Function(
      List<String> jsonPaths,
      List<int> pdfStarts,
      String titleText,
      String lectureId, {
      Directory? dirOverride,
    });

typedef HttpClientFactory = http.Client Function();

typedef FlutterBackgroundWrapper = FlutterBackgroundInterface;

abstract class FlutterBackgroundInterface {
  Future<bool> initialize({
    required FlutterBackgroundAndroidConfig androidConfig,
  });
  Future<bool> enableBackgroundExecution();
  Future<bool> disableBackgroundExecution();
}

class DefaultFlutterBackgroundWrapper implements FlutterBackgroundInterface {
  @override
  Future<bool> initialize({
    required FlutterBackgroundAndroidConfig androidConfig,
  }) {
    return FlutterBackground.initialize(androidConfig: androidConfig);
  }

  @override
  Future<bool> enableBackgroundExecution() {
    return FlutterBackground.enableBackgroundExecution();
  }

  @override
  Future<bool> disableBackgroundExecution() {
    if (FlutterBackground.isBackgroundExecutionEnabled) {
      return FlutterBackground.disableBackgroundExecution();
    } else {
      return Future(false as FutureOr<bool> Function());
    }
  }
}

typedef PdfDocumentFactory = PdfDocument Function(List<int> inputBytes);
// coverage:ignore-end

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
    this.lectureLoadingService,
    this.fetchLectureCallback,
    this.filePicker,
    this.uuid,
    this.concatenateAudioFilesCallback,
    this.concatenateJsonFilesCallback,
    this.httpClientFactory,
    this.flutterBackground,
    this.pdfDocumentFactory,
    this.fileReadingService,
  });

  final HiveManager? hiveManager;
  final LectureLoadingService? lectureLoadingService;
  final FetchLectureCallback? fetchLectureCallback;
  final FilePicker? filePicker;
  final Uuid? uuid;
  final ConcatenateAudioFilesCallback? concatenateAudioFilesCallback;
  final ConcatenateJsonFilesCallback? concatenateJsonFilesCallback;
  final HttpClientFactory? httpClientFactory;
  final FlutterBackgroundInterface? flutterBackground;
  final PdfDocumentFactory? pdfDocumentFactory;
  final FileReadingService? fileReadingService;

  @override
  State<LectureFormScreen> createState() => _LectureFormScreenState();
}

class _LectureFormScreenState extends State<LectureFormScreen> {
  // 데이터 저장소 인스턴스
  late final _hive = widget.hiveManager ?? HiveManager.instance;
  late final _loadingService =
      widget.lectureLoadingService ?? LectureLoadingService.instance;
  late final _fetchLecture = widget.fetchLectureCallback ?? fetchLecture;
  late final _filePicker = widget.filePicker ?? FilePicker.platform;
  late final _uuid = widget.uuid ?? const Uuid();
  late final _concatenateAudioFiles =
      widget.concatenateAudioFilesCallback ?? concatenateAudioFiles;
  late final _concatenateJsonFiles =
      widget.concatenateJsonFilesCallback ?? concatenateJsonFiles;
  late final _httpClientFactory =
      widget.httpClientFactory ?? (() => http.Client());
  late final _flutterBackground =
      widget.flutterBackground ?? DefaultFlutterBackgroundWrapper();
  late final _pdfDocumentFactory =
      widget.pdfDocumentFactory ?? ((bytes) => PdfDocument(inputBytes: bytes));
  late final _fileReadingService =
      widget.fileReadingService ?? const FileReadingServiceImpl();

  // 텍스트 입력 컨트롤러
  final _weekController = TextEditingController();
  final _titleController = TextEditingController();

  // 선택된 과목 ID (null = 선택 안 함)
  String? _selectedSubjectId;

  // 선택된 강의 언어
  late String _selectedLanguage = AppLocalizations.of(context).isKorean
      ? 'ko'
      : 'en';

  // 업로드된 슬라이드 PDF 파일 경로
  String? _slidePdfPath;

  // 업로드된 슬라이드의 총 페이지 수 (가능한 경우)
  int? _pdfPageCount;

  // 오디오 파일 엔트리 리스트 (최소 1개 시작)
  final List<AudioFileEntry> _audioFiles = [AudioFileEntry()];

  @override
  void dispose() {
    // 메모리 누수 방지를 위한 컨트롤러 해제
    _weekController.dispose();
    _titleController.dispose();

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
    final subjects = _hive.getSubjects().where((s) {
      return !s.isArchived;
    }).toList();

    return Scaffold(
      // 상단 앱바 - 뒤로가기 버튼과 제목
      appBar: AppBar(
        title: Text(l10n.addLecture),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _cleanUpFiles();
            Navigator.pop(context);
          },
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
                _buildSectionTitle(l10n.selectSubject),
                const SizedBox(height: 8),
                _buildSubjectDropdown(l10n, subjects),
                const SizedBox(height: 20),

                // ========== 강의 언어 선택 섹션 ==========
                _buildSectionTitle(l10n.spokenLanguage),
                const SizedBox(height: 8),
                _buildLanguageDropdown(l10n, subjects),
                if (_selectedLanguage == 'ko') const SizedBox(height: 8),
                if (_selectedLanguage == 'ko')
                  Text(
                    l10n.noTtsForKorean,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                const SizedBox(height: 20),

                // ========== 강의 주차 입력 섹션 ==========
                _buildSectionTitle(l10n.lectureWeek),
                const SizedBox(height: 8),
                _buildWeekTextField(),
                const SizedBox(height: 20),

                // ========== 강의 제목 입력 섹션 ==========
                _buildSectionTitle(l10n.lectureTitle),
                const SizedBox(height: 8),
                _buildTitleTextField(),
                const SizedBox(height: 20),

                // ========== 강의 슬라이드 업로드 섹션 ==========
                _buildSectionTitle(l10n.lectureSlides),
                const SizedBox(height: 8),
                _buildFileUploadButton(
                  icon: Icons.attach_file,
                  label: _slidePdfPath != null
                      ? _getFileName(_slidePdfPath!)
                      : '...',
                  onTap: _pickSlidePdf,
                  hasFile: _slidePdfPath != null,
                ),
                const SizedBox(height: 20),

                // ========== 강의 녹음 파일 업로드 섹션 ==========
                _buildSectionTitle(l10n.lectureAudio),
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
        return Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontSize: 20),
        );
      },
    );
  }

  /// 과목 선택 드롭다운 위젯
  /// 사용자가 강의를 소속시킬 과목을 선택하거나 "선택 안 함"을 선택할 수 있습니다.
  Widget _buildSubjectDropdown(
    AppLocalizations l10n,
    List<HiveSubject> subjects,
  ) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(8),
            border: theme.inputDecorationTheme.border != null
                ? Border.fromBorderSide(
                    (theme.inputDecorationTheme.border as OutlineInputBorder)
                        .borderSide,
                  )
                : Border.all(color: theme.colorScheme.outline),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedSubjectId == 'uncategorized'
                  ? null
                  : _selectedSubjectId,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                size: 28,
                color: theme.colorScheme.onSurface,
              ),
              hint: Text(l10n.notSelected, style: theme.textTheme.bodyLarge),
              dropdownColor: cardColor,
              items: [
                // "선택 안 함" 옵션
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    l10n.notSelected,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                // 기존 과목 리스트 (미분류 제외)
                ...subjects
                    .where((s) {
                      return !s.isUncategorized;
                    })
                    .map(
                      (s) => DropdownMenuItem<String?>(
                        value: (s as dynamic).id as String,
                        child: Text(
                          (s as dynamic).title as String,
                          style: theme.textTheme.bodyLarge,
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

  /// 언어 선택 드롭다운 위젯
  Widget _buildLanguageDropdown(AppLocalizations l10n, List<dynamic> subjects) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;

        String labelFor(String code) => (code == 'ko' ? '한국어' : 'English');

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(8),
            border: theme.inputDecorationTheme.border != null
                ? Border.fromBorderSide(
                    (theme.inputDecorationTheme.border as OutlineInputBorder)
                        .borderSide,
                  )
                : Border.all(color: theme.colorScheme.outline),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                size: 28,
                color: theme.colorScheme.onSurface,
              ),
              dropdownColor: cardColor,
              items: (l10n.isKorean ? ['ko', 'en'] : ['en', 'ko'])
                  .map(
                    (code) => DropdownMenuItem<String>(
                      value: code,
                      child: Text(
                        labelFor(code),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
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
        return TextField(
          controller: _weekController,
          decoration: InputDecoration(
            hintText: 'Ex. Week 1-1',
            border: const OutlineInputBorder(),
          ),
        );
      },
    );
  }

  /// 강의 제목 입력 텍스트 필드
  Widget _buildTitleTextField() {
    return Builder(
      builder: (context) {
        return TextField(
          controller: _titleController,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        );
      },
    );
  }

  /// 오디오 파일 리스트 (다중 모드일 때 스크롤 가능)
  Widget _buildAudioFilesList() {
    return Column(
      children: _audioFiles.asMap().entries.map((entry) {
        final index = entry.key;
        final audioEntry = entry.value;
        return _buildAudioFileEntry(index, key: Key(audioEntry.id));
      }).toList(),
    );
  }

  /// 파일 업로드 버튼 위젯
  ///
  /// [icon]: 버튼에 표시할 아이콘
  /// [label]: 파일명 또는 플레이스홀더 텍스트
  /// [onTap]: 파일 선택 콜백
  /// [onRemove]: 제거 버튼 콜백 (null이면 제거 버튼 표시 안 함)
  /// [hasFile]: 파일이 선택되었는지 여부 (true면 "변경", false면 "추가")
  Widget _buildFileUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onRemove,
    bool hasFile = false,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: theme.cardTheme.shape != null
                ? null
                : Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              // 회전된 첨부 아이콘
              Transform.rotate(
                angle: 0.785, // 45도 회전
                child: Icon(
                  Icons.attach_file,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // 파일명 표시
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: label == '...'
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // 제거 버튼 (onRemove가 있을 때만 표시)
              if (onRemove != null) ...[
                OutlinedButton(
                  onPressed: onRemove,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: _removeButtonColor,
                    side: const BorderSide(color: _removeButtonColor),
                  ),
                  child: Text(AppLocalizations.of(context).remove),
                ),
                const SizedBox(width: 12),
              ],
              // 추가/변경 버튼
              OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  hasFile
                      ? AppLocalizations.of(context).change
                      : AppLocalizations.of(context).add,
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
  /// 페이지 범위 입력 필드를 함께 표시합니다.
  Widget _buildAudioFileEntry(int index, {Key? key}) {
    final entry = _audioFiles[index];

    return Column(
      key: key,
      children: [
        // 파일 업로드 버튼
        _buildFileUploadButton(
          icon: Icons.attach_file,
          label: entry.filePath != null ? _getFileName(entry.filePath!) : '...',
          onTap: () => _pickAudioFile(index),
          onRemove: _audioFiles.length > 1 && entry.filePath != null
              ? () => _removeAudioFile(index)
              : null,
          hasFile: entry.filePath != null,
        ),

        // 페이지 범위 입력 필드 표시 (항상 표시)
        const SizedBox(height: 12),
        _buildPageRangeInputs(entry, l10n),

        // 마지막 아이템이 아니면 간격 추가
        if (index < _audioFiles.length - 1) const SizedBox(height: 12),
      ],
    );
  }

  /// 페이지 범위 입력 필드 (시작 페이지 - 끝 페이지)
  Widget _buildPageRangeInputs(AudioFileEntry entry, AppLocalizations l10n) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);

        const double pageFieldWidth = 70;

        return Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.pageRange,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: pageFieldWidth,
                        child: _buildPageTextField(entry.startPageController),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('-', style: theme.textTheme.titleLarge),
                      ),
                      SizedBox(
                        width: pageFieldWidth,
                        child: _buildPageTextField(entry.endPageController),
                      ),
                    ],
                  ),
                ),
              ),
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
        return TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          ),
        );
      },
    );
  }

  /// 하단 고정 생성 버튼
  Widget _buildBottomCreateButton(AppLocalizations l10n) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () => {
                  LectureLoadingService.instance.isLoading
                      ? _showSnackBar(l10n.isGenerating)
                      : _createLecture(),
                },
                child: LectureLoadingService.instance.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(
                            theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Text(
                        l10n.create,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
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

  /// 스낵바 메시지 표시
  void _showSnackBar(String message) {
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
    final result = await _filePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final pdfPath = result.files.single.path!;

      // PDF 페이지 수 확인
      try {
        final bytes = await _fileReadingService.readAsBytes(pdfPath);
        final document = _pdfDocumentFactory(bytes);
        final pageCount = document.pages.count;
        document.dispose();

        setState(() {
          _slidePdfPath = pdfPath;
          _pdfPageCount = pageCount;

          // 첫 번째 오디오 파일의 페이지 범위를 자동으로 설정
          if (_audioFiles.isNotEmpty) {
            _audioFiles[0].startPageController.text = '1';
            _audioFiles[0].endPageController.text = pageCount.toString();
          }
        });
      } catch (e) {
        // PDF 로드 실패 시 경로만 저장
        setState(() {
          _slidePdfPath = pdfPath;
          _pdfPageCount = null;
        });
        _showSnackBar(l10n.couldntDeterminePage);
      }
    }
  }

  /// 오디오 파일 선택
  Future<void> _pickAudioFile(int index) async {
    final result = await _filePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m4a', 'm4b'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;

      // m4a 파일만 허용
      if (!filePath.toLowerCase().endsWith('.m4a')) {
        _showSnackBar(l10n.onlyM4aAllowed);
        return;
      }

      setState(() {
        final wasEmpty = _audioFiles[index].filePath == null;
        _audioFiles[index].filePath = filePath;

        // 파일이 처음 업로드되고, 마지막 칸인 경우 새 칸 자동 추가
        if (wasEmpty && index == _audioFiles.length - 1) {
          _audioFiles.add(AudioFileEntry());
        }
      });
    }
  }

  // ========== 오디오 파일 관리 메서드들 ==========

  /// 특정 인덱스의 오디오 파일 제거
  ///
  /// 최소 1개의 오디오 파일은 유지합니다.
  void _removeAudioFile(int index) {
    if (_audioFiles.length <= 1) {
      return;
    }

    setState(() {
      _audioFiles[index].dispose();
      _audioFiles.removeAt(index);
    });
  }

  Future<void> _cleanUpFiles() async {
    if (_slidePdfPath != null) {
      try {
        final slideFile = File(_slidePdfPath!);
        await slideFile.delete();
        await slideFile.parent.delete();
      } catch (_) {
        // Ignore deletion errors
      }
    }

    final effectiveAudios = _audioFiles
        .where((e) => (e.filePath ?? '').isNotEmpty)
        .toList();
    for (int i = 0; i < effectiveAudios.length; i++) {
      try {
        final audioFile = File(effectiveAudios[i].filePath!);
        await audioFile.delete();
        await audioFile.parent.delete();
      } catch (_) {
        // Ignore deletion errors
      }
    }
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
    // 과목 선택이 없으면 미분류로 처리
    _selectedSubjectId ??= 'uncategorized';
    if (_weekController.text.trim().isEmpty) {
      _showSnackBar(l10n.pleaseEnterWeek);
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar(l10n.pleaseEnterLectureTitle);
      return;
    }
    if (_slidePdfPath == null) {
      _showSnackBar(l10n.pleaseUploadPdf);
      return;
    }
    if (_audioFiles.isEmpty || _audioFiles[0].filePath == null) {
      _showSnackBar(l10n.pleaseUploadAudio);
      return;
    }

    // 페이지 범위 검증
    final pdfTotalPages = _pdfPageCount;
    int? fallbackTotalPages;

    for (int i = 0; i < _audioFiles.length; i++) {
      final entry = _audioFiles[i];
      if (entry.filePath == null) {
        continue; // 파일이 없으면 스킵
      }

      final startText = entry.startPageController.text.trim();
      final endText = entry.endPageController.text.trim();

      if (startText.isEmpty || endText.isEmpty) {
        _showSnackBar(l10n.pleaseEnterRangeForAudio(i));
        return;
      }

      // 숫자 형식 검증
      final startPage = int.tryParse(startText);
      final endPage = int.tryParse(endText);

      if (startPage == null || endPage == null) {
        _showSnackBar(l10n.pageNumbersMustBeNumgers(i));
        return;
      }

      if (startPage < 1 || endPage < 1) {
        _showSnackBar(l10n.pageNumbersMustBeAtLeastOne(i));
        return;
      }

      if (startPage > endPage) {
        _showSnackBar(l10n.startMustBeGreaterThanEnd(i));
        return;
      }

      if (pdfTotalPages != null) {
        if (startPage > pdfTotalPages) {
          _showSnackBar(l10n.startExceedsTotal(i, startPage, pdfTotalPages));
          return;
        }
        if (endPage > pdfTotalPages) {
          _showSnackBar(l10n.endExceedsTotal(i, endPage, pdfTotalPages));
          return;
        }
      } else {
        // PDF 페이지 수를 확인하지 못했을 때는 첫 오디오의 설정 범위를 기준으로 검증
        if (fallbackTotalPages == null) {
          fallbackTotalPages = endPage;
        } else if (endPage > fallbackTotalPages) {
          _showSnackBar(l10n.endExceedsTotal(i, endPage, fallbackTotalPages));
          return;
        }
      }
    }

    // 2. 로딩 시작
    final titleText = _titleController.text.trim();
    final langCode = _selectedLanguage;

    // Enable background execution
    bool backgroundEnabled = false;
    try {
      if (Platform.isAndroid) {
        final androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: 'Generating Lecture',
          notificationText: 'Processing: $titleText',
          notificationImportance: AndroidNotificationImportance.high,
          enableWifiLock: true,
        );
        backgroundEnabled = await _flutterBackground.initialize(
          androidConfig: androidConfig,
        );
        if (backgroundEnabled) {
          await _flutterBackground.enableBackgroundExecution();
        }
      }
      // iOS doesn't need FlutterBackground - background modes in Info.plist handle it
    } catch (e) {
      debugPrint('Failed to enable background execution: $e');
      // Continue anyway - app will still work in foreground
    }

    // 로딩 서비스 시작 및 취소 콜백 등록
    final effectiveAudios = _audioFiles
        .where((e) => (e.filePath ?? '').isNotEmpty)
        .toList();
    final clients = <http.Client?>[];
    for (int i = 0; i < effectiveAudios.length; i++) {
      clients.add(_httpClientFactory());
    }
    _loadingService.startLoading(titleText, effectiveAudios.length);
    _loadingService.setOnCancel(() {
      for (int i = 0; i < effectiveAudios.length; i++) {
        clients[i]?.close();
      }
      if (mounted) {
        _showSnackBar(l10n.lectureCreationCancelled);
      }
      // Disable background execution when cancelled
      if (backgroundEnabled && Platform.isAndroid) {
        unawaited(
          Future.delayed(const Duration(seconds: 1), () async {
            await _flutterBackground.disableBackgroundExecution();
          }),
        );
      }
    });

    // 3. 서버에 강의 생성 요청
    final lectureId = _uuid.v4();
    try {
      final subjectId = _selectedSubjectId ?? 'uncategorized';
      final weekText = _weekController.text.trim();
      final slidePath = _slidePdfPath!;

      // 강의 생성 진행 중에는 홈 화면으로 복귀하여 글로벌 로딩 바만 노출
      if (mounted) {
        final navigator = Navigator.of(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigator.pushNamedAndRemoveUntil(
            Routes.home,
            (route) => false, // remove everything behind Home
          );
        });
      }

      final List<Future<List<String>?>> futures = [];
      final originalAudioPaths = <String>[];
      final ttsAudioPaths = <String>[];
      final jsonPaths = <String>[];
      final pdfStarts = <int>[];

      for (int i = 1; i <= effectiveAudios.length; i++) {
        final audioFileEntry = effectiveAudios[i - 1];
        originalAudioPaths.add(audioFileEntry.filePath!);

        futures.add(
          Future.delayed(
            i == 1 ? Duration.zero : Duration(seconds: 10),
            () => _fetchLecture(
              slidePath,
              audioFileEntry,
              titleText,
              lectureId,
              i,
              effectiveAudios.length,
              _serverAddress,
              _port,
              langCode,
              clientToClose: clients[i - 1],
            ),
          ),
        );

        // Add PDF ranges
        if (effectiveAudios.length >= 2) {
          final startText = audioFileEntry.startPageController.text.trim();
          final pdfStart = int.parse(startText);
          pdfStarts.add(pdfStart);
        }
      }

      // Async calls in parallel
      final results = await Future.wait(futures);
      final isSuccess = !results.contains(null);
      if (isSuccess) {
        for (int i = 0; i < results.length; i++) {
          if (langCode == 'en') {
            ttsAudioPaths.add(results[i]![0]); // TTS only for English lectures
          }
          jsonPaths.add(results[i]![1]);
        }
      } else {
        for (int i = 0; i < results.length; i++) {
          await _cleanUpFiles();
          if (results[i] != null) {
            if (langCode == 'en') {
              await File(results[i]![0]).delete();
            }
            await File(results[i]![1]).delete();
          }
        }
        _showSnackBar(l10n.lectureGenerationFailed);
        return;
      }

      // 4. 음성 파일이 여러 개일 경우 통합 처리
      String? originalAudioPath;
      String? ttsAudioPath; // null for Korean lectures
      String? jsonPath;
      int? duration;

      if (effectiveAudios.length > 1) {
        originalAudioPath = await _concatenateAudioFiles(
          originalAudioPaths,
          titleText,
          lectureId,
        );
        if (langCode == 'en') {
          ttsAudioPath = await _concatenateAudioFiles(
            ttsAudioPaths,
            titleText,
            lectureId,
          );
        }
        jsonPath = await _concatenateJsonFiles(
          jsonPaths,
          pdfStarts,
          titleText,
          lectureId,
        );

        if (originalAudioPath == null ||
            (ttsAudioPath == null && langCode == 'en') ||
            jsonPath == null) {
          for (int i = 0; i < results.length; i++) {
            await _cleanUpFiles();
            if (results[i] != null) {
              if (langCode == 'en') {
                await File(results[i]![0]).delete();
              }
              await File(results[i]![1]).delete();
            }
          }
          _showSnackBar(l10n.lectureGenerationFailed);
          return;
        }
      } else {
        // 단일 오디오 모드: 원본 오디오를 documentsDir로 복사
        final sourceAudioPath = originalAudioPaths[0];
        final documentsDir = await getApplicationDocumentsDirectory();
        final extension = path.extension(sourceAudioPath);
        final permanentAudioPath =
            '${documentsDir.path}/$lectureId/$titleText$extension';

        try {
          // 원본 오디오를 영구 저장소로 복사
          await File(sourceAudioPath).copy(permanentAudioPath);
          originalAudioPath = permanentAudioPath;
        } catch (e) {
          debugPrint('Failed to copy original audio to permanent storage: $e');
          _showSnackBar(l10n.lectureGenerationFailed);
          return;
        }
        if (langCode == 'en') {
          ttsAudioPath = ttsAudioPaths[0];
        }
        jsonPath = jsonPaths[0];
      }

      final jsonFile = File(jsonPath);
      final List<dynamic> jsonData =
          jsonDecode(await jsonFile.readAsString()) as List<dynamic>;
      final tsList = jsonData.cast<Map<String, dynamic>>();
      duration = tsList.last['tts_end_time'] as int;

      // 5. 강의 구조체 생성
      final hasSubject = _hive.subjects.values.contains(
        _hive.getSubject(subjectId),
      );
      final finalSubjectId = hasSubject ? subjectId : 'uncategorized';
      final generatedLecture = HiveLecture(
        id: lectureId,
        subjectId: finalSubjectId,
        weekLabel: weekText,
        title: titleText,
        duration: duration,
        slidePath: _slidePdfPath,
        originalAudioPath: originalAudioPath,
        ttsAudioPath: ttsAudioPath ?? originalAudioPath,
        jsonPath: jsonPath,
        langCode: langCode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 6. Hive에 강의 저장
      await _hive.addLecture(generatedLecture);

      // 6-1. PDF를 영구 저장소로 복사 및 경로 업데이트
      if (_slidePdfPath != null) {
        try {
          final documentsDir = await getApplicationDocumentsDirectory();
          final permanentPdfPath =
              '${documentsDir.path}/$lectureId/$titleText.pdf';

          // PDF를 영구 저장소로 복사
          await File(_slidePdfPath!).copy(permanentPdfPath);

          // Hive에 저장된 경로를 영구 저장소 경로로 업데이트
          final updatedLecture = generatedLecture.copyWith(
            slidePath: permanentPdfPath,
            updatedAt: DateTime.now(),
          );
          await _hive.updateLecture(updatedLecture);

          // File_picker로 선택한 원본 PDF 삭제
          try {
            await File(_slidePdfPath!).delete();
          } catch (e) {
            debugPrint('Failed to delete temporary PDF: $e');
          }
        } catch (e) {
          debugPrint('Failed to copy PDF to permanent storage: $e');
        }
      }

      // 6-2. File_picker 캐시 폴더 전체 정리
      try {
        final tempDir = await getTemporaryDirectory();
        final pickerDir = Directory('${tempDir.path}/file_picker');
        if (pickerDir.existsSync()) {
          await pickerDir.delete(recursive: true);
          debugPrint('Deleted file_picker cache directory: ${pickerDir.path}');
        }
      } catch (e) {
        debugPrint('Failed to delete file_picker cache: $e');
      }

      // 7. 과목에 강의 추가
      final subject = _hive.getSubject(finalSubjectId);
      if (subject != null) {
        final updatedLectureIds = [...subject.lectureIds, generatedLecture.id];
        await _hive.updateSubject(
          finalSubjectId,
          lectureIds: updatedLectureIds,
        );
      }

      // 강의 생성 완료 - lectureId 전달
      _loadingService.completeLoading(lectureId: generatedLecture.id);

      // 7. 성공 메시지
      _showSnackBar(l10n.lectureCreatedSuccessfully);
    } catch (e) {
      // 8. 에러 처리
      _loadingService.hideLoading();
      if (mounted) {
        _showSnackBar(l10n.failedLectureCreation(e));
      }
    } finally {
      // 9. 로딩 종료 및 클라이언트 정리
      for (int i = 0; i < effectiveAudios.length; i++) {
        clients[i]?.close();
      }

      // Disable background execution when task completes
      if (backgroundEnabled && Platform.isAndroid) {
        try {
          await _flutterBackground.disableBackgroundExecution();
        } catch (e) {
          debugPrint('Failed to disable background execution: $e');
        }
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
  AudioFileEntry() : id = UniqueKey().toString();
  AudioFileEntry.fromPath(this.filePath) : id = UniqueKey().toString();

  /// 고유 식별자 (위젯 Key로 사용)
  final String id;

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
