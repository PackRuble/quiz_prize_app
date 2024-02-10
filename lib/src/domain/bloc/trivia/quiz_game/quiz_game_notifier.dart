import 'dart:async' show Completer, unawaited;
import 'dart:developer' show log;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hooks_riverpod/hooks_riverpod.dart'
    show AutoDisposeNotifier, AutoDisposeNotifierProvider;

import '../cached_quizzes/cached_quizzes_notifier.dart';
import '../cached_quizzes/cached_quizzes_result.dart';
import '../model/quiz.model.dart';
import '../quiz_config/quiz_config_notifier.dart';
import '../stats/trivia_stats_bloc.dart';

/// Notifier is a certain state machine for the game process and methods
/// for managing this state.
// todo(08.02.2024): This class should contains current quiz-state (or maybe Iterator<Quiz>).
//  This will require significant changes.
class QuizGameNotifier extends AutoDisposeNotifier<void> {
  QuizGameNotifier({this.debugMode = false});

  static final instance =
      AutoDisposeNotifierProvider<QuizGameNotifier, void>(() {
    return QuizGameNotifier(debugMode: kDebugMode);
  });

  late TriviaStatsBloc _triviaStatsBloc;
  late CachedQuizzesNotifier _cachedQuizzesNotifier;
  late QuizConfigNotifier _quizConfigNotifier;
  // ignore: avoid_public_notifier_properties
  final bool debugMode;

  // internal state
  Iterator<Quiz>? _quizzesIterator;

  // todo: feature: make a request before the quizzes are over
  // Quiz? nextQuiz;

  @override
  void build() {
    _triviaStatsBloc = ref.watch(TriviaStatsProvider.instance);
    _cachedQuizzesNotifier = ref.watch(CachedQuizzesNotifier.instance.notifier);
    _quizConfigNotifier = ref.watch(QuizConfigNotifier.instance.notifier);

    ref.onDispose(() {
      _quizzesIterator = null;
    });

    return;
  }

  /// Get a new quiz. Recursive retrieval method.
  ///
  /// Will return [TriviaQuizResult] depending on the query result.
  Future<TriviaQuizResult> getQuiz() async {
    log('$this-> called method for getting quizzes');

    Completer<TriviaQuizResult?>? completer;
    // silently increase the quiz cache if their number is below the allowed level
    if (!_cachedQuizzesNotifier.enoughCachedQuizzes()) {
      log('$this-> not enough cached quizzes');

      _quizzesIterator = null;
      completer = Completer();
      completer.complete(_cachedQuizzesNotifier.increaseCachedQuizzes());
    }

    final cachedQuizzes = List.of(_cachedQuizzesNotifier.state);

    // looking for a quiz that matches the filters
    _quizzesIterator ??= cachedQuizzes.iterator;
    while (_quizzesIterator!.moveNext()) {
      final quiz = _quizzesIterator!.current;

      if (_quizConfigNotifier.matchQuizByFilter(quiz)) {
        return TriviaQuizResult.data(quiz);
      }
    }

    // quiz not found or list is empty...
    _quizzesIterator = null;
    // todo: In a good way, this logic should be rewritten and made more transparent!
    final delayedResult =
        await (completer?.future ?? _cachedQuizzesNotifier.increaseCachedQuizzes());
    if (delayedResult != null) {
      return delayedResult;
    }

    log('$this-> getting quizzes again');
    if (debugMode && cachedQuizzes.isNotEmpty) {
      return const TriviaQuizResult.error(
        'Debug: The number of suitable quizzes is limited to a constant',
      );
    }
    return getQuiz();
  }

  Future<Quiz> checkMyAnswer(String answer) async {
    var quiz = _quizzesIterator!.current;
    quiz = quiz.copyWith(yourAnswer: answer);

    unawaited(_triviaStatsBloc.savePoints(quiz.correctlySolved!));
    unawaited(_cachedQuizzesNotifier.moveQuizAsPlayed(quiz));
    return quiz;
  }
}
