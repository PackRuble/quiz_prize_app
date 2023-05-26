import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_app/src/data/local_storage/game_storage.dart';
import 'package:trivia_app/src/data/trivia/category/category.dto.dart';
import 'package:trivia_app/src/data/trivia/models.dart';
import 'package:trivia_app/src/data/trivia/quiz/quiz.dto.dart';
import 'package:trivia_app/src/data/trivia/trivia_repository.dart';

import 'model/quiz.model.dart';

class TriviaBloc {
  @visibleForTesting
  TriviaBloc({
    required this.triviaRepository,
    required this.storage,
    required this.ref,
  });

  final TriviaRepository triviaRepository;
  final GameStorage storage;
  final AutoDisposeProviderRef<TriviaBloc> ref;

  static final instance = AutoDisposeProvider<TriviaBloc>((ref) {
    return TriviaBloc(
      triviaRepository: TriviaRepository(
        client: http.Client(),
      ),
      storage: ref.watch(gameStorageProvider),
      ref: ref,
    );
  });

  late final quizzes = AutoDisposeProvider<List<QuizDTO>>((ref) {
    return storage.attach(
      GameCard.lastQuiz,
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

  static const _takeQuizIndex = 1;
  static const _minCountQuizzesForFetching = 10;
  static const _countFetchQuizzes = 25;

  /// Get a new quiz.
  Future<Quiz> getQuiz() async {
    final QuizDTO quiz = (await _fetchQuizzes()).take(_takeQuizIndex).first;

    return _quizFromDTO(quiz);
  }

  Quiz _quizFromDTO(QuizDTO quizDTO) {
    return Quiz(
      category: quizDTO.category,
      type: quizDTO.type,
      difficulty: quizDTO.difficulty,
      question: quizDTO.question,
      correctAnswer: quizDTO.correctAnswer,
      answers: [quizDTO.correctAnswer, ...quizDTO.incorrectAnswers]..shuffle(),
    );
  }

  Future<List<QuizDTO>> _fetchQuizzes() async {
    final quizzes = ref.read(this.quizzes);

    print(quizzes);

    if (quizzes.length > _minCountQuizzesForFetching) {
      return quizzes;
    } else {
      // не нужно ожидать
      final fetchedQuiz = await triviaRepository.getQuizzes(
        category: CategoryDTO.fromJson({"id": 9, "name": "General Knowledge"}),
        difficulty: ref.read(quizDifficulty),
        type: ref.read(quizType),
        amount: _countFetchQuizzes,
      );

      fetchedQuiz.addAll(quizzes);

      unawaited(storage.set<List<QuizDTO>>(GameCard.lastQuiz, fetchedQuiz));

      return fetchedQuiz;
    }
  }

  Future<Quiz> checkMyAnswer(Quiz quiz, String answer) async {
    final newQuiz = quiz.copyWith(yourAnswer: answer);
    // todo: save in storage
    return newQuiz;
  }
}
