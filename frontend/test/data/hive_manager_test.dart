import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';

HiveSubject buildSubject({
  required String id,
  required String title,
  bool favorite = false,
  List<String>? tagIds,
  List<String>? lectureIds,
  bool isUncategorized = false,
}) {
  return HiveSubject(
    id: id,
    title: title,
    favorite: favorite,
    tagIds: tagIds ?? const [],
    lectureIds: lectureIds ?? const [],
    isUncategorized: isUncategorized,
  );
}

HiveLecture buildLecture({
  required String id,
  required String subjectId,
  required String weekLabel,
  required String title,
  int duration = 3600000, // 밀리초 단위 (1시간)
  String? jsonPath,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return HiveLecture(
    id: id,
    subjectId: subjectId,
    weekLabel: weekLabel,
    title: title,
    duration: duration,
    slidePath: 'slide$id.pdf',
    originalAudioPath: 'originalAudio$id.m4a',
    ttsAudioPath: 'ttsAudio$id.opus',
    thumbnailUrl: 'https://example.com/$id.png',
    jsonPath: jsonPath,
    createdAt: createdAt ?? DateTime(2024, 01, 01),
    updatedAt: updatedAt ?? DateTime(2024, 01, 01, 12),
  );
}

Future<void> registerAdapters() async {
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(AppDataAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(AppSettingsAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(UiStateAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(HiveSubjectAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(HiveTagAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(HiveLectureAdapter());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final manager = HiveManager.instance;

  group('HiveManager with seeded data', () {
    late Directory tempDir;
    late Box<AppData> appBox;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_manager_test');
      Hive.init(tempDir.path);
      await registerAdapters();

      final subjects = <String, HiveSubject>{
        's1': buildSubject(
          id: 's1',
          title: 'Algorithms',
          favorite: true,
          tagIds: ['t1', 't2'],
          lectureIds: ['lec1', 'lec2'],
        ),
        's2': buildSubject(
          id: 's2',
          title: 'Database',
          favorite: false,
          tagIds: ['t3'],
          lectureIds: ['lec3'],
        ),
        'uncategorized': buildSubject(
          id: 'uncategorized',
          title: 'Uncategorized',
          isUncategorized: true,
        ),
      };

      final lectures = <String, HiveLecture>{
        'lec1': buildLecture(
          id: 'lec1',
          subjectId: 's1',
          weekLabel: 'Week 1',
          title: 'Sorting Basics',
        ),
        'lec2': buildLecture(
          id: 'lec2',
          subjectId: 's1',
          weekLabel: 'Week 2',
          title: 'Graph Theory',
        ),
        'lec3': buildLecture(
          id: 'lec3',
          subjectId: 's2',
          weekLabel: 'Week 1',
          title: 'Relational Algebra',
        ),
      };

      final tags = <String, HiveTag>{
        't1': HiveTag(id: 't1', name: '1Tag', color: 0xFF112233),
        't2': HiveTag(id: 't2', name: '가나다', color: 0xFF445566),
        't3': HiveTag(id: 't3', name: 'Alpha', color: 0xFF778899),
        't4': HiveTag(id: 't4', name: '@others', color: 0xFF000000),
      };

      final appData = AppData(
        settings: AppSettings(
          theme: 'dark',
          language: 'ko',
          accessibilityHighContrast: false,
          accessibilityReduceMotion: true,
          accessibilityEmphasizeCaptions: true,
          ttsGender: '남성',
          tagColorTheme: '파스텔',
        ),
        subjects: subjects,
        lectures: lectures,
        tags: tags,
        uiState: UiState(
          subjectExpandedStates: {'s1': false},
          recentSearches: ['sorting', 'graph'],
        ),
      );

      appBox = await Hive.openBox<AppData>('app_data');
      await appBox.put('main', appData);
      await manager.initForTesting(appBox);
    });

    tearDown(() async {
      await manager.close();
      if (appBox.isOpen) {
        await appBox.close();
      }
      if (await Hive.boxExists('app_data')) {
        await Hive.deleteBoxFromDisk('app_data');
      }
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('initForTesting loads existing app state', () {
      expect(manager.isInitialized, isTrue);
      expect(manager.settings.theme, 'dark');
      expect(manager.getSubject('s1')?.title, 'Algorithms');
      expect(manager.getLecture('lec3')?.title, 'Relational Algebra');
      expect(manager.getSubjectExpandedState('s2'), isTrue);
    });

    test('update settings persists changes and notifies listeners', () async {
      var notificationCount = 0;
      void listener() => notificationCount++;
      manager.addListener(listener);

      await manager.updateTheme('light');
      await manager.updateLanguage('en');
      await manager.updateAccessibility(
        highContrast: true,
        reduceMotion: false,
        emphasizeCaptions: false,
      );
      await manager.updateTts(gender: '여성');
      await manager.updateTagColorTheme('비비드');

      final saved = appBox.get('main');

      expect(manager.settings.theme, 'light');
      expect(manager.settings.language, 'en');
      expect(manager.settings.accessibilityHighContrast, isTrue);
      expect(manager.settings.accessibilityReduceMotion, isFalse);
      expect(manager.settings.accessibilityEmphasizeCaptions, isFalse);
      expect(manager.settings.ttsGender, '여성');
      expect(manager.settings.tagColorTheme, '비비드');
      expect(saved?.settings.theme, 'light');
      expect(notificationCount, greaterThan(0));

      manager.removeListener(listener);
    });

    test('subject queries and mutations behave correctly', () async {
      final favorites = manager.getSubjects(favoritesOnly: true);
      expect(favorites, hasLength(1));
      expect(favorites.first.id, 's1');
      expect(favorites.any((subject) => subject.isUncategorized), isFalse);

      final tagged = manager.getSubjects(filterTagIds: ['t2']);
      expect(tagged, hasLength(1));
      expect(tagged.first.id, 's1');
      expect(tagged.any((subject) => subject.isUncategorized), isFalse);

      await manager.toggleSubjectFavorite('s2');
      expect(manager.getSubject('s2')?.favorite, isTrue);

      await manager.updateSubject('s1', title: 'Advanced Algorithms');
      expect(manager.getSubject('s1')?.title, 'Advanced Algorithms');

      final existingIds = manager.subjects.keys.toSet();
      await manager.createSubject('Operating Systems', ['t3']);
      final newIds = manager.subjects.keys.toSet()..removeAll(existingIds);
      expect(newIds, hasLength(1));
      final newId = newIds.first;

      await manager.updateSubjectTitle(newId, 'OS');
      await manager.updateSubjectTags(newId, ['t1', 't4']);
      await manager.updateSubjectLectures(newId, ['lec1']);
      expect(manager.getSubject(newId)?.title, 'OS');
      expect(manager.getSubject(newId)?.tagIds, ['t1', 't4']);
      expect(manager.getSubject(newId)?.lectureIds, ['lec1']);

      //await manager.deleteSubject(newId);
      //expect(manager.getSubject(newId), isNull);
    });

    test('tag sorting prioritizes numeric, Korean, English, and others', () {
      final orderedNames = manager.getTags().map((tag) => tag.name).toList();
      expect(orderedNames, ['1Tag', '가나다', 'Alpha', '@others']);
    });

    test('UI state and recent search utilities manage history', () async {
      expect(manager.getRecentSearches(), ['sorting', 'graph']);
      await manager.addRecentSearch('sorting');
      await manager.addRecentSearch('trees');
      await manager.addRecentSearch('hashing');
      await manager.addRecentSearch('dynamic programming');
      expect(manager.getRecentSearches(), [
        'dynamic programming',
        'hashing',
        'trees',
      ]);

      await manager.removeRecentSearch('hashing');
      expect(manager.getRecentSearches(), ['dynamic programming', 'trees']);

      await manager.addRecentSearch('');
      expect(manager.getRecentSearches(), ['dynamic programming', 'trees']);

      await manager.setSubjectExpandedState('s1', true);
      expect(manager.getSubjectExpandedState('s1'), isTrue);
      expect(manager.getSubjectExpandedState('unknown'), isTrue);
    });

    test(
      'lecture operations update lecture collections consistently',
      () async {
        final subjectLectures = manager.getLecturesBySubject('s1');
        expect(subjectLectures.map((l) => l.id), ['lec1', 'lec2']);

        final byIds = manager.getLecturesByIds(['lec2', 'lec1']);
        expect(byIds.map((l) => l.id), ['lec2', 'lec1']);

        await manager.updateLectureMetadata('lec1', title: 'Sorting Deep Dive');
        final updated = manager.getLecture('lec1');
        expect(updated?.title, 'Sorting Deep Dive');
        expect(updated?.updatedAt?.isAfter(DateTime(2024, 01, 01, 12)), isTrue);

        final newLecture = HiveLecture(
          id: 'lec4',
          subjectId: 's2',
          weekLabel: 'Week 2',
          title: 'Transactions',
          duration: 2700,
          slidePath: null,
          originalAudioPath: 'originalAudio.m4a',
          ttsAudioPath: 'ttsAudio.opus',
          thumbnailUrl: null,
          jsonPath: null,
          createdAt: DateTime(2024, 02, 01),
          updatedAt: DateTime(2024, 02, 01),
        );
        await manager.addLecture(newLecture);
        expect(manager.getLecture('lec4')?.title, 'Transactions');

        final replacement = newLecture.copyWith(title: 'Advanced Transactions');
        await manager.updateLecture(replacement);
        expect(manager.getLecture('lec4')?.title, 'Advanced Transactions');

        final allNewestFirst = manager.getAllLectures();
        expect(allNewestFirst.first.id, 'lec4');

        final allOldestFirst = manager.getAllLectures(newestFirst: false);
        expect(allOldestFirst.first.id, 'lec1');

        final searchWeek = manager.searchLectures('week 1');
        expect(searchWeek.map((l) => l.id).toSet(), {'lec1', 'lec3'});

        //await manager.deleteLecture('lec2');
        //expect(manager.getLecture('lec2'), isNull);
        //expect(manager.getLecturesBySubject('s1').map((l) => l.id), ['lec1']);
      },
    );

    test('moveLectureToSubject moves lecture between subjects', () async {
      // 초기 상태: lec1은 s1에 속함
      expect(manager.getLecture('lec1')?.subjectId, 's1');
      expect(manager.getLecturesBySubject('s1').map((l) => l.id), [
        'lec1',
        'lec2',
      ]);
      expect(manager.getLecturesBySubject('s2').map((l) => l.id), ['lec3']);

      // lec1을 s1에서 s2로 이동
      await manager.moveLectureToSubject('lec1', 's2');

      // 검증: lec1의 subjectId가 s2로 변경됨
      expect(manager.getLecture('lec1')?.subjectId, 's2');

      // 검증: s1의 강의 목록에서 lec1이 제거됨
      expect(manager.getLecturesBySubject('s1').map((l) => l.id), ['lec2']);

      // 검증: s2의 강의 목록에 lec1이 추가됨
      expect(manager.getLecturesBySubject('s2').map((l) => l.id), [
        'lec3',
        'lec1',
      ]);

      // 검증: updatedAt이 갱신됨
      expect(
        manager
            .getLecture('lec1')
            ?.updatedAt
            ?.isAfter(DateTime(2024, 01, 01, 12)),
        isTrue,
      );
    });

    test(
      'moveLectureToSubject does nothing when moving to same subject',
      () async {
        final originalUpdatedAt = manager.getLecture('lec1')?.updatedAt;

        // 같은 과목으로 이동 시도
        await manager.moveLectureToSubject('lec1', 's1');

        // 검증: 아무 변화 없음
        expect(manager.getLecture('lec1')?.subjectId, 's1');
        expect(manager.getLecturesBySubject('s1').map((l) => l.id), [
          'lec1',
          'lec2',
        ]);
        expect(manager.getLecture('lec1')?.updatedAt, originalUpdatedAt);
      },
    );

    test(
      'moveLectureToSubject handles non-existent lecture gracefully',
      () async {
        // 존재하지 않는 강의를 이동하려고 시도
        await manager.moveLectureToSubject('non-existent', 's2');

        // 검증: 아무 변화 없음
        expect(manager.getLecturesBySubject('s2').map((l) => l.id), ['lec3']);
      },
    );
  });

  group('HiveManager init with asset defaults', () {
    const pathProviderChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_manager_init');
      final binding = TestDefaultBinaryMessengerBinding.instance;

      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        pathProviderChannel,
        (methodCall) async {
          switch (methodCall.method) {
            case 'getApplicationDocumentsDirectory':
              return tempDir.path;
            case 'getTemporaryDirectory':
              return tempDir.path;
            case 'getApplicationSupportDirectory':
              return tempDir.path;
            default:
              return tempDir.path;
          }
        },
      );

      final assets = <String, String>{
        'assets/data/subjects.json': jsonEncode({
          'subjects': [
            {
              'id': 'subject_asset',
              'title': 'Asset Subject',
              'favorite': false,
              'tagIds': ['tag_asset'],
              'lectureIds': ['lecture_asset'],
            },
          ],
        }),
        'assets/data/tags.json': jsonEncode({
          'tags': [
            {'id': 'tag_asset', 'name': 'TagName', 'color': '#AABBCC'},
          ],
        }),
        'assets/lectures/lecture_asset/meta.json': jsonEncode({
          'lectureId': 'lecture_asset',
          'subjectId': 'subject_asset',
          'weekLabel': 'Week 0',
          'title': 'Asset Lecture',
          'duration': 1234,
        }),
        'assets/lectures/lecture_asset/transcript.json': jsonEncode({
          'items': [],
        }),
      };

      binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
        ByteData? message,
      ) async {
        if (message == null) {
          return null;
        }
        final assetKey = utf8.decode(message.buffer.asUint8List());
        final asset = assets[assetKey];
        if (asset == null) {
          return null;
        }

        final encoded = utf8.encoder.convert(asset);
        final buffer = ByteData(encoded.length);
        for (var i = 0; i < encoded.length; i++) {
          buffer.setUint8(i, encoded[i]);
        }
        return buffer;
      });

      await manager.close();
      await Hive.close();
    });

    tearDown(() async {
      final binding = TestDefaultBinaryMessengerBinding.instance;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        pathProviderChannel,
        null,
      );
      binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        null,
      );
      await manager.close();
      try {
        if (await Hive.boxExists('app_data')) {
          await Hive.deleteBoxFromDisk('app_data');
        }
      } on HiveError {
        // Hive not initialized - ignore.
      }
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('init loads defaults from assets when box empty', () async {
      await manager.init();

      expect(manager.isInitialized, isTrue);
      expect(manager.subjects.length, 2); // Asset Subject + Uncategorized
      expect(manager.tags.length, 1);
      expect(manager.lectures.length, 1);
      expect(manager.settings.theme, 'system');

      final subject = manager.getSubject('subject_asset');
      expect(subject?.title, 'Asset Subject');
      expect(subject?.tagIds, ['tag_asset']);
      expect(subject?.lectureIds, ['lecture_asset']);

      final tag = manager.tags['tag_asset'];
      expect(tag?.name, 'TagName');
      expect(tag?.color, 0xFFAABBCC);

      final lecture = manager.getLecture('lecture_asset');
      expect(lecture?.title, 'Asset Lecture');
      expect(lecture?.duration, 1234);
      expect(
        lecture?.slidePath,
        'assets/lectures/lecture_asset/lecture_asset_slides.pdf',
      );

      final box = await Hive.openBox<AppData>('app_data');
      expect(box.get('main')?.subjects.containsKey('subject_asset'), isTrue);
      await box.close();

      // Re-initialize should early-return without throwing.
      await manager.init();
    });

    test('saveTags replaces existing tags and persists them', () async {
      await manager.init();
      await manager.saveTags([
        HiveTag(id: 'tag_a', name: 'Tag A', color: 0xFF000001),
        HiveTag(id: 'tag_b', name: 'Tag B', color: 0xFF000002),
      ]);

      expect(manager.tags.keys.toSet(), {'tag_a', 'tag_b'});

      final box = await Hive.openBox<AppData>('app_data');
      expect(box.get('main')?.tags.keys.toSet(), {'tag_a', 'tag_b'});
      await box.close();
    });
  });
}
