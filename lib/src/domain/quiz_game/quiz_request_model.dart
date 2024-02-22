import 'package:flutter/foundation.dart' show ValueGetter, immutable;
import 'package:quiz_prize_app/src/domain/bloc/trivia/quiz_config/quiz_config_model.dart';

@immutable
class QuizRequest {
  const QuizRequest({
    required this.quizConfig,
    required this.amountQuizzes,
    this.onlyCache = false,
    this.clearIfSuccess = false,
    this.desiredDelay,
  });

  final QuizConfig quizConfig;
  final int amountQuizzes;
  final bool onlyCache;
  final bool clearIfSuccess;
  final Duration? desiredDelay;

  QuizRequest copyWith({
    QuizConfig? quizConfig,
    int? amountQuizzes,
    bool? onlyCache,
    bool? clearIfSuccess,
    ValueGetter<Duration?>? delay,
  }) {
    return QuizRequest(
      quizConfig: quizConfig ?? this.quizConfig,
      amountQuizzes: amountQuizzes ?? this.amountQuizzes,
      onlyCache: onlyCache ?? this.onlyCache,
      clearIfSuccess: clearIfSuccess ?? this.clearIfSuccess,
      desiredDelay: delay != null ? delay() : desiredDelay,
    );
  }
}
