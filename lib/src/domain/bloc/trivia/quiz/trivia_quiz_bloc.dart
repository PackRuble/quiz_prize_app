import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
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

class TriviaQuizProvider extends TriviaQuizBloc {
  TriviaQuizProvider({
    required super.triviaRepository,
    required super.triviaStatsBloc,
    required super.storage,
  });

  static final instance = AutoDisposeProvider<TriviaQuizProvider>((ref) {
    return TriviaQuizProvider(
      triviaRepository: TriviaRepository(
        client: http.Client(),
        alwaysMockData: false ?? kDebugMode,
      ),
      storage: ref.watch(GameStorage.instance),
      triviaStatsBloc:
          ref.watch(TriviaStatsProvider.instance), // Not a bad trick, is it?
    );
  });

  late final quizzes = AutoDisposeProvider<List<Quiz>>((ref) {
    ref.onDispose(() {
      quizzesIterator = null;
    });
    return _storage.attach(
      GameCard.quizzes,
      (value) => ref.state = value,
      detacher: ref.onDispose,
    );
  });

  late final quizDifficulty = AutoDisposeProvider<TriviaQuizDifficulty>((ref) {
    return _storage.attach(
      GameCard.quizDifficulty,
      (value) => ref.state = value,
      detacher: ref.onDispose,
    );
  });

  late final quizType = AutoDisposeProvider<TriviaQuizType>((ref) {
    return _storage.attach(
      GameCard.quizType,
      (value) => ref.state = value,
      detacher: ref.onDispose,
    );
  });

  late final quizCategory = AutoDisposeProvider<CategoryDTO>((ref) {
    return _storage.attach(
      GameCard.quizCategory,
      (value) => ref.state = value,
      detacher: ref.onDispose,
    );
  });
}

/// Contains business logic for obtaining quizzes and categories. Also, caches data.
class TriviaQuizBloc {
  TriviaQuizBloc({
    required TriviaRepository triviaRepository,
    required TriviaStatsBloc triviaStatsBloc,
    required GameStorage storage,
    this.debugMode = kDebugMode,
  })  : _storage = storage,
        _triviaRepository = triviaRepository,
        _triviaStatsBloc = triviaStatsBloc;

  final TriviaRepository _triviaRepository;
  final TriviaStatsBloc _triviaStatsBloc;
  final GameStorage _storage;
  final bool debugMode;

  // ***************************************************************************
  // quizzes difficulty processing

  /// Set the difficulty of quizzes you want.
  Future<void> setQuizDifficulty(TriviaQuizDifficulty difficulty) async {
    await _storage.set<TriviaQuizDifficulty>(
        GameCard.quizDifficulty, difficulty);
  }

  // ***************************************************************************
  // quizzes type processing

  /// Set the type of quizzes you want.
  Future<void> setQuizType(TriviaQuizType type) async {
    await _storage.set<TriviaQuizType>(GameCard.quizType, type);
  }

