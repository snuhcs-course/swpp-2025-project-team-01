import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_view/core/localization/app_localizations.dart';

void main() {
  group('AppLocalizations', () {
    late AppLocalizations koreanLocalizations;
    late AppLocalizations englishLocalizations;

    setUp(() {
      koreanLocalizations = AppLocalizations(const Locale('ko', 'KR'));
      englishLocalizations = AppLocalizations(const Locale('en', 'US'));
    });

    group('Language Detection', () {
      test('isKorean returns true for Korean locale', () {
        expect(koreanLocalizations.isKorean, isTrue);
      });

      test('isKorean returns false for English locale', () {
        expect(englishLocalizations.isKorean, isFalse);
      });
    });

    group('Common Strings', () {
      test('appName is same for both languages', () {
        expect(koreanLocalizations.appName, 'Re:View');
        expect(englishLocalizations.appName, 'Re:View');
      });

      test('ok returns correct translation', () {
        expect(koreanLocalizations.ok, '확인');
        expect(englishLocalizations.ok, 'OK');
      });

      test('cancel returns correct translation', () {
        expect(koreanLocalizations.cancel, '취소');
        expect(englishLocalizations.cancel, 'Cancel');
      });

      test('save returns correct translation', () {
        expect(koreanLocalizations.save, '저장');
        expect(englishLocalizations.save, 'Save');
      });

      test('delete returns correct translation', () {
        expect(koreanLocalizations.delete, '삭제');
        expect(englishLocalizations.delete, 'Delete');
      });

      test('edit returns correct translation', () {
        expect(koreanLocalizations.edit, '수정');
        expect(englishLocalizations.edit, 'Edit');
      });

      test('add returns correct translation', () {
        expect(koreanLocalizations.add, '추가');
        expect(englishLocalizations.add, 'Add');
      });

      test('search returns correct translation', () {
        expect(koreanLocalizations.search, '검색');
        expect(englishLocalizations.search, 'Search');
      });

      test('settings returns correct translation', () {
        expect(koreanLocalizations.settings, '설정');
        expect(englishLocalizations.settings, 'Settings');
      });

      test('yes returns correct translation', () {
        expect(koreanLocalizations.yes, '예');
        expect(englishLocalizations.yes, 'Yes');
      });

      test('no returns correct translation', () {
        expect(koreanLocalizations.no, '아니오');
        expect(englishLocalizations.no, 'No');
      });

      test('warning returns correct translation', () {
        expect(koreanLocalizations.warning, '경고');
        expect(englishLocalizations.warning, 'Warning');
      });

      test('complete returns correct translation', () {
        expect(koreanLocalizations.complete, '완료');
        expect(englishLocalizations.complete, 'Complete');
      });
    });

    group('Home Screen Strings', () {
      test('menu returns correct translation', () {
        expect(koreanLocalizations.menu, '메뉴');
        expect(englishLocalizations.menu, 'Menu');
      });

      test('filter returns correct translation', () {
        expect(koreanLocalizations.filter, '필터');
        expect(englishLocalizations.filter, 'Filter');
      });

      test('addLecture returns correct translation', () {
        expect(koreanLocalizations.addLecture, '강의 생성');
        expect(englishLocalizations.addLecture, 'Create Lecture');
      });

      test('editSubjects returns correct translation', () {
        expect(koreanLocalizations.editSubjects, '과목 수정');
        expect(englishLocalizations.editSubjects, 'Edit Subjects');
      });

      test('editTags returns correct translation', () {
        expect(koreanLocalizations.editTags, '태그 수정');
        expect(englishLocalizations.editTags, 'Edit Tags');
      });

      test('noFavoriteSubjects returns correct translation', () {
        expect(koreanLocalizations.noFavoriteSubjects, '즐겨찾기된 과목이 없습니다.');
        expect(
          englishLocalizations.noFavoriteSubjects,
          'There are no favorite subjects.',
        );
      });

      test('noSubjectsWithSelectedTags returns correct translation', () {
        expect(
          koreanLocalizations.noSubjectsWithSelectedTags,
          '필터와 일치하는 태그를 가진 과목이 없습니다.',
        );
        expect(
          englishLocalizations.noSubjectsWithSelectedTags,
          'No subjects match the selected tags.',
        );
      });
    });

    group('Settings Screen Strings', () {
      test('displayMode returns correct translation', () {
        expect(koreanLocalizations.displayMode, '디스플레이 모드');
        expect(englishLocalizations.displayMode, 'Display Mode');
      });

      test('accessibility returns correct translation', () {
        expect(koreanLocalizations.accessibility, '접근성');
        expect(englishLocalizations.accessibility, 'Accessibility');
      });

      test('language returns correct translation', () {
        expect(koreanLocalizations.language, '언어 / Language');
        expect(englishLocalizations.language, 'Language / 언어');
      });

      test('lightMode returns correct translation', () {
        expect(koreanLocalizations.lightMode, '라이트 모드');
        expect(englishLocalizations.lightMode, 'Light Mode');
      });

      test('darkMode returns correct translation', () {
        expect(koreanLocalizations.darkMode, '다크 모드');
        expect(englishLocalizations.darkMode, 'Dark Mode');
      });

      test('systemSettings returns correct translation', () {
        expect(koreanLocalizations.systemSettings, '시스템 설정');
        expect(englishLocalizations.systemSettings, 'System Settings');
      });
    });

    group('Accessibility Strings', () {
      test('highContrast returns correct translation', () {
        expect(koreanLocalizations.highContrast, '고대비');
        expect(englishLocalizations.highContrast, 'High Contrast');
      });

      test('highContrastDesc returns correct translation', () {
        expect(koreanLocalizations.highContrastDesc, '텍스트와 UI 요소의 대비를 높입니다.');
        expect(
          englishLocalizations.highContrastDesc,
          'Increase contrast of text and UI elements.',
        );
      });

      test('reduceMotion returns correct translation', () {
        expect(koreanLocalizations.reduceMotion, '모션 줄이기');
        expect(englishLocalizations.reduceMotion, 'Reduce Motion');
      });

      test('reduceMotionDesc returns correct translation', () {
        expect(koreanLocalizations.reduceMotionDesc, '애니메이션 효과를 최소화합니다.');
        expect(
          englishLocalizations.reduceMotionDesc,
          'Minimize animation effects.',
        );
      });

      test('emphasizeCaptions returns correct translation', () {
        expect(koreanLocalizations.emphasizeCaptions, '자막 강조');
        expect(englishLocalizations.emphasizeCaptions, 'Emphasize Captions');
      });

      test('emphasizeCaptionsDesc returns correct translation', () {
        expect(
          koreanLocalizations.emphasizeCaptionsDesc,
          '플레이어 자막을 굵게/큰 크기로 표시합니다.',
        );
        expect(
          englishLocalizations.emphasizeCaptionsDesc,
          'Display player captions in bold and larger size.',
        );
      });

      test('accessibilityAppliedImmediately returns correct translation', () {
        expect(
          koreanLocalizations.accessibilityAppliedImmediately,
          '설정은 재생 화면에 즉시 적용됩니다.',
        );
        expect(
          englishLocalizations.accessibilityAppliedImmediately,
          'Settings are applied immediately to the player.',
        );
      });
    });

    group('Subject Strings', () {
      test('subject returns correct translation', () {
        expect(koreanLocalizations.subject, '과목');
        expect(englishLocalizations.subject, 'Subject');
      });

      test('subjects returns correct translation', () {
        expect(koreanLocalizations.subjects, '과목');
        expect(englishLocalizations.subjects, 'Subjects');
      });

      test('editingSubjects returns correct translation', () {
        expect(koreanLocalizations.editingSubjects, '과목 수정');
        expect(englishLocalizations.editingSubjects, 'Edit Subjects');
      });

      test('deleteSubject returns correct translation', () {
        expect(koreanLocalizations.deleteSubject, '과목 삭제');
        expect(englishLocalizations.deleteSubject, 'Delete Subject');
      });

      test('deleteSubjectWarning returns correct translation', () {
        expect(
          koreanLocalizations.deleteSubjectWarning,
          '과목 삭제 시\n해당 과목의 강의들까지 전부\n삭제됩니다.\n\n삭제하시겠습니까?',
        );
        expect(
          englishLocalizations.deleteSubjectWarning,
          'Deleting a subject will also\ndelete all its lectures.\n\nDo you want to delete?',
        );
      });

      test('addSubject returns correct translation', () {
        expect(koreanLocalizations.addSubject, '과목 추가');
        expect(englishLocalizations.addSubject, 'Add Subject');
      });

      test('subjectName returns correct translation', () {
        expect(koreanLocalizations.subjectName, '과목명');
        expect(englishLocalizations.subjectName, 'Subject Name');
      });

      test('subjectNameHint returns correct translation', () {
        expect(koreanLocalizations.subjectNameHint, '예) 소프트웨어 개발의 원리와 실제');
        expect(
          englishLocalizations.subjectNameHint,
          'e.g.) Principles of Software Development',
        );
      });

      test('selectTags returns correct translation', () {
        expect(koreanLocalizations.selectTags, '태그 선택');
        expect(englishLocalizations.selectTags, 'Select Tags');
      });

      test('selectTagsOptional returns correct translation', () {
        expect(koreanLocalizations.selectTagsOptional, '태그 선택 (선택사항)');
        expect(
          englishLocalizations.selectTagsOptional,
          'Select Tags (Optional)',
        );
      });

      test('pleaseEnterSubjectName returns correct translation', () {
        expect(koreanLocalizations.pleaseEnterSubjectName, '과목명을 입력해주세요');
        expect(
          englishLocalizations.pleaseEnterSubjectName,
          'Please enter subject name',
        );
      });
    });

    group('Tag Strings', () {
      test('tag returns correct translation', () {
        expect(koreanLocalizations.tag, '태그');
        expect(englishLocalizations.tag, 'Tag');
      });

      test('tags returns correct translation', () {
        expect(koreanLocalizations.tags, '태그');
        expect(englishLocalizations.tags, 'Tags');
      });

      test('editingTags returns correct translation', () {
        expect(koreanLocalizations.editingTags, '태그 수정');
        expect(englishLocalizations.editingTags, 'Edit Tags');
      });

      test('colorTheme returns correct translation', () {
        expect(koreanLocalizations.colorTheme, '색상 테마');
        expect(englishLocalizations.colorTheme, 'Color Theme');
      });

      test('tagName returns correct translation', () {
        expect(koreanLocalizations.tagName, '이름');
        expect(englishLocalizations.tagName, 'Name');
      });

      test('apply returns correct translation', () {
        expect(koreanLocalizations.apply, '적용');
        expect(englishLocalizations.apply, 'Apply');
      });

      test('newTag returns correct translation', () {
        expect(koreanLocalizations.newTag, '새 태그');
        expect(englishLocalizations.newTag, 'New Tag');
      });

      test('deleteTag returns correct translation', () {
        expect(koreanLocalizations.deleteTag, '태그 삭제');
        expect(englishLocalizations.deleteTag, 'Delete Tag');
      });

      test('maxTagsReached returns correct translation', () {
        expect(koreanLocalizations.maxTagsReached, '태그는 최대 15개까지 생성할 수 있습니다.');
        expect(
          englishLocalizations.maxTagsReached,
          'You can create up to 15 tags.',
        );
      });

      test('pleaseEnterTagName returns correct translation', () {
        expect(koreanLocalizations.pleaseEnterTagName, '태그 이름을 입력해주세요.');
        expect(
          englishLocalizations.pleaseEnterTagName,
          'Please enter tag name.',
        );
      });

      test('duplicateTagName returns correct translation', () {
        expect(
          koreanLocalizations.duplicateTagName,
          '이미 사용 중인 이름입니다. 다른 이름을 입력해주세요.',
        );
        expect(
          englishLocalizations.duplicateTagName,
          'This name is already in use. Please enter a different name.',
        );
      });

      test('tagDeleteWarning returns correct translation', () {
        final subjects = ['과목1', '과목2'];
        expect(
          koreanLocalizations.tagDeleteWarning('테스트', subjects),
          '태그 "테스트"는\n다음 과목에서 사용 중입니다:\n\n과목1\n과목2\n\n삭제하시겠습니까?',
        );
        expect(
          englishLocalizations.tagDeleteWarning('test', subjects),
          'Tag "test" is used in the following subjects:\n\n과목1\n과목2\n\nDo you want to delete it?',
        );
      });
    });

    group('Lecture Strings', () {
      test('lecture returns correct translation', () {
        expect(koreanLocalizations.lecture, '강의');
        expect(englishLocalizations.lecture, 'Lecture');
      });

      test('lectures returns correct translation', () {
        expect(koreanLocalizations.lectures, '강의');
        expect(englishLocalizations.lectures, 'Lectures');
      });

      test('lectureDetails returns correct translation', () {
        expect(koreanLocalizations.lectureDetails, '강의 상세정보');
        expect(englishLocalizations.lectureDetails, 'Lecture Details');
      });

      test('week returns correct translation', () {
        expect(koreanLocalizations.week, '주차');
        expect(englishLocalizations.week, 'Week');
      });

      test('lectureTitle returns correct translation', () {
        expect(koreanLocalizations.lectureTitle, '강의 제목');
        expect(englishLocalizations.lectureTitle, 'Lecture Title');
      });

      test('lectureLength returns correct translation', () {
        expect(koreanLocalizations.lectureLength, '강의 길이');
        expect(englishLocalizations.lectureLength, 'Lecture Length');
      });

      test('deleteLecture returns correct translation', () {
        expect(koreanLocalizations.deleteLecture, '강의 삭제');
        expect(englishLocalizations.deleteLecture, 'Delete Lecture');
      });
    });

    group('Search Screen Strings', () {
      test('searchLecture returns correct translation', () {
        expect(koreanLocalizations.searchLecture, '강의 검색');
        expect(englishLocalizations.searchLecture, 'Search Lectures');
      });

      test('recentSearches returns correct translation', () {
        expect(koreanLocalizations.recentSearches, '최근 검색');
        expect(englishLocalizations.recentSearches, 'Recent Searches');
      });

      test('noRecentSearches returns correct translation', () {
        expect(koreanLocalizations.noRecentSearches, '최근 검색 기록이 없습니다');
        expect(englishLocalizations.noRecentSearches, 'No recent searches');
      });

      test('searchPlaceholder returns correct translation', () {
        expect(koreanLocalizations.searchPlaceholder, '검색어를 입력하세요');
        expect(englishLocalizations.searchPlaceholder, 'Enter search term');
      });

      test('noSearchResults returns correct translation', () {
        expect(koreanLocalizations.noSearchResults, '검색 결과가 없습니다');
        expect(englishLocalizations.noSearchResults, 'No search results');
      });

      test('searchBy returns correct translation', () {
        expect(koreanLocalizations.searchBy, '검색 범위');
        expect(englishLocalizations.searchBy, 'Search by');
      });

      test('searchByLecture returns correct translation', () {
        expect(koreanLocalizations.searchByLecture, '강의명');
        expect(englishLocalizations.searchByLecture, 'Lecture name');
      });

      test('searchByWeek returns correct translation', () {
        expect(koreanLocalizations.searchByWeek, '주차');
        expect(englishLocalizations.searchByWeek, 'Week');
      });

      test('searchBySubject returns correct translation', () {
        expect(koreanLocalizations.searchBySubject, '과목명');
        expect(englishLocalizations.searchBySubject, 'Subject name');
      });
    });

    group('Theme Names', () {
      test('theme names return correct Korean translations', () {
        expect(koreanLocalizations.themeSpring, '봄');
        expect(koreanLocalizations.themeSummer, '여름');
        expect(koreanLocalizations.themeAutumn, '가을');
        expect(koreanLocalizations.themeWinter, '겨울');
        expect(koreanLocalizations.themeCottonCandy, '솜사탕');
        expect(koreanLocalizations.themeVivid, '비비드');
        expect(koreanLocalizations.themeSea, '바다');
      });

      test('theme names return correct English translations', () {
        expect(englishLocalizations.themeSpring, 'Spring');
        expect(englishLocalizations.themeSummer, 'Summer');
        expect(englishLocalizations.themeAutumn, 'Autumn');
        expect(englishLocalizations.themeWinter, 'Winter');
        expect(englishLocalizations.themeCottonCandy, 'Cotton Candy');
        expect(englishLocalizations.themeVivid, 'Vivid');
        expect(englishLocalizations.themeSea, 'Sea');
      });
    });

    group('getThemeName', () {
      test('returns Korean theme name for Korean locale', () {
        expect(koreanLocalizations.getThemeName('봄'), '봄');
        expect(koreanLocalizations.getThemeName('여름'), '여름');
        expect(koreanLocalizations.getThemeName('가을'), '가을');
        expect(koreanLocalizations.getThemeName('겨울'), '겨울');
        expect(koreanLocalizations.getThemeName('솜사탕'), '솜사탕');
        expect(koreanLocalizations.getThemeName('비비드'), '비비드');
        expect(koreanLocalizations.getThemeName('바다'), '바다');
      });

      test('returns English theme name for English locale', () {
        expect(englishLocalizations.getThemeName('봄'), 'Spring');
        expect(englishLocalizations.getThemeName('여름'), 'Summer');
        expect(englishLocalizations.getThemeName('가을'), 'Autumn');
        expect(englishLocalizations.getThemeName('겨울'), 'Winter');
        expect(englishLocalizations.getThemeName('솜사탕'), 'Cotton Candy');
        expect(englishLocalizations.getThemeName('비비드'), 'Vivid');
        expect(englishLocalizations.getThemeName('바다'), 'Sea');
      });

      test('returns original name for unknown theme', () {
        expect(koreanLocalizations.getThemeName('알 수 없는 테마'), '알 수 없는 테마');
        expect(englishLocalizations.getThemeName('Unknown'), 'Unknown');
      });
    });

    group('Supported Locales', () {
      test('contains Korean locale', () {
        expect(
          AppLocalizations.supportedLocales,
          contains(const Locale('ko', 'KR')),
        );
      });

      test('contains English locale', () {
        expect(
          AppLocalizations.supportedLocales,
          contains(const Locale('en', 'US')),
        );
      });

      test('has exactly 2 supported locales', () {
        expect(AppLocalizations.supportedLocales.length, 2);
      });
    });

    group('LocalizationsDelegate', () {
      const delegate = AppLocalizations.delegate;

      test('supports Korean locale', () {
        expect(delegate.isSupported(const Locale('ko', 'KR')), isTrue);
      });

      test('supports English locale', () {
        expect(delegate.isSupported(const Locale('en', 'US')), isTrue);
      });

      test('does not support unsupported locale', () {
        expect(delegate.isSupported(const Locale('ja', 'JP')), isFalse);
        expect(delegate.isSupported(const Locale('zh', 'CN')), isFalse);
      });

      test('load returns AppLocalizations instance', () async {
        final result = await delegate.load(const Locale('ko', 'KR'));
        expect(result, isA<AppLocalizations>());
        expect(result.locale, const Locale('ko', 'KR'));
      });

      test('shouldReload returns false', () {
        expect(delegate.shouldReload(delegate), isFalse);
      });
    });
  });
}
