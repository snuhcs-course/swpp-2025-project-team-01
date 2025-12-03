import 'package:flutter/material.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/core/localization/app_localizations.dart';

/// 모션 줄이기를 지원하는 커스텀 Drawer
///
/// reduceMotion이 true이면 애니메이션 없이 즉시 표시
/// reduceMotion이 false이면 일반 슬라이드 애니메이션 사용
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key, required this.reduceMotion});

  final bool reduceMotion;

  static const ShapeBorder drawerShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
  );

  /// 커스텀 Drawer를 열기 (애니메이션 제어 포함)
  static void open(BuildContext context, bool reduceMotion) {
    if (reduceMotion) {
      // 모션 줄이기: Overlay를 사용하여 즉시 표시
      _showWithoutAnimation(context);
    } else {
      // 일반: Scaffold의 기본 Drawer 사용
      Scaffold.of(context).openDrawer();
    }
  }

  /// Drawer의 기본 너비를 계산 (Flutter 내장 Drawer와 동일한 로직)
  static double _getDrawerWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Flutter 기본 Drawer 너비 = min(화면너비, 304.0)
    // 화면이 너무 작으면 화면 너비 - 56.0 사용
    const double defaultWidth = 304.0;
    const double edgeWidth = 56.0;

    // Drawer는 최소 한 변이 화면에서 56dp 떨어져야 함
    final double maxWidth = screenWidth - edgeWidth;

    return maxWidth < defaultWidth ? maxWidth : defaultWidth;
  }

  /// 애니메이션 없이 Drawer를 표시 (Overlay 사용)
  static void _showWithoutAnimation(BuildContext context) {
    final overlay = Overlay.of(context);
    final drawerWidth = _getDrawerWidth(context);

    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 반투명 배경
          GestureDetector(
            onTap: () => overlayEntry?.remove(),
            child: Container(color: Colors.black54),
          ),
          // Drawer 컨텐츠
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Material(
              color: Theme.of(context).canvasColor,
              elevation: 16,
              shape: drawerShape,
              child: SizedBox(
                width: drawerWidth,
                child: SafeArea(
                  child: _DrawerContent(
                    onClose: () => overlayEntry?.remove(),
                    delayClose: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: drawerShape,
      child: _DrawerContent(
        onClose: () => Navigator.pop(context),
        delayClose: false,
      ),
    );
  }
}

/// Drawer 내용
class _DrawerContent extends StatelessWidget {
  const _DrawerContent({required this.onClose, this.delayClose = false});

  final VoidCallback onClose;
  final bool delayClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final bool isPortrait = mediaQuery.orientation == Orientation.portrait;
    final double additionalTopPadding = isPortrait ? mediaQuery.padding.top : 0;
    final double headingTopPadding = 30.0 + additionalTopPadding;

    void handleNavigation(String route) {
      if (delayClose) {
        // Overlay 모드: navigation 후 딜레이를 주고 오버레이 제거
        Navigator.pushNamed(context, route);
        Future.delayed(const Duration(milliseconds: 100), onClose);
      } else {
        // Drawer 모드: Drawer를 먼저 닫고 navigation
        onClose();
        Navigator.pushNamed(context, route);
      }
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.0, headingTopPadding, 16.0, 16.0),
          child: Text(
            l10n.menu,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        const Divider(),
        ListTile(
          title: Text(l10n.addLecture),
          onTap: () => handleNavigation(Routes.lectureForm),
        ),
        ListTile(
          title: Text(l10n.editTags),
          onTap: () => handleNavigation(Routes.tagsEdit),
        ),
        const Divider(),
        ListTile(
          title: Text(l10n.archive),
          onTap: () => handleNavigation(Routes.archive),
        ),
        const Divider(),
        ListTile(
          title: Text(l10n.settings),
          onTap: () => handleNavigation(Routes.settings),
        ),
      ],
    );
  }
}
