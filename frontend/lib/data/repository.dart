import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'models.dart';

/// 데이터 저장소 클래스 (싱글톤)
class Repo {
  Repo._();
  static final instance = Repo._();

  late Directory _docs;            // <Documents>/review
  late Directory _dataDir;         // <Documents>/review/data

  Map<String, Subject> _subjects = {};
  Map<String, Tag> _tags = {};
  Map<String, Lecture> _lectures = {}; // 강의 메타는 필요 시 디렉토리별로 로드

  Future<void> init() async {
    _docs = Directory('${(await getApplicationDocumentsDirectory()).path}/review');
    _dataDir = Directory('${_docs.path}/data')..createSync(recursive: true);

    await _ensureSeed('subjects.json');
    await _ensureSeed('tags.json');

    await _loadSubjects();
    await _loadTags();

    // 모든 강의 메타 로드
    final allLectureIds = _subjects.values.expand((s) => s.lectureIds).toSet().toList();
    await preloadLectures(allLectureIds);
  }

  // 없으면 assets/data/<name>을 복사 (항상 최신 버전으로 덮어쓰기)
  Future<void> _ensureSeed(String name) async {
    final f = File('${_dataDir.path}/$name');
    // 항상 최신 assets 데이터로 덮어쓰기 (개발 중)
    final bytes = await rootBundle.load('assets/data/$name');
    await f.writeAsBytes(bytes.buffer.asUint8List());
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

  List<Tag> getTags() => _tags.values.toList();

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
  }

  Future<void> updateLecture(String lectureId, {String? weekLabel, String? title}) async {
    final lecture = _lectures[lectureId];
    if (lecture == null) return;

    _lectures[lectureId] = lecture.copyWith(
      weekLabel: weekLabel,
      title: title,
    );
  }

  Lecture? getLecture(String lectureId) => _lectures[lectureId];

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
  }

  String _toHex(int argb) => '#${(argb & 0xFFFFFFFF).toRadixString(16).padLeft(8,'0').toUpperCase()}';
}