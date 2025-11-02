import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:re_view/data/hive_models.dart';

/// Hive 통합 데이터베이스 매니저 (싱글톤)
///
/// 모든 앱 데이터를 하나의 Hive 박스에서 관리합니다.
/// - 설정 (테마, 언어, 접근성, TTS)
/// - 과목 데이터
/// - 태그 데이터
/// - UI 상태 (펼침/접힘, 최근 검색어)
///
/// 사용 예시:
/// ```dart
/// // 초기화 (main.dart에서 한 번만)
/// await HiveManager.instance.init();
///
/// // 데이터 읽기
/// final theme = HiveManager.instance.settings.theme;
/// final subjects = HiveManager.instance.subjects;
///
/// // 데이터 수정
/// HiveManager.instance.updateTheme('dark');
/// HiveManager.instance.toggleSubjectFavorite('s1');
///
/// // 변경 감지
/// HiveManager.instance.addListener(() {
///   print('데이터가 변경되었습니다!');
/// });
/// ```
class HiveManager extends ChangeNotifier {
  HiveManager._();
  static final HiveManager instance = HiveManager._();

  late Box<AppData> _appBox;
  AppData? _appData;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool get hasTutorialCompleted => settings.hasCompletedTutorial;

  // ========== 초기화 ==========

  /// Test-only initialization method
  /// Initializes HiveManager with an already-opened box (for testing without path_provider)
  /// Can be called multiple times to reload data
  @visibleForTesting
  Future<void> initForTesting(Box<AppData> box) async {
    _appBox = box;
    _appData = box.get('main');
    _isInitialized = true;
    notifyListeners();
  }

  /// Hive 초기화 및 데이터 로드
  /// main.dart에서 앱 시작 시 한 번만 호출
  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    // Hive 초기화 (Documents/review_db/ 폴더에 저장)
    await Hive.initFlutter('review_db');

    // TypeAdapter 등록
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AppDataAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UiStateAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(HiveSubjectAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(HiveTagAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(HiveLectureAdapter());
    }

    // Box 열기
    _appBox = await Hive.openBox<AppData>('app_data');

    // 데이터 로드 (없으면 초기화)
    if (_appBox.isEmpty) {
      await _initializeWithDefaults();
    } else {
      _appData = _appBox.get('main');

      // 미분류 과목이 없으면 추가 (기존 데이터에 대한 마이그레이션)
      if (_appData != null &&
          !_appData!.subjects.containsKey('uncategorized')) {
        final uncategorizedSubject = HiveSubject(
          id: 'uncategorized',
          title: 'Uncategorized', // UI에서 다국어 처리됨
          favorite: false,
          tagIds: [],
          lectureIds: [],
          isUncategorized: true,
        );
        _appData!.subjects['uncategorized'] = uncategorizedSubject;
        await _save();
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// assets의 기본 데이터로 초기화
  Future<void> _initializeWithDefaults() async {
    final subjects = await _loadDefaultSubjects();
    final tags = await _loadDefaultTags();
    final lectures = await _loadDemoLectures(subjects);

    // 미분류 과목 자동 생성
    final uncategorizedSubject = HiveSubject(
      id: 'uncategorized',
      title: 'Uncategorized', // UI에서 다국어 처리됨
      favorite: false,
      tagIds: [],
      lectureIds: [],
      isUncategorized: true,
    );
    subjects['uncategorized'] = uncategorizedSubject;

    _appData = AppData(
      settings: AppSettings(),
      subjects: subjects,
      tags: tags,
      lectures: lectures,
      uiState: UiState(),
    );

    await _save();
  }

  /// assets/data/subjects.json 로드
  Future<Map<String, HiveSubject>> _loadDefaultSubjects() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/subjects.json',
      );
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final list = (json['subjects'] as List).cast<Map<String, dynamic>>();

      return {
        for (final item in list)
          item['id'] as String: HiveSubject(
            id: item['id'] as String,
            title: item['title'] as String,
            favorite: item['favorite'] as bool? ?? false,
            tagIds: (item['tagIds'] as List).cast<String>(),
            lectureIds: (item['lectureIds'] as List).cast<String>(),
          ),
      };
    } catch (e) {
      debugPrint('Failed to load default subjects: $e');
      return {};
    }
  }

  /// assets/data/tags.json 로드
  Future<Map<String, HiveTag>> _loadDefaultTags() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/tags.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final list = (json['tags'] as List).cast<Map<String, dynamic>>();

