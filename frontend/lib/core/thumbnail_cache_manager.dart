import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:pdfx/pdfx.dart';

/// LRU캐시를 사용한 썸네일 캐시 매니저
/// HiveLecture의 첫 페이지 썸네일을 메모리에 caching

class ThumbnailCacheManager {
  ThumbnailCacheManager._();

  static final ThumbnailCacheManager instance = ThumbnailCacheManager._();

  static const int _maxCacheSize = 50;

  /// LRU 캐시: lectureId -> PdfPageImage
  final LinkedHashMap<String, PdfPageImage> _cache = LinkedHashMap();

  /// 캐시에서 썸네일 가져오기
  /// 캐시에 존재하면 해당 항목을 가장 최근 사용으로 이동시키고 반환
  PdfPageImage? get(String lectureId) {
    if (!_cache.containsKey(lectureId)) {
      return null;
    }

    // LRU: 접근한 항목을 맨 뒤로 이동 (가장 최근 사용)
    final image = _cache.remove(lectureId)!;
    _cache[lectureId] = image;

    return image;
  }

  /// 캐시에 썸네일 추가
  /// 캐시 크기가 최대치를 초과하면 가장 오래된 항목 제거
  void put(String lectureId, PdfPageImage image) {
    if (_cache.containsKey(lectureId)) {
      _cache.remove(lectureId);
    }

    // 캐시 크기 제한 확인
    if (_cache.length >= _maxCacheSize) {
      // 가장 오래된 항목 제거 (맨 앞)
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
      debugPrint('🗑️ Thumbnail cache evicted: $oldestKey');
    }

    // 새 항목 추가 (맨 뒤)
    _cache[lectureId] = image;
    debugPrint('Thumbnail cached: $lectureId (total: ${_cache.length})');
  }

  /// 특정 강의의 썸네일을 캐시에서 제거
  void remove(String lectureId) {
    if (_cache.containsKey(lectureId)) {
      _cache.remove(lectureId);
      debugPrint('Thumbnail removed from cache: $lectureId');
    }
  }

  /// 캐시 전체 삭제
  void clear() {
    _cache.clear();
    debugPrint('Thumbnail cache cleared');
  }

  /// 현재 캐시 크기
  int get size => _cache.length;

  /// 캐시에 특정 강의 ID가 존재하는지 확인
  bool contains(String lectureId) => _cache.containsKey(lectureId);
}
