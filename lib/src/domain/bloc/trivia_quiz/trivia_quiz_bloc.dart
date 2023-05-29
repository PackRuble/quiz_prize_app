import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
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
      ),
      storage: ref.watch(GameStorage.instance),
      triviaStatsBloc: ref.watch(TriviaStatsBloc.instance),
      ref: ref,
    );
  });

  late final quizzes = AutoDisposeProvider<List<Quiz>>((ref) {
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

  static const _minCountQuizzesForFetching = 10;
  static const _countFetchQuizzes = 25;

  /// Get a new quiz.
  ///
  /// Generates errors if no quizzes are found.
  Future<Quiz> getQuiz() async {
    final quiz = await _getNextQuiz();

    return quiz;
  }

  int? _lastFoundByIndex;

  /// If no additional restrictions are specified, the first value from the list
  /// will be returned.
  Quiz? _findQuizBy(
    List<Quiz> quizzes, {
    CategoryDTO? category,
    TriviaQuizDifficulty? difficulty,
    TriviaQuizType? type,
  }) {
    for (int i = _lastFoundByIndex ?? 0; i < quizzes.length; ++i) {
      final q = quizzes[i];

      if ((q.category == (category?.name ?? true)) &&
          (q.difficulty == (difficulty ?? true) ||
              difficulty == TriviaQuizDifficulty.any) &&
          (q.type == (type ?? true) || type == TriviaQuizType.any)) {
        _lastFoundByIndex = i;
        return q;
      }
    }
    _lastFoundByIndex = null;

    return null;
  }

  Future<Quiz> _getNextQuiz() async {
    final quizzes = _ref.read(this.quizzes);

    // print(quizzes);

    final List<Quiz> results;

    if (quizzes.length > _minCountQuizzesForFetching) {
      results = quizzes;
    } else {
      final fetchedQuiz = await _fetchQuizzes();
      fetchedQuiz.addAll(quizzes);
      unawaited(storage.set<List<Quiz>>(GameCard.quizzes, fetchedQuiz));
      results = fetchedQuiz;
    }

    final Quiz? quiz = _findQuizBy(
      results,
      category: _ref.read(quizCategory),
      difficulty: _ref.read(quizDifficulty),
      type: _ref.read(quizType),
    );

    if (quiz == null) {
      throw 'Викторины на данную тематику закончились'; // todo сделать разборку викторин на группы
    }

    return quiz;
  }

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

  Future<Quiz> checkMyAnswer(Quiz quiz, String answer) async {
    quiz = quiz.copyWith(yourAnswer: answer); // ignore: parameter_assignments

    unawaited(_triviaStatsBloc._savePoints(quiz.correctlySolved!));
    unawaited(_moveQuizAsPlayed(quiz));
    return quiz;
  }

  Future<void> _moveQuizAsPlayed(Quiz quiz) async {
    final quizzes = storage.get(GameCard.quizzes);

    final removedIndex = quizzes.indexWhere(
      (q) =>
          q.correctAnswer == quiz.correctAnswer &&
          q.question == quiz.question, // todo: uuid
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
