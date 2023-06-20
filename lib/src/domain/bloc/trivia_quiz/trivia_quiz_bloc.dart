import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_app/src/data/local_storage/game_storage.dart';
import 'package:trivia_app/src/data/trivia/category/category.dto.dart';
import 'package:trivia_app/src/data/trivia/models.dart';
import 'package:trivia_app/src/data/trivia/quiz/quiz.dto.dart';
import 'package:trivia_app/src/data/trivia/trivia_repository.dart';

import 'model/quiz.model.dart';
import 'trivia_quiz_result.dart';

/// Contains business logic for obtaining quizzes and categories. Also, caches data.
class TriviaQuizBloc {
  TriviaQuizBloc._({
    required TriviaRepository triviaRepository,
    required TriviaStatsBloc triviaStatsBloc,
    required GameStorage storage,
    required AutoDisposeProviderRef<TriviaQuizBloc> ref,
  })  : _storage = storage,
        _ref = ref,
        _triviaRepository = triviaRepository,
        _triviaStatsBloc = triviaStatsBloc;

  final TriviaRepository _triviaRepository;
  final TriviaStatsBloc _triviaStatsBloc;
  final GameStorage _storage;
  final AutoDisposeProviderRef<TriviaQuizBloc> _ref;

  static final instance = AutoDisposeProvider<TriviaQuizBloc>((ref) {
    return TriviaQuizBloc._(
      triviaRepository: TriviaRepository(
        client: http.Client(),
        alwaysMockData: kDebugMode,
      ),
      storage: ref.watch(GameStorage.instance),
      triviaStatsBloc: ref.watch(TriviaStatsBloc.instance),
      ref: ref,
    );
  });

