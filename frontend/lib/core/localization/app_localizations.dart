import 'package:flutter/material.dart';

/// 앱의 다국어 지원을 위한 클래스
class AppLocalizations {
  AppLocalizations(this.locale);
  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  String get editMode => isKorean ? '수정' : 'Edit';
  String get archive => isKorean ? '보관함' : 'Archive';
  String get addLecture => isKorean ? '강의 생성' : 'Create Lecture';
  String get editSubjects => isKorean ? '과목 수정' : 'Edit Subjects';
  String get editTags => isKorean ? '태그 수정' : 'Edit Tags';
  String get noFavoriteSubjects =>
      isKorean ? '즐겨찾기된 과목이 없습니다.' : 'There are no favorite subjects.';
  String get noSubjectsWithSelectedTags => isKorean
      ? '필터와 일치하는 태그를 가진 과목이 없습니다.'
      : 'No subjects match the selected tags.';
  String get noArchivedSubjects =>
      isKorean ? '보관된 과목이 없습니다.' : 'There are no archived subjects.';

  // 설정 화면
  String get displayMode => isKorean ? '디스플레이 모드' : 'Display Mode';
  String get accessibility => isKorean ? '접근성' : 'Accessibility';
  String get tts => isKorean ? 'TTS 설정' : 'TTS Configurations';
  String get language => isKorean ? '언어 / Language' : 'Language / 언어';
  String get lightMode => isKorean ? '라이트 모드' : 'Light Mode';
  String get darkMode => isKorean ? '다크 모드' : 'Dark Mode';
  String get systemSettings => isKorean ? '시스템 설정' : 'System Settings';
  String get help => isKorean ? '도움말' : 'Help';

  // FAQ
  String get howToFindLecture =>
      isKorean ? '강의를 못 찾겠어요.' : 'I have trouble finding my lecture.';
  String get findLectureByTitle => isKorean
      ? '• 강의의 제목, 주차 또는 과목명을 알고 있다면 홈 화면 우상단의 검색창에 입력해보세요.'
      : '• If you remember the lecture title, week or subject, type it in the search bar located in the upper right of the home screen.';
  String get findLectureByTag => isKorean
      ? '• 과목에 달린 태그를 알고 있다면 필터 창에서 태그를 눌러보세요.'
      : '• If you remember the tag appended to the subject, press the tag at the filter tab.';
  String get howToDeleteLecture =>
      isKorean ? '과목을 삭제하고 싶어요.' : 'I want to delete my lecture.';
  String get deleteLectureAtHome => isKorean
      ? '• 홈 화면에서 강의를 꾹 누르면 보이는 강의 상세 정보 팝업에서 과목 관련 정보를 편집하거나 강의를 삭제할 수 있어요.'
      : '• Touch and hold the lecture at the home screen to see lecture details popup. You can edit lecture identifiers or delete the lecture.';
  String get howToEditSubjectTag => isKorean
      ? '과목의 태그를 수정하고 싶어요.'
      : 'I want to edit tag annotations of a subject.';
  String get editTagAtSubjectEdit => isKorean
      ? '• 과목 수정 화면에서 과목을 꾹 누르면 보이는 과목 수정 팝업에서 태그를 수정할 수 있어요.'
      : '• Touch and hold the subject at the subject editing screen to see the subject edit popup, where you can edit the tag annotations.';
  String get howToUnsync => isKorean
      ? '강의 슬라이드를 원할 때 넘기고 싶어요.'
      : 'I want to manually flip the lecture slides at my own pace.';
  String get useUnsyncButton => isKorean
      ? '• 플레이어에서 싱크 버튼 (🔄)을 눌러보세요.'
      : '• Press the sync icon (🔄) at the player.';
  String get howToReorder => isKorean
      ? '과목 및 강의 간 정렬 순서를 수정하고 싶어요.'
      : 'I want to realign the order of subjects or lectures within a subject.';
  String get reorderSubjects => isKorean
      ? '• 과목 수정 화면에서 과목의 왼쪽을 누르고 원하는 순서대로 드래그해보세요.'
      : '• Drag the subject to the desired position at the subject editing screen.';
  String get reorderLectures => isKorean
      ? '• 과목 수정 화면에서 강의의 왼쪽을 누르고 원하는 순서대로 드래그해보세요.'
      : '• Press and hold the left icon of the lecture and drag the it to the desired position at the subject editing screen.';
  String get howToHideLoading => isKorean
      ? '로딩 바가 화면을 가려서 화면이 제대로 보이지 않아요.'
      : 'I want to diminish the loading bar to better view the screen.';
  String get hideLoadingBySwipe => isKorean
      ? '• 로딩 바를 스와이프하면 위젯이 원형으로 작아져요. 원형 위젯을 원하는 곳으로 이동시켜 보세요.'
      : '• Swipe the loading bar to diminish the widget to a circular one. You can translocate the circular loading widget to the desried positon.';
  String get showLoadingBarAgain => isKorean
      ? '• 원형 로딩 위젯을 다시 누르면 로딩 바가 원래대로 보여요.'
      : '• Press the circular loading widget again to view the original loading bar.';
  String get howToViewSlidesAtPlayer => isKorean
      ? '현재 슬라이드의 앞, 뒤 슬라이드도 보고 싶어요.'
      : 'I want to view the former & latter slides of current slide.';
  String get showSlidesBySwipe => isKorean
      ? '• 화면 하단부를 위로 스와이프해보세요.'
      : '• Swipe from bottom to up at the player.';

