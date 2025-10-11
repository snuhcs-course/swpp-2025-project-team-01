import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:re_view/data/models.dart';

class Repo extends ChangeNotifier {
  Repo._();
  static final Repo instance = Repo._();

  late Directory _docs; // <Documents>/review
  late Directory _dataDir; // <Documents>/review/data

  Map<String, Subject> _subjects = {};
  Map<String, Tag> _tags = {};
  final Map<String, Lecture> _lectures = {}; // 강의 메타는 필요 시 디렉토리별로 로드
  String _currentTagTheme = '파스텔'; // 현재 선택된 태그 색상 테마
  final Map<String, bool> _subjectExpandedStates = {}; // 과목별 펼침/접힘 상태

  Future<void> init() async {
    _docs = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/review',
    );
    _dataDir = Directory('${_docs.path}/data')..createSync(recursive: true);

    await _ensureSeed('subjects.json');
    await _ensureSeed('tags.json');

    await _loadSubjects();
    await _loadTags();
    await _loadTagTheme();
    await loadSubjectExpandedStates();

    // 모든 강의 메타 로드
    final List<String> allLectureIds = _subjects.values
        .expand((s) => s.lectureIds)
        .toSet()
        .toList();
    await preloadLectures(allLectureIds);
  }

  // 없으면 assets/data/<name>을 복사
  Future<void> _ensureSeed(String name) async {
    final File f = File('${_dataDir.path}/$name');
    // 파일이 없을 때만 assets에서 복사
    if (!f.existsSync()) {
      final ByteData bytes = await rootBundle.load('assets/data/$name');
      await f.writeAsBytes(bytes.buffer.asUint8List());
    }
  }

  Future<void> _loadSubjects() async {
    final File f = File('${_dataDir.path}/subjects.json');
    final Map<String, dynamic> j =
        jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    final List<Map<String, dynamic>> list = (j['subjects'] as List)
        .cast<Map<String, dynamic>>();
    _subjects = {
      for (final m in list)
        m['id'] as String: Subject(
          id: m['id'] as String,
          title: m['title'] as String,
          favorite: m['favorite'] as bool? ?? false,
          tagIds: (m['tagIds'] as List).cast<String>(),
          lectureIds: (m['lectureIds'] as List).cast<String>(),
        ),
    };
  }

  Future<void> _loadTags() async {
    final File f = File('${_dataDir.path}/tags.json');
    final Map<String, dynamic> j =
        jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    final List<Map<String, dynamic>> list = (j['tags'] as List)
        .cast<Map<String, dynamic>>();
    _tags = {
      for (final m in list)
        m['id'] as String: Tag(
          id: m['id'] as String,
          name: m['name'] as String,
          color: _parseHex(m['color'] as String),
        ),
    };
  }

  int _parseHex(String str) {
    final String s = str.replaceAll('#', '');
    final int v = int.parse(s, radix: 16);
    return (s.length == 6) ? (0xFF000000 | v) : v; // RRBBGG → AARRGGBB
  }

  // ====== 공개 API (UI에서 사용) ======
  Future<void> ensureReady() async {
    /* 앱 시작 시 main()에서 await Repo.instance.init(); */
  }

  List<Subject> getSubjects({
    bool favoritesOnly = false,
    List<String> filterTagIds = const [],
  }) {
    List<Subject> list = _subjects.values.toList()
      ..sort((a, b) => a.title.compareTo(b.title)); // 또는 order 사용
    if (favoritesOnly) {
      list = list.where((s) => s.favorite).toList();
    }
    if (filterTagIds.isNotEmpty) {
      // intersection: 선택한 모든 태그를 가진 과목만 표시
      list = list
          .where((s) => filterTagIds.every((tagId) => s.tagIds.contains(tagId)))
          .toList();
    }
    return list;
  }

  List<Tag> getTags() {
    final List<Tag> tags = _tags.values.toList();
    tags.sort((a, b) => _compareTagNames(a.name, b.name));
    return tags;
  }

  // 태그 이름 정렬: 숫자 > 한글 > 영어, 각각 사전식
  int compareTagNames(String a, String b) {
    final int aType = _getNameType(a);
    final int bType = _getNameType(b);

    if (aType != bType) {
      return aType.compareTo(bType);
    }

    return a.compareTo(b);
  }

  int _compareTagNames(String a, String b) => compareTagNames(a, b);

  int _getNameType(String name) {
    if (name.isEmpty) {
      return 3;
    }
    final String first = name[0];

    if (RegExp(r'[0-9]').hasMatch(first)) {
      return 0; // 숫자
    }
    if (RegExp(r'[ㄱ-ㅎ가-힣]').hasMatch(first)) {
      return 1; // 한글
    }
    if (RegExp(r'[a-zA-Z]').hasMatch(first)) {
      return 2; // 영어
    }

    return 3; // 기타
  }

  Future<Lecture?> _loadLectureMeta(String lectureId) async {
    if (_lectures.containsKey(lectureId)) {
      return _lectures[lectureId];
    }

    try {
      final String metaString = await rootBundle.loadString(
        'assets/lectures/$lectureId/meta.json',
      );
      final Map<String, dynamic> meta =
          jsonDecode(metaString) as Map<String, dynamic>;

      final Lecture lecture = Lecture(
        id: meta['lectureId'] as String? ?? lectureId,
        subjectId: meta['subjectId'] as String? ?? '',
        weekLabel: meta['weekLabel'] as String? ?? 'Week ?',
        title: meta['title'] as String? ?? 'Untitled',
        durationSec: meta['durationSec'] as int? ?? 0,
        slidesPath: 'assets/lectures/$lectureId/${lectureId}_slides.pdf',
      );

      _lectures[lectureId] = lecture;
      return lecture;
    } catch (e) {
      return null;
    }
  }

  List<Lecture> lecturesBySubject(String subjectId) {
    final Subject? s = _subjects[subjectId];
    if (s == null) {
      return [];
    }

    // 동기적으로 캐시된 강의 반환 (없으면 빈 객체)
    return s.lectureIds
        .map(
          (id) =>
              _lectures[id] ??
              Lecture(
                id: id,
                subjectId: subjectId,
                weekLabel: 'Week ?',
                title: 'Untitled',
                durationSec: 0,
              ),
        )
        .toList();
  }

  Future<void> preloadLectures(List<String> lectureIds) async {
    for (final id in lectureIds) {
      await _loadLectureMeta(id);
    }
  }

  Future<void> toggleSubjectFavorite(String id) async {
    final Subject s = _subjects[id]!;
    _subjects[id] = s.copyWith(favorite: !s.favorite);
    await _saveSubjects();
    notifyListeners();
  }

  // 과목 펼침/접힘 상태 로드
  Future<void> loadSubjectExpandedStates() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? keys = prefs.getStringList('subject_expanded_states');
    if (keys != null) {
      for (final key in keys) {
        final bool? value = prefs.getBool('subject_expanded_$key');
        if (value != null) {
          _subjectExpandedStates[key] = value;
        }
      }
    }
  }

  // 과목 펼침/접힘 상태 저장
  Future<void> saveSubjectExpandedState(String subjectId, bool expanded) async {
    _subjectExpandedStates[subjectId] = expanded;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('subject_expanded_$subjectId', expanded);
    await prefs.setStringList(
      'subject_expanded_states',
      _subjectExpandedStates.keys.toList(),
    );
  }

  // 과목 펼침/접힘 상태 가져오기 (기본값: true)
  bool getSubjectExpandedState(String subjectId) {
    return _subjectExpandedStates[subjectId] ?? true;
  }

  Future<void> _saveSubjects() async {
    final List<Map<String, dynamic>> list = _subjects.values
        .map(
          (s) => {
            'id': s.id,
            'title': s.title,
            'favorite': s.favorite,
            'tagIds': s.tagIds,
            'lectureIds': s.lectureIds,
          },
        )
        .toList();
    final File f = File('${_dataDir.path}/subjects.json');
    await f.writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert({'schemaVersion': 1, 'subjects': list}),
    );
  }

  Future<void> saveTags(List<Tag> tags) async {
    _tags = {for (final t in tags) t.id: t};
    final List<Map<String, dynamic>> list = tags
        .map((t) => {'id': t.id, 'name': t.name, 'color': _toHex(t.color)})
        .toList();
    final File f = File('${_dataDir.path}/tags.json');
    await f.writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert({'schemaVersion': 1, 'tags': list}),
    );
    notifyListeners();
  }

  String _toHex(int argb) =>
      '#${(argb & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0').toUpperCase()}';

  // 태그 색상 테마 로드
  Future<void> _loadTagTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentTagTheme = prefs.getString('tag_color_theme') ?? '파스텔';
  }

  // 태그 색상 테마 저장
  Future<void> saveTagTheme(String themeName) async {
    _currentTagTheme = themeName;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('tag_color_theme', themeName);
  }

  // 현재 태그 색상 테마 가져오기
  String getTagTheme() => _currentTagTheme;

  // 과목 삭제
  Future<void> deleteSubject(String subjectId) async {
    _subjects.remove(subjectId);
    await _saveSubjects();
    notifyListeners();
  }

  // 과목의 수업 순서 업데이트
  Future<void> updateSubjectLectures(
    String subjectId,
    List<String> lectureIds,
  ) async {
    final Subject? s = _subjects[subjectId];
    if (s != null) {
      _subjects[subjectId] = s.copyWith(lectureIds: lectureIds);
      await _saveSubjects();
      notifyListeners();
    }
  }

  // 과목의 태그 업데이트
  Future<void> updateSubjectTags(String subjectId, List<String> tagIds) async {
    final Subject? s = _subjects[subjectId];
    if (s != null) {
      _subjects[subjectId] = s.copyWith(tagIds: tagIds);
      await _saveSubjects();
      notifyListeners();
    }
  }

  // 과목 이름 업데이트
  Future<void> updateSubjectTitle(String subjectId, String newTitle) async {
    final Subject? s = _subjects[subjectId];
    if (s != null) {
      _subjects[subjectId] = s.copyWith(title: newTitle);
      await _saveSubjects();
      notifyListeners();
    }
  }

  // 수업 삭제 (과목에서 제거)
  Future<void> deleteLecture(String subjectId, String lectureId) async {
    final Subject? s = _subjects[subjectId];
    if (s != null) {
      final List<String> newLectureIds = List<String>.from(s.lectureIds)
        ..remove(lectureId);
      _subjects[subjectId] = s.copyWith(lectureIds: newLectureIds);
      _lectures.remove(lectureId);
      await _saveSubjects();
      notifyListeners();
    }
  }

  // 외부에서 수동으로 리스너 알림 (화면 강제 새로고침용)
  void refresh() {
    notifyListeners();
  }

  // 과목 생성
  Future<void> createSubject(String title, List<String> tagIds) async {
    final String newId = 'subject_${DateTime.now().millisecondsSinceEpoch}';
    _subjects[newId] = Subject(
      id: newId,
      title: title,
      favorite: false,
      tagIds: tagIds,
      lectureIds: [],
    );
    await _saveSubjects();
    notifyListeners();
  }

  // 강의 메타데이터 업데이트
  Future<void> updateLecture(
    String lectureId, {
    String? weekLabel,
    String? title,
  }) async {
    final Lecture? lecture = _lectures[lectureId];
    if (lecture != null) {
      _lectures[lectureId] = lecture.copyWith(
        weekLabel: weekLabel,
        title: title,
      );
      // 강의 메타데이터 파일 저장 (필요시 구현)
      notifyListeners();
    }
  }

  // 강의 조회
  Lecture? getLecture(String lectureId) => _lectures[lectureId];
}
