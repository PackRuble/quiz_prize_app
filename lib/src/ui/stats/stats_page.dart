import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/ui/shared/app_bar_custom.dart';

import '../const/app_colors.dart';
import '../shared/cardpad.dart';
import 'stats_page_ctrl.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  static const path = '/stats';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesPlayedCount = ref.watch(StatsPageCtrl.quizzesPlayed).length;

    return Scaffold(
      appBar: const AppBarCustom(
        title: 'Statistics',
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: GeneralStatsBlock()),
          if (quizzesPlayedCount > 0) ...const [
            DifficultyBlockSliver(),
            CategoriesBlockSliver(),
            SliverToBoxAdapter(child: Divider(indent: 8, endIndent: 8)),
            SliverToBoxAdapter(child: HintToColoredAnswers()),
            PlayedQuizzesSliver(),
            SliverToBoxAdapter(child: SizedBox(height: 64)),
          ],
        ],
      ),
    );
  }
}

class HintToColoredAnswers extends ConsumerWidget {
  const HintToColoredAnswers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    Widget buildHint(String text, Color color) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: textTheme.labelMedium,
            ),
          ),
        ],
      );
    }

    return CardPad(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(child: buildHint('correct answer', AppColors.correctAnswer)),
          Flexible(child: buildHint('my answer', AppColors.myAnswer)),
        ],
      ),
    );
  }
}

class GeneralStatsBlock extends ConsumerWidget {
  const GeneralStatsBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    final pageController = ref.watch(StatsPageCtrl.instance.notifier);
    final totalCount = ref.watch(StatsPageCtrl.quizzesPlayed).length;
    final solvedCount = ref.watch(StatsPageCtrl.solvedCount);
    final unsolvedCount = ref.watch(StatsPageCtrl.unsolvedCount);

    return CardPad(
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Total score: ',
                style: textTheme.labelLarge,
                children: <InlineSpan>[
                  TextSpan(
                    text: '$totalCount ',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.orange[900],
                    ),
                  ),
                  TextSpan(
                    text: '[',
                    style: textTheme.titleMedium,
                  ),
                  TextSpan(
                    text: '⬇$unsolvedCount ',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.unCorrectCounterText,
                    ),
                  ),
                  TextSpan(
                    text: '⬆$solvedCount',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.correctCounterText,
                    ),
                  ),
                  TextSpan(
                    text: ']',
                    style: textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          FilledButton.tonal(
            onPressed: () async {
              await showDialogConfirmResetStats(
                context,
                () {
                  pageController.resetStatistics();
                  Navigator.of(context).pop();
                },
              );
            },
            child: const Text('Reset stats'),
          ),
        ],
      ),
    );
  }

  Future<void> showDialogConfirmResetStats(
    BuildContext context,
    VoidCallback onOk,
  ) async {
    return showAdaptiveDialog(
      context: context,
      builder: (context) {
        return AlertDialog.adaptive(
          title: const Text('Reset statistics?'),
          content: const Text(
            'All played quizzes will be deleted, all indicators will be reset.',
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text(
                MaterialLocalizations.of(context).cancelButtonLabel,
              ),
            ),
            TextButton(
              onPressed: onOk,
              child: Text(
                MaterialLocalizations.of(context).okButtonLabel,
              ),
            ),
          ],
        );
      },
    );
  }
}

class DifficultyBlockSliver extends ConsumerWidget {
  const DifficultyBlockSliver({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final statsOnDifficulty = ref.watch(StatsPageCtrl.statsByDifficulty);

    return SliverToBoxAdapter(
      child: CardPad(
        child: Column(
          children: [
            for (final MapEntry(
                  key: difficulty,
                  value: (int correctly, int incorrectly)
                ) in statsOnDifficulty.entries)
              Row(
                children: [
                  Expanded(child: Text(difficulty.name)),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '⬇$incorrectly',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.unCorrectCounterText,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '⬆$correctly',
                      textAlign: TextAlign.right,
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.correctCounterText,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class CategoriesBlockSliver extends ConsumerWidget {
  const CategoriesBlockSliver({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    final statsOnCategory = ref.watch(StatsPageCtrl.statsByCategory);

    return SliverToBoxAdapter(
      child: CardPad(
        child: Column(
          children: [
            for (final MapEntry(
                  key: categoryName,
                  value: (int correctly, int incorrectly)
                ) in statsOnCategory.entries)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(categoryName)),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '⬇$incorrectly',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.unCorrectCounterText,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '⬆$correctly',
                      textAlign: TextAlign.right,
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.correctCounterText,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class PlayedQuizzesSliver extends ConsumerWidget {
  const PlayedQuizzesSliver({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    final quizzesPlayed = ref.watch(StatsPageCtrl.quizzesPlayed);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: quizzesPlayed.length,
        (context, index) {
          final quiz = quizzesPlayed[index];

          return CardPad(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.question,
                  style: textTheme.labelLarge,
                ),
                ...[
                  for (final answer in quiz.answers)
                    Text(
                      '-> $answer',
                      style: switch (quiz.correctlySolved) {
                        true when answer == quiz.yourAnswer =>
                          TextStyle(backgroundColor: AppColors.correctAnswer),
                        false when answer == quiz.yourAnswer =>
                          TextStyle(backgroundColor: AppColors.correctAnswer),
                        false when answer == quiz.correctAnswer =>
                          TextStyle(backgroundColor: AppColors.myAnswer),
                        _ => null
                      },
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
