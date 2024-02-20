// ignore_for_file: avoid_final_parameters, invalid_annotation_target

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trivia_app/src/data/trivia/model_dto/quiz/quiz.dto.dart';
import 'package:trivia_app/src/data/trivia/model_dto/trivia_config_models.dart';

part 'quiz.model.freezed.dart';
part 'quiz.model.g.dart';

@freezed
class Quiz with _$Quiz {
  const factory Quiz({
    /// The name of category
    required final String category,

    /// The type of the question multiple or True/False.
    required final TriviaQuizType type,

    /// The difficulty of the question.
    required final TriviaQuizDifficulty difficulty,

    /// The actual question.
    required final String question,

    /// Holds the correct answer.
    required final String correctAnswer,

    /// Holds the your answer.
    @Default(null) final String? yourAnswer,

    /// Mixed answers in the amount of 4 pieces. The correct answer included.
    required final List<String> answers,
  }) = _Quiz;

  const Quiz._();

  /// If you gave the correct answer, true will be returned, else false.
  /// If there hasn't been a response yet, return null.
  bool? get correctlySolved =>
      yourAnswer == null ? null : yourAnswer == correctAnswer;

  factory Quiz.fromJson(Map<String, dynamic> json) => _$QuizFromJson(json);

  static List<Quiz> quizzesFromDTO(List<QuizDTO> quizzesDTO) {
    return [
      for (final quizDTO in quizzesDTO)
        Quiz(
          category: quizDTO.category,
          type: quizDTO.type,
          difficulty: quizDTO.difficulty,
          question: quizDTO.question,
          correctAnswer: quizDTO.correctAnswer,
          answers: [quizDTO.correctAnswer, ...quizDTO.incorrectAnswers]
            ..shuffle(),
        ),
    ];
  }
}
