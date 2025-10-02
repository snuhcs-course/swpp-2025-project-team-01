// 검색 화면: 강의명 검색, 최근 검색어
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repository.dart';
import '../../data/models.dart';
import '../../app_router.dart';
import '../home/home_widgets.dart' show LectureCard;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<String> _recentSearches = [];
  List<Lecture> _searchResults = [];
  bool _isSearching = false;

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

  void _performSearch(String query, {bool saveToRecent = false}) {
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

    // 모든 과목의 모든 강의에서 검색
    final allLectures = <Lecture>[];
    for (final subject in Repo.instance.getSubjects()) {
      final lectures = Repo.instance.lecturesBySubject(subject.id);
      allLectures.addAll(lectures);
    }

    // 강의명으로 필터링
    final results = allLectures
        .where((lec) => lec.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() {
      _searchResults = results;
      _isSearching = true;
    });
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
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '강의명 검색',
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

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final lecture = _searchResults[index];
        return LectureCard(
          lec: lecture,
          onTap: (lec) {
            Navigator.pushNamed(context, Routes.player, arguments: {'lectureId': lec.id});
          },
        );
      },
    );
  }
}