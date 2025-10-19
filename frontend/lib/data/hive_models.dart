import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import 'package:re_view/data/models.dart';

part 'hive_models.g.dart'; // 코드 생성 파일

/// Hive에 저장할 통합 앱 데이터 모델
@HiveType(typeId: 0)
class AppData extends HiveObject {
  AppData({
    AppSettings? settings,
    Map<String, HiveSubject>? subjects,
    Map<String, HiveTag>? tags,
    Map<String, HiveLecture>? lectures,
    UiState? uiState,
  }) {
    this.settings = settings ?? AppSettings();
    this.subjects = subjects ?? {};
    this.tags = tags ?? {};
    this.lectures = lectures ?? {};
    this.uiState = uiState ?? UiState();
  }

  @HiveField(0)
  late AppSettings settings;

  @HiveField(1)
  late Map<String, HiveSubject> subjects;

  @HiveField(2)
  late Map<String, HiveTag> tags;

  @HiveField(3)
  late UiState uiState;

  @HiveField(4)
  late Map<String, HiveLecture> lectures;
}

/// 앱 설정 (테마, 언어, 접근성, TTS 등)
@HiveType(typeId: 1)
class AppSettings {
  AppSettings({
    this.theme = 'system',
    this.language = 'ko',
    this.accessibilityHighContrast = false,
    this.accessibilityReduceMotion = false,
    this.accessibilityEmphasizeCaptions = true,
    this.ttsGender = '남성',
    this.ttsSpeed = '보통',
    this.tagColorTheme = '파스텔',
  });

  @HiveField(0)
  String theme; // 'light', 'dark', 'system'

  @HiveField(1)
  String language; // 'ko', 'en'

  @HiveField(2)
  bool accessibilityHighContrast;

  @HiveField(3)
  bool accessibilityReduceMotion;

  @HiveField(4)
  bool accessibilityEmphasizeCaptions;

  @HiveField(5)
  String ttsGender; // '남성', '여성'

  @HiveField(6)
  String ttsSpeed; // '빠르게', '보통', '느리게'

  @HiveField(7)
  String tagColorTheme; // '파스텔', etc.
}

/// UI 상태 (과목 펼침/접힘, 최근 검색어 등)
@HiveType(typeId: 2)
class UiState {
  UiState({
    Map<String, bool>? subjectExpandedStates,
    List<String>? recentSearches,
  }) : subjectExpandedStates = subjectExpandedStates ?? {},
       recentSearches = recentSearches ?? [];

  @HiveField(0)
  Map<String, bool> subjectExpandedStates;

  @HiveField(1)
  List<String> recentSearches;
}

/// 과목 모델
@HiveType(typeId: 3)
class HiveSubject {
  HiveSubject({
    required this.id,
    required this.title,
    this.favorite = false,
    List<String>? tagIds,
    List<String>? lectureIds,
  }) : tagIds = tagIds ?? [],
       lectureIds = lectureIds ?? [];

  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool favorite;

  @HiveField(3)
  List<String> tagIds;

  @HiveField(4)
  List<String> lectureIds;

  HiveSubject copyWith({
    String? id,
    String? title,
    bool? favorite,
    List<String>? tagIds,
    List<String>? lectureIds,
  }) {
    return HiveSubject(
      id: id ?? this.id,
      title: title ?? this.title,
      favorite: favorite ?? this.favorite,
      tagIds: tagIds ?? this.tagIds,
      lectureIds: lectureIds ?? this.lectureIds,
    );
  }

  /// Convert to models.dart Subject
  Subject toSubject() {
    return Subject(
      id: id,
      title: title,
      favorite: favorite,
      tagIds: tagIds,
      lectureIds: lectureIds,
    );
  }
}

/// 태그 모델
@HiveType(typeId: 4)
class HiveTag {
  HiveTag({required this.id, required this.name, required this.color});

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int color; // ARGB 형식

