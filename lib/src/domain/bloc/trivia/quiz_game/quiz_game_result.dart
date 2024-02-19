import '../model/quiz.model.dart';

sealed class QuizGameResult {
  const QuizGameResult();

  const factory QuizGameResult.data(Quiz quiz) = QuizGameData;
  const factory QuizGameResult.loading([String? withMessage]) = QuizGameLoading;
  const factory QuizGameResult.completed([String message]) = QuizGameCompleted;
  const factory QuizGameResult.tryChangeCategory([String message]) =
      QuizGameTryChangeCategory;
  const factory QuizGameResult.tokenExpired([String message]) =
      QuizGameTokenExpired;
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

class QuizGameCompleted extends QuizGameResult {
  const QuizGameCompleted([
    this.message =
        'Congratulations, you have solved all the quizzes for the given category.',
  ]);
  final String message;
}

class QuizGameTryChangeCategory extends QuizGameResult {
  const QuizGameTryChangeCategory([
    this.message = 'Quizzes have ended in this category. '
        'Please choose another category or reset your token.',
  ]);
  final String message;
}

class QuizGameTokenExpired extends QuizGameResult {
  const QuizGameTokenExpired([
    this.message =
        'The token was inactive for 6 hours and expired. Reset your token for a new game.',
  ]);
  final String message;
}

class QuizGameError extends QuizGameResult {
  const QuizGameError(this.message);
  final String message;
}
