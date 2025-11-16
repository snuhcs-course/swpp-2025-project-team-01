import 'package:flutter/material.dart';
import 'package:re_view/core/localization/app_localizations.dart';

/// 도움말 화면 (Figma 2-4-5. Help)
/// - 질문을 탭하면 답변이 펼쳐졌다 접히는 토글형 위젯(3개)
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      backgroundColor: isDark ? null : const Color(0xFFF5F5F5),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FaqTile(
            leadingIcon: Icons.search,
            question: l10n.howToFindLecture,
            answer:
                '${l10n.findLectureByTitle}\n'
                '${l10n.findLectureByTag}',
          ),
          const SizedBox(height: 12),
          _FaqTile(
            leadingIcon: Icons.delete,
            question: l10n.howToDeleteLecture,
            answer: l10n.deleteLectureAtHome,
          ),
          const SizedBox(height: 12),
          _FaqTile(
            leadingIcon: Icons.tag,
            question: l10n.howToEditSubjectTag,
            answer: l10n.editTagAtSubjectEdit,
          ),
          const SizedBox(height: 12),
          _FaqTile(
            leadingIcon: Icons.reorder,
            question: l10n.howToReorder,
            answer:
                '${l10n.reorderSubjects}\n'
                '${l10n.reorderLectures}',
          ),
          const SizedBox(height: 12),
          _FaqTile(
            leadingIcon: Icons.update,
            question: l10n.howToHideLoading,
            answer:
                '${l10n.hideLoadingBySwipe}\n'
                '${l10n.showLoadingBarAgain}',
          ),
          const SizedBox(height: 12),
          _FaqTile(
            leadingIcon: Icons.menu_book,
            question: l10n.howToViewSlidesAtPlayer,
            answer: l10n.showSlidesBySwipe,
          ),
          const SizedBox(height: 12),
          _FaqTile(
            leadingIcon: Icons.sync,
            question: l10n.howToUnsync,
            answer: l10n.useUnsyncButton,
          ),
          const SizedBox(height: 24),
          l10n.isKorean
              ? _InfoCard(
                  title: '한국어 강의도 지원되나요?',
                  body:
                      '  현재 개발 중에 있으며 11월 중으로 만나보실 수 있습니다!\n'
                      '  기대해주세요 :)',
                )
              : _InfoCard(
                  title: l10n.buyCoffee,
                  body: '  https://buymeacoffee.com',
                ),
        ],
      ),
    );
  }
}

/// 단일 FAQ 토글 타일
class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
    this.leadingIcon = Icons.help_outline,
  });

  final String question;
  final String answer;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(leadingIcon),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          title: Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(answer, style: const TextStyle(height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 보조 안내용 간단 카드
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(height: 1.5)),
          ],
        ),
      ),
    );
  }
}
