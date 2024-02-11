import 'package:flutter/foundation.dart' show immutable;
import 'package:trivia_app/src/data/trivia/model_dto/category/category.dto.dart';
import 'package:trivia_app/src/data/trivia/model_dto/trivia_config_models.dart';

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

  @override
  String toString() {
    return 'QuizConfig{'
        'category: ${quizCategory.name}|${quizCategory.id}, '
        '$quizDifficulty, '
        '$quizType}';
  }
}
