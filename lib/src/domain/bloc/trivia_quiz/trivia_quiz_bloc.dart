import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_app/src/data/local_storage/game_storage.dart';
import 'package:trivia_app/src/data/trivia/category/category.dto.dart';
import 'package:trivia_app/src/data/trivia/models.dart';
import 'package:trivia_app/src/data/trivia/quiz/quiz.dto.dart';
import 'package:trivia_app/src/data/trivia/trivia_repository.dart';

import 'model/quiz.model.dart';

class TriviaQuizBloc {
  @visibleForTesting
  TriviaQuizBloc({
    required TriviaRepository triviaRepository,
    required TriviaStatsBloc triviaStatsBloc,
    required this.storage,
    required AutoDisposeProviderRef<TriviaQuizBloc> ref,
  })  : _ref = ref,
        _triviaRepository = triviaRepository,
        _triviaStatsBloc = triviaStatsBloc;

  final TriviaRepository _triviaRepository;
  final TriviaStatsBloc _triviaStatsBloc;
  final GameStorage storage;
  final AutoDisposeProviderRef<TriviaQuizBloc> _ref;

  static final instance = AutoDisposeProvider<TriviaQuizBloc>((ref) {
    return TriviaQuizBloc(
      triviaRepository: TriviaRepository(
        client: http.Client(),
        alwaysMockData: kDebugMode,
      ),
      storage: ref.watch(GameStorage.instance),
      triviaStatsBloc: ref.watch(TriviaStatsBloc.instance),
      ref: ref,
    );
  });

  late final quizzes = AutoDisposeProvider<List<Quiz>>((ref) {
    ref.onDispose(() {
      quizzesIterator = null;
    });
    return storage.attach(
      GameCard.quizzes,
      (value) => ref.state = value,
      detacher: ref.onDispose,
    );
  });

  late final quizDifficulty = AutoDisposeProvider<TriviaQuizDifficulty>((ref) {
    return storage.attach(
      GameCard.quizDifficulty,
      (value) => ref.state = value,
      detacher: ref.onDispose,
    );
  });

  late final quizType = AutoDisposeProvider<TriviaQuizType>((ref) {
    return storage.attach(
      GameCard.quizType,
      (value) => ref.state = value,
      detacher: ref.onDispose,
    );
  });

  late final quizCategory = AutoDisposeProvider<CategoryDTO>((ref) {
    return storage.attach(
      GameCard.quizCategory,
      (value) => ref.state = value,
      detacher: ref.onDispose,
    );
  });

  /// Get all sorts of categories of quizzes.
  Future<List<CategoryDTO>> fetchCategories() async {
    return _triviaRepository.getCategories();
  }

  /// Set the quiz category as the current selection.
  Future<void> setCategory(CategoryDTO category) async {
    await storage.set<CategoryDTO>(GameCard.quizCategory, category);
  }

  static const _minCountCachedQuizzes = 10;

  bool _enoughCachedQuizzes() =>
      storage.get(GameCard.quizzes).length > _minCountCachedQuizzes;

  bool _suitQuizByFilter(Quiz quiz) {
    final category = _ref.read(quizCategory);
    final difficulty = _ref.read(quizDifficulty);
    final type = _ref.read(quizType);

    if ((quiz.category == category.name) &&
        (quiz.difficulty == difficulty ||
            difficulty == TriviaQuizDifficulty.any) &&
        (quiz.type == type || type == TriviaQuizType.any)) {
      return true;
    }

    return false;
  }

  Iterator<Quiz>? quizzesIterator;

  /// Get a new quiz.
  ///
  /// Generates errors if no quiz are found.
  Future<Quiz> getQuiz() async {
    final cachedQuizzes = storage.get(GameCard.quizzes);

    Completer<void>? completer;
    // silently increase the quiz cache if their number is below the allowed level
    if (!_enoughCachedQuizzes()) {
      quizzesIterator = null;
      completer = Completer();
      completer.complete(_increaseCachedQuizzes());
    }

    // looking for a quiz that matches the filters
    quizzesIterator ??= cachedQuizzes.iterator;
    while (quizzesIterator!.moveNext()) {
      final quiz = quizzesIterator!.current;

      if (_suitQuizByFilter(quiz)) {
        return quiz;
      }
    }

    // quiz not found or list is empty...
    quizzesIterator = null;
    await (completer?.future ?? _increaseCachedQuizzes());
    return getQuiz();
  }

  Future<void> _increaseCachedQuizzes() async {
    // todo if the quizzes are over on the server
    final fetched = await _fetchQuizzes();

    // we leave unsuitable quizzes for future times
    await storage.set<List<Quiz>>(GameCard.quizzes, [
      ...fetched,
      ...storage.get(GameCard.quizzes),
    ]);
  }

  // ***************************************************************************

  static const _countFetchQuizzes = 6;

  /// Get quizzes from [TriviaRepository.getQuizzes].
  Future<List<Quiz>> _fetchQuizzes() async {
    final fetchedQuizDTO = await _triviaRepository.getQuizzes(
      category: _ref.read(quizCategory),
      difficulty: _ref.read(quizDifficulty),
      type: _ref.read(quizType),
      amount: _countFetchQuizzes,
    );

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
    final quizzes = storage.get(GameCard.quizzes);

    final removedIndex = quizzes.indexWhere(
      (q) =>
          q.correctAnswer == quiz.correctAnswer && q.question == quiz.question,
    );
    await storage.set<List<Quiz>>(
      GameCard.quizzes,
      quizzes..removeAt(removedIndex),
    );

    final quizzesPlayed = storage.get(GameCard.quizzesPlayed);
    await storage.set<List<Quiz>>(
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
}
