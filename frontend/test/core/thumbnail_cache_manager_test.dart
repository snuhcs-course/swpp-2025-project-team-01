import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:pdfx/pdfx.dart';

import 'package:re_view/core/thumbnail_cache_manager.dart';

import 'thumbnail_cache_manager_test.mocks.dart';

@GenerateNiceMocks([MockSpec<PdfPageImage>()])
void main() {
  late ThumbnailCacheManager manager;

  setUp(() {
    manager = ThumbnailCacheManager.instance;
    manager.clear(); // ensure clean state before each test
  });

  group('ThumbnailCacheManager basic operations', () {
    test('put() stores and get() retrieves CachedThumbnail', () {
      final mockImage = MockPdfPageImage();
      const lectureId = 'lecture-1';
      const aspectRatio = 1.5;

      expect(manager.size, 0);
      expect(manager.contains(lectureId), isFalse);

      manager.put(lectureId, mockImage, aspectRatio);

      expect(manager.size, 1);
      expect(manager.contains(lectureId), isTrue);

      final cached = manager.get(lectureId);
      expect(cached, isNotNull);
      expect(cached!.image, same(mockImage));
      expect(cached.aspectRatio, aspectRatio);
    });

    test(
      'get() for unknown lectureId returns null and does not change size',
      () {
        final mockImage = MockPdfPageImage();

        manager.put('existing', mockImage, 1.0);

        expect(manager.size, 1);
        final result = manager.get('non-existing');
        expect(result, isNull);
        expect(manager.size, 1);
      },
    );

    test('put() replaces existing entry and updates aspect ratio', () {
      final mockImage1 = MockPdfPageImage();
      final mockImage2 = MockPdfPageImage();
      const lectureId = 'lecture-1';

      manager.put(lectureId, mockImage1, 1.0);
      expect(manager.size, 1);

      manager.put(lectureId, mockImage2, 2.0);
      expect(manager.size, 1); // still 1, replaced

      final cached = manager.get(lectureId);
      expect(cached, isNotNull);
      expect(cached!.image, same(mockImage2));
      expect(cached.aspectRatio, 2.0);
    });

    test('remove() removes specific lecture from cache', () {
      final mockImage1 = MockPdfPageImage();
      final mockImage2 = MockPdfPageImage();

      manager.put('lecture-1', mockImage1, 1.0);
      manager.put('lecture-2', mockImage2, 2.0);

      expect(manager.size, 2);
      expect(manager.contains('lecture-1'), isTrue);

      manager.remove('lecture-1');

      expect(manager.size, 1);
      expect(manager.contains('lecture-1'), isFalse);
      expect(manager.contains('lecture-2'), isTrue);
    });

    test('clear() removes all entries', () {
      final mockImage1 = MockPdfPageImage();
      final mockImage2 = MockPdfPageImage();

      manager.put('lecture-1', mockImage1, 1.0);
      manager.put('lecture-2', mockImage2, 2.0);

      expect(manager.size, 2);

      manager.clear();

      expect(manager.size, 0);
      expect(manager.contains('lecture-1'), isFalse);
      expect(manager.contains('lecture-2'), isFalse);
    });
  });

  group('ThumbnailCacheManager LRU behavior', () {
    test('evicts oldest when capacity is exceeded', () {
      // We know _maxCacheSize is 50 from the implementation.
      const maxSize = 50;

      // Fill the cache with 0..49
      for (var i = 0; i < maxSize; i++) {
        manager.put('lecture-$i', MockPdfPageImage(), 1.0);
      }

      expect(manager.size, maxSize);
      expect(manager.contains('lecture-0'), isTrue);
      expect(manager.contains('lecture-49'), isTrue);

      // Adding one more should evict the oldest (lecture-0)
      manager.put('lecture-50', MockPdfPageImage(), 1.0);

      expect(manager.size, maxSize);
      expect(manager.contains('lecture-0'), isFalse);
      expect(manager.contains('lecture-1'), isTrue);
      expect(manager.contains('lecture-50'), isTrue);
    });

    test('get() updates recency so item is not evicted next', () {
      const maxSize = 50;

      // Fill 0..49
      for (var i = 0; i < maxSize; i++) {
        manager.put('lecture-$i', MockPdfPageImage(), 1.0);
      }

      // Access lecture-0 so it becomes most recently used
      final cached = manager.get('lecture-0');
      expect(cached, isNotNull);

      // Now when we add lecture-50, the LRU should evict lecture-1, not lecture-0
      manager.put('lecture-50', MockPdfPageImage(), 1.0);

      expect(manager.size, maxSize);
      expect(
        manager.contains('lecture-0'),
        isTrue,
        reason: 'recently used, should remain',
      );
      expect(
        manager.contains('lecture-1'),
        isFalse,
        reason: 'oldest unaccessed, should be evicted',
      );
      expect(manager.contains('lecture-50'), isTrue);
    });
  });
}
