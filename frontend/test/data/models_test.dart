import 'package:flutter_test/flutter_test.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/data/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tag model', () {
    test('toHiveTag converts to persistence model', () {
      const tag = Tag(id: 'tag1', name: 'Algorithms', color: 0xFFABCDEF);
      final hiveTag = tag.toHiveTag();

      expect(hiveTag, isA<HiveTag>());
      expect(hiveTag.id, 'tag1');
      expect(hiveTag.name, 'Algorithms');
      expect(hiveTag.color, 0xFFABCDEF);
    });
  });

  group('Lecture model', () {
    test('copyWith returns new lecture with overrides', () {
      const lecture = Lecture(
        id: 'lec1',
        subjectId: 'subject1',
        weekLabel: 'Week 1',
        title: 'Introduction',
        durationSec: 3600,
        thumbs: ['thumb.png'],
        slidesPath: 'slides/lec1.pdf',
      );

      final copy = lecture.copyWith();

      final updated = lecture.copyWith(
        weekLabel: 'Week 2',
        title: 'Advanced Topics',
      );

      expect(updated.id, 'lec1');
      expect(updated.subjectId, 'subject1');
      expect(updated.weekLabel, 'Week 2');
      expect(updated.title, 'Advanced Topics');
      expect(updated.durationSec, 3600);
      expect(updated.thumbs, ['thumb.png']);
      expect(updated.slidesPath, 'slides/lec1.pdf');
      expect(identical(copy.weekLabel, lecture.weekLabel), isTrue);
      expect(identical(copy.title, lecture.title), isTrue);
      expect(identical(updated, lecture), isFalse);
    });
  });

  group('Subject model', () {
    test('copyWith updates properties while keeping defaults', () {
      const subject = Subject(
        id: 'subject1',
        title: 'Algorithms',
        favorite: false,
        tagIds: ['t1'],
        lectureIds: ['lec1'],
      );

      final copy = subject.copyWith();

      final updated = subject.copyWith(
        title: 'Advanced Algorithms',
        favorite: true,
        tagIds: ['t1', 't2'],
      );

      expect(updated.id, 'subject1');
      expect(updated.title, 'Advanced Algorithms');
      expect(updated.favorite, isTrue);
      expect(updated.tagIds, ['t1', 't2']);
      expect(updated.lectureIds, ['lec1']);
      expect(identical(copy.title, subject.title), isTrue);
      expect(identical(copy.favorite, subject.favorite), isTrue);
      expect(identical(copy.tagIds, subject.tagIds), isTrue);
      expect(identical(updated, subject), isFalse);
    });

    test('toHiveSubject converts to persistence model', () {
      const subject = Subject(
        id: 'subject1',
        title: 'Algorithms',
        favorite: true,
        tagIds: ['t1', 't2'],
        lectureIds: ['lec1'],
      );

      final hiveSubject = subject.toHiveSubject();
      expect(hiveSubject, isA<HiveSubject>());
      expect(hiveSubject.id, 'subject1');
      expect(hiveSubject.title, 'Algorithms');
      expect(hiveSubject.favorite, isTrue);
      expect(hiveSubject.tagIds, ['t1', 't2']);
      expect(hiveSubject.lectureIds, ['lec1']);
    });
  });
}
