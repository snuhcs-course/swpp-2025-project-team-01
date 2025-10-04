import 'package:flutter/material.dart';

/// 앱의 다국어 지원을 위한 클래스
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // 지원하는 언어 목록
  static const List<Locale> supportedLocales = [
    Locale('ko', 'KR'),
    Locale('en', 'US'),
  ];

  bool get isKorean => locale.languageCode == 'ko';

  // 공통
  String get appName => isKorean ? 'Re:View' : 'Re:View';
  String get ok => isKorean ? '확인' : 'OK';
  String get cancel => isKorean ? '취소' : 'Cancel';
  String get save => isKorean ? '저장' : 'Save';
  String get delete => isKorean ? '삭제' : 'Delete';
  String get edit => isKorean ? '수정' : 'Edit';
  String get add => isKorean ? '추가' : 'Add';
  String get search => isKorean ? '검색' : 'Search';
  String get settings => isKorean ? '설정' : 'Settings';
  String get yes => isKorean ? '예' : 'Yes';
  String get no => isKorean ? '아니오' : 'No';
  String get warning => isKorean ? '경고' : 'Warning';
  String get complete => isKorean ? '완료' : 'Complete';

  // 홈 화면
  String get menu => isKorean ? '메뉴' : 'Menu';
  String get filter => isKorean ? '필터' : 'Filter';
  String get favorites => isKorean ? '즐겨찾기' : 'Favorites';
  String get addLecture => isKorean ? '수업 추가' : 'Add Lecture';
  String get editSubjects => isKorean ? '과목 수정' : 'Edit Subjects';
  String get editTags => isKorean ? '태그 수정' : 'Edit Tags';

  // 설정 화면
  String get displayMode => isKorean ? '디스플레이 모드' : 'Display Mode';
  String get accessibility => isKorean ? '접근성' : 'Accessibility';
  String get language => isKorean ? '언어' : 'Language';
  String get lightMode => isKorean ? '라이트 모드' : 'Light Mode';
  String get darkMode => isKorean ? '다크 모드' : 'Dark Mode';
  String get systemSettings => isKorean ? '시스템 설정' : 'System Settings';

  // 접근성
  String get highContrast => isKorean ? '고대비' : 'High Contrast';
  String get highContrastDesc => isKorean ? '텍스트와 UI 요소의 대비를 높입니다.' : 'Increase contrast of text and UI elements.';
  String get reduceMotion => isKorean ? '모션 줄이기' : 'Reduce Motion';
  String get reduceMotionDesc => isKorean ? '애니메이션 효과를 최소화합니다.' : 'Minimize animation effects.';
  String get emphasizeCaptions => isKorean ? '자막 강조' : 'Emphasize Captions';
  String get emphasizeCaptionsDesc => isKorean ? '플레이어 자막을 굵게/큰 크기로 표시합니다.' : 'Display player captions in bold and larger size.';
  String get accessibilityAppliedImmediately => isKorean ? '설정은 재생 화면에 즉시 적용됩니다.' : 'Settings are applied immediately to the player.';

  // 과목
  String get subject => isKorean ? '과목' : 'Subject';
  String get subjects => isKorean ? '과목' : 'Subjects';
  String get editingSubjects => isKorean ? '과목 수정' : 'Editing Subjects';
  String get deleteSubject => isKorean ? '과목 삭제' : 'Delete Subject';
  String get deleteSubjectWarning => isKorean
      ? '과목 삭제 시\n해당 과목의 강의들까지 전부\n삭제됩니다.\n\n삭제하시겠습니까?'
      : 'Deleting a subject will also\ndelete all its lectures.\n\nDo you want to delete?';
  String get editTags2 => isKorean ? '태그 수정' : 'Edit Tags';
  String get editComplete => isKorean ? '수정 완료' : 'Complete';
  String get addSubject => isKorean ? '과목 추가' : 'Add Subject';
  String get subjectName => isKorean ? '과목명' : 'Subject Name';
  String get subjectNameHint => isKorean ? '예) 소프트웨어 개발의 원리와 실제' : 'e.g.) Principles of Software Development';
  String get selectTags => isKorean ? '태그 선택' : 'Select Tags';
  String get selectTagsOptional => isKorean ? '태그 선택 (선택사항)' : 'Select Tags (Optional)';
  String get pleaseEnterSubjectName => isKorean ? '과목명을 입력해주세요' : 'Please enter subject name';

  // 태그
  String get tag => isKorean ? '태그' : 'Tag';
  String get tags => isKorean ? '태그' : 'Tags';
  String get editingTags => isKorean ? '태그 수정' : 'Editing Tags';
  String get colorTheme => isKorean ? '색상 테마' : 'Color Theme';
  String get tagName => isKorean ? '이름' : 'Name';
  String get apply => isKorean ? '적용' : 'Apply';
  String get newTag => isKorean ? '새 태그' : 'New Tag';
  String get maxTagsReached => isKorean ? '태그는 최대 15개까지 생성할 수 있습니다.' : 'You can create up to 15 tags.';
  String get pleaseEnterTagName => isKorean ? '태그 이름을 입력해주세요.' : 'Please enter tag name.';
  String get duplicateTagName => isKorean ? '이미 사용 중인 이름입니다. 다른 이름을 입력해주세요.' : 'This name is already in use. Please enter a different name.';
  String tagDeleteWarning(String tagName, List<String> subjectTitles) => isKorean
      ? '태그 "#$tagName"는\n다음 과목에서 사용 중입니다:\n\n${subjectTitles.join('\n')}\n\n삭제하시겠습니까?'
      : 'Tag "#$tagName" is used by:\n\n${subjectTitles.join('\n')}\n\nDo you want to delete?';

  // 강의
  String get lecture => isKorean ? '강의' : 'Lecture';
  String get lectures => isKorean ? '강의' : 'Lectures';
  String get lectureDetails => isKorean ? '강의 상세정보' : 'Lecture Details';
  String get week => isKorean ? '주차' : 'Week';
  String get lectureTitle => isKorean ? '강의 제목' : 'Lecture Title';
  String get lectureLength => isKorean ? '강의 길이' : 'Lecture Length';
  String get deleteLecture => isKorean ? '강의 삭제' : 'Delete Lecture';

  // 검색 화면
  String get searchLecture => isKorean ? '강의 검색' : 'Search Lectures';
  String get recentSearches => isKorean ? '최근 검색' : 'Recent Searches';
  String get noRecentSearches => isKorean ? '최근 검색 기록이 없습니다' : 'No recent searches';
  String get searchPlaceholder => isKorean ? '검색어를 입력하세요' : 'Enter search term';
  String get noSearchResults => isKorean ? '검색 결과가 없습니다' : 'No search results';
  String get searchBy => isKorean ? '검색 범위' : 'Search by';
  String get searchByLecture => isKorean ? '강의명' : 'Lecture name';
  String get searchByWeek => isKorean ? '주차' : 'Week';
  String get searchBySubject => isKorean ? '과목명' : 'Subject name';

  // 색상 테마 이름들
  String get themePastel => isKorean ? '파스텔' : 'Pastel';
  String get themeVivid => isKorean ? '비비드' : 'Vivid';
  String get themeNeon => isKorean ? '네온' : 'Neon';
  String get themeSoft => isKorean ? '소프트' : 'Soft';
  String get themeEarth => isKorean ? '어스톤' : 'Earth';

  String getThemeName(String koreanName) {
    switch (koreanName) {
      case '파스텔': return themePastel;
      case '비비드': return themeVivid;
      case '네온': return themeNeon;
      case '소프트': return themeSoft;
      case '어스톤': return themeEarth;
      default: return koreanName;
    }
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ko', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
