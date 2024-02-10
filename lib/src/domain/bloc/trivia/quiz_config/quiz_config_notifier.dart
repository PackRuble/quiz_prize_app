
import 'dart:async';
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_app/src/data/local_storage/game_storage.dart';
import 'package:trivia_app/src/data/trivia/model_dto/category/category.dto.dart';
import 'package:trivia_app/src/data/trivia/model_dto/trivia_config_models.dart';
import 'package:trivia_app/src/data/trivia/trivia_repository.dart';
import 'package:trivia_app/src/domain/bloc/trivia/model/quiz.model.dart';

import 'quiz_config_model.dart';

class QuizConfigNotifier extends AutoDisposeNotifier<QuizConfig> {
  static final instance =
  AutoDisposeNotifierProvider<QuizConfigNotifier, QuizConfig>(
    QuizConfigNotifier.new,
  );

  late GameStorage _storage;
  late TriviaRepository _triviaRepository;

  @override
  QuizConfig build() {
    _storage = ref.watch(GameStorage.instance);
    _triviaRepository = TriviaRepository(
      client: http.Client(),
    );

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
}
