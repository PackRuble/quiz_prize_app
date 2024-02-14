import 'dart:collection';
import 'dart:core';
import 'dart:developer' show log;
import 'package:hooks_riverpod/hooks_riverpod.dart'
    show AutoDisposeNotifier, AutoDisposeNotifierProvider;
import 'package:http/http.dart' as http;
import 'package:trivia_app/extension/bidirectional_iterator.dart';
import 'package:trivia_app/extension/binary_reduction.dart';
import 'package:trivia_app/internal/debug_flags.dart';
import 'package:trivia_app/src/data/trivia/model_dto/quiz/quiz.dto.dart';
import 'package:trivia_app/src/data/trivia/trivia_repository.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quiz_game/quiz_game_result.dart';

import '../cached_quizzes/cached_quizzes_notifier.dart';
import '../model/quiz.model.dart';
import '../quiz_config/quiz_config_notifier.dart';
import '../stats/trivia_stats_bloc.dart';
typedef TriviaResultAsyncCallback = Future<TriviaResult> Function();

class _QuizRequest {
  const _QuizRequest({
    required this.execution,
    this.onlyCache = false,
    this.clearIfSuccess = false,
  });
  final TriviaResultAsyncCallback execution;
  final bool onlyCache;
  final bool clearIfSuccess;
}

