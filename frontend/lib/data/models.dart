// MVP용 모델 3종 (한 파일)
import 'package:re_view/data/hive_models.dart';

/// 강의 모델 클래스
class Lecture {
  const Lecture({
    required this.id,
    required this.subjectId,
    required this.weekLabel,
    required this.title,
    required this.duration,
    this.thumbs = const [],
    this.slidesPath,
  });

  final String id;
  final String subjectId;
  final String weekLabel;
  final String title;
  final int duration;
  final List<String> thumbs; // 이미지 경로/URL
  final String? slidesPath; // PDF 슬라이드 경로

  Lecture copyWith({String? weekLabel, String? title}) => Lecture(
    id: id,
    subjectId: subjectId,
    weekLabel: weekLabel ?? this.weekLabel,
    title: title ?? this.title,
    duration: duration,
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
    this.isUncategorized = false,
  });

  final String id;
  final String title;
  final bool favorite;
  final List<String> tagIds;
  final List<String> lectureIds;
  final bool isUncategorized; // 미분류 과목 여부

  Subject copyWith({
    String? title,
    bool? favorite,
    List<String>? tagIds,
    List<String>? lectureIds,
    bool? isUncategorized,
  }) => Subject(
    id: id,
    title: title ?? this.title,
    favorite: favorite ?? this.favorite,
    tagIds: tagIds ?? this.tagIds,
    lectureIds: lectureIds ?? this.lectureIds,
    isUncategorized: isUncategorized ?? this.isUncategorized,
  );

  /// Convert to HiveSubject for storage
  HiveSubject toHiveSubject() {
    return HiveSubject(
      id: id,
      title: title,
      favorite: favorite,
      tagIds: tagIds,
      lectureIds: lectureIds,
      isUncategorized: isUncategorized,
    );
  }
}
