import 'package:flutter/foundation.dart' show ValueGetter, immutable, protected;
import 'package:quiz_prize_app/src/domain/bloc/trivia/quiz_config/quiz_config_model.dart';

@immutable
class QuizRequest {
  const QuizRequest({
    required this.quizConfig,
    required this.amountQuizzes,
    this.clearIfSuccess = false,
  });

  final QuizConfig quizConfig;
  final int amountQuizzes;
  final bool clearIfSuccess;

  QuizRequest copyWith({
    QuizConfig? quizConfig,
    int? amountQuizzes,
    bool? onlyCache,
    bool? clearIfSuccess,
  }) {
    return QuizRequest(
      quizConfig: quizConfig ?? this.quizConfig,
      amountQuizzes: amountQuizzes ?? this.amountQuizzes,
      clearIfSuccess: clearIfSuccess ?? this.clearIfSuccess,
    );
  }
}
