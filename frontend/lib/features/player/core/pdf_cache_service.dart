import 'dart:typed_data';
import 'package:pdfx/pdfx.dart';

/// PDF 페이지 이미지 캐싱 서비스
///
/// 20개 단위 청크로 PDF 페이지 이미지를 캐싱하여
/// 중복 렌더링을 방지하고 성능을 최적화합니다.
class PdfCacheService {
  // PDF 페이지 이미지 캐싱 (20개 단위)
  final Map<int, Uint8List> _pageImageCache = {};
  final Map<int, Future<Uint8List>> _pageImageFutures = {};
  static const int cacheChunkSize = 20;

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

    future.then((imageBytes) {
      _pageImageCache[pageNumber] = imageBytes;
      _pageImageFutures.remove(pageNumber);
    }).catchError((error) {
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
        throw Exception('Failed to render PDF page $pageNumber: pageImage is null');
      }

      return pageImage.bytes;
    } catch (e) {
      rethrow;
    }
  }

  /// 캐시된 이미지 또는 Future를 반환
  Future<Uint8List> getCachedOrRenderPage(int pageNumber) {
    // 이미 캐시된 경우
    if (_pageImageCache.containsKey(pageNumber)) {
      return Future.value(_pageImageCache[pageNumber]!);
    }

    // 로딩 중인 경우
    if (_pageImageFutures.containsKey(pageNumber)) {
      return _pageImageFutures[pageNumber]!;
    }

    // 캐시되지 않은 경우 새로 로딩
    final future = _renderPdfPage(pageNumber);
    _pageImageFutures[pageNumber] = future;

    future
        .then((imageBytes) {
          _pageImageCache[pageNumber] = imageBytes;
          _pageImageFutures.remove(pageNumber);
        })
        .catchError((error) {
          _pageImageFutures.remove(pageNumber);
        });

    return future;
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
