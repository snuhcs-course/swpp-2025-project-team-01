// 매우 단순한 메모리 저장소 (나중에 로컬/원격으로 교체)
import 'models.dart';

class Repo {
  Repo._();
  static final instance = Repo._();

  final Map<String, Tag> _tags = {
    't1': const Tag(id: 't1', name: '25-2', color: 0xFFEFF0A4),
    't2': const Tag(id: 't2', name: '전필', color: 0xFF9BB2BF),
  };

  final Map<String, Lecture> _lectures = {
    'l1': const Lecture(id: 'l1', subjectId: 's1', weekLabel: 'Week 1-1', title: 'Course Overview', durationSec: 4056),
    'l2': const Lecture(id: 'l2', subjectId: 's1', weekLabel: 'Week 1-2', title: 'AI App Examples', durationSec: 3920),
    'l3': const Lecture(id: 'l3', subjectId: 's2', weekLabel: 'Week 2-1', title: 'Software Processes', durationSec: 4070),
  };

  final Map<String, Subject> _subjects = {
    's1': const Subject(id: 's1', title: '소프트웨어 개발의 원리와 실습', favorite: true, tagIds: ['t1', 't2'], lectureIds: ['l1','l2']),
    's2': const Subject(id: 's2', title: '외계행성과 생명', tagIds: ['t1'], lectureIds: ['l3']),
  };

  List<Subject> getSubjects({bool favoritesOnly = false, List<String> filterTagIds = const []}) {
    var list = _subjects.values.toList();
    if (favoritesOnly) list = list.where((s) => s.favorite).toList();
    if (filterTagIds.isNotEmpty) {
      list = list.where((s) => s.tagIds.any(filterTagIds.contains)).toList();
    }
    return list;
  }

  List<Lecture> lecturesBySubject(String subjectId) =>
      _subjects[subjectId]?.lectureIds.map((id) => _lectures[id]!).toList() ?? [];

  List<Tag> getTags() => _tags.values.toList();

  void toggleSubjectFavorite(String id) {
    final s = _subjects[id]!;
    _subjects[id] = s.copyWith(favorite: !s.favorite);
  }
}