import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/data/models.dart';

ByteData _encodeAsset(String value) {
  final bytes = utf8.encoder.convert(value);
  final data = ByteData(bytes.length);
  for (var i = 0; i < bytes.length; i++) {
    data.setUint8(i, bytes[i]);
  }
  return data;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppData', () {
    test('defaults to empty collections and default settings', () {
      final data = AppData();
      expect(data.settings.theme, 'system');
      expect(data.subjects, isEmpty);
      expect(data.tags, isEmpty);
      expect(data.lectures, isEmpty);
      expect(data.uiState.subjectExpandedStates, isEmpty);
      expect(data.uiState.recentSearches, isEmpty);
    });

    test('respects provided instances', () {
      final subjects = {'id': HiveSubject(id: 'id', title: 'Title')};
      final tags = {'tag': HiveTag(id: 'tag', name: 'Tag', color: 0xFF000001)};
      final lectures = {
        'lec': HiveLecture(
          id: 'lec',
          subjectId: 'id',
          weekLabel: 'Week 1',
          title: 'Lecture',
          duration: 60,
          originalAudioPath: null,
          ttsAudioPath: null,
        ),
      };
      final state = UiState(
        subjectExpandedStates: {'id': false},
        recentSearches: ['a'],
      );
      final settings = AppSettings(theme: 'dark');

      final data = AppData(
        settings: settings,
        subjects: subjects,
        tags: tags,
        lectures: lectures,
        uiState: state,
      );

      expect(identical(data.settings, settings), isTrue);
      expect(identical(data.subjects, subjects), isTrue);
      expect(identical(data.tags, tags), isTrue);
      expect(identical(data.lectures, lectures), isTrue);
      expect(identical(data.uiState, state), isTrue);
    });
  });

  group('AppSettings', () {
    test('default values', () {
      final settings = AppSettings();
      expect(settings.theme, 'system');
      expect(settings.language, 'ko');
      expect(settings.accessibilityHighContrast, isFalse);
      expect(settings.accessibilityReduceMotion, isFalse);
      expect(settings.accessibilityEmphasizeCaptions, isTrue);
      expect(settings.ttsGender, '남성');
      expect(settings.ttsSpeed, '보통');
      expect(settings.tagColorTheme, '봄');
    });

    test('allows mutation of fields', () {
      final settings = AppSettings(theme: 'light', language: 'en');
      settings.accessibilityHighContrast = true;
      settings.ttsGender = '여성';
      settings.tagColorTheme = '비비드';

      expect(settings.theme, 'light');
      expect(settings.language, 'en');
      expect(settings.accessibilityHighContrast, isTrue);
      expect(settings.ttsGender, '여성');
      expect(settings.tagColorTheme, '비비드');
    });
  });

  group('UiState', () {
    test('defaults to empty collections', () {
      final state = UiState();
      expect(state.subjectExpandedStates, isEmpty);
      expect(state.recentSearches, isEmpty);
    });

    test('uses provided references', () {
      final expanded = {'id': false};
      final searches = ['algo'];
      final state = UiState(
        subjectExpandedStates: expanded,
        recentSearches: searches,
      );
      expect(identical(state.subjectExpandedStates, expanded), isTrue);
      expect(identical(state.recentSearches, searches), isTrue);
    });
  });

  group('HiveSubject', () {
    test('copyWith applies overrides', () {
      final subject = HiveSubject(
        id: 'id',
        title: 'Original',
        favorite: false,
        tagIds: const ['t1'],
        lectureIds: const ['l1'],
      );

      final copy = subject.copyWith(
        title: 'Updated',
        favorite: true,
        tagIds: const ['t2'],
      );

      expect(copy.id, 'id');
      expect(copy.title, 'Updated');
      expect(copy.favorite, isTrue);
      expect(copy.tagIds, ['t2']);
      expect(copy.lectureIds, ['l1']);
    });

    test('toSubject converts to UI model', () {
      final hive = HiveSubject(
        id: 'id',
        title: 'Title',
        favorite: true,
        tagIds: const ['tag'],
        lectureIds: const ['lecture'],
      );
      final subject = hive.toSubject();
      expect(subject, isA<Subject>());
      expect(subject.id, 'id');
      expect(subject.favorite, isTrue);
      expect(subject.tagIds, ['tag']);
      expect(subject.lectureIds, ['lecture']);
    });
  });

  group('HiveTag', () {
    test('copyWith updates fields selectively', () {
      final tag = HiveTag(id: 'id', name: 'Old', color: 0xFF000001);
      final copy = tag.copyWith(name: 'New');
      expect(copy.id, 'id');
      expect(copy.name, 'New');
      expect(copy.color, 0xFF000001);
    });

    test('toTag converts to Tag model', () {
      final tag = HiveTag(id: 'id', name: 'Label', color: 0xFF123456);
      final converted = tag.toTag();
      expect(converted, isA<Tag>());
      expect(converted.id, 'id');
      expect(converted.name, 'Label');
      expect(converted.color, 0xFF123456);
    });
  });

  group('HiveLecture', () {
    test('copyWith overrides single field', () {
      final base = HiveLecture(
        id: 'lec1',
        subjectId: 'sub1',
        weekLabel: 'Week 1',
        title: 'Intro',
        duration: 120,
        slidePath: '/slides.pdf',
        originalAudioPath: 'original.mp3',
        ttsAudioPath: 'tts.mp3',
        thumbnailUrl: 'thumb',
        jsonPath: 'timestamps.json',
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 2),
      );

      final copy = base.copyWith(title: 'Updated', duration: 240);
      expect(copy.title, 'Updated');
      expect(copy.duration, 240);
      expect(copy.subjectId, 'sub1');
      expect(copy.slidePath, '/slides.pdf');
    });

    test('toLecture converts to lightweight model', () {
      final hive = HiveLecture(
        id: 'lec1',
        subjectId: 'sub1',
        weekLabel: 'Week 1',
        title: 'Intro',
        duration: 120,
        slidePath: '/slides.pdf',
        originalAudioPath: 'original.mp3',
        ttsAudioPath: 'tts.mp3',
        thumbnailUrl: 'https://example.com/thumb.png',
        jsonPath: 'timestamps.json',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final lecture = hive.toLecture();
      expect(lecture, isA<Lecture>());
      expect(lecture.id, 'lec1');
      expect(lecture.weekLabel, 'Week 1');
      expect(lecture.title, 'Intro');
      expect(lecture.duration, 120);
      expect(lecture.slidesPath, '/slides.pdf');
      expect(lecture.thumbs, ['https://example.com/thumb.png']);
    });
  });

  group('HiveLecture.fromAssets', () {
    const channel = 'flutter/assets';
    late Map<String, String> assets;

    setUp(() {
      assets = {};
      final binding = TestDefaultBinaryMessengerBinding.instance;
      binding.defaultBinaryMessenger.setMockMessageHandler(channel, (
        ByteData? message,
      ) async {
        if (message == null) {
          return null;
        }
        final key = utf8.decoder.convert(message.buffer.asUint8List());
        final asset = assets[key];
        if (asset == null) {
          return null;
        }
        return _encodeAsset(asset);
      });
    });

    tearDown(() {
      final binding = TestDefaultBinaryMessengerBinding.instance;
      binding.defaultBinaryMessenger.setMockMessageHandler(channel, null);
    });

    test('returns lecture populated from asset metadata', () async {
      assets['assets/lectures/demo/meta.json'] = jsonEncode({
        'lectureId': 'demo',
        'subjectId': 'subject',
        'weekLabel': 'Week 3',
        'title': 'Asset Title',
        'duration': 321,
      });
      assets['assets/lectures/demo/transcript.json'] = jsonEncode({
        'lines': [],
      });

      final lecture = await HiveLecture.fromAssets('demo');

      expect(lecture, isNotNull);
      expect(lecture?.id, 'demo');
      expect(lecture?.subjectId, 'subject');
      expect(lecture?.weekLabel, 'Week 3');
      expect(lecture?.title, 'Asset Title');
      expect(lecture?.duration, 321);
      expect(lecture?.slidePath, 'assets/lectures/demo/demo_slides.pdf');
      expect(lecture?.jsonPath, 'assets/lectures/demo/transcript.json');
      expect(lecture?.createdAt, isNotNull);
      expect(lecture?.updatedAt, isNotNull);
    });

    test('returns null when metadata missing or invalid', () async {
      assets.remove('assets/lectures/missing/meta.json');
      final lecture = await HiveLecture.fromAssets('missing');
      expect(lecture, isNull);
    });

    test('uses fallback values when metadata incomplete', () async {
      assets['assets/lectures/minimal/meta.json'] = jsonEncode(
        <String, dynamic>{},
      );
      assets['assets/lectures/minimal/transcript.json'] = jsonEncode({});

      final lecture = await HiveLecture.fromAssets('minimal');

      expect(lecture, isNotNull);
      expect(lecture?.id, 'minimal');
      expect(lecture?.subjectId, '');
      expect(lecture?.weekLabel, 'Week ?');
      expect(lecture?.title, 'Untitled');
      expect(lecture?.duration, 0);
    });
  });
}
