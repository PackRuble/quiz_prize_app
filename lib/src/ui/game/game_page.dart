import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/trivia/model_dto/trivia_config_models.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quizzes/model/quiz.model.dart';
import 'package:trivia_app/src/ui/const/app_colors.dart';
import 'package:trivia_app/src/ui/game/game_page_presenter.dart';

import '../shared/app_bar_custom.dart';
import '../shared/app_dialog.dart';
import '../shared/cardpad.dart';
import '../shared/material_state_custom.dart';
import 'game_page_state.dart';

class GamePage extends ConsumerWidget {
  const GamePage({super.key});

  static const path = '/game';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      appBar: _AppCardBar(),
      body: CardPad(child: _GamePageData()),
    );
  }
}

class _GamePageData extends ConsumerWidget {
  const _GamePageData({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagePresenter = ref.watch(GamePagePresenter.instance.notifier);
    final gamePageState = ref.watch(GamePagePresenter.instance);

    return switch (gamePageState) {
      GamePageData(:final data) => GameDataView(quiz: data),
      GamePageLoading(:final message) => _WrapperGameMessageView(
          messageWidget: Column(
            children: [
              const CircularProgressIndicator(),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(message),
                ),
            ],
          ),
          actions: const [],
        ),
      GamePageError(:final message) => _WrapperGameMessageView(
          messageWidget: Center(
            child: SelectableText(message, textAlign: TextAlign.center),
          ),
          actions: [
            OutlinedButton(
              onPressed: pagePresenter.onTryAgainError,
              child: const Text(
                'Try again',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      GamePageCongratulation(:final message) ||
      GamePageNewToken(:final message) ||
      GamePageNewTokenOrChangeCategory(:final message) =>
        GameMessageView(message: message, gamePageState: gamePageState),
    };
  }
}

class GameDataView extends ConsumerWidget {
  const GameDataView({super.key, required this.quiz});

  final Quiz quiz;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagePresenter = ref.watch(GamePagePresenter.instance.notifier);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return ListView(
      children: [
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
        SelectableText(
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
            onTap: () async => pagePresenter.checkAnswer(answer),
          ),
        const SizedBox(height: 30),
        if (quiz.correctlySolved != null)
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_forward),
            onPressed: pagePresenter.onNextQuiz,
            label: const Text('Next question'),
          ),
        if (kDebugMode)
          CardPad(
            margin: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    return Text(
                      'Available questions: ${ref.watch(GamePagePresenter.debugAmountQuizzes)}',
                    );
                  },
                ),
                Text('Correct answer: ${quiz.correctAnswer}'),
              ],
            ),
          ),
      ],
    );
  }
}

class GameMessageView extends HookConsumerWidget {
  const GameMessageView({
    super.key,
    required this.message,
    required this.gamePageState,
  });

  final String message;
  final GamePageState gamePageState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagePresenter = ref.watch(GamePagePresenter.instance.notifier);

    final confettiControllerRef = useRef<ConfettiController?>(null);
    useEffect(() {
      if (gamePageState is GamePageCongratulation) {
        confettiControllerRef.value = ConfettiController()..play();
      }

      return confettiControllerRef.value?.dispose;
    }, const []); // ignore: require_trailing_commas

    final child = _WrapperGameMessageView(
      message: message,
      actions: [
        OutlinedButton(
          onPressed: () async {
            final resetStats = await showDeleteStatsDialog(context);
            if (resetStats == null) return;

            await pagePresenter.onResetToken(
              withResetStats: resetStats,
            );
          },
          child: const Text(
            'Reset token',
            textAlign: TextAlign.center,
          ),
        ),
        if (gamePageState is GamePageNewTokenOrChangeCategory)
          OutlinedButton(
            onPressed: () async {
              await pagePresenter.onResetFilters();
            },
            child: const Text(
              'Any category',
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );

    final confettiController = confettiControllerRef.value;
    return confettiController != null
        ? Stack(
            children: [
              Center(
                child: ConfettiWidget(
                  key: ValueKey(confettiControllerRef.hashCode),
                  shouldLoop: true,
                  emissionFrequency: 0.04,
                  blastDirectionality: BlastDirectionality.explosive,
                  maxBlastForce: 80,
                  pauseEmissionOnLowFrameRate: false,
                  confettiController: confettiController,
                ),
              ),
              child,
            ],
          )
        : child;
  }

  /// Returned true, if permission to delete statistics is granted.
  Future<bool?> showDeleteStatsDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: 'Confirmation',
        message: 'Delete statistics too?',
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(MaterialLocalizations.of(context).deleteButtonTooltip),
          ),
        ],
      ),
    );
  }
}

class _WrapperGameMessageView extends StatelessWidget {
  const _WrapperGameMessageView({
    super.key,
    this.message,
    this.messageWidget,
    required this.actions,
  }) : assert(message == null || messageWidget == null);

  final String? message;
  final Widget? messageWidget;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const Spacer(),
        messageWidget ??
            Flexible(
              child: Text(
                message!,
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final action in actions)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: action,
                ),
              ),
          ],
        ),
        const Spacer(),
      ],
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
              // the key is needed because window size can change which will cause an error
              key: ValueKey(answer),
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
              onPressed: onPressed,
              child: SelectableText(
                answer,
                textAlign: TextAlign.center,
                onTap: onPressed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? get onPressed => blocked ? null : onTap;

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
      path.lineTo(
        halfWidth + externalRadius * cos(step),
        halfWidth + externalRadius * sin(step),
      );
      path.lineTo(
        halfWidth + internalRadius * cos(step + halfDegreesPerStep),
        halfWidth + internalRadius * sin(step + halfDegreesPerStep),
      );
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

class _AppCardBar extends AppBarCustom {
  const _AppCardBar();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final textTheme = Theme.of(context).textTheme;
        final solvedCount = ref.watch(GamePagePresenter.solvedCountProvider);
        final unsolvedCount =
            ref.watch(GamePagePresenter.unSolvedCountProvider);
        final score = solvedCount - unsolvedCount;

        return AppBarCustom(
          actions: [
            Text(
              'Score: $score',
              style: textTheme.labelLarge,
            ),
            const Spacer(),
            Text(
              '⬆$solvedCount',
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.correctCounterText,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '⬇$unsolvedCount',
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.unCorrectCounterText,
              ),
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }
}
