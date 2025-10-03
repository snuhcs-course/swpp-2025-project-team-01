// 검색 화면: 강의명 검색, 최근 검색어
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repository.dart';
import '../../data/models.dart';
import '../../app_router.dart';

/// 검색 화면
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

/// 검색 범위를 정의하는 열거형
enum SearchScope { lecture, week, subject }

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<String> _recentSearches = [];
  List<Lecture> _searchResults = [];
  bool _isSearching = false;
  SearchScope _searchScope = SearchScope.lecture;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query); // 중복 제거
    _recentSearches.insert(0, query); // 맨 앞에 추가
    if (_recentSearches.length > 3) {
      _recentSearches = _recentSearches.sublist(0, 3); // 최대 3개
    }
    await prefs.setStringList('recent_searches', _recentSearches);
    setState(() {});
  }

  Future<void> _removeRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    await prefs.setStringList('recent_searches', _recentSearches);
    setState(() {});
  }

  String _getHintText() {
    switch (_searchScope) {
      case SearchScope.lecture:
        return '강의명 검색';
      case SearchScope.week:
        return '주차 검색 (예: Week 1)';
      case SearchScope.subject:
        return '과목명 검색';
    }
  }

  Future<void> _performSearch(String query, {bool saveToRecent = false}) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    // 엔터나 검색 완료 시에만 최근 검색어에 저장
    if (saveToRecent) {
      _saveRecentSearch(query);
    }

    // 모든 과목의 모든 강의 ID 수집 및 로드
    final allLectureIds = <String>[];
    for (final subject in Repo.instance.getSubjects()) {
      allLectureIds.addAll(subject.lectureIds);
    }

    // 강의 메타데이터 미리 로드
    await Repo.instance.preloadLectures(allLectureIds);

    // 모든 과목의 모든 강의에서 검색
    final allLectures = <Lecture>[];
    for (final subject in Repo.instance.getSubjects()) {
      final lectures = Repo.instance.lecturesBySubject(subject.id);
      allLectures.addAll(lectures);
    }

    // 검색 범위에 따라 필터링
    final results = allLectures.where((lec) {
      // 빈 Lecture 객체 필터링 (제대로 로드되지 않은 것)
      if (lec.title == 'Untitled') return false;

      final searchQuery = query.toLowerCase();
      switch (_searchScope) {
        case SearchScope.lecture:
          return lec.title.toLowerCase().contains(searchQuery);
        case SearchScope.week:
          return lec.weekLabel.toLowerCase().contains(searchQuery);
        case SearchScope.subject:
          final subject = Repo.instance.getSubjects().firstWhere(
            (s) => s.id == lec.subjectId,
            orElse: () => const Subject(id: '', title: ''),
          );
          return subject.title.toLowerCase().contains(searchQuery);
      }
    }).toList();

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('검색'),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 검색 범위 드롭다운
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<SearchScope>(
                    value: _searchScope,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: SearchScope.lecture, child: Text('강의')),
                      DropdownMenuItem(value: SearchScope.week, child: Text('주차')),
                      DropdownMenuItem(value: SearchScope.subject, child: Text('과목')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _searchScope = value!;
                        if (_searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // 검색 입력 필드
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: _getHintText(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _isSearching = false;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black87, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                      _performSearch(value); // 실시간 검색 (저장 안함)
                    },
                    onSubmitted: (value) => _performSearch(value, saveToRecent: true), // 엔터 시 저장
                  ),
                ),
              ],
            ),
          ),

          // 최근 검색어 또는 검색 결과
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildRecentSearches(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return const Center(
        child: Text('최근 검색어가 없습니다', style: TextStyle(color: Colors.black38)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('최근 검색어', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: _recentSearches.length,
          itemBuilder: (context, index) {
            final query = _recentSearches[index];
            return ListTile(
              leading: const Icon(Icons.history, color: Colors.black54),
              title: Text(query),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: () => _removeRecentSearch(query),
              ),
              onTap: () {
                _searchController.text = query;
                _performSearch(query, saveToRecent: false); // 이미 최근 검색어이므로 다시 저장 안함
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('검색 결과가 없습니다', style: TextStyle(color: Colors.black38)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final lecture = _searchResults[index];
        final subject = Repo.instance.getSubjects().firstWhere(
          (s) => s.id == lecture.subjectId,
          orElse: () => const Subject(id: '', title: ''),
        );

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          title: Row(
            children: [
              Text(
                lecture.weekLabel,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lecture.title,
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subject.title,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, Routes.player, arguments: {'lectureId': lecture.id});
          },
        );
      },
    );
  }
}