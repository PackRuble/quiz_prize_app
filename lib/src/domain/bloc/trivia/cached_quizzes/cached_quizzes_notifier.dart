// ignore_for_file: avoid_public_notifier_properties
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_app/src/data/local_storage/game_storage.dart';
import 'package:trivia_app/src/data/trivia/model_dto/category/category.dto.dart';
import 'package:trivia_app/src/data/trivia/model_dto/quiz/quiz.dto.dart';
import 'package:trivia_app/src/data/trivia/trivia_repository.dart';

import '../model/quiz.model.dart';
import '../quiz_config/quiz_config_notifier.dart';
import 'cached_quizzes_result.dart';

/// Notifier contains a state of cached quizzes.
///
/// Has methods for retrieving quizzes from the Internet and storing them in storage.
class CachedQuizzesNotifier extends AutoDisposeNotifier<List<Quiz>> {
  CachedQuizzesNotifier({this.debugMode = false});

  static final instance =
      AutoDisposeNotifierProvider<CachedQuizzesNotifier, List<Quiz>>(() {
    return CachedQuizzesNotifier(
      debugMode: kDebugMode,
    );
  });

  late GameStorage _storage;
  late TriviaRepository _triviaRepository;
  late QuizConfigNotifier _quizConfigNotifier;
  final bool debugMode;

  @override
  List<Quiz> build() {
    _storage = ref.watch(GameStorage.instance);
    _triviaRepository = TriviaRepository(
      client: http.Client(),
      useMockData: debugMode,
    );
    _quizConfigNotifier = ref.watch(QuizConfigNotifier.instance.notifier);

    // The `attach` method provides a reactive state change while storing
    // the new value in storage
    return _storage.attach(
      GameCard.quizzes,
      (value) => state = value,
      detacher: ref.onDispose,
    );
  }

  /// Limited so as to make the least number of requests to the server,
  /// if the number of available quizzes on the selected parameters is minimal.
  static const _minCountCachedQuizzes = 3;

  bool enoughCachedQuizzes() => state.length > _minCountCachedQuizzes;

  Future<TriviaQuizResult?> increaseCachedQuizzes() async {
    log('$this-> get new quizzes and save them to the storage');
    final List<Quiz> fetched;
    try {
      fetched = await _fetchQuizzes();
    } on TriviaQuizResult catch (result) {
      return result;
    }

    // we leave unsuitable quizzes for future times
    await _storage.set<List<Quiz>>(
      GameCard.quizzes,
      [...state, ...fetched]..shuffle(),
    );

    return null;
  }

  /// Get quizzes from [TriviaRepository.getQuizzes].
  ///
  /// May throw an exception [TriviaQuizResult].
  Future<List<Quiz>> _fetchQuizzes() async {
    // desired number of quizzes to fetch
    const kCountFetchQuizzes = 47;
    // 47 ~/= 2; -> 23 -> 11 -> 5 -> 2 -> 1
    // this still doesn't get rid of the edge cases where the number of available
    // quizzes on the server will be 4, 6, 7, etc. but it's better than nothing at all ^)
    const reductionFactor = 2;

    bool tryAgainWithReduce = false;
    int countFetchQuizzes = kCountFetchQuizzes;

    log('$this-> const count [`kCountFetchQuizzes`=$kCountFetchQuizzes]');

    List<QuizDTO>? fetchedQuizDTO;
    do {
      // attempt to reduce the number of quizzes for a query
      if (tryAgainWithReduce) {
        countFetchQuizzes ~/= reductionFactor;
        log('-> next fetch attempt with [`countFetchQuizzes`=$countFetchQuizzes]');
      }

      final quizConfig = _quizConfigNotifier.state;
      log('$this-> fetchQuizzes params: [`category`=${quizConfig.quizCategory}],[`difficulty`=${quizConfig.quizDifficulty}],[`type`=${quizConfig.quizDifficulty}]');
      final result = await _triviaRepository.getQuizzes(
        category: quizConfig.quizCategory,
        difficulty: quizConfig.quizDifficulty,
        type: quizConfig.quizType,
        amount: countFetchQuizzes,
      );

      switch (result) {
        case TriviaRepoData<List<QuizDTO>>(data: final data):
          fetchedQuizDTO = data;
          tryAgainWithReduce = false;
        case TriviaRepoErrorApi(exception: final exception):
          switch (exception) {
            case TriviaException.noResults:
              // it is worth trying to query with less [countFetchQuizzes]
              tryAgainWithReduce = true;
            case _:
              throw TriviaQuizResult.error(result.exception.message);
          }
        case TriviaRepoError(error: final e):
          throw TriviaQuizResult.error(e.toString());
      }
    } while (countFetchQuizzes > 1 && tryAgainWithReduce);

    if (fetchedQuizDTO == null) {
      throw const TriviaQuizResult.emptyData();
    }

    return Quiz.quizzesFromDTO(fetchedQuizDTO);
  }

  /// Get all sorts of categories of quizzes.
  Future<List<CategoryDTO>> fetchCategories() async {
    return switch (await _triviaRepository.getCategories()) {
      TriviaRepoData<List<CategoryDTO>>(data: final list) => () async {
          await _storage.set(GameCard.allCategories, list);
          return list;
        }.call(),
      TriviaRepoError(error: final e) =>
        e is SocketException || e is TimeoutException
            ? _storage.get(GameCard.allCategories)
            : throw Exception(e),
      _ => throw Exception('$this.fetchCategories() failed'),
    };
  }

  // todo(08.02.2024): move in TriviaStatsBloc + create dependencies
  Future<void> moveQuizAsPlayed(Quiz quiz) async {
    final quizzes = state;

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
}
