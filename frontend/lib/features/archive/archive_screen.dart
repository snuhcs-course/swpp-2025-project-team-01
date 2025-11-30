import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:re_view/app_router.dart';
import 'package:re_view/core/device_orientation_helper.dart';
import 'package:re_view/core/localization/app_localizations.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/data/hive_models.dart';
import 'package:re_view/features/home/home_widgets.dart';
import 'package:re_view/shared/widgets.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key, this.hiveManager});

  final HiveManager? hiveManager;
  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen>
    with WidgetsBindingObserver {
  late final HiveManager _manager = widget.hiveManager ?? HiveManager.instance;
  List<HiveSubject> _archivedSubjects = [];

  /// Player로 이동하고 돌아올 때 orientation 재설정
  Future<void> _navigateToPlayer(String lectureId) async {
    // PlayerScreen 활성화 중에는 HomeScreen의 orientation 관찰 중단
    WidgetsBinding.instance.removeObserver(this);

    await Navigator.pushNamed(
      context,
      Routes.player,
      arguments: {'lectureId': lectureId},
    );

    // Player에서 돌아온 후 observer 재등록 및 orientation 재설정
    WidgetsBinding.instance.addObserver(this);
    if (mounted) {
      lockToCurrentOrientation(context);
    }
  }

  Future<bool?> _showUnarchiveConfirmationDialog(HiveSubject subject) {
    final l10n = AppLocalizations.of(context);

    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => DeleteWarningDialog(
        warningText: l10n.unarchive,
        yesText: l10n.yes,
        noText: l10n.no,
        onConfirm: () async {
          await _manager.unarchiveSubject(subject.id);
          if (!mounted) {
            return;
          }

          setState(() {
            // nothing to do here
          });
        },
        body: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              height: 1.5,
            ),
            children: [
              TextSpan(text: l10n.unarchiveConfirmText(subject.title)),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(HiveSubject subject) {
    final l10n = AppLocalizations.of(context);

    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => DeleteWarningDialog(
        warningText: l10n.warning,
        yesText: l10n.yes,
        noText: l10n.no,
        onConfirm: () {
          _manager.deleteSubject(subject.id);
          if (!mounted) {
            return;
          }

          setState(() {
            // nothing to do here
          });
        },
        body: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              height: 1.5,
            ),
            children: [
              TextSpan(text: l10n.deleteSubjectWarning1),
              TextSpan(
                text: l10n.deleteSubjectWarning2,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: l10n.deleteSubjectWarning3),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // HiveManager가 초기화되지 않았으면 로딩 표시
    if (!_manager.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _archivedSubjects = _manager.archivedSubjects.values.where((subject) {
      // 미분류 과목은 강의가 있을 때만 표시
      if (subject.isUncategorized) {
        return false;
      }
      return subject.isArchived;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.archive),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // 과목 패널 리스트 또는 빈 상태 메시지
          if (_archivedSubjects.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: EmptyStateMessage(message: l10n.noArchivedSubjects),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverMasonryGrid.count(
                crossAxisCount:
                    MediaQuery.of(context).size.width >
                        MediaQuery.of(context).size.height
                    ? 2
                    : 1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childCount: _archivedSubjects.length,
                itemBuilder: (context, i) {
                  final HiveSubject s = _archivedSubjects[i];
                  final lectures = _manager.getLecturesBySubject(s.id);
                  return SubjectPanel(
                    key: ValueKey(s.id),
                    subject: s,
                    tags: [],
                    lectures: lectures,
                    onToggleFavorite: () {
                      // No favorite in archive
                    },
                    onOpenLecture: (HiveLecture lec) {
                      _navigateToPlayer(lec.id);
                    },
                    onUnarchiveSubject: () {
                      _showUnarchiveConfirmationDialog(s);
                    },
                    onDeleteSubject: () {
                      _showDeleteConfirmationDialog(s);
                    },
                    showEdit: false,
                    isArchivedSubject: true,
                    hiveManager: _manager,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
