import '../model/quiz.model.dart';

sealed class TriviaQuizResult {
  const TriviaQuizResult();

  const factory TriviaQuizResult.data(Quiz data) = TriviaQuizData;
  const factory TriviaQuizResult.emptyData([String message]) = TriviaQuizEmptyData;
  const factory TriviaQuizResult.error(String message) = TriviaQuizError;
}

class TriviaQuizData extends TriviaQuizResult {
  const TriviaQuizData(this.data);
  final Quiz data;
}

class TriviaQuizEmptyData extends TriviaQuizResult {
  const TriviaQuizEmptyData([
    this.message = 'Congratulations, you have solved all the quizzes for the given category. '
        'Please try other categories or '
        'reset your token for a new game.',
  ]);
  final String message;
}

class TriviaQuizError extends TriviaQuizResult {
  const TriviaQuizError(this.message);
  final String message;
}
