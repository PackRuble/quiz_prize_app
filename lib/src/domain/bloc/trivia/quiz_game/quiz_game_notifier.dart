import 'dart:async' show Completer, unawaited;
import 'dart:core';
import 'dart:developer' show log;

import 'package:hooks_riverpod/hooks_riverpod.dart'
    show AutoDisposeNotifier, AutoDisposeNotifierProvider;
import 'package:http/http.dart' as http;
import 'package:trivia_app/extension/bidirectional_iterator.dart';
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

    // this allows you to run method immediately after this build has finished running
    Future.microtask(nextQuiz);

    return const QuizGameResult.loading();
  }

  /// This is a list of numbers, each of which represents the number of quizzes
  /// we would like to receive from the server.
  static const _iterableCountForFetching = [50, 25, 12, 5, 2, 1];

  Future<void> nextQuiz() async {
    log('$this-> get next quiz');

    state = const QuizGameResult.loading();

    final countQuizzesIterator = ListBiIterator(_iterableCountForFetching)
      ..moveNext();
    int desiredCount = countQuizzesIterator.current;
    // silently increase number of quizzes if their cached number is below allowed level
    Completer<TriviaRepoResult>? completer = _fetchQuizSilent(desiredCount);

    // looking for a quiz that matches the filters
    final cachedQuiz = _getCachedQuiz();
    if (cachedQuiz != null) {
      state = QuizGameData(cachedQuiz);
    } else {
      log('$this-> Локальные данные не найдены, делаем первый запрос на получение из сети. desiredCount=$desiredCount');
      completer ??= Completer()..complete(_fetchQuiz(desiredCount));
    }

    // if a request to fetch quizzes was made, we need to get data from completer,
    // and ignore the other cases.
    if (completer != null) {
      final triviaResult = await completer.future;
      if (triviaResult case TriviaRepoData<List<QuizDTO>>(:final data)) {
        await _quizzesNotifier.cacheQuizzes(Quiz.quizzesFromDTO(data));
      }
    }

    if (cachedQuiz != null) {
      log('$this-> Повторный запрос не требуется, поскольку найдена локальная викторина!');
      return;
    }

    // this means that locally suitable data is no longer available
    _cachedQuizzesIterator = null;

    // todo(11.02.2024): add emergency interrupt based on a counter based on the length of the repeats
    while (countQuizzesIterator.moveNext()) {
      desiredCount = countQuizzesIterator.current;

      state = QuizGameResult.loading('Repeated request with $desiredCount');
      
      log('$this-> Делаем повторный запрос. desiredCount=$desiredCount');
      final triviaResult = await _fetchQuiz(desiredCount);

      if (triviaResult case TriviaRepoData<List<QuizDTO>>(:final data)) {
        await _quizzesNotifier.cacheQuizzes(Quiz.quizzesFromDTO(data));
        // after this, the `QuizzesNotifier` state already contains current data

        final cachedQuiz = _getCachedQuiz();
        log('$this-> Данные получены, повторный запрос на поиск=$cachedQuiz');
        if (cachedQuiz != null) {
          state = QuizGameData(cachedQuiz);
          return;
        }
        await Future.delayed(const Duration(seconds: 6)); // todo: мы должны ждать каждый раз 6 секунд
        // todo: и далее, нам нужен список из запросов, которые мы выполним после
        // фишка в том, что этот список мы можем легко отменить, если вдруг юзер выйдет
        // а решение о том, что запрос 6 секунд, должен приниматься в другом месте
      } else if (triviaResult case TriviaRepoExceptionApi(:final exception)) {
        if (exception case TriviaException.noResults) {
          log('$this-> try again because $exception');

          // it is worth trying to query with less [countFetchQuizzes]
          await Future.delayed(const Duration(seconds: 6)); // todo: мы должны ждать каждый раз 6 секунд
        } else if (exception case TriviaException.rateLimit) {
          log('$this-> try again because $exception');

          // Update: At some point in the Trivia backend there is a limit on the number
          // of requests per second from one IP. To get around this, we will wait an
          // additional 5 seconds when this error occurs.
          //
          // therefore we wait 6 seconds as the backend dictates. Then we do a second request.
          log('$this-> wait 6 seconds...');
          await Future.delayed(const Duration(seconds: 6));
          // and try a second request with the same desired number of quizzes
          countQuizzesIterator.movePrevious();
        } else {
          state = QuizGameResult.error(exception.message);
          return;
        }
      } else if (triviaResult case TriviaRepoError(:final error)) {
        state = QuizGameResult.error(error.toString());
        return;
      }
    }
    
    state = const QuizGameResult.emptyData();
  }

  Future<TriviaRepoResult> _fetchQuiz(int countFetchQuizzes) async {
    final quizConfig = _quizConfigNotifier.state;
    log('$this.fetch quizzes-> with $quizConfig, countFetchQuizzes=$countFetchQuizzes');

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

  Completer<TriviaRepoResult>? _fetchQuizSilent(int countFetchQuizzes) {
    Completer<TriviaRepoResult>? completer;
    if (!_isEnoughCachedQuizzes) {
      log('$this-> not enough cached quizzes');

      // ignore: discarded_futures
      completer = Completer()..complete(_fetchQuiz(countFetchQuizzes));
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
