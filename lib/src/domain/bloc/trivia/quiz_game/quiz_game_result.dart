import '../model/quiz.model.dart';

sealed class QuizGameResult {
  const QuizGameResult();

  const factory QuizGameResult.data(Quiz quiz) = QuizGameData;
  const factory QuizGameResult.loading([String? withMessage]) = QuizGameLoading;
  const factory QuizGameResult.emptyData([String message]) = QuizGameEmptyData;
  const factory QuizGameResult.error(String message) = QuizGameError;
}

class QuizGameData extends QuizGameResult {
  const QuizGameData(this.quiz);
  final Quiz quiz;
}

class QuizGameLoading extends QuizGameResult {
  const QuizGameLoading([this.withMessage]);
  final String? withMessage;
}

class QuizGameEmptyData extends QuizGameResult {
  const QuizGameEmptyData([
    this.message =
        'Congratulations, you have solved all the quizzes for the given category. '
            'Please try other categories or '
            'reset your token for a new game.',
  ]);
  final String message;
}

class QuizGameError extends QuizGameResult {
  const QuizGameError(this.message);
  final String message;
}
