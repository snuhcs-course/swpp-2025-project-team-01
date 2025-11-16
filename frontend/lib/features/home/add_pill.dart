import 'package:flutter/material.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/home/home_subject_widgets.dart';
import 'package:re_view/features/home/home_widgets.dart';

class AddPill extends StatefulWidget {
  const AddPill({
    super.key,
    required this.icon,
    required this.link,
    this.hiveManager,
  });

  final IconData icon;
  final LayerLink link;
  final HiveManager? hiveManager;

  @override
  State<AddPill> createState() => _AddPillState();
}

class _AddPillState extends State<AddPill> with SingleTickerProviderStateMixin {
  late final HiveManager _manager = widget.hiveManager ?? HiveManager.instance;

  bool active = false;

  VoidCallback get onTap => _toggleAddMenu;

  @override
  void initState() {
    super.initState();
    // Repository 변경 리스너 등록
    _manager.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    // 리스너 제거
    _manager.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = active
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? Colors.white : Colors.black87);

    return PillButton(
      onTap: onTap,
      active: active,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [Icon(widget.icon, size: 18, color: fg)],
      ),
    );
  }

  OverlayEntry? _addMenu;
  late final AnimationController _addCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  late final Animation<Offset> _slide1 = Tween(
    begin: const Offset(0, -0.15),
    end: Offset.zero,
  ).chain(CurveTween(curve: Curves.easeOut)).animate(_addCtrl);
  late final Animation<Offset> _slide2 = Tween(
    begin: const Offset(0, -0.30),
    end: Offset.zero,
  ).chain(CurveTween(curve: Curves.easeOut)).animate(_addCtrl);

  void _toggleAddMenu() {
    if (_addMenu == null) {
      _showAddMenu();
    } else {
      _hideAddMenu();
    }
  }

  void _showAddMenu() {
    final l10n = AppLocalizations.of(context);
    final overlay = Overlay.of(context);

    // 1) Resolve layout boxes
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final plusBox =
        (widget.key! as GlobalKey).currentContext?.findRenderObject()
            as RenderBox?;
    if (overlayBox == null || plusBox == null) {
      return;
    }

    // 2) Global geometry (in overlay coords)
    final Offset plusTopLeft = plusBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final Size plusSize = plusBox.size;
    final double screenW = overlayBox.size.width;

    // 3) Safe-area & margins
    final padding = MediaQuery.of(context).viewPadding; // safe area
    final leftLimit = padding.left + 12.0; // min gap to left edge
    final rightLimit = screenW - padding.right - 12.0; // max x for right edge

    // 4) Desired menu width (you can tweak or compute from text)
    const double desiredMenuW = 180.0;
    final double menuW = desiredMenuW.clamp(120.0, rightLimit - leftLimit);

    // 5) Base anchor x: align menu's left to the + pill's left (LTR) or right (RTL)
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final double baseX = rtl
        ? (plusTopLeft.dx + plusSize.width - menuW) // right-align to +
        : plusTopLeft.dx; // left-align to +

    // 6) Clamp horizontally so menu fits the screen
    double clampedX = baseX;
    if (clampedX < leftLimit) {
      clampedX = leftLimit;
    }
    if (clampedX + menuW > rightLimit) {
      clampedX = rightLimit - menuW;
    }

    // 7) Convert clamped global X back to follower-relative dx shift
    //    Follower offset is relative to the + target's top-left.
    final double dxShift = clampedX - plusTopLeft.dx;

    // 8) Vertical offset: place menu below the +
    final double dy = plusSize.height + 8.0;

    setState(() => active = true);

    _addMenu = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideAddMenu,
            ),
          ),
          CompositedTransformFollower(
            link: widget.link,
            showWhenUnlinked: false,
            offset: Offset(dxShift, dy),
            child: ConstrainedBox(
              constraints: BoxConstraints.tightFor(width: menuW),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SlideTransition(
                      position: _slide1,
                      child: MiniActionPill(
                        text: l10n.addLecture,
                        icon: Icons.note_add_outlined,
                        onTap: () {
                          _hideAddMenu();
                          Navigator.pushNamed(context, Routes.lectureForm);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    SlideTransition(
                      position: _slide2,
                      child: MiniActionPill(
                        text: l10n.addSubject,
                        icon: Icons.folder_open_outlined,
                        onTap: () async {
                          _hideAddMenu();
                          await _showCreateSubjectDialog(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_addMenu!);
    _addCtrl.forward(from: 0);
  }

  void _hideAddMenu() {
    _addCtrl.reverse();
    _addMenu?.remove();
    _addMenu = null;
    setState(() => active = false);
  }

  Future<void> _showCreateSubjectDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CreateSubjectDialog(allTags: _manager.getTags()),
    );

    if (!mounted || result == null || result['action'] != 'create') {
      return;
    }

    final titleText = result['title'] as String;
    final selectedTagIds = result['tagIds'] as List<String>;

    await _manager.createSubject(titleText, selectedTagIds);
  }
}

// 강의 및 과목 추가
class MiniActionPill extends StatelessWidget {
  const MiniActionPill({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      elevation: isDark ? 0 : 4,
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
