import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pdfx/pdfx.dart';

import 'package:re_view/features/player/core/pdf_cache_service.dart';

import 'pdf_cache_service_test.mocks.dart';

@GenerateMocks([PdfDocument, PdfPage, PdfPageImage])
void main() {
  group('PdfCacheService', () {
    late PdfCacheService service;
    late MockPdfDocument mockPdfDocument;
    late MockPdfPage mockPdfPage;
    late MockPdfPageImage mockPdfPageImage;

    setUp(() {
      service = PdfCacheService();
      mockPdfDocument = MockPdfDocument();
      mockPdfPage = MockPdfPage();
      mockPdfPageImage = MockPdfPageImage();

      // 기본 mock 설정
      when(mockPdfPage.width).thenReturn(100);
      when(mockPdfPage.height).thenReturn(150);
      when(mockPdfPage.close()).thenAnswer((_) async => {});
      when(mockPdfPageImage.bytes).thenReturn(Uint8List.fromList([1, 2, 3, 4]));
    });

    tearDown(() {
      service.clearCache();
    });

    group('LRU Cache', () {
      test('should update LRU when accessing cached page', () async {
        service.setPdfDocument(mockPdfDocument);

        // 첫 번째 페이지 캐싱
        final imageBytes1 = Uint8List.fromList([1, 2, 3]);
        service.setCachedImage(1, imageBytes1);

        // 두 번째 페이지 캐싱
        final imageBytes2 = Uint8List.fromList([4, 5, 6]);
        service.setCachedImage(2, imageBytes2);

        // 첫 번째 페이지 재접근 (LRU 업데이트)
        final result = await service.getCachedOrRenderPage(1);

        expect(result, equals(imageBytes1));
        expect(service.getCacheSize(), equals(2));
      });

      test('should evict oldest page when cache exceeds maxCacheSize', () async {
        service.setPdfDocument(mockPdfDocument);

        // maxCacheSize(30)를 초과하도록 31개 페이지 캐싱
        for (int i = 1; i <= 31; i++) {
          service.setCachedImage(i, Uint8List.fromList([i]));
        }

        // 캐시 크기가 maxCacheSize로 제한되어야 함
        expect(service.getCacheSize(), equals(PdfCacheService.maxCacheSize));

        // 가장 오래된 페이지(1번)는 제거되어야 함
        expect(service.getCachedImageDirect(1), isNull);

        // 가장 최근 페이지(31번)는 존재해야 함
        expect(service.getCachedImageDirect(31), isNotNull);
      });

      test('should maintain LRU order when updating cache', () async {
        service.setPdfDocument(mockPdfDocument);

        // 페이지 1, 2, 3 순서로 캐싱
        service.setCachedImage(1, Uint8List.fromList([1]));
        service.setCachedImage(2, Uint8List.fromList([2]));
        service.setCachedImage(3, Uint8List.fromList([3]));

        // 페이지 1 재접근 (LRU 업데이트)
        await service.getCachedOrRenderPage(1);

        // 28개 더 추가하여 총 31개 (maxCacheSize 초과)
        for (int i = 4; i <= 31; i++) {
          service.setCachedImage(i, Uint8List.fromList([i]));
        }

        // 페이지 2가 가장 오래되었으므로 제거되어야 함
        expect(service.getCachedImageDirect(2), isNull);

        // 페이지 1은 재접근했으므로 유지되어야 함
        expect(service.getCachedImageDirect(1), isNotNull);
      });
    });

    group('Cache Operations', () {
      test('getCachedImageDirect should return cached image', () {
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        service.setCachedImage(1, imageBytes);

        final result = service.getCachedImageDirect(1);

        expect(result, equals(imageBytes));
      });

      test('getCachedImageDirect should return null for non-cached page', () {
        final result = service.getCachedImageDirect(999);

        expect(result, isNull);
      });

      test('setCachedImage should store image in cache', () {
        final imageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        service.setCachedImage(5, imageBytes);

        expect(service.getCachedImageDirect(5), equals(imageBytes));
        expect(service.getCacheSize(), equals(1));
      });

      test('clearCache should remove all cached data', () {
        service.setCachedImage(1, Uint8List.fromList([1]));
        service.setCachedImage(2, Uint8List.fromList([2]));
        service.setCachedImage(3, Uint8List.fromList([3]));

        expect(service.getCacheSize(), equals(3));

        service.clearCache();

        expect(service.getCacheSize(), equals(0));
        expect(service.getCachedImageDirect(1), isNull);
        expect(service.getCachedImageDirect(2), isNull);
        expect(service.getCachedImageDirect(3), isNull);
      });

      test('getCacheSize should return correct cache size', () {
        expect(service.getCacheSize(), equals(0));

        service.setCachedImage(1, Uint8List.fromList([1]));
        expect(service.getCacheSize(), equals(1));

        service.setCachedImage(2, Uint8List.fromList([2]));
        expect(service.getCacheSize(), equals(2));

        service.clearCache();
        expect(service.getCacheSize(), equals(0));
      });

      test('getLoadingCount should return number of pending futures', () async {
        service.setPdfDocument(mockPdfDocument);

        when(mockPdfDocument.getPage(any))
            .thenAnswer((_) async => mockPdfPage);
        when(mockPdfPage.render(
          width: anyNamed('width'),
          height: anyNamed('height'),
          format: anyNamed('format'),
        )).thenAnswer((_) async => mockPdfPageImage);

        // 여러 페이지를 동시에 캐싱 시작 (await 없이)
        service.cacheSinglePage(1);
        service.cacheSinglePage(2);
        service.cacheSinglePage(3);

        // 로딩 중인 Future 개수 확인
        expect(service.getLoadingCount(), greaterThan(0));

        // 모든 렌더링이 완료될 때까지 대기
        await Future.delayed(const Duration(milliseconds: 100));

        // 완료 후에는 로딩 카운트가 0이어야 함
        expect(service.getLoadingCount(), equals(0));
      });
    });

    group('PDF Document Management', () {
      test('setPdfDocument should set the document', () {
        service.setPdfDocument(mockPdfDocument);

        // 문서가 설정되면 캐싱이 가능해야 함
        service.cacheSinglePage(1);

        // 설정되지 않으면 오류가 발생하지 않아야 함
        expect(() => service.cacheSinglePage(1), returnsNormally);
      });

      test('cacheSinglePage should not cache without PDF document', () {
        // PDF 문서를 설정하지 않음
        service.cacheSinglePage(1);

        // 캐시에 아무것도 저장되지 않아야 함
        expect(service.getCacheSize(), equals(0));
        expect(service.getLoadingCount(), equals(0));
      });
    });

    group('Single Page Caching', () {
      test('cacheSinglePage should cache page successfully', () async {
        service.setPdfDocument(mockPdfDocument);

        when(mockPdfDocument.getPage(1)).thenAnswer((_) async => mockPdfPage);
        when(mockPdfPage.render(
          width: anyNamed('width'),
          height: anyNamed('height'),
          format: anyNamed('format'),
        )).thenAnswer((_) async => mockPdfPageImage);

        service.cacheSinglePage(1);

        // 렌더링이 완료될 때까지 대기
        await Future.delayed(const Duration(milliseconds: 100));

        expect(service.getCachedImageDirect(1), isNotNull);
      });

      test('cacheSinglePage should skip if already cached', () async {
        service.setPdfDocument(mockPdfDocument);

        final imageBytes = Uint8List.fromList([1, 2, 3]);
        service.setCachedImage(1, imageBytes);

        service.cacheSinglePage(1);

        // getPage가 호출되지 않아야 함
        verifyNever(mockPdfDocument.getPage(any));
      });

      test('cacheSinglePage should skip if already loading', () async {
        service.setPdfDocument(mockPdfDocument);

        when(mockPdfDocument.getPage(1)).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return mockPdfPage;
        });
        when(mockPdfPage.render(
          width: anyNamed('width'),
          height: anyNamed('height'),
          format: anyNamed('format'),
        )).thenAnswer((_) async => mockPdfPageImage);

        // 첫 번째 캐싱 시작
        service.cacheSinglePage(1);

        // 두 번째 캐싱 시도 (중복)
        service.cacheSinglePage(1);

        // 짧은 대기 후 로딩 카운트 확인
        await Future.delayed(const Duration(milliseconds: 10));

        // getPage가 한 번만 호출되어야 함
        verify(mockPdfDocument.getPage(1)).called(1);
      });
    });

    group('Render and Retry', () {
      test('getCachedOrRenderPage should return cached image immediately',
          () async {
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        service.setCachedImage(1, imageBytes);

        final result = await service.getCachedOrRenderPage(1);

        expect(result, equals(imageBytes));
        verifyNever(mockPdfDocument.getPage(any));
      });

      test('getCachedOrRenderPage should render page if not cached', () async {
        service.setPdfDocument(mockPdfDocument);

        when(mockPdfDocument.getPage(1)).thenAnswer((_) async => mockPdfPage);
        when(mockPdfPage.render(
          width: anyNamed('width'),
          height: anyNamed('height'),
          format: anyNamed('format'),
        )).thenAnswer((_) async => mockPdfPageImage);

        final result = await service.getCachedOrRenderPage(1);

        expect(result, equals(mockPdfPageImage.bytes));
        verify(mockPdfDocument.getPage(1)).called(1);
      });

      test('getCachedOrRenderPage should reuse existing future', () async {
        service.setPdfDocument(mockPdfDocument);

        when(mockPdfDocument.getPage(1)).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return mockPdfPage;
        });
        when(mockPdfPage.render(
          width: anyNamed('width'),
          height: anyNamed('height'),
          format: anyNamed('format'),
        )).thenAnswer((_) async => mockPdfPageImage);

        // 동시에 두 번 요청
        final future1 = service.getCachedOrRenderPage(1);
        final future2 = service.getCachedOrRenderPage(1);

        final results = await Future.wait([future1, future2]);

        expect(results[0], equals(mockPdfPageImage.bytes));
        expect(results[1], equals(mockPdfPageImage.bytes));

        // getPage가 한 번만 호출되어야 함
        verify(mockPdfDocument.getPage(1)).called(1);
      });

      test('should retry on failure up to maxRetries', () async {
        service.setPdfDocument(mockPdfDocument);

        int callCount = 0;
        when(mockPdfDocument.getPage(1)).thenAnswer((_) async {
          callCount++;
          if (callCount <= 2) {
            throw Exception('Render failed');
          }
          return mockPdfPage;
        });
        when(mockPdfPage.render(
          width: anyNamed('width'),
          height: anyNamed('height'),
          format: anyNamed('format'),
        )).thenAnswer((_) async => mockPdfPageImage);

        final result = await service.getCachedOrRenderPage(1);

        expect(result, equals(mockPdfPageImage.bytes));
        expect(callCount, equals(3)); // 첫 시도 + 2번 재시도
      });

      test('should fail after exceeding maxRetries', () async {
        service.setPdfDocument(mockPdfDocument);

        when(mockPdfDocument.getPage(1))
            .thenThrow(Exception('Persistent render failure'));

        expect(
          () => service.getCachedOrRenderPage(1),
          throwsException,
        );
      });

      test('should throw exception when PDF document not loaded', () async {
        // PDF 문서를 설정하지 않음
        expect(
          () => service.getCachedOrRenderPage(1),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Concurrent Rendering Limits', () {
      test('should limit concurrent renders to maxConcurrentRenders', () async {
        service.setPdfDocument(mockPdfDocument);

        int activeRenders = 0;
        int maxActiveRenders = 0;

        when(mockPdfDocument.getPage(any)).thenAnswer((_) async {
          activeRenders++;
          maxActiveRenders =
              activeRenders > maxActiveRenders ? activeRenders : maxActiveRenders;
          await Future.delayed(const Duration(milliseconds: 50));
          activeRenders--;
          return mockPdfPage;
        });
        when(mockPdfPage.render(
          width: anyNamed('width'),
          height: anyNamed('height'),
          format: anyNamed('format'),
        )).thenAnswer((_) async => mockPdfPageImage);

        // maxConcurrentRenders(3)보다 많은 요청
        final futures = [
          service.getCachedOrRenderPage(1),
          service.getCachedOrRenderPage(2),
          service.getCachedOrRenderPage(3),
          service.getCachedOrRenderPage(4),
          service.getCachedOrRenderPage(5),
        ];

        await Future.wait(futures);

        // 동시 렌더링이 maxConcurrentRenders를 초과하지 않아야 함
        expect(
          maxActiveRenders,
          lessThanOrEqualTo(PdfCacheService.maxConcurrentRenders),
        );
      });

      test('should process queued renders after completion', () async {
        service.setPdfDocument(mockPdfDocument);

        when(mockPdfDocument.getPage(any)).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 30));
          return mockPdfPage;
        });
        when(mockPdfPage.render(
          width: anyNamed('width'),
          height: anyNamed('height'),
          format: anyNamed('format'),
        )).thenAnswer((_) async => mockPdfPageImage);

        // 5개 페이지 렌더링 요청
        final futures = [
          service.getCachedOrRenderPage(1),
          service.getCachedOrRenderPage(2),
          service.getCachedOrRenderPage(3),
          service.getCachedOrRenderPage(4),
          service.getCachedOrRenderPage(5),
        ];

        final results = await Future.wait(futures);

        // 모든 페이지가 성공적으로 렌더링되어야 함
        expect(results.length, equals(5));
        for (var result in results) {
          expect(result, equals(mockPdfPageImage.bytes));
        }
      });
    });

    group('Edge Cases', () {
      test('should handle null pageImage', () async {
        service.setPdfDocument(mockPdfDocument);

        when(mockPdfDocument.getPage(1)).thenAnswer((_) async => mockPdfPage);
        when(mockPdfPage.render(
          width: anyNamed('width'),
          height: anyNamed('height'),
          format: anyNamed('format'),
        )).thenAnswer((_) async => null);

        expect(
          () => service.getCachedOrRenderPage(1),
          throwsException,
        );
      });

      test('should clean up futures on error', () async {
        service.setPdfDocument(mockPdfDocument);

        when(mockPdfDocument.getPage(1))
            .thenThrow(Exception('Render error'));

        try {
          await service.getCachedOrRenderPage(1);
        } catch (e) {
          // 예외 발생 예상
        }

        // Future가 정리되어야 함
        await Future.delayed(const Duration(milliseconds: 500));
        expect(service.getLoadingCount(), equals(0));
      });

      test('should handle rapid cache eviction', () {
        // maxCacheSize의 2배만큼 빠르게 캐싱
        for (int i = 1; i <= PdfCacheService.maxCacheSize * 2; i++) {
          service.setCachedImage(i, Uint8List.fromList([i % 256]));
        }

        expect(service.getCacheSize(), equals(PdfCacheService.maxCacheSize));

        // 처음 30개는 제거되었어야 함
        expect(service.getCachedImageDirect(1), isNull);
        expect(service.getCachedImageDirect(30), isNull);

        // 마지막 30개는 유지되어야 함
        expect(service.getCachedImageDirect(31), isNotNull);
        expect(service.getCachedImageDirect(60), isNotNull);
      });

      test('should handle huge cache', () {
        // 매우 큰 이미지 데이터를 생성 (10MB)
        final hugeImageBytes = Uint8List(10 * 1024 * 1024);
        for (int i = 0; i < hugeImageBytes.length; i++) {
          hugeImageBytes[i] = i % 256;
        }

        // 큰 이미지를 캐싱
        service.setCachedImage(1, hugeImageBytes);

        // 캐시에 정상적으로 저장되어야 함
        expect(service.getCachedImageDirect(1), isNotNull);
        expect(service.getCachedImageDirect(1)?.length, equals(hugeImageBytes.length));

        // 추가 페이지를 캐싱해도 정상 동작해야 함
        service.setCachedImage(2, Uint8List.fromList([1, 2, 3]));
        expect(service.getCacheSize(), equals(2));
      });
    });
  });
}
