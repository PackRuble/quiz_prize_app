import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/domain/bloc/trivia_quiz/model/quiz.model.dart';
import 'package:trivia_app/src/domain/bloc/trivia_quiz/trivia_quiz_bloc.dart';
import 'package:trivia_app/src/domain/bloc/trivia_quiz/trivia_quiz_result.dart';

sealed class GamePageState {
  const GamePageState();
}

class GamePageStateData extends GamePageState {
  const GamePageStateData(this.data);
  final Quiz data;
}

class GamePageStateLoading extends GamePageState {
  const GamePageStateLoading();
}

class GamePageStateEmptyData extends GamePageState {
  const GamePageStateEmptyData(this.message);
  final String message;
}

class GamePageStateError extends GamePageState {
  const GamePageStateError(this.message);
  final String message;
}

class GamePageCtrl {
  GamePageCtrl({
    required Ref ref,
    required TriviaQuizProvider triviaQuizBloc,
    required this.triviaStatsBloc,
  })  : _triviaQuizBloc = triviaQuizBloc,
        _ref = ref;

  final Ref _ref;
  final TriviaQuizProvider _triviaQuizBloc;
  final TriviaStatsBloc triviaStatsBloc;

  static final instance = AutoDisposeProvider<GamePageCtrl>(
    (ref) => GamePageCtrl(
      ref: ref,
      triviaQuizBloc: ref.watch(TriviaQuizProvider.instance),
      triviaStatsBloc: ref.watch(TriviaStatsBloc.instance),
    ),
  );

  late final currentQuiz = AutoDisposeStateProvider<GamePageState>((ref) {
    ref.listenSelf((_, next) async {
      if (next is GamePageStateLoading) {
        final quizResult = await _triviaQuizBloc.getQuiz();

        ref.controller.state = switch (quizResult) {
          TriviaQuizResultData(data: final quiz) => GamePageStateData(quiz),
          TriviaQuizResultEmptyData(message: final message) =>
            GamePageStateEmptyData(message),
          TriviaQuizResultError(message: final message) =>
            GamePageStateError(message),
        };
      }
    });
    return const GamePageStateLoading();
  });

  late final amountQuizzes = AutoDisposeProvider<int>(
      (ref) => ref.watch(_triviaQuizBloc.quizzes).length);

  Future<void> checkAnswer(String answer) async {
    final quiz = await _triviaQuizBloc.checkMyAnswer(answer);

    _ref.read(currentQuiz.notifier).update((_) => GamePageStateData(quiz));
  }

  Future<void> onNextQuiz() async {
    // we need to return the value immediately without waiting.
    // ignore: unused_result
    _ref.refresh(currentQuiz);
  }
}
