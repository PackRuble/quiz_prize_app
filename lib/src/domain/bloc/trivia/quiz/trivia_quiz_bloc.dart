// ignore_for_file: avoid_public_notifier_properties
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart' show immutable, kDebugMode;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_app/src/data/local_storage/game_storage.dart';
import 'package:trivia_app/src/data/trivia/model_dto/category/category.dto.dart';
import 'package:trivia_app/src/data/trivia/model_dto/quiz/quiz.dto.dart';
import 'package:trivia_app/src/data/trivia/model_dto/trivia_models.dart';
import 'package:trivia_app/src/data/trivia/trivia_repository.dart';

import '../model/quiz.model.dart';
import '../stats/trivia_stats_bloc.dart';
import 'trivia_quiz_result.dart';

@immutable
class QuizConfig {
  const QuizConfig({
    required this.quizCategory,
    required this.quizDifficulty,
    required this.quizType,
  });

  final CategoryDTO quizCategory;
  final TriviaQuizDifficulty quizDifficulty;
  final TriviaQuizType quizType;

  QuizConfig copyWith({
    CategoryDTO? quizCategory,
    TriviaQuizDifficulty? quizDifficulty,
    TriviaQuizType? quizType,
  }) {
    return QuizConfig(
      quizCategory: quizCategory ?? this.quizCategory,
      quizDifficulty: quizDifficulty ?? this.quizDifficulty,
      quizType: quizType ?? this.quizType,
    );
  }
}

class QuizConfigNotifier extends AutoDisposeNotifier<QuizConfig> {
  static final instance =
      AutoDisposeNotifierProvider<QuizConfigNotifier, QuizConfig>(
    QuizConfigNotifier.new,
  );

  late GameStorage _storage;

  @override
  QuizConfig build() {
    _storage = ref.watch(GameStorage.instance);

    // The `attach` method provides a reactive state change while storing
    // the new value in storage
    return QuizConfig(
      quizCategory: _storage.attach(
        GameCard.quizCategory,
        (value) => state = state.copyWith(quizCategory: value),
        detacher: ref.onDispose,
      ),
      quizDifficulty: _storage.attach(
        GameCard.quizDifficulty,
        (value) => state = state.copyWith(quizDifficulty: value),
        detacher: ref.onDispose,
      ),
      quizType: _storage.attach(
        GameCard.quizType,
        (value) => state = state.copyWith(quizType: value),
        detacher: ref.onDispose,
      ),
    );
  }

  /// Determines if the quiz matches the current quiz configuration
  bool matchQuizByFilter(Quiz quiz) {
    final category = state.quizCategory;
    final difficulty = state.quizDifficulty;
    final type = state.quizType;

    if ((quiz.category == category.name || category.isAny) &&
        (quiz.difficulty == difficulty ||
            difficulty == TriviaQuizDifficulty.any) &&
        (quiz.type == type || type == TriviaQuizType.any)) {
      return true;
    } else {
      return false;
    }
  }

  /// Set the difficulty of quizzes you want.
  Future<void> setQuizDifficulty(TriviaQuizDifficulty difficulty) async {
    await _storage.set<TriviaQuizDifficulty>(
        GameCard.quizDifficulty, difficulty);
  }

  /// Set the type of quizzes you want.
  Future<void> setQuizType(TriviaQuizType type) async {
    await _storage.set<TriviaQuizType>(GameCard.quizType, type);
  }

  /// Set the quiz category as the current selection.
  Future<void> setCategory(CategoryDTO category) async {
    await _storage.set<CategoryDTO>(GameCard.quizCategory, category);
  }
}

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

  bool _enoughCachedQuizzes() => state.length > _minCountCachedQuizzes;

  Future<TriviaQuizResult?> _increaseCachedQuizzes() async {
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
  /// May throw an exception [TriviaRepoResult].
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
  late List<Quiz> _quizzes;
  late CachedQuizzesNotifier _quizzesNotifier;
  late QuizConfigNotifier _quizConfigNotifier;
  final bool debugMode;

  // internal state
  Iterator<Quiz>? _quizzesIterator;

  @override
  void build() {
    _triviaStatsBloc = ref.watch(TriviaStatsProvider.instance);
    _quizzes = ref.watch(CachedQuizzesNotifier.instance);
    _quizzesNotifier = ref.watch(CachedQuizzesNotifier.instance.notifier);
    _quizConfigNotifier = ref.watch(QuizConfigNotifier.instance.notifier);

    ref.onDispose(() {
      _quizzesIterator = null;
    });

    return;
  }

  // todo: feature: make a request before the quizzes are over
  // Quiz? nextQuiz;

  /// Get a new quiz. Recursive retrieval method.
  ///
  /// Will return [TriviaQuizResult] depending on the query result.
  Future<TriviaQuizResult> getQuiz() async {
    log('$this-> called method for getting quizzes');

    final cachedQuizzes = _quizzes;

    Completer<TriviaQuizResult?>? completer;
    // silently increase the quiz cache if their number is below the allowed level
    if (!_quizzesNotifier._enoughCachedQuizzes()) {
      log('$this-> not enough cached quizzes');

      _quizzesIterator = null;
      completer = Completer();
      completer.complete(_quizzesNotifier._increaseCachedQuizzes());
    }

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
        await (completer?.future ?? _quizzesNotifier._increaseCachedQuizzes());
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
    unawaited(_quizzesNotifier.moveQuizAsPlayed(quiz));
    return quiz;
  }
}