/// Notifier is a certain state machine for the game process and methods
/// for managing this state.
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
  final _executionRequestQueue = Queue<_QuizRequest>();
  // LinkedList<Future>? _cachedQuizzesIterator;

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

    print('build QuizGameNotifier');

    ref.onDispose(() {
      _executionRequestQueue.clear();
    });

    // this allows you to run method immediately after this build has finished running
    Future.microtask(nextQuiz);

    return const QuizGameResult.loading();
  }

  /// This is a list of numbers, each of which represents the number of quizzes
  /// we would like to receive from the server.
  ///

  ///
  /// for 50: [25, 13, 7, 4, 2, 1]
  /// for 16: [ 8,  4, 2, 1]
  ListBiIterator<int> getReductionNumbers() =>
      ListBiIterator(getReductionsSequence(_maxCountQuizzesPerRequest));

  /// Maximum number of quizzes per request.
  ///
  /// If the category is popular, we will make 6 requests,
  /// otherwise we will make only 4.
  int get _maxCountQuizzesPerRequest =>
      _quizConfigNotifier.state.quizCategory.isAny ? 50 : 16;

  Future<void> nextQuiz() async {
    log('$this-> get next quiz');

    state = const QuizGameResult.loading();

    bool needSilentRequest = false;
    // todo: вероятно код ниже даже можно убрать
    // looking for a quiz that matches the filters
    final cachedQuiz = _getCachedQuiz();
    if (cachedQuiz != null) {
      log('$this-> Викторина найдена=$cachedQuiz');
      state = QuizGameData(cachedQuiz);
    } else {
      needSilentRequest = true;

      _cachedQuizzesIterator = null;
      log('$this-> Локальные данные не найдены, добавляем запрос в очередь первым. desiredCount=1');
      _executionRequestQueue.addFirst(
        _QuizRequest(
          execution: () async {
            // We don't need to think about it, since the queue handler will
            // re-create the request with a delay if an error occurs.
            // Quantity is 1 because we are guaranteed to want the quiz right now
            // subsequent calls will be delayed :(
            return await _fetchQuiz(1, Duration.zero);
          },
        ),
      );
    }

    // silently increase number of quizzes if their cached number is below allowed level
    if (!_isEnoughCachedQuizzes || needSilentRequest) {
      log('$this-> not enough cached quizzes');

      // this means that locally suitable data is no longer available
      _cachedQuizzesIterator = null;
      _fillQueueSilent();
    }

    while (_executionRequestQueue.isNotEmpty) {
      final currentRequest = _executionRequestQueue.removeFirst();

      await _updateStateWithResult(currentRequest);
    }
  }

  Future<void> _updateStateWithResult(_QuizRequest currentRequest) async {
    final triviaResult = await currentRequest.execution.call();

    if (triviaResult case TriviaData<List<QuizDTO>>(:final data)) {
      _cachedQuizzesIterator = null;

      final quizzes = Quiz.quizzesFromDTO(data);
      await _quizzesNotifier.cacheQuizzes(quizzes);
      print('Полученные викторины: ${quizzes.length}');
      // todo: возможен красивый фикс с чистой функцией
      // after this, the `QuizzesNotifier` state already contains current data
      final cachedQuiz = _getCachedQuiz();
      log('$this-> Повторный запрос с результатом=$cachedQuiz');
      if (cachedQuiz != null) {
        log('$this-> Викторина найдена=$cachedQuiz');
        if (!currentRequest.onlyCache) state = QuizGameData(cachedQuiz);
      }
    } else if (triviaResult case TriviaExceptionApi(exception: final exc)) {
      log('$this-> try again because $exc');
      if (exc case TriviaException.rateLimit) {
        await Future.delayed(const Duration(seconds: 5));
        _executionRequestQueue.addFirst(currentRequest);
      } else if (exc case TriviaException.tokenEmptySession) {
        print('предложить сбросить сессию');
        // todo
      } else {
        if (!currentRequest.onlyCache)
          state = QuizGameResult.error(exc.message);
        _executionRequestQueue.clear();
      }
    } else if (triviaResult case TriviaError(:final error)) {
      if (!currentRequest.onlyCache)
        state = QuizGameResult.error(error.toString());
      _executionRequestQueue.clear();
    } else {
      _executionRequestQueue.clear();
      if (!currentRequest.onlyCache) state = const QuizGameResult.emptyData();
    }

    if (currentRequest.clearIfSuccess) _executionRequestQueue.clear();
  }

  void _fillQueueSilent() {
    _executionRequestQueue.add(
      _QuizRequest(
        execution: () async {
          log('$this-> Делаем максимальный запрос. desiredCount=$_maxCountQuizzesPerRequest');
          return await _fetchQuiz(_maxCountQuizzesPerRequest);
        },
        onlyCache: true,
        clearIfSuccess: true,
      ),
    );

    final numbersReductionIterator = getReductionNumbers();
    while (numbersReductionIterator.moveNext()) {
      final desiredCount = numbersReductionIterator.current;

      _executionRequestQueue.add(
        _QuizRequest(
          execution: () async {
            log('$this-> Делаем повторный запрос. desiredCount=$desiredCount');
            return await _fetchQuiz(desiredCount);
          },
          onlyCache: true,
        ),
      );
    }
  }

  Future<TriviaResult> _fetchQuiz(
    int countFetchQuizzes, [
    // Update: At some point in the Trivia backend there is a limit on the number
    // of requests per second from one IP. To get around this, we will wait an
    // additional 5 seconds when this error occurs.
    //
    // therefore we wait 5 seconds as the backend dictates. Then we do a request.
    Duration delay = const Duration(seconds: 5),
  ]) async {
    final quizConfig = _quizConfigNotifier.state;
    log('$this.fetch quizzes-> with $quizConfig, countFetchQuizzes=$countFetchQuizzes');

    await Future.delayed(delay);
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
  static const _minCountCachedQuizzes = 10;

  bool get _isEnoughCachedQuizzes =>
      _quizzesNotifier.state.length > _minCountCachedQuizzes;

  Quiz? _getCachedQuiz() {
    if (_cachedQuizzesIterator == null) {
      final quizzes = List.of(_quizzesNotifier.state)..shuffle();
      _cachedQuizzesIterator = quizzes.iterator;
    }

    print('Состояние кеширующего нотифаера: ${_quizzesNotifier.state.length}');

    while (_cachedQuizzesIterator!.moveNext()) {
      final quiz = _cachedQuizzesIterator!.current;

      if (_quizConfigNotifier.matchQuizByFilter(quiz)) {
        print('Викторина успешно подошла $quiz');
        return quiz;
      }
    }

    return null;
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