  // ***************************************************************************
  // quizzes categories processing

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
      _ => throw Exception('$TriviaQuizBloc.fetchCategories() failed'),
    };
  }

  /// Set the quiz category as the current selection.
  Future<void> setCategory(CategoryDTO category) async {
    await _storage.set<CategoryDTO>(GameCard.quizCategory, category);
  }

  // ***************************************************************************
  // quiz processing

  /// Limited so as to make the least number of requests to the server,
  /// if the number of available quizzes on the selected parameters is minimal.
  static const _minCountCachedQuizzes = 3;

  bool _enoughCachedQuizzes() =>
      _storage.get(GameCard.quizzes).length > _minCountCachedQuizzes;

  bool _suitQuizByFilter(Quiz quiz) {
    final category = _storage.get(GameCard.quizCategory);
    final difficulty = _storage.get(GameCard.quizDifficulty);
    final type = _storage.get(GameCard.quizType);

    if ((quiz.category == category.name || category.isAny) &&
        (quiz.difficulty == difficulty ||
            difficulty == TriviaQuizDifficulty.any) &&
        (quiz.type == type || type == TriviaQuizType.any)) {
      return true;
    }

    return false;
  }

  Iterator<Quiz>? quizzesIterator;

  // todo: feature: make a request before the quizzes are over
  // Quiz? nextQuiz;

  /// Get a new quiz.
  ///
  /// Will return [TriviaQuizResult] depending on the query result.
  Future<TriviaQuizResult> getQuiz() async {
    log('$TriviaQuizBloc.getQuiz called');

    final cachedQuizzes = _storage.get(GameCard.quizzes);

    Completer<TriviaQuizResult?>? completer;
    // silently increase the quiz cache if their number is below the allowed level
    if (!_enoughCachedQuizzes()) {
      log('-> not enough cached quizzes');

      quizzesIterator = null;
      completer = Completer();
      completer.complete(_increaseCachedQuizzes());
    }

    // looking for a quiz that matches the filters
    quizzesIterator ??= cachedQuizzes.iterator;
    while (quizzesIterator!.moveNext()) {
      final quiz = quizzesIterator!.current;

      if (_suitQuizByFilter(quiz)) {
        return TriviaQuizResult.data(quiz);
      }
    }

    // quiz not found or list is empty...
    quizzesIterator = null;
    // todo: In a good way, this logic should be rewritten and made more transparent!
    final delayedResult = await (completer?.future ?? _increaseCachedQuizzes());
    if (delayedResult != null) {
      return delayedResult;
    }

    log('-> getting quizzes again');
    if (debugMode && cachedQuizzes.isNotEmpty) {
      return const TriviaQuizResult.error(
        'Debug: The number of suitable quizzes is limited to a constant',
      );
    }
    return getQuiz();
  }

  Future<TriviaQuizResult?> _increaseCachedQuizzes() async {
    log('-> get new quizzes and save them to the storage');
    final List<Quiz> fetched;
    try {
      fetched = await _fetchQuizzes();
    } on TriviaQuizResult catch (result) {
      return result;
    }

    // we leave unsuitable quizzes for future times
    await _storage.set<List<Quiz>>(
      GameCard.quizzes,
      [
        ..._storage.get(GameCard.quizzes),
        ...fetched,
      ]..shuffle(),
    );

    return null;
  }

  /// Get quizzes from [TriviaRepository.getQuizzes].
  ///
  /// May throw an exception [TriviaRepoResult].
  Future<List<Quiz>> _fetchQuizzes() async {
    final category = _storage.get(GameCard.quizCategory);
    final difficulty = _storage.get(GameCard.quizDifficulty);
    final type = _storage.get(GameCard.quizType);
    log('-> fetchQuizzes params: [`category`=$category] [`difficulty`=$difficulty] [`type`=$type]');

    // desired number of quizzes to fetch
    const kCountFetchQuizzes = 47;
    // 47 ~/= 2; -> 23 -> 11 -> 5 -> 2 -> 1
    // this still doesn't get rid of the edge cases where the number of available
    // quizzes on the server will be 4, 6, 7, etc. but it's better than nothing at all ^)
    const reductionFactor = 2;

    bool tryAgainWithReduce = false;
    int countFetchQuizzes = kCountFetchQuizzes;

    late final List<QuizDTO> fetchedQuizDTO;
    do {
      // attempt to reduce the number of quizzes for a query
      if (tryAgainWithReduce) {
        log('-> next fetch attempt with [`countFetchQuizzes`=$countFetchQuizzes]');
        countFetchQuizzes ~/= reductionFactor;
      }

      final result = await _triviaRepository.getQuizzes(
        category: category,
        difficulty: difficulty,
        type: type,
        amount: countFetchQuizzes,
      );

      switch (result) {
        case TriviaRepoData<List<QuizDTO>>():
          fetchedQuizDTO = result.data;
          tryAgainWithReduce = false;
        case TriviaRepoErrorApi():
          switch (result.exception) {
            case TriviaException.tokenEmptySession:
              throw const TriviaQuizResult.emptyData();
            case TriviaException.noResults:
              // it is worth trying to query with less [countFetchQuizzes]
              tryAgainWithReduce = true;
            case _:
              throw TriviaQuizResult.error(result.exception.message);
          }
        case TriviaRepoError(error: final e):
          throw TriviaQuizResult.error(e.toString());
      }
    } while (tryAgainWithReduce && countFetchQuizzes > 1);

    return _quizzesFromDTO(fetchedQuizDTO);
  }

  Future<Quiz> checkMyAnswer(String answer) async {
    var quiz = quizzesIterator!.current;
    quiz = quiz.copyWith(yourAnswer: answer); // ignore: parameter_assignments

    unawaited(_triviaStatsBloc.savePoints(quiz.correctlySolved!));
    unawaited(_moveQuizAsPlayed(quiz));
    return quiz;
  }

  Future<void> _moveQuizAsPlayed(Quiz quiz) async {
    final quizzes = _storage.get(GameCard.quizzes);

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
      [...quizzesPlayed, quiz],
    );
  }

  List<Quiz> _quizzesFromDTO(List<QuizDTO> dto) {
    return dto
        .map(
          (quizDTO) => Quiz(
            category: quizDTO.category,
            type: quizDTO.type,
            difficulty: quizDTO.difficulty,
            question: quizDTO.question,
            correctAnswer: quizDTO.correctAnswer,
            answers: [quizDTO.correctAnswer, ...quizDTO.incorrectAnswers]
              ..shuffle(),
          ),
        )
        .toList();
  }
}
