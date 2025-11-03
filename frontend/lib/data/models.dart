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