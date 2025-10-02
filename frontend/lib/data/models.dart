// MVP용 모델 3종 (한 파일)
/// 태그 모델 클래스
class Tag {
  final String id;
  final String name;
  final int color; // 0xFF... ARGB
  const Tag({required this.id, required this.name, required this.color});
}

/// 강의 모델 클래스
class Lecture {
  final String id;
  final String subjectId;
  final String weekLabel;
  final String title;
  final int durationSec;
  final List<String> thumbs; // 이미지 경로/URL
  final String? slidesPath; // PDF 슬라이드 경로
  const Lecture({
    required this.id,
    required this.subjectId,
    required this.weekLabel,
    required this.title,
    required this.durationSec,
    this.thumbs = const [],
    this.slidesPath,
  });
}

/// 과목 모델 클래스
class Subject {
  final String id;
  final String title;
  final bool favorite;
  final List<String> tagIds;
  final List<String> lectureIds;
  const Subject({
    required this.id,
    required this.title,
    this.favorite = false,
    this.tagIds = const [],
    this.lectureIds = const [],
  });

  Subject copyWith({bool? favorite}) =>
      Subject(id: id, title: title, favorite: favorite ?? this.favorite, tagIds: tagIds, lectureIds: lectureIds);
}