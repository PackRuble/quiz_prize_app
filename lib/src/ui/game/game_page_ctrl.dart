import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/domain/bloc/trivia/cached_quizzes/cached_quizzes_notifier.dart';
import 'package:trivia_app/src/domain/bloc/trivia/cached_quizzes/cached_quizzes_result.dart';
import 'package:trivia_app/src/domain/bloc/trivia/model/quiz.model.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quiz_game/quiz_game_notifier.dart';
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
    required CachedQuizzesNotifier cachedQuizzesNotifier,
    required TriviaStatsProvider triviaStatsProvider,
    required QuizGameNotifier quizGameNotifier,
  })  : _quizGameNotifier = quizGameNotifier,
        _cachedQuizzesNotifier = cachedQuizzesNotifier,
        _triviaStatsProvider = triviaStatsProvider,
        _ref = ref;

  final Ref _ref;
  final CachedQuizzesNotifier _cachedQuizzesNotifier;
  final QuizGameNotifier _quizGameNotifier;
  final TriviaStatsProvider _triviaStatsProvider;

  static final instance = AutoDisposeProvider<GamePageCtrl>(
    (ref) {
      final cachedQuizzesNotifier =
          ref.watch(CachedQuizzesNotifier.instance.notifier);
      // this allows the iterator to be properly cleaned up
      // so we're just listen, no rebuilding
      // ref.listen(triviaQuizProvider.quizzes, (_, __) {});

      return GamePageCtrl(
        ref: ref,
        cachedQuizzesNotifier: cachedQuizzesNotifier,
        triviaStatsProvider: ref.watch(TriviaStatsProvider.instance),
        quizGameNotifier: ref.watch(QuizGameNotifier.instance.notifier),
      );
    },
  );

  AutoDisposeProvider<int> get solvedCountProvider =>
      _triviaStatsProvider.winning;
  AutoDisposeProvider<int> get unSolvedCountProvider =>
      _triviaStatsProvider.losing;

  late final currentQuiz = AutoDisposeStateProvider<GamePageState>((ref) {
    ref.listenSelf((_, next) async {
      if (next is GamePageLoading) {
        final quizResult = await _quizGameNotifier.getQuiz();

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
      (ref) => _cachedQuizzesNotifier.state.length);

  Future<void> checkAnswer(String answer) async {
    final quiz = await _quizGameNotifier.checkMyAnswer(answer);

    _ref.read(currentQuiz.notifier).update((_) => GamePageData(quiz));
  }

  Future<void> onNextQuiz() async {
    // we need to return the value immediately without waiting.
    // ignore: unused_result
    _ref.refresh(currentQuiz);
  }
}
