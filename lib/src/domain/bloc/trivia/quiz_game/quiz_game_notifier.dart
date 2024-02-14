import 'dart:async';
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
import '../quiz_config/quiz_config_model.dart';
import '../quiz_config/quiz_config_notifier.dart';
import '../stats/trivia_stats_bloc.dart';
typedef TriviaResultAsyncCallback = Future<TriviaResult> Function();

class _QuizRequest {
  const _QuizRequest({
    required this.execution,
    required this.quizConfig,
    this.onlyCache = false,
    this.clearIfSuccess = false,
  });
  final TriviaResultAsyncCallback execution;
  final bool onlyCache;
  final bool clearIfSuccess;
  final QuizConfig quizConfig;
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

  @override
  QuizGameResult build() {
    _quizStatsNotifier = ref.watch(TriviaStatsProvider.instance);
    _quizzesNotifier = ref.watch(QuizzesNotifier.instance.notifier);
    _triviaRepository = TriviaRepository(
      client: http.Client(),
      useMockData: DebugFlags.triviaRepoUseMock,
    );
    _quizConfigNotifier = ref.watch(QuizConfigNotifier.instance.notifier);

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
  /// for 50: [25, 13, 7, 4, 2, 1]
  /// for 16: [ 8,  4, 2, 1]
  ListBiIterator<int> getReductionNumbers() =>
      ListBiIterator(getReductionsSequence(_maxAmountQuizzesPerRequest));

  /// Maximum number of quizzes per request.
  ///
  /// If the category is popular, we will make 6 requests,
  /// otherwise we will make only 4.
  int get _maxAmountQuizzesPerRequest =>
      _quizConfigNotifier.state.quizCategory.isAny ? 50 : 16;

  QuizConfig get _getQuizConfig => _quizConfigNotifier.state;

  /// Request for the next quiz. The state will be updated reactively.
  Future<void> nextQuiz() async {
    log('$this.nextQuiz-> Request for the next quiz');

    state = const QuizGameResult.loading();

    bool needSilentRequest = false;
    // looking for a quiz that matches the filters
    final cachedQuiz = _getCachedQuiz();
    if (cachedQuiz != null) {
      state = QuizGameData(cachedQuiz);
    } else {
      log('$this-> Cached quizzes were not found, add request to queue first, amount=1');
      needSilentRequest = true;
      _cachedQuizzesIterator = null;

      final quizConfig = _getQuizConfig;
      _executionRequestQueue.addFirst(
        _QuizRequest(
          quizConfig: _getQuizConfig,
          execution: () async {
            // We don't need to think about it, since the queue handler will
            // re-create the request with a delay if an error occurs.
            // Quantity is 1 because we are guaranteed to want the quiz right now
            // subsequent calls will be delayed :(
            return await _fetchQuiz(
              amountQuizzes: 1,
              quizConfig: quizConfig,
              delay: Duration.zero,
            );
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

  Future<void> _updateStateWithResult(_QuizRequest request) async {
    final triviaResult = await request.execution.call();

    if (triviaResult case TriviaData<List<QuizDTO>>(:final data)) {
      final quizzes = Quiz.quizzesFromDTO(data);
      log('$this-> result with data, l=${_quizzesNotifier.state.length}');
      await _quizzesNotifier.cacheQuizzes(quizzes);

      _cachedQuizzesIterator = null;
      // after this, the `QuizzesNotifier` state already contains current data
      final cachedQuiz = _getCachedQuiz();
      if (cachedQuiz != null) {
        if (!request.onlyCache) state = QuizGameData(cachedQuiz);
      }
    } else if (triviaResult case TriviaExceptionApi(exception: final exc)) {
      log('$this-> try again because $exc');
      if (exc case TriviaException.rateLimit) {
        await Future.delayed(const Duration(seconds: 6));
        // if (_executionRequestQueue.isNotEmpty) {
        //   await _updateStateWithResult(request);
        // }
        // todo: проблема правильно обработать очередь

      } else if (exc case TriviaException.tokenEmptySession) {
        _clearQueueByConfig(request);
        // todo
        print('предложить сбросить сессию');
        if (!request.onlyCache) state = const QuizGameResult.emptyData();

      } else {
        _executionRequestQueue.clear();
        if (!request.onlyCache) state = QuizGameResult.error(exc.message);
      }
    } else if (triviaResult case TriviaError(:final error)) {
      _executionRequestQueue.clear();
      if (!request.onlyCache) state = QuizGameResult.error(error.toString());
    }

    if (request.clearIfSuccess) _clearQueueByConfig(request);
  }

  /// Removes requests from the queue if they have the same config as the current request.
  void _clearQueueByConfig(_QuizRequest request) {
    _executionRequestQueue.removeWhere((el) => el.quizConfig == request.quizConfig);
  }

  /// The function fills the queue with requests [TriviaRepository.getQuizzes].
  /// These requests will be completed later.
  ///
  /// Feature: the first request is always for the maximum number of quizzes,
  /// and then each subsequent request with a binary reduction of the requested
  /// number.
  void _fillQueueSilent() {
    final quizConfig = _getQuizConfig;

    _executionRequestQueue.add(
      _QuizRequest(
        execution: () async {
          log('$this-> Request for maximum amount=$_maxAmountQuizzesPerRequest');
          return await _fetchQuiz(
            amountQuizzes: _maxAmountQuizzesPerRequest,
            quizConfig: quizConfig,
          );
        },
        quizConfig: quizConfig,
        onlyCache: true,
        // clear the queue with this config if the request was successful
        clearIfSuccess: true,
      ),
    );

    final numbersReductionIterator = getReductionNumbers();
    while (numbersReductionIterator.moveNext()) {
      final amount = numbersReductionIterator.current;

      _executionRequestQueue.add(
        _QuizRequest(
          execution: () async {
            log('$this-> Request for amount=$amount');
            return await _fetchQuiz(
              amountQuizzes: amount,
              quizConfig: quizConfig,
            );
          },
          quizConfig: quizConfig,
          onlyCache: true,
        ),
      );
    }
  }

  /// Get quizzes from the Trivia server. Use delay if necessary.
  ///
  /// Pure method.
  Future<TriviaResult> _fetchQuiz({
    required int amountQuizzes,
    required QuizConfig quizConfig,
    // Update: At some point in the Trivia backend there is a limit on the number
    // of requests per second from one IP. To get around this, we will wait an
    // additional 5 seconds when this error occurs.
    //
    // therefore we wait 5 seconds as the backend dictates. Then we do a request.
    Duration delay = const Duration(seconds: 6),
  }) async {
    log('$this._fetchQuiz-> with $quizConfig, amount=$amountQuizzes, delay=${delay.inSeconds}sec');

    await Future.delayed(delay);
    final result = await _triviaRepository.getQuizzes(
      category: quizConfig.quizCategory,
      difficulty: quizConfig.quizDifficulty,
      type: quizConfig.quizType,
      amount: amountQuizzes,
    );

    return result;
  }

  /// Limited so as to make the least number of requests to the server,
  /// if the number of available quizzes on the selected parameters is minimal.
  static const _minCountCachedQuizzes = 10;

  bool get _isEnoughCachedQuizzes =>
      _quizzesNotifier.state.length > _minCountCachedQuizzes;

  Iterator<Quiz> get _getNewCachedQuizzesIterator {
    final quizzes = List.of(_quizzesNotifier.state)..shuffle();
    return quizzes.iterator;
  }

  Quiz? _getCachedQuiz() {
    log('$this-> $_quizzesNotifier state: l=${_quizzesNotifier.state.length}');

    _cachedQuizzesIterator ??= _getNewCachedQuizzesIterator;
    while (_cachedQuizzesIterator!.moveNext()) {
      final quiz = _cachedQuizzesIterator!.current;

      if (_quizConfigNotifier.matchQuizByFilter(quiz)) {
        log('$this-> Quiz found in cache, hash:${quiz.hashCode}');
        return quiz;
      }
    }

    return null;
  }

  Future<void> checkMyAnswer(String answer) async {
    if (state is! QuizGameData) return;

    var quiz = (state as QuizGameData).quiz;
    quiz = quiz.copyWith(yourAnswer: answer);

    unawaited(_quizStatsNotifier.savePoints(quiz.correctlySolved!));
    unawaited(_quizzesNotifier.moveQuizAsPlayed(quiz));
    state = QuizGameResult.data(quiz);
  }

  @override
  String toString() =>
      super.toString().replaceFirst('Instance of ', '').replaceAll("'", '');
}
