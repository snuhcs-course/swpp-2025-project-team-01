// 모든 라우트 테이블/네비게이션 진입점
import 'package:flutter/material.dart';

// 화면들
import 'features/home/home_screen.dart';
import 'features/search/search_screen.dart';
import 'features/edit/lecture_form_screen.dart';
import 'features/edit/subject_tag_screen.dart';
import 'features/player/player_screen.dart';
import 'features/settings/display_mode_screen.dart';
import 'features/settings/accessibility_mode.dart';
import 'features/settings/help_screen.dart';
import 'features/settings/language_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/tts_screen.dart';
import 'features/subjects/subjects_edit_screen.dart';
import 'features/tags/tags_edit_screen.dart';


class Routes {
  static const onboarding = '/';
  static const home = '/home';
  static const search = '/search';
  static const lectureForm = '/lectures/new';
  static const subjectTag = '/manage';
  static const player = '/player';        // args: { lectureId, startSlide? }
  static const settings = '/settings';

  static const settingsDisplay = '/settings/display';
  static const settingsTts = '/settings/tts';
  static const settingsAccessibility = '/settings/accessibility';
  static const settingsLanguage = '/settings/language';
  static const settingsHelp = '/settings/help';
  static const subjectsEdit = '/subjects/edit';
  static const tagsEdit = '/tags/edit';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    switch (s.name) {
      case Routes.home:
      case Routes.onboarding:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case Routes.search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case Routes.lectureForm:
        return MaterialPageRoute(builder: (_) => const LectureFormScreen());
      case Routes.subjectTag:
        return MaterialPageRoute(builder: (_) => const SubjectTagScreen());
      case Routes.player:
        return MaterialPageRoute(builder: (_) => PlayerScreen(args: s.arguments));
      case Routes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case Routes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case Routes.settingsDisplay:
        return MaterialPageRoute(builder: (_) => const DisplayModeScreen());
      case Routes.settingsTts:
        return MaterialPageRoute(builder: (_) => const TtsScreen());
      case Routes.settingsAccessibility:
        return MaterialPageRoute(builder: (_) => const AccessibilityScreen());
      case Routes.settingsLanguage:
        return MaterialPageRoute(builder: (_) => const LanguageScreen());
      case Routes.settingsHelp:
        return MaterialPageRoute(builder: (_) => const HelpScreen());
      case Routes.subjectsEdit:
        return MaterialPageRoute(builder: (_) => const SubjectsEditScreen());
      case Routes.tagsEdit: 
        return MaterialPageRoute(builder: (_) => const TagsEditScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('Not Found'))),
        );
    }
  }
}