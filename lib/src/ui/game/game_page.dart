import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Card(
          child: AppBar(
            forceMaterialTransparency: true,
            title: const Text('Game'),
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
                  Text('Available questions: ${data.amountQuizzes}'),
                  Text(quiz.category),
                  Text(quiz.difficulty.name),
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
                  const SizedBox(height: 50),
                  if (quiz.isCorrectYourAnswer != null)
                    ElevatedButton(
                      onPressed: notifier.onNextQuiz,
                      child: const Text('Next quiz'),
                    ),
                  Text('Correct answer: ${quiz.correctAnswer}'),
                ],
              ),
            ),
          );
        },
        error: (error, stackTrace) {
          FlutterError.reportError(
              FlutterErrorDetails(exception: error, stack: stackTrace));
          return Text('$error $stackTrace');
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
        child: Text(answer),
      ),
    );
  }
}
