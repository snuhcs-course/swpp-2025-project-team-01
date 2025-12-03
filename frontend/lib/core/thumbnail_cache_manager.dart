import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:pdfx/pdfx.dart';

/// LRU캐시를 사용한 썸네일 캐시 매니저
/// HiveLecture의 첫 페이지 썸네일을 메모리에 caching

/// 썸네일 이미지와 aspect ratio를 함께 저장하는 클래스
class CachedThumbnail {
  CachedThumbnail({required this.image, required this.aspectRatio});

  final PdfPageImage image;
  final double aspectRatio;
}

class ThumbnailCacheManager {
  ThumbnailCacheManager._();

  static final ThumbnailCacheManager instance = ThumbnailCacheManager._();

  static const int _maxCacheSize = 50;

  /// LRU 캐시: lectureId -> CachedThumbnail
  final LinkedHashMap<String, CachedThumbnail> _cache = LinkedHashMap();

  /// 캐시에서 썸네일 가져오기
  /// 캐시에 존재하면 해당 항목을 가장 최근 사용으로 이동시키고 반환
  CachedThumbnail? get(String lectureId) {
    if (!_cache.containsKey(lectureId)) {
      return null;
    }

    // LRU: 접근한 항목을 맨 뒤로 이동 (가장 최근 사용)
    final thumbnail = _cache.remove(lectureId)!;
    _cache[lectureId] = thumbnail;

    return thumbnail;
  }

  /// 캐시에 썸네일 추가
  /// 캐시 크기가 최대치를 초과하면 가장 오래된 항목 제거
  void put(String lectureId, PdfPageImage image, double aspectRatio) {
    if (_cache.containsKey(lectureId)) {
      _cache.remove(lectureId);
    }

    // 캐시 크기 제한 확인
    if (_cache.length >= _maxCacheSize) {
      // 가장 오래된 항목 제거 (맨 앞)
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
      debugPrint('🗑️ Thumbnail cache evicted: $oldestKey'); // coverage:ignore-line
    }

    // 새 항목 추가 (맨 뒤)
    _cache[lectureId] = CachedThumbnail(image: image, aspectRatio: aspectRatio);
    debugPrint('Thumbnail cached: $lectureId (total: ${_cache.length})'); // coverage:ignore-line
  }

  /// 특정 강의의 썸네일을 캐시에서 제거
  void remove(String lectureId) {
    if (_cache.containsKey(lectureId)) {
      _cache.remove(lectureId);
      debugPrint('Thumbnail removed from cache: $lectureId'); // coverage:ignore-line
    }
  }

  /// 캐시 전체 삭제
  void clear() {
    _cache.clear();
    debugPrint('Thumbnail cache cleared'); // coverage:ignore-line
  }

  /// 현재 캐시 크기
  int get size => _cache.length;

  /// 캐시에 특정 강의 ID가 존재하는지 확인
  bool contains(String lectureId) => _cache.containsKey(lectureId);
}
