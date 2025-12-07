import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pdfx/pdfx.dart';

/// PDF 페이지 이미지 캐싱 서비스
///
/// 동시 렌더링 제한과 LRU 캐시를 통해 안정적이고 효율적인 PDF 렌더링을 제공합니다.
class PdfCacheService {
  // PDF 페이지 이미지 캐싱 (LRU)
  final Map<int, Uint8List> _pageImageCache = {};
  final Map<int, Future<Uint8List>> _pageImageFutures = {};
  final List<int> _lruList = []; // LRU 추적 리스트

  static const int maxCacheSize = 30; // 최대 캐시 크기
  static const int cacheChunkSize = 20;

  // 동시 렌더링 제한 (최대 2개까지만 동시에 렌더링)
  static const int maxConcurrentRenders = 2;
  int _currentRenderingCount = 0;

  // 재시도 관련
  static const int maxRetries = 2;
  final Map<int, int> _retryCount = {};

  PdfDocument? _pdfDocument;

  /// PDF 문서 설정
  void setPdfDocument(PdfDocument? document) {
    _pdfDocument = document;
  }

  /// LRU 캐시 업데이트 (가장 최근에 사용된 페이지를 리스트 끝으로 이동)
  void _updateLRU(int pageNumber) {
    _lruList.remove(pageNumber);
    _lruList.add(pageNumber);

    // 캐시 크기 초과 시 가장 오래된 항목 제거
    while (_lruList.length > maxCacheSize) {
      final oldestPage = _lruList.removeAt(0);
      _pageImageCache.remove(oldestPage);
      // Future도 함께 제거하여 완전히 정리
      _pageImageFutures.remove(oldestPage);
      _retryCount.remove(oldestPage);
    }
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
          _updateLRU(pageNumber);
          _pageImageFutures.remove(pageNumber);
        })
        .catchError((error) {
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
      rethrow;
    }
  }

  /// 캐시된 이미지 또는 Future를 반환 (큐 기반 렌더링)
  Future<Uint8List> getCachedOrRenderPage(int pageNumber) {
    // 이미 캐시된 경우 - LRU 업데이트하고 즉시 반환
    if (_pageImageCache.containsKey(pageNumber)) {
      _updateLRU(pageNumber);
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
  Future<Uint8List> _queueRenderRequest(int pageNumber) async {
    final completer = Completer<Uint8List>();

    // Future를 먼저 캐시에 저장
    _pageImageFutures[pageNumber] = completer.future;

    // 렌더링 시작
    _renderWithRetry(pageNumber, completer);

    return completer.future;
  }

  /// 재시도 로직을 포함한 렌더링
  Future<void> _renderWithRetry(
    int pageNumber,
    Completer<Uint8List> completer,
  ) async {
    // 동시 렌더링 제한 확인
    while (_currentRenderingCount >= maxConcurrentRenders) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _currentRenderingCount++;
    bool shouldDecrementCount = true;

    try {
      final imageBytes = await _renderPdfPage(pageNumber);
      _pageImageCache[pageNumber] = imageBytes;
      _updateLRU(pageNumber);
      _retryCount.remove(pageNumber);
      _pageImageFutures.remove(pageNumber);
      completer.complete(imageBytes);
    } catch (error) {
      final currentRetry = _retryCount[pageNumber] ?? 0;

      if (currentRetry < maxRetries) {
        // 재시도 가능
        _retryCount[pageNumber] = currentRetry + 1;

        // 잠시 대기 후 재시도
        await Future.delayed(Duration(milliseconds: 300 * (currentRetry + 1)));

        // 재시도 (현재 카운트 감소 후 재귀)
        _currentRenderingCount--;
        shouldDecrementCount = false;
        return _renderWithRetry(pageNumber, completer);
      } else {
        // 최대 재시도 횟수 초과
        _retryCount.remove(pageNumber);
        _pageImageFutures.remove(pageNumber);
        completer.completeError(error);
      }
    } finally {
      if (shouldDecrementCount) {
        _currentRenderingCount--;
      }
    }
  }

  /// 캐시된 이미지 직접 조회 (동기적으로 즉시 반환)
  Uint8List? getCachedImageDirect(int pageNumber) {
    return _pageImageCache[pageNumber];
  }

  /// 캐시에 이미지 직접 저장 (첫 페이지 빠른 로딩용)
  void setCachedImage(int pageNumber, Uint8List imageBytes) {
    _pageImageCache[pageNumber] = imageBytes;
    _updateLRU(pageNumber);
  }

  /// 캐시 초기화
  void clearCache() {
    _pageImageCache.clear();
    _pageImageFutures.clear();
    _lruList.clear();
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
