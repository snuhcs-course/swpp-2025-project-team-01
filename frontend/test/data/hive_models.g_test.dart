// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
// ignore: implementation_imports
import 'package:hive/src/binary/binary_reader_impl.dart';
// ignore: implementation_imports
import 'package:hive/src/binary/binary_writer_impl.dart';
// ignore: implementation_imports
import 'package:hive/src/hive_impl.dart';
import 'package:re_view/data/hive_models.dart';

class _AdapterBundle {
  _AdapterBundle({
    required this.registry,
    required this.appData,
    required this.appSettings,
    required this.uiState,
    required this.hiveSubject,
    required this.hiveTag,
    required this.hiveLecture,
  });

  final HiveImpl registry;
  final AppDataAdapter appData;
  final AppSettingsAdapter appSettings;
  final UiStateAdapter uiState;
  final HiveSubjectAdapter hiveSubject;
  final HiveTagAdapter hiveTag;
  final HiveLectureAdapter hiveLecture;
}

_AdapterBundle _createBundle() {
  final registry = HiveImpl();
  final appData = AppDataAdapter();
  final appSettings = AppSettingsAdapter();
  final uiState = UiStateAdapter();
  final hiveSubject = HiveSubjectAdapter();
  final hiveTag = HiveTagAdapter();
  final hiveLecture = HiveLectureAdapter();

  registry.registerAdapter(appData);
  registry.registerAdapter(appSettings);
  registry.registerAdapter(uiState);
  registry.registerAdapter(hiveSubject);
  registry.registerAdapter(hiveTag);
  registry.registerAdapter(hiveLecture);

  return _AdapterBundle(
    registry: registry,
    appData: appData,
    appSettings: appSettings,
    uiState: uiState,
    hiveSubject: hiveSubject,
    hiveTag: hiveTag,
    hiveLecture: hiveLecture,
  );
}