  // Infobox
  String get buyCoffee =>
      isKorean ? '개발자에게 커피 사주기' : 'Buy the developer a cup of coffee.';

  // 접근성
  String get highContrast => isKorean ? '고대비' : 'High Contrast';
  String get highContrastDesc => isKorean
      ? '텍스트와 UI 요소의 대비를 높입니다.'
      : 'Increase contrast of text and UI elements.';
  String get reduceMotion => isKorean ? '모션 줄이기' : 'Reduce Motion';
  String get reduceMotionDesc =>
      isKorean ? '애니메이션 효과를 최소화합니다.' : 'Minimize animation effects.';
  String get emphasizeCaptions => isKorean ? '자막 강조' : 'Emphasize Captions';
  String get emphasizeCaptionsDesc => isKorean
      ? '플레이어 자막을 굵게/큰 크기로 표시합니다.'
      : 'Display player captions in bold and larger size.';
  String get accessibilityAppliedImmediately => isKorean
      ? '설정은 재생 화면에 즉시 적용됩니다.'
      : 'Settings are applied immediately to the player.';

  // 과목
  String get subject => isKorean ? '과목' : 'Subject';
  String get subjects => isKorean ? '과목' : 'Subjects';
  String get uncategorized => isKorean ? '미분류' : 'Uncategorized';
  String get editingSubject => isKorean ? '과목 정보 수정' : 'Edit Subject Info';
  String get deleteSubject => isKorean ? '과목 삭제' : 'Delete Subject';
  String get deleteSubjectWarning1 =>
      isKorean ? '과목 삭제 시 해당 과목의\n' : 'Deleting a subject will also\n';
  String get deleteSubjectWarning2 =>
      isKorean ? '강의들까지 전부 삭제' : 'delete all its lectures.';
  String get deleteSubjectWarning3 =>
      isKorean ? '됩니다.\n\n삭제하시겠습니까?' : '\n\nDo you want to delete?';
  String get editTags2 => isKorean ? '태그 수정' : 'Edit Tags';
  String get editComplete => isKorean ? '수정 완료' : 'Complete';
  String get addSubject => isKorean ? '과목 추가' : 'Add Subject';
  String get subjectName => isKorean ? '과목명' : 'Subject Name';
  String get subjectNameHint => isKorean
      ? '예) 소프트웨어 개발의 원리와 실제'
      : 'e.g.) Principles of Software Development';
  String get selectTags => isKorean ? '태그 선택' : 'Select Tags';
  String get selectTagsOptional =>
      isKorean ? '태그 선택 (선택사항)' : 'Select Tags (Optional)';
  String get pleaseEnterSubjectName =>
      isKorean ? '과목명을 입력해주세요' : 'Please enter subject name';

