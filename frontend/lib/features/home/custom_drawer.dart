import 'package:flutter/material.dart';
import '../../app_router.dart';
import '../../core/accessibility_service.dart';

/// 모션 줄이기를 지원하는 커스텀 Drawer
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AccessibilityService().reduceMotion;

    if (reduceMotion) {
      // 모션 줄이기: 애니메이션 없는 Drawer
      return _NoAnimationDrawer();
    } else {
      // 일반 Drawer
      return Drawer(
        child: _DrawerContent(),
      );
    }
  }
}

/// 애니메이션 없는 Drawer (모션 줄이기용)
class _NoAnimationDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).drawerTheme.backgroundColor ?? Theme.of(context).canvasColor,
      elevation: 16,
      child: SafeArea(
        child: _DrawerContent(),
      ),
    );
  }
}

/// Drawer 내용
class _DrawerContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text('메뉴', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ),
        ),
        ListTile(
          title: const Text('수업 추가'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, Routes.lectureForm);
          },
        ),
        ListTile(
          title: const Text('과목 수정'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, Routes.subjectsEdit);
          },
        ),
        ListTile(
          title: const Text('태그 수정'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, Routes.tagsEdit);
          },
        ),
        const Divider(),
        ListTile(
          title: const Text('설정'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, Routes.settings);
          },
        ),
      ],
    );
  }
}