  // ***************************************************************************
  // providers for watching

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
      TriviaResultData<List<CategoryDTO>>(data: final list) => list,
      TriviaResultError(error: final e) => throw Exception(e),
      _ => throw Exception('$TriviaQuizBloc.fetchCategories() failed'),
    };
  }

  /// Set the quiz category as the current selection.
  Future<void> setCategory(CategoryDTO category) async {
    await _storage.set<CategoryDTO>(GameCard.quizCategory, category);
  }

  // ***************************************************************************
  // quiz processing

  static const _minCountCachedQuizzes = 10;

  bool _enoughCachedQuizzes() =>
      _storage.get(GameCard.quizzes).length > _minCountCachedQuizzes;

  bool _suitQuizByFilter(Quiz quiz) {
    final category = _ref.read(quizCategory);
    final difficulty = _ref.read(quizDifficulty);
    final type = _ref.read(quizType);

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
    // await storage.remove(GameCard.quizzes);
    // throw '';

    Completer<void>? completer;
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
    await (completer?.future ?? _increaseCachedQuizzes());

    log('-> getting quizzes again');
    if (kDebugMode) {
      return const TriviaQuizResult.error(
        'Debug: The number of suitable quizzes is limited to a constant',
      );
    }
    return getQuiz();
  }

  Future<void> _increaseCachedQuizzes() async {
    log('-> get new quizzes and save them to the storage');
    final fetched = await _fetchQuizzes();

    // we leave unsuitable quizzes for future times
    await _storage.set<List<Quiz>>(GameCard.quizzes, [
      ...fetched,
      ..._storage.get(GameCard.quizzes),
    ]);
  }

  static const _countFetchQuizzes = 6;

  /// Get quizzes from [TriviaRepository.getQuizzes].
  Future<List<Quiz>> _fetchQuizzes() async {
    final result = await _triviaRepository.getQuizzes(
      category: _ref.read(quizCategory),
      difficulty: _ref.read(quizDifficulty),
      type: _ref.read(quizType),
      amount: _countFetchQuizzes,
    );

    final fetchedQuizDTO = switch (result) {
      TriviaResultData<List<QuizDTO>>() => result.data,
      TriviaResultErrorApi() => switch (result.exception) {
          TriviaException.tokenEmptySession =>
            throw const TriviaQuizResult.emptyData(),
          _ => throw TriviaQuizResult.error(result.exception.message),
        },
      TriviaResultError(error: final e) =>
        throw TriviaQuizResult.error(e.toString()),
    };

    return _quizzesFromDTO(fetchedQuizDTO);
  }

  Future<Quiz> checkMyAnswer(String answer) async {
    var quiz = quizzesIterator!.current;
    quiz = quiz.copyWith(yourAnswer: answer); // ignore: parameter_assignments

    unawaited(_triviaStatsBloc._savePoints(quiz.correctlySolved!));
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

typedef _CategoryName = String;

class TriviaStatsBloc {
  @visibleForTesting
  TriviaStatsBloc({
    required GameStorage storage,
  }) : _storage = storage;

  final GameStorage _storage;

  static final instance = AutoDisposeProvider<TriviaStatsBloc>((ref) {
    return TriviaStatsBloc(
      storage: ref.watch(GameStorage.instance),
    );
  });

  // ***************************************************************************
  // counting quizzes played by their difficulty

  late final statsOnDifficulty = AutoDisposeProvider<
      Map<TriviaQuizDifficulty, (int correctly, int uncorrectly)>>(
    (ref) => _calculateStatsOnDifficulty(ref.watch(quizzesPlayed)),
  );

  Map<TriviaQuizDifficulty, (int correctly, int uncorrectly)>
      _calculateStatsOnDifficulty(List<Quiz> quizzes) {
    final result = <TriviaQuizDifficulty, (int correctly, int uncorrectly)>{};

    for (final q in quizzes) {
      var (int correctly, int uncorrectly) = result[q.difficulty] ?? (0, 0);

      if (q.correctlySolved!) {
        result[q.difficulty] = (++correctly, uncorrectly);
      } else {
        result[q.difficulty] = (correctly, ++uncorrectly);
      }
    }

    return result;
  }

  // ***************************************************************************
  // counting quizzes played by their category

  late final statsOnCategory =
      AutoDisposeProvider<Map<_CategoryName, (int correctly, int uncorrectly)>>(
    (ref) => _calculateStatsOnCategory(ref.watch(quizzesPlayed)),
  );

  Map<_CategoryName, (int correctly, int uncorrectly)>
      _calculateStatsOnCategory(List<Quiz> quizzes) {
    final result = <_CategoryName, (int correctly, int uncorrectly)>{};

    for (final q in quizzes) {
      var (int correctly, int uncorrectly) = result[q.category] ?? (0, 0);

      if (q.correctlySolved!) {
        result[q.category] = (++correctly, uncorrectly);
      } else {
        result[q.category] = (correctly, ++uncorrectly);
      }
    }

    return result;
  }

  // ***************************************************************************
  // others

  late final quizzesPlayed = AutoDisposeProvider<List<Quiz>>((ref) {
    return _storage.attach(
      GameCard.quizzesPlayed,
      (value) => ref.state = value,
      detacher: ref.onDispose,
    );
  });

  late final winning = AutoDisposeProvider<int>((ref) {
    return _storage.attach(
      GameCard.winning,
      (value) => ref.state = value,
      detacher: ref.onDispose,
    );
  });

  late final losing = AutoDisposeProvider<int>((ref) {
    return _storage.attach(
      GameCard.losing,
      (value) => ref.state = value,
      detacher: ref.onDispose,
    );
  });

  Future<void> _savePoints(bool isWin) async {
    isWin
        ? await _storage.set<int>(
            GameCard.winning,
            _storage.get(GameCard.winning) + 1,
          )
        : await _storage.set<int>(
            GameCard.losing,
            _storage.get(GameCard.losing) + 1,
          );
  }

  Future<void> resetStats() async {
    await _storage.remove(GameCard.winning);
    await _storage.remove(GameCard.losing);
    await _storage.remove(GameCard.quizzesPlayed);
  }
}