  // 태그
  String get tag => isKorean ? '태그' : 'Tag';
  String get tags => isKorean ? '태그' : 'Tags';
  String get editingTags => isKorean ? '태그 수정' : 'Edit Tags';
  String get colorTheme => isKorean ? '색상 테마' : 'Color Theme';
  String get tagName => isKorean ? '이름' : 'Name';
  String get apply => isKorean ? '적용' : 'Apply';
  String get nameApply => isKorean ? '이름 적용' : 'Apply Name';
  String get newTag => isKorean ? '새 태그' : 'New Tag';
  String get deleteTag => isKorean ? '태그 삭제' : 'Delete Tag';
  String get maxTagsReached =>
      isKorean ? '태그는 최대 15개까지 생성할 수 있습니다.' : 'You can create up to 15 tags.';
  String get pleaseEnterTagName =>
      isKorean ? '태그 이름을 입력해주세요.' : 'Please enter tag name.';
  String get duplicateTagName => isKorean
      ? '이미 사용 중인 이름입니다. 다른 이름을 입력해주세요.'
      : 'This name is already in use. Please enter a different name.';
  String tagDeleteWarning(String tagName, List<String> subjectTitles) =>
      isKorean
      ? '태그 "$tagName"는\n다음 과목에서 사용 중입니다:\n\n${subjectTitles.join('\n')}\n\n삭제하시겠습니까?'
      : 'Tag "$tagName" is used in the following subjects:\n\n${subjectTitles.join('\n')}\n\nDo you want to delete it?';

  // 강의
  String get lecture => isKorean ? '강의' : 'Lecture';
  String get lectures => isKorean ? '강의' : 'Lectures';
  String get editLecture => isKorean ? '강의 정보 수정' : 'Edit Lecture Info';
  String get week => isKorean ? '주차' : 'Week';
  String get lectureTitle => isKorean ? '강의 제목' : 'Lecture Title';
  String get lectureLength => isKorean ? '강의 길이' : 'Lecture Length';
  String get deleteLecture => isKorean ? '강의 삭제' : 'Delete Lecture';

  // 검색 화면
  String get searchLecture => isKorean ? '강의 검색' : 'Search Lectures';
  String get recentSearches => isKorean ? '최근 검색' : 'Recent Searches';
  String get noRecentSearches =>
      isKorean ? '최근 검색 기록이 없습니다' : 'No recent searches';
  String get searchPlaceholder => isKorean ? '검색어를 입력하세요' : 'Enter search term';
  String get noSearchResults => isKorean ? '검색 결과가 없습니다' : 'No search results';
  String get searchBy => isKorean ? '검색 범위' : 'Search by';
  String get searchByLecture => isKorean ? '강의명' : 'Lecture name';
  String get searchByWeek => isKorean ? '주차' : 'Week';
  String get searchBySubject => isKorean ? '과목명' : 'Subject name';

  // 색상 테마 이름들
  String get themeSpring => isKorean ? '봄' : 'Spring';
  String get themeSummer => isKorean ? '여름' : 'Summer';
  String get themeAutumn => isKorean ? '가을' : 'Autumn';
  String get themeWinter => isKorean ? '겨울' : 'Winter';
  String get themeCottonCandy => isKorean ? '솜사탕' : 'Cotton Candy';
  String get themeVivid => isKorean ? '비비드' : 'Vivid';
  String get themeSea => isKorean ? '바다' : 'Sea';

  String getThemeName(String koreanName) {
    switch (koreanName) {
      case '봄':
        return themeSpring;
      case '여름':
        return themeSummer;
      case '가을':
        return themeAutumn;
      case '겨울':
        return themeWinter;
      case '솜사탕':
        return themeCottonCandy;
      case '비비드':
        return themeVivid;
      case '바다':
        return themeSea;
      default:
        return koreanName;
    }
  }

  // 플레이어
  String get subtitle => isKorean ? '자막' : 'Subtitle';
  String get transcript => isKorean ? '대본' : 'Transcript';
  String pagesAhead(int pages) =>
      isKorean ? '$pages 페이지 빠름' : '$pages pages ahead';
  String pagesBehind(int pages) =>
      isKorean ? '$pages 페이지 느림' : '$pages pages behind';

  // 플레이어 에러 메시지
  String get lectureIdMissing =>
      isKorean ? '강의 ID가 없습니다.' : 'Lecture ID is missing.';
  String get lectureNotFound =>
      isKorean ? '강의를 찾을 수 없습니다.' : 'Lecture not found.';
  String get failedToLoadTranscript =>
      isKorean ? '자막 파일을 불러올 수 없습니다.' : 'Failed to load transcript file.';
  String get invalidTranscriptFormat =>
      isKorean ? '자막 데이터 형식이 올바르지 않습니다.' : 'Invalid transcript data format.';
  String get failedToInitializePlayer =>
      isKorean ? '플레이어 초기화에 실패했습니다.' : 'Failed to initialize player.';
  String get unknownError =>
      isKorean ? '알 수 없는 오류가 발생했습니다.' : 'An unknown error occurred.';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
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
