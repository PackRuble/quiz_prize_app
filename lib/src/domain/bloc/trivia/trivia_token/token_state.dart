import 'trivia_token_model.dart';

sealed class TokenState {
  const TokenState();

  const factory TokenState.active(TriviaToken token) = TokenActive;
  const factory TokenState.expired(TriviaToken token) = TokenExpired;
  const factory TokenState.none() = TokenNone;
  const factory TokenState.error(String message) = TokenError;
}

class TokenActive extends TokenState {
  const TokenActive(this.token);

  final TriviaToken token;
}

class TokenExpired extends TokenState {
  const TokenExpired(this.token);

  final TriviaToken token;
}

class TokenEmptySession extends TokenState {
  const TokenEmptySession(this.token);

  final TriviaToken token;
}

class TokenNone extends TokenState {
  const TokenNone();
}

class TokenError extends TokenState {
  const TokenError(this.message);
  final String message;
}