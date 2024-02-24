import 'dart:async';
import 'dart:collection' show Queue;
import 'dart:core';
import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'
    show AutoDisposeNotifier, AutoDisposeNotifierProvider;
import 'package:quiz_prize_app/extension/bidirectional_iterator.dart';
import 'package:quiz_prize_app/extension/binary_reduction.dart';
import 'package:quiz_prize_app/src/data/trivia/model_dto/quiz/quiz.dto.dart';
import 'package:quiz_prize_app/src/data/trivia/trivia_repository.dart';
import 'package:quiz_prize_app/src/domain/bloc/trivia/quizzes/model/quiz.model.dart';
import 'package:quiz_prize_app/src/domain/bloc/trivia/trivia_token/token_notifier.dart';
import 'package:quiz_prize_app/src/domain/quiz_game/quiz_game_result.dart';

import '../bloc/trivia/quiz_config/quiz_config_model.dart';
import '../bloc/trivia/quiz_config/quiz_config_notifier.dart';
import '../bloc/trivia/quizzes/quizzes_notifier.dart';
import '../bloc/trivia/stats_notifier.dart';
import 'quiz_iterator_bloc.dart';
import 'quiz_request_model.dart';

// futodo(22.02.2024): Debug mode does not exist at the moment
//  However, there is a flag in [TriviaRepository] for mocking categories.
//  It can be controlled from [DebugFlags.triviaRepoUseMock]

/// Notifier is a certain state machine for the game process and methods
/// for managing this state.
class QuizGameNotifier extends AutoDisposeNotifier<QuizGameResult> {
  static final instance =
      AutoDisposeNotifierProvider<QuizGameNotifier, QuizGameResult>(
    QuizGameNotifier.new,
  );

  late QuizStatsNotifier _quizStatsNotifier;
  late QuizzesNotifier _quizzesNotifier;
  late QuizConfigNotifier _quizConfigNotifier;

  // internal state
  late QuizIteratorBloc _quizIteratorBloc;
  // futodo(15.02.2024): In the future, this can be abandoned if you
  //  separate the request queue management into a separate class
  final _executionRequestQueue = Queue<QuizRequest>();
  bool _queueAtWork = false;

  @override
  QuizGameResult build() {
    _quizStatsNotifier = ref.watch(QuizStatsNotifier.instance.notifier);
    _quizzesNotifier = ref.watch(QuizzesNotifier.instance.notifier);
    _quizConfigNotifier = ref.watch(QuizConfigNotifier.instance.notifier);

    // update our iterator whenever new quizzes arrive in the cache
    ref.listen(
      QuizzesNotifier.instance,
      fireImmediately: true,
      (_, next) => _quizIteratorBloc = QuizIteratorBloc(List.of(next)),
    );

    ref.onDispose(() {
      _executionRequestQueue.clear();
    });

    // this allows you to run method immediately after this build has finished running
    Future.microtask(nextQuiz);

    return const QuizGameResult.loading();
  }

  /// Maximum number of quizzes allowed for request.
  static const _maxAmountQuizzesForRequest = 50;

  /// Maximum number of quizzes per request by current config.
  int get _amountQuizzesPerRequest =>
      _quizConfig.quizCategory.isAny ? _maxAmountQuizzesForRequest : 16;

  QuizConfig get _quizConfig => _quizConfigNotifier.state;

  /// Restart in case of accidents.
  void updateStateWhenError() => unawaited(_resetInternalState());

  Future<void> resetGame(bool withResetStats) async {
    await resetQuizConfig(silent: true);
    if (withResetStats) await resetStatistics();
    await _resetSessionToken();
    await _resetInternalState();
  }

  Future<void> resetStatistics() async {
    await _quizStatsNotifier.resetStats();
  }

  Future<void> _resetSessionToken() async {
    await ref.read(TokenNotifier.instance.notifier).resetToken();
  }

  Future<void> resetQuizConfig({bool silent = false}) async {
    await _quizConfigNotifier.resetQuizConfig();
    if (!silent) await _resetInternalState();
  }

  Future<void> _resetInternalState() async {
    _executionRequestQueue.clear();
    ref.invalidateSelf();
  }

