import 'model/quiz.model.dart';

sealed class TriviaQuizResult {
  const TriviaQuizResult();

  const factory TriviaQuizResult.data(Quiz data) = TriviaQuizResultData;
  const factory TriviaQuizResult.emptyData([String message]) =
      TriviaQuizResultEmptyData;
  const factory TriviaQuizResult.error(String message) = TriviaQuizResultError;
}

class TriviaQuizResultData extends TriviaQuizResult {
  const TriviaQuizResultData(this.data);
  final Quiz data;
}

class TriviaQuizResultEmptyData extends TriviaQuizResult {
  const TriviaQuizResultEmptyData([
    this.message =
        'Congratulations, you have solved all the quizzes for the given category. '
            'Please try other categories or '
            'reset your token for a new game.',
  ]);
  final String message;
}

class TriviaQuizResultError extends TriviaQuizResult {
  const TriviaQuizResultError(this.message);
  final String message;
}
