import 'package:flutter/material.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/core/localization/app_localizations.dart';

/// 접근성 설정 화면 (Figma 2-4-3. Accessibility)
///
/// 이 화면은 시각, 청각, 운동 능력 등에 제약이 있는 사용자들을 위한
/// 접근성 기능을 설정할 수 있습니다.
///
/// 제공되는 접근성 기능:
/// - 고대비 (High Contrast): 텍스트와 배경의 대비를 높여 가독성 향상
/// - 모션 줄이기 (Reduce Motion): 애니메이션과 화면 전환 효과 최소화
/// - 자막 강조 (Emphasize Captions): 자막의 크기와 굵기를 강조하여 표시
///
/// 모든 설정은 AccessibilityService를 통해 관리되며 즉시 적용됩니다.
///
/// UI 구조:
/// - 상단: 앱바 (제목: "접근성")
/// - 본문: 스위치 리스트 타일 3개 (각 접근성 기능)
/// - 하단: 안내 텍스트
class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({
    super.key,
    this.hiveManager, // [추가] 생성자에 추가
  });

  final HiveManager? hiveManager;

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  // 접근성 서비스 인스턴스
  late final HiveManager _manager;

  @override
  void initState() {
    super.initState();
    // 접근성 설정 변경 리스너 등록 (설정 변경 시 자동 UI 업데이트)
    _manager = widget.hiveManager ?? HiveManager.instance;
    _manager.addListener(_onAccessibilityChanged);
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위해 리스너 제거
    _manager.removeListener(_onAccessibilityChanged);
    super.dispose();
  }

  /// 접근성 설정 변경 시 호출되는 콜백
  ///
  /// UI를 다시 빌드하여 변경된 설정을 반영합니다.
  void _onAccessibilityChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 상단 앱바
      appBar: AppBar(title: Text(l10n.accessibility)),
      backgroundColor: isDark ? null : const Color(0xFFF5F5F5),

      // 접근성 설정 옵션 리스트
      body: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ListView(
          children: [
            // 1. 고대비 모드 (High Contrast)
            // 텍스트와 배경의 대비를 높여 시각적 가독성 향상
            SwitchListTile(
              contentPadding: const EdgeInsets.only(left: 24, right: 16),
              title: Text(l10n.highContrast),
              subtitle: Text(l10n.highContrastDesc),
              value: _manager.settings.accessibilityHighContrast,
              onChanged: (value) =>
                  _manager.updateAccessibility(highContrast: value),
            ),

            // 2. 모션 줄이기 (Reduce Motion)
            // 애니메이션 효과를 최소화하여 멀미 방지 및 인지 부담 감소
            SwitchListTile(
              contentPadding: const EdgeInsets.only(left: 24, right: 16),
              title: Text(l10n.reduceMotion),
              subtitle: Text(l10n.reduceMotionDesc),
              value: _manager.settings.accessibilityReduceMotion,
              onChanged: (value) =>
                  _manager.updateAccessibility(reduceMotion: value),
            ),

            // 3. 자막 강조 (Emphasize Captions)
            // 자막의 크기와 굵기를 강조하여 청각 장애인 지원
            SwitchListTile(
              contentPadding: const EdgeInsets.only(left: 24, right: 16),
              title: Text(l10n.emphasizeCaptions),
              subtitle: Text(l10n.emphasizeCaptionsDesc),
              value: _manager.settings.accessibilityEmphasizeCaptions,
              onChanged: (value) =>
                  _manager.updateAccessibility(emphasizeCaptions: value),
            ),

            // 안내 텍스트: 설정 즉시 적용 알림
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.accessibilityAppliedImmediately,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