  HiveTag copyWith({String? id, String? name, int? color}) {
    return HiveTag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  /// Convert to models.dart Tag
  Tag toTag() {
    return Tag(id: id, name: name, color: color);
  }
}

/// 강의 모델 (백엔드에서 생성된 완성품)
@HiveType(typeId: 5)
class HiveLecture {
  HiveLecture({
    required this.id,
    required this.subjectId,
    required this.weekLabel,
    required this.title,
    required this.durationSec,
    this.slidePath,
    required this.audioPaths,
    this.thumbnailUrl,
    this.transcriptPaths,
    this.createdAt,
    this.updatedAt,
  });

  /// 백엔드 API 응답에서 생성
  factory HiveLecture.fromJson(
    Map<String, dynamic> json,
    List<String?> audioPaths,
    List<String> jsonPaths,
  ) {
    return HiveLecture(
      id: json['id'] as String,
      subjectId: json['subject_id'] as String,
      weekLabel: json['week_label'] as String,
      title: json['title'] as String,
      durationSec: json['duration_sec'] as int,
      slidePath: json['slides_url'] as String?,
      audioPaths: audioPaths,
      thumbnailUrl: json['thumbnail_url'] as String?,
      transcriptPaths: jsonPaths,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  @HiveField(0)
  String id;

  @HiveField(1)
  String subjectId;

  @HiveField(2)
  String weekLabel;

  @HiveField(3)
  String title;

  @HiveField(4)
  int durationSec;

  @HiveField(5)
  String? slidePath; // 백엔드 파일 경로 (PDF)

  @HiveField(6)
  List<String?>? audioPaths; // 백엔드 파일 경로 (오디오)

  @HiveField(7)
  String? thumbnailUrl; // 썸네일 이미지 URL

  @HiveField(8)
  List<String>? transcriptPaths; // 자막/스크립트 JSON 경로

  @HiveField(9)
  DateTime? createdAt;

  @HiveField(10)
  DateTime? updatedAt;

  /// 백엔드로 전송할 JSON (필요 시)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'week_label': weekLabel,
      'title': title,
      'duration_sec': durationSec,
      'slides_url': slidePath,
      'audio_url': audioPaths,
      'thumbnail_url': thumbnailUrl,
      'transcript_url': transcriptPaths,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// models.dart Lecture로 변환 (UI 레이어용)
  Lecture toLecture() {
    return Lecture(
      id: id,
      subjectId: subjectId,
      weekLabel: weekLabel,
      title: title,
      durationSec: durationSec,
      slidesPath: slidePath, // URL을 path로 사용
      thumbs: thumbnailUrl != null ? [thumbnailUrl!] : [],
    );
  }

  HiveLecture copyWith({
    String? id,
    String? subjectId,
    String? weekLabel,
    String? title,
    int? durationSec,
    String? slidePath,
    List<String?>? audioPaths,
    String? thumbnailUrl,
    List<String>? transcriptPaths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HiveLecture(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      weekLabel: weekLabel ?? this.weekLabel,
      title: title ?? this.title,
      durationSec: durationSec ?? this.durationSec,
      slidePath: slidePath ?? this.slidePath,
      audioPaths: audioPaths ?? this.audioPaths,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      transcriptPaths: transcriptPaths ?? this.transcriptPaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 데모 강의 로드 (개발/테스트용, assets에서)
  static Future<HiveLecture?> fromAssets(String lectureId) async {
    try {
      final metaString = await rootBundle.loadString(
        'assets/lectures/$lectureId/meta.json',
      );
      final meta = jsonDecode(metaString) as Map<String, dynamic>;

      return HiveLecture(
        id: meta['lectureId'] as String? ?? lectureId,
        subjectId: meta['subjectId'] as String? ?? '',
        weekLabel: meta['weekLabel'] as String? ?? 'Week ?',
        title: meta['title'] as String? ?? 'Untitled',
        durationSec: meta['durationSec'] as int? ?? 0,
        slidePath: 'assets/lectures/$lectureId/${lectureId}_slides.pdf',
        audioPaths: null, // 데모는 로컬 파일 사용
        thumbnailUrl: null,
        transcriptPaths: ['assets/lectures/$lectureId/transcript.json'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Failed to load demo lecture $lectureId: $e');
      return null;
    }
  }
}
