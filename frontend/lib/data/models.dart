// MVP용 모델 3종 (한 파일)
/// 태그 모델 클래스
class Tag {
  const Tag({required this.id, required this.name, required this.color});

  final String id;
  final String name;
  final int color; // 0xFF... ARGB
}

/// 강의 모델 클래스
class Lecture {
  const Lecture({
    required this.id,
    required this.subjectId,
    required this.weekLabel,
    required this.title,
    required this.durationSec,
    this.thumbs = const [],
    this.slidesPath,
  });

  final String id;
  final String subjectId;
  final String weekLabel;
  final String title;
  final int durationSec;
  final List<String> thumbs; // 이미지 경로/URL
  final String? slidesPath; // PDF 슬라이드 경로

  Lecture copyWith({String? weekLabel, String? title}) => Lecture(
    id: id,
    subjectId: subjectId,
    weekLabel: weekLabel ?? this.weekLabel,
    title: title ?? this.title,
    durationSec: durationSec,
    thumbs: thumbs,
    slidesPath: slidesPath,
  );
}

/// 과목 모델 클래스
class Subject {
  const Subject({
    required this.id,
    required this.title,
    this.favorite = false,
    this.tagIds = const [],
    this.lectureIds = const [],
  });

  final String id;
  final String title;
  final bool favorite;
  final List<String> tagIds;
  final List<String> lectureIds;

  Subject copyWith({
    String? title,
    bool? favorite,
    List<String>? tagIds,
    List<String>? lectureIds,
  }) => Subject(
    id: id,
    title: title ?? this.title,
    favorite: favorite ?? this.favorite,
    tagIds: tagIds ?? this.tagIds,
    lectureIds: lectureIds ?? this.lectureIds,
  );
}
