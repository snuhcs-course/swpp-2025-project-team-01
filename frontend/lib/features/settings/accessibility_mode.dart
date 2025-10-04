import 'package:flutter/material.dart';
import '../../core/accessibility_service.dart';
import '../../core/localization/app_localizations.dart';

/// Figma: 2-4-3. Accessibility
/// - 예시: 고대비/모션 줄이기/자막 강조 등 토글 + 가이드 텍스트
/// AccessibilityService를 통해 각 요소 정보 저장
class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});
  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  final _service = AccessibilityService();

  @override
  void initState() {
    super.initState();
    // 리스너 등록
    _service.addListener(_onAccessibilityChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onAccessibilityChanged);
    super.dispose();
  }

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
      appBar: AppBar(title: Text(l10n.accessibility)),
      backgroundColor: isDark ? null : const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ListView(
          children: [
            SwitchListTile(
              contentPadding: const EdgeInsets.only(left: 24, right: 16),
              title: Text(l10n.highContrast),
              subtitle: Text(l10n.highContrastDesc),
              value: _service.highContrast,
              onChanged: (value) => _service.setHighContrast(value),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.only(left: 24, right: 16),
              title: Text(l10n.reduceMotion),
              subtitle: Text(l10n.reduceMotionDesc),
              value: _service.reduceMotion,
              onChanged: (value) => _service.setReduceMotion(value),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.only(left: 24, right: 16),
              title: Text(l10n.emphasizeCaptions),
              subtitle: Text(l10n.emphasizeCaptionsDesc),
              value: _service.emphasizeCaptions,
              onChanged: (value) => _service.setEmphasizeCaptions(value),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.accessibilityAppliedImmediately, style: const TextStyle(color: Colors.black54)),
            ),
          ],
        ),
      ),
    );
  }
}