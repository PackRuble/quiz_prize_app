import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/trivia/models.dart';
import 'package:trivia_app/src/ui/game/game_bloc.dart';

import '../shared/material_state_custom.dart';

class GamePage extends ConsumerWidget {
  const GamePage({
    super.key,
  });

  static const path = 'game';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    final state = ref.watch(GamePageBloc.instance);
    final notifier = ref.watch(GamePageBloc.instance.notifier);

    // todo
    final solvedCount = 25;
    final unsolvedCount = 6;

    final score = solvedCount - unsolvedCount;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Card(
          child: Row(
            children: [
              const BackButton(),
              Text(
                'Score: $score',
                style: textTheme.labelLarge,
              ),
              const Spacer(),
              Text(
                '⬆$solvedCount',
                style: textTheme.labelLarge,
              ),
              const SizedBox(width: 8),
              Text(
                '⬇$unsolvedCount',
                style: textTheme.labelLarge,
              ),
              const SizedBox(width: 8),

              // AppBar(
              //   forceMaterialTransparency: true,
              //   title: const Text('Game'),
              // ),
            ],
          ),
        ),
      ),
      body: state.when(
        data: (data) {
          final quiz = data.quiz;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: [
                  if (false ?? kDebugMode)
                    Text('Available questions: ${data.amountQuizzes}'),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Text(
                          quiz.category,
                          style: textTheme.titleSmall,
                        ),
                      ),
                      DifficultyStarWidget(difficulty: quiz.difficulty),
                    ],
                  ),
                  const Divider(),
                  Text(
                    quiz.question,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  for (final answer in quiz.answers)
                    _AnswerSelectButton(
                      isCorrect: switch (quiz.isCorrectYourAnswer) {
                        true when answer == quiz.yourAnswer => true,
                        false when answer == quiz.correctAnswer => true,
                        false when answer == quiz.yourAnswer => false,
                        _ => null,
                      },
                      blocked: quiz.isCorrectYourAnswer != null,
                      answer: answer,
                      onTap: () async => notifier.checkAnswer(answer),
                    ),
                  const SizedBox(height: 30),
                  if (quiz.isCorrectYourAnswer != null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: notifier.onNextQuiz,
                      label: const Text('Next question'),
                    ),
                  if (kDebugMode) Text('Correct answer: ${quiz.correctAnswer}'),
                ],
              ),
            ),
          );
        },
        error: (error, stackTrace) {
          FlutterError.reportError(
              FlutterErrorDetails(exception: error, stack: stackTrace));
          return Center(child: Text('$error'));
        },
        loading: () => const CircularProgressIndicator(),
      ),
    );
  }
}

class _AnswerSelectButton extends ConsumerWidget {
  const _AnswerSelectButton({
    super.key,
    required this.onTap,
    required this.answer,
    required this.isCorrect,
    required this.blocked,
  });

  final VoidCallback onTap;
  final String answer;
  final bool? isCorrect;
  final bool blocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color? resolveBg(Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        if (isCorrect == null) return Colors.red.withOpacity(0.6);

        return isCorrect!
            ? Colors.green.withOpacity(0.8)
            : Colors.deepPurpleAccent.withOpacity(0.7);
      }
      return null;
    }

    Color? resolveFg(Set<MaterialState> states) {
      return states.contains(MaterialState.disabled)
          ? Theme.of(context).colorScheme.onSecondaryContainer
          : null;
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FilledButton.tonal(
        style: ButtonStyle(
          backgroundColor: MaterialStateColorOrNull.resolveWith(resolveBg),
          foregroundColor: MaterialStateColorOrNull.resolveWith(resolveFg),
        ),
        onPressed: blocked ? null : onTap,
        child: Text(
          answer,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class DifficultyStarWidget extends StatelessWidget {
  const DifficultyStarWidget({super.key, required this.difficulty});

  final TriviaQuizDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        difficulty.index,
        (index) => const Icon(
          Icons.star_rounded,
          color: Colors.deepOrange,
        ),
      ),
    );
  }
}
