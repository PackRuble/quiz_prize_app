import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:trivia_app/extension/hex_color.dart';
import 'package:trivia_app/src/data/trivia/category/category.dto.dart';
import 'package:trivia_app/src/data/trivia/models.dart';
import 'package:trivia_app/src/domain/bloc/trivia_quiz/trivia_quiz_bloc.dart';
import 'package:trivia_app/src/ui/shared/app_bar_custom.dart';

import 'stats_page_ctrl.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  static const path = 'stats';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsBloc = ref.watch(TriviaStatsBloc.instance);
    final Map<TriviaQuizDifficulty, (int correctly, int uncorrectly)>
        statsOnDifficulty = ref.watch(statsBloc.statsOnDifficulty);
    final Map<String, (int correctly, int uncorrectly)> statsOnCategory =
        ref.watch(statsBloc.statsOnCategory);

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const AppBarCustom(
        children: [BackButton()],
      ),
      body: SizedBox(
        width: double.infinity,
        child: ListView(
          children: [
            const CardWidget(
              child: Column(
                children: [
                  Text('Total score: 21'),
                  Text('Quizzes Won: 23'),
                  Text('Wrong answer: 54'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.tonal(
                    onPressed: () {},
                    child: Text('Reset stats'),
                  ),
                ],
              ),
            ),
            CardWidget(
              child: Column(
                children: [
                  for (final entry in statsOnDifficulty.entries)
                    Row(
                      children: [
                        Expanded(child: Text(entry.key.name)),
                        // const Spacer(),
                        SizedBox(
                          width: 48,
                          child: Text(
                            '⬇${entry.value.$2}',
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.red.shade900,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 48,
                          child: Text(
                            '⬆${entry.value.$1}',
                            textAlign: TextAlign.right,
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.green.shade900,
                            ),
                          ),
                        ),
                      ],
                    )
                ],
              ),
            ),
            CardWidget(
              child: Column(
                children: [
                  for (final entry in statsOnCategory.entries)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(entry.key)),
                        // const Spacer(),
                        SizedBox(
                          width: 48,
                          child: Text(
                            '⬇${entry.value.$2}',
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.red.shade900,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 48,
                          child: Text(
                            '⬆${entry.value.$1}',
                            textAlign: TextAlign.right,
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.green.shade900,
                            ),
                          ),
                        ),
                      ],
                    )
                ],
              ),
            ),
            const PlayedQuizzes(),
          ],
        ),
      ),
    );
  }
}

class CardWidget extends StatelessWidget {
  const CardWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: child,
      ),
    );
  }
}

class PlayedQuizzes extends ConsumerWidget {
  const PlayedQuizzes({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsBloc = ref.watch(TriviaStatsBloc.instance);
    final quizzesPlayed = ref.watch(statsBloc.quizzesPlayed);

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: quizzesPlayed
            .map(
              (quiz) => SizedBox(
                width: double.infinity,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(quiz.question),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              quiz.answers.map((e) => Text('→ $e')).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
