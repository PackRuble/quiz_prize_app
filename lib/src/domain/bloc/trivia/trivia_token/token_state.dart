import 'token_model.dart';

sealed class TokenState {
  const TokenState();

  const factory TokenState.active(TokenModel token) = TokenActive;
  const factory TokenState.expired(TokenModel token) = TokenExpired;
  const factory TokenState.none() = TokenNone;
  const factory TokenState.error(String message) = TokenError;
}

class TokenActive extends TokenState {
  const TokenActive(this.token);

  final TokenModel token;
}

class TokenExpired extends TokenState {
  const TokenExpired(this.token);

  final TokenModel token;
}

class TokenEmptySession extends TokenState {
  const TokenEmptySession(this.token);

  final TokenModel token;
}

class TokenNone extends TokenState {
  const TokenNone();
}

class TokenError extends TokenState {
  const TokenError(this.message);
  final String message;
}
