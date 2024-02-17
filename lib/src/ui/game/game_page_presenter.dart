import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/domain/bloc/trivia/cached_quizzes/cached_quizzes_notifier.dart';
import 'package:trivia_app/src/domain/bloc/trivia/model/quiz.model.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quiz_game/quiz_game_notifier.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quiz_game/quiz_game_result.dart';
import 'package:trivia_app/src/domain/bloc/trivia/stats/trivia_stats_bloc.dart';

sealed class GamePageState {
  const GamePageState();
}

class GamePageData extends GamePageState {
  const GamePageData(this.data);
  final Quiz data;
}

class GamePageLoading extends GamePageState {
  const GamePageLoading([this.message]);

  final String? message;
}

class GamePageEmptyData extends GamePageState {
  const GamePageEmptyData(this.message);
  final String message;
}

class GamePageError extends GamePageState {
  const GamePageError(this.message);
  final String message;
}

class GamePagePresenter extends AutoDisposeNotifier<GamePageState> {
  static final instance =
      AutoDisposeNotifierProvider<GamePagePresenter, GamePageState>(
    GamePagePresenter.new,
  );

  late QuizGameNotifier _quizGameNotifier;

  @override
  GamePageState build() {
    _quizGameNotifier = ref.watch(QuizGameNotifier.instance.notifier);

    final quizGameResult = ref.watch(QuizGameNotifier.instance);
    return switch (quizGameResult) {
      QuizGameData(:final quiz) => GamePageData(quiz),
      QuizGameLoading(:final withMessage) => GamePageLoading(withMessage),
      QuizGameEmptyData(:final message) => GamePageEmptyData(message),
      QuizGameError(:final message) => GamePageError(message),
    };
  }

  Future<void> checkAnswer(String answer) async {
    await _quizGameNotifier.checkMyAnswer(answer);
  }

  Future<void> onNextQuiz() async {
    await _quizGameNotifier.nextQuiz();
  }

  Future<void> onResetToken() async {
    state = const GamePageLoading('Renewing the token...');
    await _quizGameNotifier.resetSessionToken();
    await onNextQuiz();
  }

  Future<void> onResetQuizConfig() async {
    // todo(17.02.2024):
  }

  static final debugAmountQuizzes = AutoDisposeProvider<int>(
    (ref) => ref.watch(QuizzesNotifier.instance).length,
  );

  static final solvedCountProvider = AutoDisposeProvider<int>(
    (ref) => ref.watch(ref.watch(TriviaStatsProvider.instance).winning),
  );

  static final unSolvedCountProvider = AutoDisposeProvider<int>(
    (ref) => ref.watch(ref.watch(TriviaStatsProvider.instance).losing),
  );
}
