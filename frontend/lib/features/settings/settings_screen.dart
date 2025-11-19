import 'package:flutter/material.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/core/localization/app_localizations.dart';

/// 설정 메인 화면 (Figma 2-4. Settings)
///
/// 이 화면은 앱의 각종 설정 메뉴로 이동할 수 있는 진입점을 제공합니다.
///
/// 제공되는 설정 메뉴:
/// - 화면 모드 (Display Mode): 라이트/다크/시스템 설정
/// - TTS: 음성 성별, 악센트, 재생 속도 설정
/// - 접근성 (Accessibility): 고대비, 모션 줄이기, 자막 강조
/// - 언어 (Language): 한국어/English 선택
/// - 도움말 (Help): 기본 안내 및 튜토리얼
///
/// UI 구조:
/// - 상단: 앱바 (제목: "설정")
/// - 본문: 설정 메뉴 리스트 (각 항목은 해당 설정 화면으로 이동)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 상단 앱바
      appBar: AppBar(title: Text(l10n.settings)),
      backgroundColor: isDark ? null : const Color(0xFFF5F5F5),

      // 설정 메뉴 목록 (각 항목은 상세 설정 화면으로 이동)
      body: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ListView(
          children: [
            // 1. 화면 모드: 라이트/다크/시스템 설정
            _buildNavigationTile(
              context,
              l10n.displayMode,
              Routes.settingsDisplay,
            ),

            // 2. TTS: 음성 성별, 악센트, 재생 속도 설정
            _buildNavigationTile(context, l10n.tts, Routes.settingsTts),

            // 3. 접근성: 고대비, 모션 줄이기, 자막 강조
            _buildNavigationTile(
              context,
              l10n.accessibility,
              Routes.settingsAccessibility,
            ),

            // 4. 언어: 한국어/English 선택
            _buildNavigationTile(
              context,
              l10n.language,
              Routes.settingsLanguage,
            ),

            // 5. 도움말: 기본 안내 및 튜토리얼
            _buildNavigationTile(context, l10n.help, Routes.settingsHelp),
          ],
        ),
      ),
    );
  }

  /// 네비게이션 타일 위젯
  ///
  /// 설정 메뉴 항목을 표시하고 탭하면 해당 화면으로 이동합니다.
  ///
  /// [context]: 빌드 컨텍스트
  /// [title]: 메뉴 항목 제목
  /// [route]: 이동할 라우트 경로
  Widget _buildNavigationTile(
    BuildContext context,
    String title,
    String route,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 24, right: 16),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}
