import 'package:flutter/foundation.dart';
import 'package:trivia_app/src/data/trivia/models.dart';
import 'package:trivia_app/src/data/trivia/quiz/quiz.dto.dart';

@immutable
class Quiz {
  const Quiz(
    this._quizDTO, {
    this.yourAnswer,
  });

  final QuizDTO _quizDTO;

  /// The name of category
  String get category => _quizDTO.category;

  /// The type of the question multiple or True/False.
  TriviaQuizType get type => _quizDTO.type;

  /// The difficulty of the question.
  TriviaQuizDifficulty get difficulty => _quizDTO.difficulty;

  /// The actual question.
  String get question => _quizDTO.question;

  /// Holds the correct answer.
  String get correctAnswer => _quizDTO.correctAnswer;

  /// Holds the your answer.
  final String? yourAnswer;

  /// Mixed answers in the amount of 4 pieces. The correct answer included.
  List<String> get answers =>
      [_quizDTO.correctAnswer, ..._quizDTO.incorrectAnswers]..shuffle();

  @override
  int get hashCode => Object.hash(yourAnswer, _quizDTO.hashCode);

  @override
  bool operator ==(Object other) {
    return other.runtimeType == runtimeType &&
        other is Quiz &&
        super == other &&
        other.yourAnswer == correctAnswer;
  }
}
