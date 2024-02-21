import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quizzes/quizzes_notifier.dart';
import 'package:trivia_app/src/domain/bloc/trivia/stats_notifier.dart';
import 'package:trivia_app/src/domain/quiz_game/quiz_game_notifier.dart';
import 'package:trivia_app/src/domain/quiz_game/quiz_game_result.dart';

import 'game_page_state.dart';

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
      QuizGameCompleted(:final message) => GamePageCongratulation(message),
      QuizGameTokenExpired(:final message) => GamePageNewToken(message),
      QuizGameTryChangeCategory(:final message) =>
        GamePageNewTokenOrChangeCategory(message),
      QuizGameError(:final message) => GamePageError(message),
    };
  }

  Future<void> checkAnswer(String answer) async {
    await _quizGameNotifier.checkMyAnswer(answer);
  }

  Future<void> onNextQuiz() async {
    await _quizGameNotifier.nextQuiz();
  }

  Future<void> onTryAgainError() async {
    _quizGameNotifier.updateStateWhenError();
  }

  Future<void> onResetToken({required bool withResetStats}) async {
    state = const GamePageLoading('Renewing the token...');
    await _quizGameNotifier.resetGame(withResetStats);
  }

  Future<void> onResetFilters() async {
    await _quizGameNotifier.resetQuizConfig();
  }

  static final debugAmountQuizzes = AutoDisposeProvider<int>(
    (ref) => ref.watch(QuizzesNotifier.instance).length,
  );

  static final solvedCountProvider = AutoDisposeProvider<int>(
    (ref) => ref.watch(
      QuizStatsNotifier.instance.select((stats) => stats.winning),
    ),
  );

  static final unSolvedCountProvider = AutoDisposeProvider<int>(
    (ref) => ref.watch(
      QuizStatsNotifier.instance.select((stats) => stats.losing),
    ),
  );
}