T _roundTrip<T>(_AdapterBundle bundle, TypeAdapter<T> adapter, T value) {
  final writer = BinaryWriterImpl(bundle.registry);
  adapter.write(writer, value);
  final bytes = writer.toBytes();
  final reader = BinaryReaderImpl(bytes, bundle.registry);
  return adapter.read(reader);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppDataAdapter', () {
    test('typeId matches annotation', () {
      expect(AppDataAdapter().typeId, 0);
    });

    test('serializes and deserializes AppData with nested values', () {
      final bundle = _createBundle();
      final data = AppData(
        settings: AppSettings(
          theme: 'dark',
          language: 'en',
          accessibilityHighContrast: true,
          accessibilityReduceMotion: true,
          accessibilityEmphasizeCaptions: false,
          ttsGender: '여성',
          ttsSpeed: '빠르게',
          tagColorTheme: '비비드',
        ),
        subjects: {
          's1': HiveSubject(
            id: 's1',
            title: 'Subject',
            favorite: true,
            tagIds: const ['t1'],
            lectureIds: const ['lec1'],
          ),
        },
        tags: {'t1': HiveTag(id: 't1', name: 'Tag', color: 0xFF010203)},
        lectures: {
          'lec1': HiveLecture(
            id: 'lec1',
            subjectId: 's1',
            weekLabel: 'Week 1',
            title: 'Lecture',
            duration: 100,
            slidePath: 'slides/lec1.pdf',
            audioPath: 'audio.mp3',
            thumbnailUrl: 'thumb.png',
            jsonPath: 'timestamps.json',
            createdAt: DateTime.utc(2024, 1, 1),
            updatedAt: DateTime.utc(2024, 1, 2),
          ),
        },
        uiState: UiState(
          subjectExpandedStates: {'s1': false},
          recentSearches: ['query'],
        ),
      );

      final roundTripped = _roundTrip(bundle, bundle.appData, data);

      expect(roundTripped.settings.theme, 'dark');
      expect(roundTripped.subjects['s1']?.title, 'Subject');
      expect(roundTripped.tags['t1']?.color, 0xFF010203);
      expect(roundTripped.lectures['lec1']?.title, 'Lecture');
      expect(roundTripped.uiState.recentSearches, ['query']);
    });
  });

  group('AppSettingsAdapter', () {
    test('typeId matches annotation', () {
      expect(AppSettingsAdapter().typeId, 1);
    });

    test('round-trips mutable fields', () {
      final bundle = _createBundle();
      final original = AppSettings(
        theme: 'light',
        language: 'ko',
        accessibilityHighContrast: true,
        accessibilityReduceMotion: true,
        accessibilityEmphasizeCaptions: false,
        ttsGender: '남성',
        ttsSpeed: '느리게',
        tagColorTheme: '파스텔',
      );

      final result = _roundTrip(bundle, bundle.appSettings, original);
      expect(result.theme, 'light');
      expect(result.accessibilityReduceMotion, isTrue);
      expect(result.ttsSpeed, '느리게');
      expect(result.tagColorTheme, '파스텔');
    });
  });

  group('UiStateAdapter', () {
    test('typeId matches annotation', () {
      expect(UiStateAdapter().typeId, 2);
    });

    test('round-trips UI state maps and lists', () {
      final bundle = _createBundle();
      final original = UiState(
        subjectExpandedStates: {'s1': false, 's2': true},
        recentSearches: ['a', 'b'],
      );
      final result = _roundTrip(bundle, bundle.uiState, original);
      expect(result.subjectExpandedStates['s1'], isFalse);
      expect(result.subjectExpandedStates['s2'], isTrue);
      expect(result.recentSearches, ['a', 'b']);
    });
  });

  group('HiveSubjectAdapter', () {
    test('typeId matches annotation', () {
      expect(HiveSubjectAdapter().typeId, 3);
    });

    test('round-trips subject data', () {
      final bundle = _createBundle();
      final subject = HiveSubject(
        id: 'subject',
        title: 'Algorithms',
        favorite: true,
        tagIds: const <String>['t1', 't2'],
        lectureIds: const <String>['lec1'],
      );
      final result = _roundTrip(bundle, bundle.hiveSubject, subject);
      expect(result.id, 'subject');
      expect(result.favorite, isTrue);
      expect(result.tagIds, ['t1', 't2']);
      expect(result.lectureIds, ['lec1']);
    });
  });

  group('HiveTagAdapter', () {
    test('typeId matches annotation', () {
      expect(HiveTagAdapter().typeId, 4);
    });

    test('round-trips tag data', () {
      final bundle = _createBundle();
      final tag = HiveTag(id: 't1', name: 'Label', color: 0xFFAABBCC);
      final result = _roundTrip(bundle, bundle.hiveTag, tag);
      expect(result.id, 't1');
      expect(result.name, 'Label');
      expect(result.color, 0xFFAABBCC);
    });
  });

  group('HiveLectureAdapter', () {
    test('typeId matches annotation', () {
      expect(HiveLectureAdapter().typeId, 5);
    });

    test('round-trips lecture with optional fields', () {
      final bundle = _createBundle();
      final lecture = HiveLecture(
        id: 'lec',
        subjectId: 'subject',
        weekLabel: 'Week 5',
        title: 'Advanced Topics',
        duration: 3600,
        slidePath: null,
        audioPath: 'audio.mp3',
        thumbnailUrl: null,
        jsonPath: 'timestamps.json',
        createdAt: DateTime.utc(2024, 2, 1),
        updatedAt: DateTime.utc(2024, 2, 2),
      );

      final result = _roundTrip(bundle, bundle.hiveLecture, lecture);
      expect(result.id, 'lec');
      expect(result.audioPath, 'audio.mp3');
      expect(result.thumbnailUrl, isNull);
      expect(result.jsonPath, 'timestamps.json');
      expect(result.createdAt, DateTime.utc(2024, 2, 1));
      expect(result.updatedAt, DateTime.utc(2024, 2, 2));
    });
  });

  group('Cross-model testing', () {
    test('distinguishable by == operator', () {
      final dataAdapter1 = AppDataAdapter();
      final dataAdapter2 = AppDataAdapter();
      final settingsAdapter1 = AppSettingsAdapter();
      final settingsAdapter2 = AppSettingsAdapter();
      final uistateAdapter1 = UiStateAdapter();
      final uistateAdapter2 = UiStateAdapter();
      final subjectAdapter1 = HiveSubjectAdapter();
      final subjectAdapter2 = HiveSubjectAdapter();
      final tagAdapter1 = HiveTagAdapter();
      final tagAdapter2 = HiveTagAdapter();
      final lectureAdapter1 = HiveLectureAdapter();
      final lectureAdapter2 = HiveLectureAdapter();

      // Same-type equality
      expect(dataAdapter1 == dataAdapter2, isTrue);
      expect(settingsAdapter1 == settingsAdapter2, isTrue);
      expect(uistateAdapter1 == uistateAdapter2, isTrue);
      expect(subjectAdapter1 == subjectAdapter2, isTrue);
      expect(tagAdapter1 == tagAdapter2, isTrue);
      expect(lectureAdapter1 == lectureAdapter2, isTrue);

      // Cross-type inequality
      expect(dataAdapter1 == settingsAdapter1, isFalse);
      expect(dataAdapter1 == uistateAdapter1, isFalse);
      expect(dataAdapter1 == subjectAdapter1, isFalse);
      expect(dataAdapter1 == tagAdapter1, isFalse);
      expect(dataAdapter1 == lectureAdapter1, isFalse);
      expect(settingsAdapter1 == uistateAdapter1, isFalse);
      expect(settingsAdapter1 == subjectAdapter1, isFalse);
      expect(settingsAdapter1 == tagAdapter1, isFalse);
      expect(settingsAdapter1 == lectureAdapter1, isFalse);
      expect(uistateAdapter1 == subjectAdapter1, isFalse);
      expect(uistateAdapter1 == tagAdapter1, isFalse);
      expect(uistateAdapter1 == lectureAdapter1, isFalse);
      expect(subjectAdapter1 == tagAdapter1, isFalse);
      expect(subjectAdapter1 == lectureAdapter1, isFalse);
      expect(tagAdapter1 == lectureAdapter1, isFalse);
    });

    test('distinguishable by type hashCode', () {
      final dataAdapter1 = AppDataAdapter();
      final dataAdapter2 = AppDataAdapter();
      final settingsAdapter1 = AppSettingsAdapter();
      final settingsAdapter2 = AppSettingsAdapter();
      final uistateAdapter1 = UiStateAdapter();
      final uistateAdapter2 = UiStateAdapter();
      final subjectAdapter1 = HiveSubjectAdapter();
      final subjectAdapter2 = HiveSubjectAdapter();
      final tagAdapter1 = HiveTagAdapter();
      final tagAdapter2 = HiveTagAdapter();
      final lectureAdapter1 = HiveLectureAdapter();
      final lectureAdapter2 = HiveLectureAdapter();

      // Same-type hashCode equality
      expect(dataAdapter1.hashCode == dataAdapter2.hashCode, isTrue);
      expect(settingsAdapter1.hashCode == settingsAdapter2.hashCode, isTrue);
      expect(uistateAdapter1.hashCode == uistateAdapter2.hashCode, isTrue);
      expect(subjectAdapter1.hashCode == subjectAdapter2.hashCode, isTrue);
      expect(tagAdapter1.hashCode == tagAdapter2.hashCode, isTrue);
      expect(lectureAdapter1.hashCode == lectureAdapter2.hashCode, isTrue);

      // Cross-type hashCode inequality
      expect(dataAdapter1.hashCode == settingsAdapter1.hashCode, isFalse);
      expect(dataAdapter1.hashCode == uistateAdapter1.hashCode, isFalse);
      expect(dataAdapter1.hashCode == subjectAdapter1.hashCode, isFalse);
      expect(dataAdapter1.hashCode == tagAdapter1.hashCode, isFalse);
      expect(dataAdapter1.hashCode == lectureAdapter1.hashCode, isFalse);
      expect(settingsAdapter1.hashCode == uistateAdapter1.hashCode, isFalse);
      expect(settingsAdapter1.hashCode == subjectAdapter1.hashCode, isFalse);
      expect(settingsAdapter1.hashCode == tagAdapter1.hashCode, isFalse);
      expect(settingsAdapter1.hashCode == lectureAdapter1.hashCode, isFalse);
      expect(uistateAdapter1.hashCode == subjectAdapter1.hashCode, isFalse);
      expect(uistateAdapter1.hashCode == tagAdapter1.hashCode, isFalse);
      expect(uistateAdapter1.hashCode == lectureAdapter1.hashCode, isFalse);
      expect(subjectAdapter1.hashCode == tagAdapter1.hashCode, isFalse);
      expect(subjectAdapter1.hashCode == lectureAdapter1.hashCode, isFalse);
      expect(tagAdapter1.hashCode == lectureAdapter1.hashCode, isFalse);
    });
  });
}
