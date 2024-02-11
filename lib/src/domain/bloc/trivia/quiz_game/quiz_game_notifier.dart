import 'dart:async' show Completer, FutureOr, StreamController, unawaited;
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
  Iterator<Quiz>? _quizzesIterator;
  StreamController<QuizGameResult>? _hiddenProcessFetchingQuizzes;

  // todo: feature: make a request before the quizzes are over
  // Quiz? nextQuiz;

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

    ref.onDispose(() {
      // ignore: discarded_futures
      _hiddenProcessFetchingQuizzes?.close();
      _quizzesIterator = null;
    });

    return const QuizGameResult.loading();
  }

  Future<void> nextQuiz() async {
    log('$this-> get next quiz');

    state = const QuizGameResult.loading();

    // silently increase number of quizzes if their cached number is below allowed level
    final completer = _fetchQuizSilent();

    // looking for a quiz that matches the filters
    final cachedQuizzesResult = _getCachedQuizzes();
    if (cachedQuizzesResult != null) {
      state = cachedQuizzesResult;
      return;
    } else {
      // quiz not found or list is empty...
      // if we have not previously requested a network fetching, we do so now
      _hiddenProcessFetchingQuizzes?.stream.listen((event) {
        state = event;
      });

      state = await (completer?.future ?? _fetchQuiz());
    }
  }

  /// Limited so as to make the least number of requests to the server,
  /// if the number of available quizzes on the selected parameters is minimal.
  static const _minCountCachedQuizzes = 3;

  bool get _isEnoughCachedQuizzes =>
      _quizzesNotifier.state.length > _minCountCachedQuizzes;

  QuizGameData? _getCachedQuizzes() {
    _quizzesIterator ??= List.of(_quizzesNotifier.state).iterator;
    while (_quizzesIterator!.moveNext()) {
      final quiz = _quizzesIterator!.current;

      if (_quizConfigNotifier.matchQuizByFilter(quiz)) {
        return QuizGameData(quiz);
      }
    }
    return null;
  }

  Completer<QuizGameResult>? _fetchQuizSilent() {
    Completer<QuizGameResult>? completer;
    if (!_isEnoughCachedQuizzes) {
      log('$this-> not enough cached quizzes');

      completer = Completer();
      // ignore: discarded_futures
      completer.complete(_fetchQuiz());
    }
    return completer;
  }

  Future<QuizGameResult> _fetchQuiz() async {
    _hiddenProcessFetchingQuizzes = StreamController<QuizGameResult>();

    // desired number of quizzes to fetch
    const kCountFetchQuizzes = 47;
    // 47 ~/= 2; -> 23 -> 11 -> 5 -> 2 -> 1
    // this still doesn't get rid of the edge cases where the number of available
    // quizzes on the server will be 4, 6, 7, etc. but it's better than nothing at all ^)
    //
    // Update: At some point in the Trivia backend there is a limit on the number
    // of requests per second from one IP. To get around this, we will wait an
    // additional 5 seconds when this error occurs.
    const reductionFactor = 2;

    bool tryAgainWithReduce = false;
    int countFetchQuizzes = kCountFetchQuizzes;

    log('$this._fetchQuizzes-> with [kCountFetchQuizzes=$kCountFetchQuizzes]');

    final quizConfig = _quizConfigNotifier.state;
    log('$this-> with $quizConfig');

    QuizGameResult? quizGameResult;
    quizFetchingLabel : do {
      // attempt to reduce the number of quizzes for a query
      if (tryAgainWithReduce) {
        countFetchQuizzes ~/= reductionFactor;
        _hiddenProcessFetchingQuizzes!.add(QuizGameResult.loading('Retrying to load $countFetchQuizzes quiz'));
        log('$this-> next fetch attempt with [countFetchQuizzes=$countFetchQuizzes]');
      }

      final result = await _triviaRepository.getQuizzes(
        category: quizConfig.quizCategory,
        difficulty: quizConfig.quizDifficulty,
        type: quizConfig.quizType,
        amount: countFetchQuizzes,
      );

       switch (result) {
        case TriviaRepoData<List<QuizDTO>>(:final data):
          final quizzes = Quiz.quizzesFromDTO(data);

          if (quizzes.isNotEmpty) {
            await _quizzesNotifier.cacheQuizzes(quizzes);
          }

          quizGameResult = _getCachedQuizzes() ?? const QuizGameResult.emptyData();
          break quizFetchingLabel;
        case TriviaRepoErrorApi(:final exception):
          switch (exception) {
            case TriviaException.noResults:
              // it is worth trying to query with less [countFetchQuizzes]
              tryAgainWithReduce = true;
              log('$this-> try again because ${TriviaException.noResults}');
            case TriviaException.rateLimit:
              tryAgainWithReduce = true;
              log('$this-> try again because ${TriviaException.rateLimit}');
              // wait 5 seconds as the backend dictates. Then we do a second request.
              await Future.delayed(const Duration(seconds: 6));
            case _:
              quizGameResult = QuizGameResult.error(exception.message);
              break quizFetchingLabel;
          }
        case TriviaRepoError(:final error):
          quizGameResult = QuizGameResult.error(error.toString());
          break quizFetchingLabel;
      }
    } while (countFetchQuizzes > 1 && tryAgainWithReduce);

    await _hiddenProcessFetchingQuizzes!.close();

    return quizGameResult!;
  }

  Future<void> checkMyAnswer(String answer) async {
    var quiz = _quizzesIterator!.current;
    quiz = quiz.copyWith(yourAnswer: answer);

    unawaited(_quizStatsNotifier.savePoints(quiz.correctlySolved!));
    unawaited(_quizzesNotifier.moveQuizAsPlayed(quiz));
    state = QuizGameResult.data(quiz);
  }

  @override
  String toString() =>
      super.toString().replaceFirst('Instance of ', '').replaceAll("'", '');
}