  Future<void> checkMyAnswer(String answer) async {
    final currentState = state;
    if (currentState is! QuizGameData) return;

    var quiz = currentState.quiz;
    quiz = quiz.copyWith(yourAnswer: answer);

    log('$this.checkMyAnswer-> $quiz');

    unawaited(_quizStatsNotifier.savePoints(quiz.correctlySolved!));
    unawaited(_quizzesNotifier.moveQuizAsPlayed(quiz));
    state = QuizGameResult.data(quiz);
  }

  /// Request for the next quiz. The state will be updated reactively.
  Future<void> nextQuiz() async {
    log('$this.nextQuiz-> Request for the next quiz');

    state = const QuizGameResult.loading();

    bool needSilentRequest = false;
    // looking for a quiz that matches the filters
    final cachedQuiz =
        _quizIteratorBloc.getCachedQuiz(_quizConfigNotifier.matchQuizByFilter);
    if (cachedQuiz != null) {
      state = QuizGameData(cachedQuiz);
    } else {
      log('$this-> Cached quizzes were not found');
      needSilentRequest = true;

      final isPopularConfig = _quizConfigNotifier.isPopular();
      _executionRequestQueue.addFirst(
        // We don't need to think about it, since the queue handler will
        // re-create the request with a delay if an `TriviaException.rateLimit` occur.
        // Amount is 1 because we are guaranteed to want the quiz right now
        // subsequent calls will be delayed :(
        QuizRequest(
          quizConfig: _quizConfig,
          amountQuizzes: isPopularConfig ? _amountQuizzesPerRequest : 1,
          clearIfSuccess: isPopularConfig,
        ),
      );
    }

    // silently increase number of quizzes if their cached number is below allowed level
    if (!_quizzesNotifier.isEnoughCachedQuizzes || needSilentRequest) {
      log('$this-> not enough cached quizzes');
      _fillQueueSilent(_quizConfig);
    }

    if (_queueAtWork) {
      // requests will still be executed in previous `nextQuiz` call
      return;
    } else {
      _queueAtWork = true;
      while (_executionRequestQueue.isNotEmpty) {
        final currentRequest = _executionRequestQueue.removeFirst();

        await _updateStateWithResult(currentRequest);
      }
      _queueAtWork = false;
    }
  }

  /// The timer is designed to delay the call to the quizzes service.
  /// If it's active, then the retrieval request needs to be delayed (on 5 sec).
  ///
  /// Fields are specifically static so that neither [_timerCallLimit] nor [_callDelay] are reset.
  static Timer? _timerCallLimit;
  static Duration _callDelay = Duration.zero;

