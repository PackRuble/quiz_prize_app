import 'dart:async' show Completer, unawaited;
import 'dart:developer' show log;

import 'package:hooks_riverpod/hooks_riverpod.dart'
    show AutoDisposeNotifier, AutoDisposeNotifierProvider;
import 'package:http/http.dart' as http;
import 'package:trivia_app/internal/debug_flags.dart';
import 'package:trivia_app/src/data/trivia/model_dto/quiz/quiz.dto.dart';
import 'package:trivia_app/src/data/trivia/trivia_repository.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quiz_game/quiz_game_result.dart';

import '../cached_quizzes/cached_quizzes_notifier.dart';
import '../model/quiz.model.dart';
import '../quiz_config/quiz_config_notifier.dart';
import '../stats/trivia_stats_bloc.dart';

/// Notifier is a certain state machine for the game process and methods
/// for managing this state.
// todo(08.02.2024): This class should contains current quiz-state (or maybe Iterator<Quiz>).
//  This will require significant changes.
class QuizGameNotifier extends AutoDisposeNotifier<QuizGameResult> {
  static final instance =
      AutoDisposeNotifierProvider<QuizGameNotifier, QuizGameResult>(
    QuizGameNotifier.new,
  );

  late QuizStatsNotifier _quizStatsNotifier;
  late QuizzesNotifier _quizzesNotifier;
  late TriviaRepository _triviaRepository;
  late QuizConfigNotifier _quizConfigNotifier;

  // internal state
  Iterator<Quiz>? _cachedQuizzesIterator;

  // todo: feature: make a request before the quizzes are over
  // Quiz? nextQuiz; // or nextState

  @override
  QuizGameResult build() {
    _quizStatsNotifier = ref.watch(TriviaStatsProvider.instance);
    _quizzesNotifier = ref.watch(QuizzesNotifier.instance.notifier);
    _triviaRepository = TriviaRepository(
      client: http.Client(),
      useMockData: DebugFlags.triviaRepoUseMock,
    );
    _quizConfigNotifier = ref.watch(QuizConfigNotifier.instance.notifier);

    unawaited(nextQuiz());

    return const QuizGameResult.loading();
  }

  // desired number of quizzes to fetch
  static const _kCountFetchQuizzes = 47;

   int _getNextCount([int current = _kCountFetchQuizzes]) {
    assert(0 > current || current <= _kCountFetchQuizzes);

    // 47 ~/= 2; -> 23 -> 11 -> 5 -> 2 -> 1
    // this still doesn't get rid of the edge cases where the number of available
    // quizzes on the server will be 4, 6, 7, etc. but it's better than nothing at all ^)
    return current ~/ 2;
  }

