import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class Repo extends ChangeNotifier {
  Repo._();
  static final instance = Repo._();

  late Directory _docs;            // <Documents>/review
  late Directory _dataDir;         // <Documents>/review/data

  Map<String, Subject> _subjects = {};
  Map<String, Tag> _tags = {};
  Map<String, Lecture> _lectures = {}; // 강의 메타는 필요 시 디렉토리별로 로드
  String _currentTagTheme = '파스텔'; // 현재 선택된 태그 색상 테마

  // 홈 화면 새로고침 콜백 (홈 화면에서 등록)
  VoidCallback? _onDataChanged;

  Future<void> init() async {
    _docs = Directory('${(await getApplicationDocumentsDirectory()).path}/review');
    _dataDir = Directory('${_docs.path}/data')..createSync(recursive: true);

    await _ensureSeed('subjects.json');
    await _ensureSeed('tags.json');

    await _loadSubjects();
    await _loadTags();
    await _loadTagTheme();

    // 모든 강의 메타 로드
    final allLectureIds = _subjects.values.expand((s) => s.lectureIds).toSet().toList();
    await preloadLectures(allLectureIds);
  }

  // 없으면 assets/data/<name>을 복사
  Future<void> _ensureSeed(String name) async {
    final f = File('${_dataDir.path}/$name');
    // 파일이 없을 때만 assets에서 복사
    if (!f.existsSync()) {
      final bytes = await rootBundle.load('assets/data/$name');
      await f.writeAsBytes(bytes.buffer.asUint8List());
    }
  }

  Future<void> _loadSubjects() async {
    final f = File('${_dataDir.path}/subjects.json');
    final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    final list = (j['subjects'] as List).cast<Map<String, dynamic>>();
    _subjects = {
      for (final m in list)
        m['id'] as String: Subject(
          id: m['id'],
          title: m['title'],
          favorite: m['favorite'] ?? false,
          tagIds: (m['tagIds'] as List).cast<String>(),
          lectureIds: (m['lectureIds'] as List).cast<String>(),
        )
    };
  }

  Future<void> _loadTags() async {
    final f = File('${_dataDir.path}/tags.json');
    final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    final list = (j['tags'] as List).cast<Map<String, dynamic>>();
    _tags = {
      for (final m in list)
        m['id'] as String: Tag(
          id: m['id'],
          name: m['name'],
          color: _parseHex(m['color']),
        )
    };
  }

  int _parseHex(String str) {
    final s = str.replaceAll('#', '');
    final v = int.parse(s, radix: 16);
    return (s.length == 6) ? (0xFF000000 | v) : v; // RRBBGG → AARRGGBB
  }

  // ====== 공개 API (UI에서 사용) ======
  Future<void> ensureReady() async { /* 앱 시작 시 main()에서 await Repo.instance.init(); */ }

  List<Subject> getSubjects({bool favoritesOnly = false, List<String> filterTagIds = const []}) {
    var list = _subjects.values.toList()
      ..sort((a,b)=> a.title.compareTo(b.title)); // 또는 order 사용
    print('getSubjects - favoritesOnly: $favoritesOnly, filterTagIds: $filterTagIds'); // 디버깅
    if (favoritesOnly) list = list.where((s) => s.favorite).toList();
    if (filterTagIds.isNotEmpty) {
      // intersection: 선택한 모든 태그를 가진 과목만 표시
      list = list.where((s) => filterTagIds.every((tagId) => s.tagIds.contains(tagId))).toList();
      print('Filtered subjects: ${list.map((s) => s.title).toList()}'); // 디버깅
    }
    return list;
  }

  List<Tag> getTags() {
    final tags = _tags.values.toList();
    tags.sort((a, b) => _compareTagNames(a.name, b.name));
    return tags;
  }

  // 태그 이름 정렬: 숫자 > 한글 > 영어, 각각 사전식
  int _compareTagNames(String a, String b) {
    final aType = _getNameType(a);
    final bType = _getNameType(b);

    if (aType != bType) {
      return aType.compareTo(bType);
    }

    return a.compareTo(b);
  }

  int _getNameType(String name) {
    if (name.isEmpty) return 3;
    final first = name[0];

    if (RegExp(r'[0-9]').hasMatch(first)) return 0; // 숫자
    if (RegExp(r'[ㄱ-ㅎ가-힣]').hasMatch(first)) return 1; // 한글
    if (RegExp(r'[a-zA-Z]').hasMatch(first)) return 2; // 영어

    return 3; // 기타
  }

  Future<Lecture?> _loadLectureMeta(String lectureId) async {
    if (_lectures.containsKey(lectureId)) return _lectures[lectureId];

    try {
      final metaString = await rootBundle.loadString('assets/lectures/$lectureId/meta.json');
      final meta = jsonDecode(metaString) as Map<String, dynamic>;

      final lecture = Lecture(
        id: meta['lectureId'] ?? lectureId,
        subjectId: meta['subjectId'] ?? '',
        weekLabel: meta['weekLabel'] ?? 'Week ?',
        title: meta['title'] ?? 'Untitled',
        durationSec: meta['durationSec'] ?? 0,
        slidesPath: 'assets/lectures/$lectureId/${lectureId}_slides.pdf',
      );

      _lectures[lectureId] = lecture;
      print('Loaded lecture: ${lecture.id}, ${lecture.title}, ${lecture.subjectId}'); // 디버깅
      return lecture;
    } catch (e) {
      print('Failed to load lecture $lectureId: $e'); // 디버깅
      return null;
    }
  }

  List<Lecture> lecturesBySubject(String subjectId) {
    final s = _subjects[subjectId];
    if (s == null) return [];

    // 동기적으로 캐시된 강의 반환 (없으면 빈 객체)
    return s.lectureIds.map((id) =>
      _lectures[id] ?? Lecture(id: id, subjectId: subjectId, weekLabel: 'Week ?', title: 'Untitled', durationSec: 0)
    ).toList();
  }

  Future<void> preloadLectures(List<String> lectureIds) async {
    for (final id in lectureIds) {
      await _loadLectureMeta(id);
    }
  }

  Future<void> toggleSubjectFavorite(String id) async {
    final s = _subjects[id]!;
    _subjects[id] = s.copyWith(favorite: !s.favorite);
    await _saveSubjects();
    notifyListeners();
  }

  Future<void> _saveSubjects() async {
    final list = _subjects.values.map((s) => {
      'id': s.id,
      'title': s.title,
      'favorite': s.favorite,
      'tagIds': s.tagIds,
      'lectureIds': s.lectureIds,
    }).toList();
    final f = File('${_dataDir.path}/subjects.json');
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert({'schemaVersion':1,'subjects':list}));
  }

  Future<void> saveTags(List<Tag> tags) async {
    _tags = {for (final t in tags) t.id: t};
    final list = tags.map((t) => {'id': t.id, 'name': t.name, 'color': _toHex(t.color)}).toList();
    final f = File('${_dataDir.path}/tags.json');
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert({'schemaVersion':1,'tags':list}));
    notifyListeners();
  }

  String _toHex(int argb) => '#${(argb & 0xFFFFFFFF).toRadixString(16).padLeft(8,'0').toUpperCase()}';

  // 태그 색상 테마 로드
  Future<void> _loadTagTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _currentTagTheme = prefs.getString('tag_color_theme') ?? '파스텔';
  }

  // 태그 색상 테마 저장
  Future<void> saveTagTheme(String themeName) async {
    _currentTagTheme = themeName;
    final prefs = await SharedPreferences.getInstance();
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
  Future<void> updateSubjectLectures(String subjectId, List<String> lectureIds) async {
    final s = _subjects[subjectId];
    if (s != null) {
      _subjects[subjectId] = s.copyWith(lectureIds: lectureIds);
      await _saveSubjects();
      notifyListeners();
    }
  }

  // 과목의 태그 업데이트
  Future<void> updateSubjectTags(String subjectId, List<String> tagIds) async {
    final s = _subjects[subjectId];
    if (s != null) {
      _subjects[subjectId] = s.copyWith(tagIds: tagIds);
      await _saveSubjects();
      notifyListeners();
    }
  }

  // 수업 삭제 (과목에서 제거)
  Future<void> deleteLecture(String subjectId, String lectureId) async {
    final s = _subjects[subjectId];
    if (s != null) {
      final newLectureIds = List<String>.from(s.lectureIds)..remove(lectureId);
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
    final newId = 'subject_${DateTime.now().millisecondsSinceEpoch}';
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
  Future<void> updateLecture(String lectureId, {String? weekLabel, String? title}) async {
    final lecture = _lectures[lectureId];
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