import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/domain/bloc/trivia/model/quiz.model.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quiz/trivia_quiz_bloc.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quiz/trivia_quiz_result.dart';
import 'package:trivia_app/src/domain/bloc/trivia/stats/trivia_stats_bloc.dart';

sealed class GamePageState {
  const GamePageState();
}

class GamePageData extends GamePageState {
  const GamePageData(this.data);
  final Quiz data;
}

class GamePageLoading extends GamePageState {
  const GamePageLoading();
}

class GamePageEmptyData extends GamePageState {
  const GamePageEmptyData(this.message);
  final String message;
}

class GamePageError extends GamePageState {
  const GamePageError(this.message);
  final String message;
}

class GamePageCtrl {
  GamePageCtrl({
    required Ref ref,
    required TriviaQuizProvider triviaQuizProvider,
    required TriviaStatsProvider triviaStatsProvider,
  })  : _triviaQuizBloc = triviaQuizProvider,
        _triviaStatsProvider = triviaStatsProvider,
        _ref = ref;

  final Ref _ref;
  final TriviaQuizProvider _triviaQuizBloc;
  final TriviaStatsProvider _triviaStatsProvider;

  static final instance = AutoDisposeProvider<GamePageCtrl>(
    (ref) => GamePageCtrl(
      ref: ref,
      triviaQuizProvider: ref.watch(TriviaQuizProvider.instance),
      triviaStatsProvider: ref.watch(TriviaStatsProvider.instance),
    ),
  );

  AutoDisposeProvider<int> get solvedCountProvider =>
      _triviaStatsProvider.winning;
  AutoDisposeProvider<int> get unSolvedCountProvider =>
      _triviaStatsProvider.losing;

  late final currentQuiz = AutoDisposeStateProvider<GamePageState>((ref) {
    ref.listenSelf((_, next) async {
      if (next is GamePageLoading) {
        final quizResult = await _triviaQuizBloc.getQuiz();

        ref.controller.state = switch (quizResult) {
          TriviaQuizData(data: final quiz) => GamePageData(quiz),
          TriviaQuizEmptyData(message: final message) =>
            GamePageEmptyData(message),
          TriviaQuizError(message: final message) => GamePageError(message),
        };
      }
    });
    return const GamePageLoading();
  });

  late final amountQuizzes = AutoDisposeProvider<int>(
      (ref) => ref.watch(_triviaQuizBloc.quizzes).length);

  Future<void> checkAnswer(String answer) async {
    final quiz = await _triviaQuizBloc.checkMyAnswer(answer);

    _ref.read(currentQuiz.notifier).update((_) => GamePageData(quiz));
  }

  Future<void> onNextQuiz() async {
    // we need to return the value immediately without waiting.
    // ignore: unused_result
    _ref.refresh(currentQuiz);
  }
}