  Future<void> _updateStateWithResult(QuizRequest request) async {
    final triviaResult = await _quizzesNotifier
        .fetchQuiz(
      amountQuizzes: request.amountQuizzes,
      quizConfig: request.quizConfig,
      delay: _callDelay,
    )
        .whenComplete(
      () {
        _callDelay = const Duration(seconds: 5);
        _timerCallLimit = Timer(_callDelay, () {
          _callDelay = Duration.zero;
          _timerCallLimit?.cancel();
        });
      },
    );

    QuizGameResult? newState;
    if (triviaResult case TriviaData<List<QuizDTO>>(:final data)) {
      final quizzes = Quiz.quizzesFromDTO(data);
      log('$this-> result with data, l=${quizzes.length}');
      await _quizzesNotifier.cacheQuizzes(quizzes);

      if (state is! QuizGameData) {
        final cachedQuiz = _quizIteratorBloc
            .getCachedQuiz(_quizConfigNotifier.matchQuizByFilter);
        if (cachedQuiz != null) {
          newState = QuizGameData(cachedQuiz);
        }
      }

      if (request.clearIfSuccess) _clearQueueByConfig(request);
    } else if (triviaResult case TriviaExceptionApi(exception: final exc)) {
      log('$this-> result is $exc');
      if (exc case TriviaException.rateLimit) {
        // we are sure that added query will be executed because `_updateStateWithResult` method
        // is always executed in a `while (_executionRequestQueue.isNotEmpty)` loop.
        _executionRequestQueue.addFirst(request);
        _callDelay += const Duration(seconds: 1);

        // futodo(15.02.2024): Another solution to the problem is to use threads
        //  that can listen and perform actions as long as there are elements in the queue
        //  - maybe `StreamQueue` ?..
      } else if (exc case TriviaException.tokenEmptySession) {
        if (request.amountQuizzes == 1) {
          // as it turns out, if the number of quizzes requested is too large,
          // the server will first issue [tokenEmptySession], not [noResults]
          // as you might expect, so we check that the requested number is exactly 1.
          if (_quizConfigNotifier.isPopular() &&
              _quizConfig.quizCategory.isAny) {
            newState = const QuizGameResult.completed();
          } else {
            newState = const QuizGameResult.tryChangeCategory();
          }

          _clearQueueByConfig(request);
        }
      } else if (exc case TriviaException.tokenNotFound) {
        newState = const QuizGameResult.tokenExpired();

        _clearQueueByConfig(request);
      } else if (exc case TriviaException.invalidParameter) {
        newState = QuizGameResult.error(exc.message);
      } else if (exc case TriviaException.noResults) {
        final nextRequest = _executionRequestQueue.firstOrNull;
        if (nextRequest != null) {
          state = QuizGameResult.loading(
            switch (nextRequest.amountQuizzes) {
              < _maxAmountQuizzesForRequest =>
                'Requesting latest ${nextRequest.amountQuizzes} quizzes...',
              1 => 'Requesting last quiz...',
              _ => null,
            },
          );
        }
      }
    } else if (triviaResult case TriviaError(:final error)) {
      log('$this-> result error: $error');
      newState = QuizGameResult.error(error.toString());
    }

    log('$this._updateStateWithResult ended-> newState=$newState');
    if (state is QuizGameData) {
      return;
    } else if (newState != null) {
      if (newState is QuizGameError && _executionRequestQueue.isNotEmpty) {
        return;
      }

      state = newState;
    }
  }

  /// Removes requests from the queue if they have the same config as the current request.
  void _clearQueueByConfig(QuizRequest request) {
    _executionRequestQueue
        .removeWhere((el) => el.quizConfig == request.quizConfig);
  }

  /// The function fills the queue with requests [TriviaRepository.getQuizzes].
  /// These requests will be completed later.
  ///
  /// Feature: the first request is always for the maximum number of quizzes,
  /// and then each subsequent request with a binary reduction of the requested
  /// number.
  void _fillQueueSilent(QuizConfig quizConfig) {
    final first = _executionRequestQueue.firstOrNull;

    if (first == null ||
        !(first.amountQuizzes == _amountQuizzesPerRequest &&
            first.quizConfig == quizConfig)) {
      // make a request only if there is no similar request in the queue
      _executionRequestQueue.add(
        QuizRequest(
          amountQuizzes: _amountQuizzesPerRequest,
          quizConfig: quizConfig,
          // clear the queue with this config if the request was successful
          clearIfSuccess: true,
        ),
      );
    }

    // we fill the queue with binary reduction queries only to retrieve data if
    // the first query fails. If the request is successful, the queue will be
    // cleared (this is what the [_QuizRequest.clearIfSuccess] flag is for)
    final numbersReductionIterator = _getReductionNumbers();
    while (numbersReductionIterator.moveNext()) {
      final amount = numbersReductionIterator.current;

      _executionRequestQueue.add(
        QuizRequest(
          amountQuizzes: amount,
          quizConfig: quizConfig,
          // the last request must be a cleanup request
          clearIfSuccess: amount == 1,
        ),
      );
    }
  }

  /// This is a list of numbers, each of which represents the number of quizzes
  /// we would like to receive from the server.
  ///
  /// for 50: [25, 13, 7, 4, 2, 1]
  /// for 16: [ 8,  4, 2, 1]
  ///
  /// If the category is popular, we will make 6 requests,
  /// otherwise we will make only 4.
  ListBiIterator<int> _getReductionNumbers() =>
      ListBiIterator(getReductionsSequence(_amountQuizzesPerRequest));

  @override
  @protected
  String toString() =>
      super.toString().replaceFirst('Instance of ', '').replaceAll("'", '');
}
