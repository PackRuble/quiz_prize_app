// ignore_for_file: avoid_public_notifier_properties
import 'dart:async';
import 'dart:developer';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:quiz_prize_app/internal/debug_flags.dart';
import 'package:quiz_prize_app/src/data/local_storage/game_storage.dart';
import 'package:quiz_prize_app/src/data/trivia/trivia_repository.dart';
import 'package:quiz_prize_app/src/domain/bloc/trivia/quiz_config/quiz_config_model.dart';
import 'package:quiz_prize_app/src/domain/bloc/trivia/trivia_token/token_notifier.dart';
import 'package:quiz_prize_app/src/domain/bloc/trivia/trivia_token/token_state.dart';
import 'package:quiz_prize_app/src/domain/storage_notifiers.dart';

import 'model/quiz.model.dart';

/// Notifier contains a state of cached quizzes.
///
/// Has methods for retrieving quizzes from the Internet and storing them in storage.
class QuizzesNotifier extends AutoDisposeNotifier<List<Quiz>> {
  static final instance =
      AutoDisposeNotifierProvider<QuizzesNotifier, List<Quiz>>(
    QuizzesNotifier.new,
  );

  late GameStorage _storage;
  late TriviaRepository _triviaRepository;
  late TokenNotifier _tokenNotifier;

  @override
  List<Quiz> build() {
    _storage = ref.watch(StorageNotifiers.game);
    _triviaRepository = TriviaRepository(
      client: http.Client(),
      useMockData: DebugFlags.triviaRepoUseMock,
    );
    _tokenNotifier = ref.watch(TokenNotifier.instance.notifier);

    // The `attach` method provides a reactive state change while storing
    // the new value in storage
    return _storage.attach(
      GameCard.quizzes,
      (value) => state = List.of(value),
      detacher: ref.onDispose,
      onRemove: () => state = [],
    );
  }

  Future<void> cacheQuizzes(List<Quiz> fetched) async {
    await _storage.set<List<Quiz>>(
      GameCard.quizzes,
      [...state, ...fetched],
    );
  }

  Future<void> clearAll() async {
    await _storage.remove(GameCard.quizzes);
  }

  /// Limited so as to make the least number of requests to the server,
  /// if the number of available quizzes on the selected parameters is minimal.
  static const _minCountCachedQuizzes = 10;

  bool get isEnoughCachedQuizzes => state.length > _minCountCachedQuizzes;

  /// Get quizzes from the Trivia server. Use delay if necessary.
  ///
  /// Pure method.
  Future<TriviaResult> fetchQuiz({
    required int amountQuizzes,
    required QuizConfig quizConfig,
    // Update: At some point in the Trivia backend there is a limit on the number
    // of requests per second from one IP. To get around this, we will wait an
    // additional 5 seconds when this error occurs.
    //
    // therefore we wait 5 seconds as the backend dictates. Then we do a request.
    Duration? delay = const Duration(seconds: 5),
  }) async {
    // ignore: parameter_assignments
    delay ??= const Duration(seconds: 5);
    log('$this._fetchQuiz-> with $quizConfig, amount=$amountQuizzes, delay=${delay.inSeconds}sec');

    final (token, exception) = await _getToken();
    if (exception != null) return exception;

    await Future.delayed(delay);
    final result = await _triviaRepository.getQuizzes(
      category: quizConfig.quizCategory,
      difficulty: quizConfig.quizDifficulty,
      type: quizConfig.quizType,
      amount: amountQuizzes,
      token: token,
    );

    if (result case TriviaData()) await _tokenNotifier.extendValidityOfToken();

    return result;
  }

  /// Calling this method may result in an exception [TriviaExceptionApi]:
  /// - [TriviaException.tokenEmptySession]
  /// - [TriviaException.tokenNotFound]
  Future<(String? token, TriviaExceptionApi? exception)> _getToken() async {
    String? token;
    TriviaExceptionApi? exception;

    switch (_tokenNotifier.state) {
      case TokenActive(token: final triviaToken):
        token = triviaToken.token;
      case TokenEmptySession():
        exception = const TriviaExceptionApi(TriviaException.tokenEmptySession);
      case TokenExpired():
        // this state can be handled separately, however, we will not torture
        // the user in obtaining the token independently

        // we will also clear all cache to avoid repeat quizzes
        await clearAll();
        continue noneLabel;
      noneLabel:
      case TokenNone():
        final triviaToken = await _tokenNotifier.fetchNewToken();
        if (triviaToken == null) {
          continue errorLabel;
        } else {
          token = triviaToken.token;
        }
      errorLabel:
      case TokenError():
        exception = const TriviaExceptionApi(TriviaException.tokenNotFound);
    }
    return (token, exception);
  }

  Future<void> moveQuizAsPlayed(Quiz quiz) async {
    final quizzes = List.of(state);

    final removedIndex = quizzes.indexWhere(
      (q) =>
          q.correctAnswer == quiz.correctAnswer && q.question == quiz.question,
    );
    await _storage.set<List<Quiz>>(
      GameCard.quizzes,
      quizzes..removeAt(removedIndex),
    );

    final quizzesPlayed = _storage.get(GameCard.quizzesPlayed);
    await _storage.set<List<Quiz>>(
      GameCard.quizzesPlayed,
      [quiz, ...quizzesPlayed],
    );
  }

  @override
  String toString() =>
      super.toString().replaceFirst('Instance of ', '').replaceAll("'", '');
}