      return {
        for (final item in list)
          item['id'] as String: HiveTag(
            id: item['id'] as String,
            name: item['name'] as String,
            color: _parseHexColor(item['color'] as String),
          ),
      };
    } catch (e) {
      debugPrint('Failed to load default tags: $e');
      return {};
    }
  }

  /// assets/lectures에서 데모 강의 로드 (개발/테스트용)
  Future<Map<String, HiveLecture>> _loadDemoLectures(
    Map<String, HiveSubject> subjects,
  ) async {
    final Map<String, HiveLecture> lectures = {};

    // 모든 과목의 강의 ID 수집
    final Set<String> allLectureIds = {};
    for (final subject in subjects.values) {
      allLectureIds.addAll(subject.lectureIds);
    }

    // 각 강의 메타데이터 로드
    for (final lectureId in allLectureIds) {
      final lecture = await HiveLecture.fromAssets(lectureId);
      if (lecture != null) {
        lectures[lectureId] = lecture;
      }
    }

    debugPrint('Loaded ${lectures.length} demo lectures from assets');
    return lectures;
  }

  int _parseHexColor(String hex) {
    final s = hex.replaceAll('#', '');
    final v = int.parse(s, radix: 16);
    return (s.length == 6) ? (0xFF000000 | v) : v;
  }

  /// 데이터 저장 (Hive에 자동 저장)
  Future<void> _save() async {
    if (_appData != null) {
      await _appBox.put('main', _appData!);
      notifyListeners();
    }
  }

  // ========== Getter (읽기) ==========

  AppSettings get settings => _appData?.settings ?? AppSettings();
  Map<String, HiveSubject> get subjects => _appData?.subjects ?? {};
  Map<String, HiveTag> get tags => _appData?.tags ?? {};
  UiState get uiState => _appData?.uiState ?? UiState();
  Map<String, HiveLecture> get lectures => _appData?.lectures ?? {};
  List<String> get subjectOrder => _appData?.subjectOrder ?? [];

  // ========== 설정 관련 ==========

  Future<void> updateTheme(String theme) async {
    settings.theme = theme;
    await _save();
  }

  Future<void> updateLanguage(String language) async {
    settings.language = language;
    await _save();
  }

  Future<void> updateAccessibility({
    bool? highContrast,
    bool? reduceMotion,
    bool? emphasizeCaptions,
  }) async {
    if (highContrast != null) {
      settings.accessibilityHighContrast = highContrast;
    }
    if (reduceMotion != null) {
      settings.accessibilityReduceMotion = reduceMotion;
    }
    if (emphasizeCaptions != null) {
      settings.accessibilityEmphasizeCaptions = emphasizeCaptions;
    }
    await _save();
  }

  Future<void> updateTts({String? gender}) async {
    if (gender != null) {
      settings.ttsGender = gender;
    }
    await _save();
  }

  Future<void> updateTagColorTheme(String theme) async {
    settings.tagColorTheme = theme;
    await _save();
  }

  // ========== 과목 관련 ==========

  List<HiveSubject> getSubjects({
    bool favoritesOnly = false,
    List<String> filterTagIds = const [],
  }) {
    List<HiveSubject> list;

    // 미분류 과목과 일반 과목 분리
    final normalSubjects = subjects.values.where((s) => !s.isUncategorized);
    final uncategorizedSubjects = subjects.values.where(
      (s) => s.isUncategorized,
    );

    // 저장된 순서가 있으면 그 순서를 사용, 없으면 알파벳 순
    if (subjectOrder.isNotEmpty) {
      // subjectOrder에 있는 일반 과목들을 순서대로 추가
      list = subjectOrder
          .map((id) => subjects[id])
          .whereType<HiveSubject>()
          .where((s) => !s.isUncategorized)
          .toList();

      // subjectOrder에 없는 일반 과목들을 알파벳 순으로 추가
      final orderedIds = subjectOrder.toSet();
      final remainingSubjects =
          normalSubjects.where((s) => !orderedIds.contains(s.id)).toList()
            ..sort((a, b) => a.title.compareTo(b.title));
      list.addAll(remainingSubjects);
    } else {
      list = normalSubjects.toList()
        ..sort((a, b) => a.title.compareTo(b.title));
    }

    // 일반 과목에만 필터 적용
    if (favoritesOnly) {
      list = list.where((s) => s.favorite).toList();
    }

    if (filterTagIds.isNotEmpty) {
      list = list
          .where((s) => filterTagIds.every((tagId) => s.tagIds.contains(tagId)))
          .toList();
    }

    // 미분류 과목을 항상 마지막에 추가 (필터링 영향 받지 않음)
    list.addAll(uncategorizedSubjects);

    return list;
  }

  HiveSubject? getSubject(String id) => subjects[id];

  Future<void> toggleSubjectFavorite(String id) async {
    final subject = subjects[id];
    if (subject != null) {
      subjects[id] = subject.copyWith(favorite: !subject.favorite);
      await _save();
    }
  }

  Future<void> updateSubject(
    String id, {
    String? title,
    bool? favorite,
    List<String>? tagIds,
    List<String>? lectureIds,
  }) async {
    final subject = subjects[id];
    if (subject != null) {
      subjects[id] = subject.copyWith(
        title: title,
        favorite: favorite,
        tagIds: tagIds,
        lectureIds: lectureIds,
      );
      await _save();
    }
  }

  Future<void> createSubject(String title, List<String> tagIds) async {
    final newId = 'subject_${DateTime.now().millisecondsSinceEpoch}';
    subjects[newId] = HiveSubject(
      id: newId,
      title: title,
      favorite: false,
      tagIds: tagIds,
      lectureIds: [],
    );

    // 새 과목을 순서 목록의 맨 앞에 추가
    if (!subjectOrder.contains(newId)) {
      subjectOrder.insert(0, newId);
    }

    await _save();
  }

  Future<void> deleteSubject(String id) async {
    subjects.remove(id);
    subjectOrder.remove(id); // 순서 목록에서도 제거
    await _save();
  }

  // Convenience wrappers for subjects_edit_screen.dart
  Future<void> updateSubjectTitle(String id, String title) async {
    await updateSubject(id, title: title);
  }

  Future<void> updateSubjectLectures(String id, List<String> lectureIds) async {
    await updateSubject(id, lectureIds: lectureIds);
  }

  Future<void> updateSubjectTags(String id, List<String> tagIds) async {
    await updateSubject(id, tagIds: tagIds);
  }

  /// 과목 순서 업데이트
  Future<void> updateSubjectOrder(List<String> newOrder) async {
    _appData?.subjectOrder.clear();
    _appData?.subjectOrder.addAll(newOrder);
    await _save();
  }

  // ========== 태그 관련 ==========

  List<HiveTag> getTags() {
    final tagList = tags.values.toList();
    tagList.sort((a, b) => _compareTagNames(a.name, b.name));
    return tagList;
  }

  int _compareTagNames(String a, String b) {
    final aType = _getNameType(a);
    final bType = _getNameType(b);
    if (aType != bType) {
      return aType.compareTo(bType);
    }
    return a.compareTo(b);
  }

  int _getNameType(String name) {
    if (name.isEmpty) {
      return 3;
    }
    final first = name[0];
    if (RegExp(r'[0-9]').hasMatch(first)) {
      return 0;
    }
    if (RegExp(r'[ㄱ-ㅎ가-힣]').hasMatch(first)) {
      return 1;
    }
    if (RegExp(r'[a-zA-Z]').hasMatch(first)) {
      return 2;
    }
    return 3;
  }

  Future<void> saveTags(List<HiveTag> newTags) async {
    tags.clear();
    for (final tag in newTags) {
      tags[tag.id] = tag;
    }
    await _save();
  }

  // ========== UI 상태 관련 ==========

  bool getSubjectExpandedState(String subjectId) {
    return uiState.subjectExpandedStates[subjectId] ?? true;
  }

  Future<void> setSubjectExpandedState(String subjectId, bool expanded) async {
    uiState.subjectExpandedStates[subjectId] = expanded;
    await _save();
  }

  List<String> getRecentSearches() => uiState.recentSearches;

  Future<void> addRecentSearch(String query) async {
    if (query.trim().isEmpty) {
      return;
    }

    uiState.recentSearches.remove(query);
    uiState.recentSearches.insert(0, query);

    if (uiState.recentSearches.length > 3) {
      uiState.recentSearches = uiState.recentSearches.sublist(0, 3);
    }

    await _save();
  }

  Future<void> removeRecentSearch(String query) async {
    uiState.recentSearches.remove(query);
    await _save();
  }

  // ========== 강의 관련 ==========

  /// 강의 추가 (백엔드에서 생성 완료 후 호출)
  Future<void> addLecture(HiveLecture lecture) async {
    lectures[lecture.id] = lecture;
    await _save();
  }

  /// 강의 조회
  HiveLecture? getLecture(String id) => lectures[id];

  /// 과목별 강의 목록 (과목의 lectureIds 순서 유지)
  List<HiveLecture> getLecturesBySubject(String subjectId) {
    final subject = subjects[subjectId];
    if (subject == null) {
      return [];
    }

    return subject.lectureIds
        .map((id) => lectures[id])
        .whereType<HiveLecture>()
        .toList();
  }

  /// 여러 강의 ID로 조회 (순서 유지)
  List<HiveLecture> getLecturesByIds(List<String> lectureIds) {
    return lectureIds
        .map((id) => lectures[id])
        .whereType<HiveLecture>()
        .toList();
  }

  /// 강의 업데이트 (백엔드 sync 후)
  Future<void> updateLecture(HiveLecture lecture) async {
    if (lectures.containsKey(lecture.id)) {
      lectures[lecture.id] = lecture;
      await _save();
    }
  }

  /// 강의 메타데이터만 부분 업데이트
  Future<void> updateLectureMetadata(
    String id, {
    String? weekLabel,
    String? title,
  }) async {
    final lecture = lectures[id];
    if (lecture != null) {
      lectures[id] = lecture.copyWith(
        weekLabel: weekLabel,
        title: title,
        updatedAt: DateTime.now(),
      );
      await _save();
    }
  }

  /// 강의를 다른 과목으로 이동
  Future<void> moveLectureToSubject(
    String lectureId,
    String newSubjectId,
  ) async {
    final lecture = lectures[lectureId];
    if (lecture == null) {
      return;
    }

    final oldSubjectId = lecture.subjectId;

    // 같은 과목이면 아무 것도 하지 않음
    if (oldSubjectId == newSubjectId) {
      return;
    }

    // 이전 과목에서 강의 제거
    final oldSubject = subjects[oldSubjectId];
    if (oldSubject != null) {
      final updatedOldIds = oldSubject.lectureIds
          .where((id) => id != lectureId)
          .toList();
      subjects[oldSubjectId] = oldSubject.copyWith(lectureIds: updatedOldIds);
    }

    // 새 과목에 강의 추가
    final newSubject = subjects[newSubjectId];
    if (newSubject != null) {
      if (!newSubject.lectureIds.contains(lectureId)) {
        final updatedNewIds = [...newSubject.lectureIds, lectureId];
        subjects[newSubjectId] = newSubject.copyWith(lectureIds: updatedNewIds);
      }
    }

    // 강의의 subjectId 업데이트
    lectures[lectureId] = lecture.copyWith(
      subjectId: newSubjectId,
      updatedAt: DateTime.now(),
    );

    await _save();
  }

  /// 강의 삭제
  Future<void> deleteLecture(String lectureId) async {
    // 모든 과목에서 제거
    for (final subject in subjects.values) {
      if (subject.lectureIds.contains(lectureId)) {
        final updatedIds = subject.lectureIds
            .where((id) => id != lectureId)
            .toList();
        subjects[subject.id] = subject.copyWith(lectureIds: updatedIds);
      }
    }

    // 강의 데이터 삭제
    lectures.remove(lectureId);
    await _save();
  }

  /// 강의 검색
  List<HiveLecture> searchLectures(String query) {
    if (query.trim().isEmpty) {
      return [];
    }

    final lowerQuery = query.toLowerCase();
    return lectures.values
        .where(
          (lecture) =>
              lecture.title.toLowerCase().contains(lowerQuery) ||
              lecture.weekLabel.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  /// 모든 강의 (생성일 기준 정렬)
  List<HiveLecture> getAllLectures({bool newestFirst = true}) {
    final list = lectures.values.toList();
    list.sort((a, b) {
      if (a.createdAt == null || b.createdAt == null) {
        return 0;
      }
      return newestFirst
          ? b.createdAt!.compareTo(a.createdAt!)
          : a.createdAt!.compareTo(b.createdAt!);
    });
    return list;
  }

  // ========== 유틸리티 ==========

  /// Hive 박스 닫기 (앱 종료 시)
  Future<void> close() async {
    if (!_isInitialized) {
      return;
    }

    if (_appBox.isOpen) {
      await _appBox.close();
    }

    _appData = null;
    _isInitialized = false;
  }

  // ========== 튜토리얼 관련 ==========

  // 튜토리얼 완료 상태 업데이트
  Future<void> completeTutorial() async {
    settings.hasCompletedTutorial = true;
    await _save(); // Hive에 저장
    notifyListeners(); // UI 업데이트 알림
  }

  // 개발/테스트용: 튜토리얼 리셋
  Future<void> resetTutorial() async {
    settings.hasCompletedTutorial = false;
    await _save();
    notifyListeners();
  }
}
