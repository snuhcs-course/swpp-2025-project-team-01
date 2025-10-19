import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdfx/pdfx.dart';

/// PDF 페이지 이미지 캐싱 서비스
///
/// 동시 렌더링 제한과 큐를 통해 안정적인 PDF 렌더링을 제공합니다.
class PdfCacheService {
  // PDF 페이지 이미지 캐싱
  final Map<int, Uint8List> _pageImageCache = {};
  final Map<int, Future<Uint8List>> _pageImageFutures = {};
  static const int cacheChunkSize = 20;

  // 동시 렌더링 제한 (최대 3개까지만 동시에 렌더링)
  static const int maxConcurrentRenders = 3;
  int _currentRenderingCount = 0;
  final List<_RenderRequest> _renderQueue = [];

  // 재시도 관련
  static const int maxRetries = 2;
  final Map<int, int> _retryCount = {};

  PdfDocument? _pdfDocument;

  /// PDF 문서 설정
  void setPdfDocument(PdfDocument? document) {
    _pdfDocument = document;
  }

  /// 특정 페이지가 속한 청크의 시작 페이지 번호 계산
  /// 1번 페이지는 별도, 2-21, 22-41, 42-61...
  int getChunkStartPage(int pageNumber) {
    if (pageNumber == 1) {
      return 1;
    }
    // 2페이지부터는 20개 단위 청크
    return ((pageNumber - 2) ~/ cacheChunkSize) * cacheChunkSize + 2;
  }

  /// 단일 페이지만 캐싱 (아직 캐싱되지 않은 경우에만)
  void cacheSinglePage(int pageNumber) {
    if (_pdfDocument == null) {
      return;
    }

    // 이미 캐싱되었거나 로딩 중이면 스킵
    if (_pageImageCache.containsKey(pageNumber) ||
        _pageImageFutures.containsKey(pageNumber)) {
      return;
    }

    // 페이지 렌더링 시작
    final future = _renderPdfPage(pageNumber);
    _pageImageFutures[pageNumber] = future;

    future
        .then((imageBytes) {
          _pageImageCache[pageNumber] = imageBytes;
          _pageImageFutures.remove(pageNumber);
          debugPrint('✓ PDF Cache: Successfully cached page $pageNumber');
        })
        .catchError((error) {
          debugPrint(
            '✗ PDF Cache ERROR: Failed to cache page $pageNumber - $error',
          );
          _pageImageFutures.remove(pageNumber);
        });
  }

  /// PDF 페이지를 렌더링하여 이미지 바이트 반환
  Future<Uint8List> _renderPdfPage(int pageNumber) async {
    if (_pdfDocument == null) {
      throw Exception('PDF document not loaded');
    }

    try {
      final page = await _pdfDocument!.getPage(pageNumber);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );
      await page.close();

      if (pageImage == null) {
        throw Exception(
          'Failed to render PDF page $pageNumber: pageImage is null',
        );
      }

      return pageImage.bytes;
    } catch (e) {
      debugPrint('✗ PDF Cache ERROR: Render failed for page $pageNumber - $e');
      rethrow;
    }
  }

  /// 캐시된 이미지 또는 Future를 반환 (큐 기반 렌더링)
  Future<Uint8List> getCachedOrRenderPage(int pageNumber) {
    // 이미 캐시된 경우 - 즉시 반환
    if (_pageImageCache.containsKey(pageNumber)) {
      return Future.value(_pageImageCache[pageNumber]!);
    }

    // 로딩 중인 경우 - 기존 Future 재사용 (중복 렌더링 방지)
    if (_pageImageFutures.containsKey(pageNumber)) {
      return _pageImageFutures[pageNumber]!;
    }

    // 새로운 렌더링 요청 - 큐에 추가하고 처리
    return _queueRenderRequest(pageNumber);
  }

  /// 렌더링 요청을 큐에 추가하고 처리 (재시도 포함)
  Future<Uint8List> _queueRenderRequest(int pageNumber) {
    // Future 생성 (나중에 완료됨)
    final completer = Future<Uint8List>.sync(() async {
      // 동시 렌더링 제한 확인
      while (_currentRenderingCount >= maxConcurrentRenders) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 렌더링 시작
      _currentRenderingCount++;
      final retryAttempt = _retryCount[pageNumber] ?? 0;
      debugPrint(
        '→ PDF Cache: Starting render for page $pageNumber (attempt ${retryAttempt + 1}/${maxRetries + 1}, concurrent: $_currentRenderingCount/$maxConcurrentRenders)',
      );

      try {
        final imageBytes = await _renderPdfPage(pageNumber);
        _pageImageCache[pageNumber] = imageBytes;
        _retryCount.remove(pageNumber); // 성공 시 재시도 카운트 제거
        debugPrint('✓ PDF Cache: Successfully cached page $pageNumber');
        return imageBytes;
      } catch (error) {
        final currentRetry = _retryCount[pageNumber] ?? 0;

        if (currentRetry < maxRetries) {
          // 재시도 가능
          _retryCount[pageNumber] = currentRetry + 1;
          debugPrint(
            '⚠ PDF Cache: Failed to render page $pageNumber (attempt ${currentRetry + 1}/${maxRetries + 1}), will retry - $error',
          );

          // 잠시 대기 후 재시도
          await Future.delayed(
            Duration(milliseconds: 200 * (currentRetry + 1)),
          );

          // 재귀적으로 재시도 (현재 렌더링 카운트 감소시키고 다시 큐에 추가)
          _currentRenderingCount--;
          _pageImageFutures.remove(pageNumber);
          return await _queueRenderRequest(pageNumber);
        } else {
          // 최대 재시도 횟수 초과
          _retryCount.remove(pageNumber);
          debugPrint(
            '✗ PDF Cache ERROR: Failed to render page $pageNumber after ${maxRetries + 1} attempts - $error',
          );
          rethrow;
        }
      } finally {
        _currentRenderingCount--;
        _pageImageFutures.remove(pageNumber);
        debugPrint(
          '← PDF Cache: Finished with page $pageNumber (concurrent: $_currentRenderingCount/$maxConcurrentRenders)',
        );
      }
    });

    _pageImageFutures[pageNumber] = completer;
    return completer;
  }

  /// 캐시된 이미지 직접 조회 (동기적으로 즉시 반환)
  Uint8List? getCachedImageDirect(int pageNumber) {
    return _pageImageCache[pageNumber];
  }

  /// 캐시에 이미지 직접 저장 (첫 페이지 빠른 로딩용)
  void setCachedImage(int pageNumber, Uint8List imageBytes) {
    _pageImageCache[pageNumber] = imageBytes;
  }

  /// 캐시 초기화
  void clearCache() {
    _pageImageCache.clear();
    _pageImageFutures.clear();
    _renderQueue.clear();
    _retryCount.clear();
    _currentRenderingCount = 0;
  }

  /// 캐시 크기 확인 (디버깅용)
  int getCacheSize() {
    return _pageImageCache.length;
  }

  /// 로딩 중인 Future 개수 (디버깅용)
  int getLoadingCount() {
    return _pageImageFutures.length;
  }
}

/// 렌더링 요청 정보
class _RenderRequest {
  final int pageNumber;
  final Future<Uint8List> Function() renderFunction;

  _RenderRequest(this.pageNumber, this.renderFunction);
}
