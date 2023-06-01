import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/trivia/models.dart';
import 'package:trivia_app/src/ui/game/game_page_ctrl.dart';

import '../shared/material_state_custom.dart';

class GamePage extends ConsumerWidget {
  const GamePage({
    super.key,
  });

  static const path = 'game';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: _AppCardBar(),
      ),
      body: Card(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: _QuizWidget(),
        ),
      ),
    );
  }
}

class _QuizWidget extends ConsumerWidget {
  const _QuizWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final pageController = ref.watch(GamePageCtrl.instance);
    final currentQuiz = ref.watch(pageController.currentQuiz);

    return currentQuiz.when(
      data: (quiz) => ListView(
        children: [
          if (true ?? kDebugMode)
            Consumer(
              builder: (context, ref, child) {
                return Text(
                  'Available questions: ${ref.watch(pageController.amountQuizzes)}',
                );
              },
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  quiz.category,
                  style: textTheme.titleSmall,
                ),
              ),
              _DifficultyStarWidget(difficulty: quiz.difficulty),
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
              isCorrectChoice: quiz.yourAnswer == quiz.correctAnswer,
              isCorrect: switch (quiz.correctlySolved) {
                true when answer == quiz.yourAnswer => true,
                false when answer == quiz.yourAnswer => false,
                false when answer == quiz.correctAnswer => true,
                _ => null,
              },
              blocked: quiz.correctlySolved != null,
              answer: answer,
              onTap: () async => pageController.checkAnswer(answer),
            ),
          const SizedBox(height: 30),
          if (quiz.correctlySolved != null)
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward),
              onPressed: pageController.onNextQuiz,
              label: const Text('Next question'),
            ),
          if (kDebugMode) Text('Correct answer: ${quiz.correctAnswer}'),
        ],
      ),
      error: (error, stackTrace) {
        FlutterError.reportError(
            FlutterErrorDetails(exception: error, stack: stackTrace));
        return Center(child: Text('$error'));
      },
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _AnswerSelectButton extends HookConsumerWidget {
  const _AnswerSelectButton({
    super.key,
    required this.onTap,
    required this.answer,
    required this.isCorrect,
    required this.isCorrectChoice,
    required this.blocked,
  });

  final VoidCallback onTap;
  final String answer;
  final bool? isCorrect;
  final bool isCorrectChoice;
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

    final confettiCtrl = useState(
      ConfettiController(duration: const Duration(seconds: 1)),
    ).value;

    useEffect(
      () {
        if ((isCorrect ?? false) && isCorrectChoice == true) {
          confettiCtrl.play();
        }
        return null;
      },
      [isCorrect],
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        children: [
          Align(
            child: ConfettiWidget(
              blastDirectionality: BlastDirectionality.explosive,
              createParticlePath: drawStar,
              pauseEmissionOnLowFrameRate: false,
              confettiController: confettiCtrl,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateColorOrNull.resolveWith(resolveBg),
                foregroundColor:
                    MaterialStateColorOrNull.resolveWith(resolveFg),
              ),
              onPressed: blocked ? null : onTap,
              child: Text(
                answer,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A custom Path to paint stars.
  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }
}

class _DifficultyStarWidget extends StatelessWidget {
  const _DifficultyStarWidget({super.key, required this.difficulty});

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

class _AppCardBar extends ConsumerWidget {
  const _AppCardBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final pageController = ref.watch(GamePageCtrl.instance);

    final solvedCount = ref.watch(pageController.triviaStatsBloc.winning);
    final unsolvedCount = ref.watch(pageController.triviaStatsBloc.losing);
    final score = solvedCount - unsolvedCount;

    return Card(
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
        ],
      ),
    );
  }
}