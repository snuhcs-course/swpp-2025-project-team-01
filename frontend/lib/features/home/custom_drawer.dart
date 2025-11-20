import 'package:flutter/material.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/core/localization/app_localizations.dart';

/// 모션 줄이기를 지원하는 커스텀 Drawer
///
/// 일반 모드: Scaffold의 drawer 속성에 사용
/// 모션 줄이기 모드: CustomDrawer.showAsDialog()를 호출하여 다이얼로그로 표시
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(child: _DrawerContent());
  }

  /// 모션 줄이기 모드용 다이얼로그 표시
  static void showAsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Theme.of(context).canvasColor,
          elevation: 16,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.75,
            height: double.infinity,
            child: SafeArea(child: _DrawerContent()),
          ),
        ),
      ),
    );
  }
}

/// Drawer 내용
class _DrawerContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final bool isPortrait = mediaQuery.orientation == Orientation.portrait;
    final double additionalTopPadding = isPortrait ? mediaQuery.padding.top : 0;
    final double headingTopPadding = 30.0 + additionalTopPadding;

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
          title: Text(l10n.archive),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, Routes.archive);
          },
        ),
        const Divider(),
        ListTile(
          title: Text(l10n.addLecture),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, Routes.lectureForm);
          },
        ),
        ListTile(
          title: Text(l10n.editTags),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, Routes.tagsEdit);
          },
        ),
        const Divider(),
        ListTile(
          title: Text(l10n.settings),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, Routes.settings);
          },
        ),
      ],
    );
  }
}
