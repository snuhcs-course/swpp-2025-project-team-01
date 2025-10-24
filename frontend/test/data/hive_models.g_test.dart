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
            durationSec: 100,
            slidePath: 'slides/lec1.pdf',
            audioPaths: const <String?>['audio.mp3'],
            thumbnailUrl: 'thumb.png',
            transcriptPaths: const ['transcript.json'],
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
        durationSec: 3600,
        slidePath: null,
        audioPaths: const <String?>[null, 'audio_2.mp3'],
        thumbnailUrl: null,
        transcriptPaths: const ['tran.json'],
        createdAt: DateTime.utc(2024, 2, 1),
        updatedAt: DateTime.utc(2024, 2, 2),
      );

      final result = _roundTrip(bundle, bundle.hiveLecture, lecture);
      expect(result.id, 'lec');
      expect(result.audioPaths, [null, 'audio_2.mp3']);
      expect(result.thumbnailUrl, isNull);
      expect(result.transcriptPaths, ['tran.json']);
      expect(result.createdAt, DateTime.utc(2024, 2, 1));
      expect(result.updatedAt, DateTime.utc(2024, 2, 2));
    });
  });
}
