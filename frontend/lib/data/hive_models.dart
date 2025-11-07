import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';

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
    List<String>? subjectOrder,
  }) {
    this.settings = settings ?? AppSettings();
    this.subjects = subjects ?? {};
    this.tags = tags ?? {};
    this.lectures = lectures ?? {};
    this.uiState = uiState ?? UiState();
    this.subjectOrder = subjectOrder ?? [];
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

  @HiveField(5)
  late List<String> subjectOrder;
}

/// 앱 설정 (테마, 언어, 접근성, TTS 등)
@HiveType(typeId: 1)
class AppSettings {
  AppSettings({
    this.theme = 'system',
    this.language = 'ko',
    this.accessibilityHighContrast = false,
    this.accessibilityReduceMotion = false,
    this.accessibilityEmphasizeCaptions = false,
    this.ttsGender = '남성',
    this.tagColorTheme = '봄',
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
  String tagColorTheme; // '봄', '여름', '가을', '겨울', '솜사탕', '비비드', '바다'
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
    this.isUncategorized = false,
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

  @HiveField(5)
  bool isUncategorized;

  HiveSubject copyWith({
    String? id,
    String? title,
    bool? favorite,
    List<String>? tagIds,
    List<String>? lectureIds,
    bool? isUncategorized,
  }) {
    return HiveSubject(
      id: id ?? this.id,
      title: title ?? this.title,
      favorite: favorite ?? this.favorite,
      tagIds: tagIds ?? this.tagIds,
      lectureIds: lectureIds ?? this.lectureIds,
      isUncategorized: isUncategorized ?? this.isUncategorized,
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
}

/// 강의 모델 (백엔드에서 생성된 완성품)
@HiveType(typeId: 5)
class HiveLecture {
  HiveLecture({
    required this.id,
    required this.subjectId,
    required this.weekLabel,
    required this.title,
    required this.duration,
    this.slidePath,
    required this.originalAudioPath,
    required this.ttsAudioPath,
    this.thumbnailUrl,
    this.jsonPath,
    this.createdAt,
    this.updatedAt,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String subjectId;

  @HiveField(2)
  String weekLabel;

  @HiveField(3)
  String title;

  @HiveField(4)
  int duration;

  @HiveField(5)
  String? slidePath; // 파일 경로 (PDF)

  @HiveField(6)
  String originalAudioPath; // 원본 오디오 파일 경로

  @HiveField(7)
  String ttsAudioPath; // TTS 오디오 파일 경로

  @HiveField(8)
  String? thumbnailUrl; // 썸네일 이미지 URL

  @HiveField(9)
  String? jsonPath; // 자막/스크립트 JSON 경로

  @HiveField(10)
  DateTime? createdAt;

  @HiveField(11)
  DateTime? updatedAt;

  HiveLecture copyWith({
    String? id,
    String? subjectId,
    String? weekLabel,
    String? title,
    int? duration,
    String? slidePath,
    String? originalAudioPath,
    String? ttsAudioPath,
    String? thumbnailUrl,
    String? jsonPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HiveLecture(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      weekLabel: weekLabel ?? this.weekLabel,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      slidePath: slidePath ?? this.slidePath,
      originalAudioPath: originalAudioPath ?? this.originalAudioPath,
      ttsAudioPath: ttsAudioPath ?? this.ttsAudioPath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      jsonPath: jsonPath ?? this.jsonPath,
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
        duration: meta['duration'] as int? ?? 0,
        slidePath: 'assets/lectures/$lectureId/${lectureId}_slides.pdf',
        originalAudioPath: 'assets/lectures/$lectureId/${lectureId}_audio.m4a',
        ttsAudioPath:
            'assets/lectures/$lectureId/${lectureId}_audio.opus', // 데모는 로컬 파일 사용
        thumbnailUrl: null,
        jsonPath: 'assets/lectures/$lectureId/transcript.json',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Failed to load demo lecture $lectureId: $e');
      return null;
    }
  }
}
