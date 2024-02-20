import '../../domain/bloc/trivia/quizzes/model/quiz.model.dart';

sealed class GamePageState {
  const GamePageState();
}

class GamePageData extends GamePageState {
  const GamePageData(this.data);
  final Quiz data;
}

class GamePageLoading extends GamePageState {
  const GamePageLoading([this.message]);

  final String? message;
}

class GamePageCongratulation extends GamePageState {
  const GamePageCongratulation(this.message);
  final String message;
}

class GamePageNewToken extends GamePageState {
  const GamePageNewToken(this.message);
  final String message;
}

class GamePageNewTokenOrChangeCategory extends GamePageState {
  const GamePageNewTokenOrChangeCategory(this.message);
  final String message;
}

class GamePageError extends GamePageState {
  const GamePageError(this.message);
  final String message;
}
