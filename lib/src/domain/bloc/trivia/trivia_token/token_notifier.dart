import 'dart:async';
import 'dart:developer';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_app/src/data/local_storage/game_storage.dart';
import 'package:trivia_app/src/data/trivia/trivia_repository.dart';

import 'token_state.dart';
import 'trivia_token_model.dart';

/// Notifier contains methods for working with the [TriviaToken].
///
class TokenNotifier extends Notifier<TokenState> {
  static final instance = NotifierProvider<TokenNotifier, TokenState>(
    TokenNotifier.new,
  );

  late GameStorage _storage;
  late TriviaTokenRepository _tokenRepository;

  @override
  TokenState build() {
    _storage = ref.watch(GameStorage.instance);
    _tokenRepository = TriviaTokenRepository(client: http.Client());

    final token = _storage.getOrNull(GameCard.token);

    return switch (token) {
      null => const TokenState.none(),
      TriviaToken() => isValidToken(token)
          ? TokenState.active(token)
          : TokenState.expired(token),
    };
  }

  /// Local token verification. If the token has not been used, it will be reset
  /// via [TriviaTokenRepository.tokenLifetime].
  bool isValidToken(TriviaToken token) =>
      (token.dateOfRenewal ?? token.dateOfReceipt).difference(DateTime.now()) <
      TriviaTokenRepository.tokenLifetime;

  /// Get a new token that lives [TriviaTokenRepository.tokenLifetime] time.
  /// The state will be updated reactively.
  ///
  /// - if return true -> token successfully updated
  /// - if return null -> the request was unsuccessful/token not received
  Future<TriviaToken?> fetchNewToken() async {
    final result = await _tokenRepository.fetchToken();

    switch (result) {
      case TriviaData<String>(data: final token):
        final newToken = TriviaToken(
          dateOfReceipt: DateTime.now(),
          token: token,
        );
        await _storage.set(GameCard.token, newToken);
        state = TokenState.active(newToken);
        return newToken;
      case TriviaExceptionApi(:final exception):
        log('$TokenNotifier.updateToken -> result is $exception');

        state = TokenState.error(
          'An exception occurred as a result of receiving a new token: $exception',
        );
      case TriviaError(:final error, :final stack):
        log('$TokenNotifier.updateToken -> result is $error, $stack');
        state = TokenState.error(
          'An error occurred as a result of receiving a new token: $error',
        );
    }

    return null;
  }

  /// According to Trivia API, a token is considered renewed if it was used
  /// to make a request to receive quizzes.
  ///
  /// We simply update [TriviaToken.dateOfRenewal] in the token.
  Future<void> extendValidityOfToken() async {
    if (state case TokenActive(:final token)) {
      await _storage.set(
        GameCard.token,
        token.copyWith(dateOfRenewal: DateTime.now()),
      );
    }
  }

  /// Reset token on server. Updates the state in case of a request to the server.
  Future<void> resetToken() async {
    final triviaToken = _storage.getOrNull(GameCard.token) ??
        switch (state) { TokenActive(:final token) => token, _ => null };

    if (triviaToken != null) {
      final result = await _tokenRepository.resetToken(triviaToken.token);

      if (result case TriviaData<bool>(data: final isSuccess)) {
        if (isSuccess) {
          final newToken = TriviaToken(
            dateOfReceipt: DateTime.now(),
            token: triviaToken.token,
          );
          await _storage.set(GameCard.token, newToken);
          state = TokenState.active(newToken);
        } else {
          state = const TokenState.none();
        }
      } else if (result case TriviaError(:final error, :final stack)) {
        log('$TokenNotifier.resetToken -> result is $error, $stack');
        state = TokenState.error('Error during token reset process: $error');
      }
    }
  }
}