  Future<void> nextQuiz() async {
    log('$this-> get next quiz');

    state = const QuizGameResult.loading();

    // silently increase number of quizzes if their cached number is below allowed level
    Completer<TriviaRepoResult>? completer = _fetchQuizSilent();

    // looking for a quiz that matches the filters
    final cachedQuiz = _getCachedQuiz();
    if (cachedQuiz != null) {
      state = QuizGameData(cachedQuiz);
    } else {
      completer ??= Completer()..complete(_fetchQuiz(_kCountFetchQuizzes));
    }

    bool repeatRequestForFetching = false;

    // if a request to fetch quizzes was made, we need to get data from completer,
    // and ignore the other cases.
    if (completer != null) {
      final triviaResult = await completer.future;
      if (triviaResult case TriviaRepoData<List<QuizDTO>>(:final data)) {
        await _quizzesNotifier.cacheQuizzes(Quiz.quizzesFromDTO(data));
      }

      if (cachedQuiz == null) {
        // this means that locally suitable data is no longer available
        _cachedQuizzesIterator = null;
        repeatRequestForFetching = true;
      }
    }

    int countFetchQuizzes = _getNextCount() ;
    while (repeatRequestForFetching) {
      log('$this-> Делаем повторный запрос $countFetchQuizzes');
      final triviaResult = await _fetchQuiz(countFetchQuizzes);

      if (triviaResult case TriviaRepoData<List<QuizDTO>>(:final data)) {
        await _quizzesNotifier.cacheQuizzes(Quiz.quizzesFromDTO(data));
        // after this, the `QuizzesNotifier` state already contains current data

        log('$this-> Данные получены');
        final cachedQuiz = _getCachedQuiz();
        if (cachedQuiz != null) {
          state = QuizGameData(cachedQuiz);
          repeatRequestForFetching = false;
        }
      } else if (triviaResult case TriviaRepoExceptionApi(:final exception)) {
        if (exception case TriviaException.noResults) {
          log('$this-> try again because $exception');
          // it is worth trying to query with less [countFetchQuizzes]
          state = const QuizGameResult.loading('Repeated request');
        } else if (exception case TriviaException.rateLimit) {
          log('$this-> try again because $exception');

          state = const QuizGameResult.loading('Repeated request');

          // Update: At some point in the Trivia backend there is a limit on the number
          // of requests per second from one IP. To get around this, we will wait an
          // additional 5 seconds when this error occurs.
          //
          // therefore we wait 6 seconds as the backend dictates. Then we do a second request.
          await Future.delayed(const Duration(seconds: 6));
          // and make again request with the same `countFetchQuizzes`
        } else {
          state = QuizGameResult.error(exception.message);
          repeatRequestForFetching = false;
        }
      } else if (triviaResult case TriviaRepoError(:final error)) {
        state = QuizGameResult.error(error.toString());
        repeatRequestForFetching = false;
      }

      countFetchQuizzes = _getNextCount(countFetchQuizzes);

      if (countFetchQuizzes == 0) {
        state = const QuizGameResult.emptyData();
        repeatRequestForFetching = false;
      }
    }
  }

  Future<TriviaRepoResult> _fetchQuiz(int countFetchQuizzes) async {
    final quizConfig = _quizConfigNotifier.state;
    log('$this-> with $quizConfig');

    final result = await _triviaRepository.getQuizzes(
      category: quizConfig.quizCategory,
      difficulty: quizConfig.quizDifficulty,
      type: quizConfig.quizType,
      amount: countFetchQuizzes,
    );

    return result;
  }

  /// Limited so as to make the least number of requests to the server,
  /// if the number of available quizzes on the selected parameters is minimal.
  static const _minCountCachedQuizzes = 3;

  bool get _isEnoughCachedQuizzes =>
      _quizzesNotifier.state.length > _minCountCachedQuizzes;

  Quiz? _getCachedQuiz() {
    _cachedQuizzesIterator ??= List.of(_quizzesNotifier.state).iterator;
    while (_cachedQuizzesIterator!.moveNext()) {
      final quiz = _cachedQuizzesIterator!.current;

      if (_quizConfigNotifier.matchQuizByFilter(quiz)) {
        return quiz;
      }
    }
    return null;
  }

  Completer<TriviaRepoResult>? _fetchQuizSilent() {
    Completer<TriviaRepoResult>? completer;
    if (!_isEnoughCachedQuizzes) {
      log('$this-> not enough cached quizzes');

      // ignore: discarded_futures
      completer = Completer()..complete(_fetchQuiz(_kCountFetchQuizzes));
    }
    return completer;
  }

  Future<void> checkMyAnswer(String answer) async {
    var quiz = _cachedQuizzesIterator!.current;
    quiz = quiz.copyWith(yourAnswer: answer);

    unawaited(_quizStatsNotifier.savePoints(quiz.correctlySolved!));
    unawaited(_quizzesNotifier.moveQuizAsPlayed(quiz));
    state = QuizGameResult.data(quiz);
  }

  @override
  String toString() =>
      super.toString().replaceFirst('Instance of ', '').replaceAll("'", '');
}
