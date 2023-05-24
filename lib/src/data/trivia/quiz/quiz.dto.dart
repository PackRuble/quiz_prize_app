// ignore_for_file: avoid_final_parameters, invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../models.dart';

part 'quiz.dto.freezed.dart';
part 'quiz.dto.g.dart';

@freezed
class QuizDTO with _$QuizDTO {
  const factory QuizDTO({
    /// The name of category
    @JsonKey(name: 'category') required final String category,

    /// The type of the question multiple or True/False.
    @JsonKey(name: 'type') required final TriviaQuizType type,

    /// The difficulty of the question.
    @JsonKey(name: 'difficulty') required final TriviaQuizDifficulty difficulty,

    /// The actual question.
    @JsonKey(name: 'question') required final String question,

    /// Holds the correct answer.
    @JsonKey(name: 'correct_answer') required final String correctAnswer,

    /// Contains 3 wrong answers.
    @JsonKey(name: 'incorrect_answers')
    required final List<String> incorrectAnswers,
  }) = _QuizDTO;

  factory QuizDTO.fromJson(Map<String, dynamic> json) =>
      _$QuizDTOFromJson(json);
}
