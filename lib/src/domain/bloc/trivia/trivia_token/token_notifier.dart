import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart' show protected;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:quiz_prize_app/src/data/local_storage/token_storage.dart';
import 'package:quiz_prize_app/src/data/trivia/trivia_repository.dart';
import 'package:quiz_prize_app/src/domain/storage_notifiers.dart';

import 'token_model.dart';
import 'token_state.dart';

/// Notifier contains methods for working with the [TokenModel].
class TokenNotifier extends Notifier<TokenState> {
  static final instance = NotifierProvider<TokenNotifier, TokenState>(
    TokenNotifier.new,
  );

  late SecretStorage _storage;
  late TriviaTokenRepository _tokenRepository;

  @override
  TokenState build() {
    _storage = ref.watch(StorageNotifiers.secret);
    _tokenRepository = TriviaTokenRepository(client: http.Client());

    final token = _storage.getOrNull(SecretCards.token);

    log('$this-> $token, valid=${token != null ? _isValidToken(token) : null}');

    return switch (token) {
      null => const TokenState.none(),
      TokenModel() => _isValidToken(token)
          ? TokenState.active(token)
          : TokenState.expired(token),
    };
  }

  /// Local token verification. If the token has not been used, it will be reset
  /// via [TriviaTokenRepository.tokenLifetime].
  bool _isValidToken(TokenModel token) =>
      DateTime.now().difference(token.dateOfRenewal ?? token.dateOfReceipt) <
      TriviaTokenRepository.tokenLifetime;

  /// Get a new token that lives [TriviaTokenRepository.tokenLifetime] time.
  /// The state will be updated reactively.
  ///
  /// - if return true -> token successfully updated
  /// - if return null -> the request was unsuccessful/token not received
  Future<TokenModel?> fetchNewToken() async {
    final result = await _tokenRepository.fetchToken();

    switch (result) {
      case TriviaData<String>(data: final token):
        final newToken = TokenModel(
          dateOfReceipt: DateTime.now(),
          token: token,
        );
        await _storage.set(SecretCards.token, newToken);
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
  /// We simply update [TokenModel.dateOfRenewal] in the token.
  Future<void> extendValidityOfToken() async {
    if (state case TokenActive(:final token)) {
      await _storage.set(
        SecretCards.token,
        token.copyWith(dateOfRenewal: DateTime.now()),
      );
      // we don't need to update the state since the validity of the token
      // is independent of the local date.
      // Although I don't rule out that a different state management should fix this
    }
  }

  /// Reset token on server. Updates the state in case of a request to the server.
  Future<void> resetToken() async {
    final triviaToken = _storage.getOrNull(SecretCards.token) ??
        switch (state) { TokenActive(:final token) => token, _ => null };

    if (triviaToken != null) {
      final result = await _tokenRepository.resetToken(triviaToken.token);

      if (result case TriviaData<bool>(data: final isSuccess)) {
        if (isSuccess) {
          final newToken = TokenModel(
            dateOfReceipt: DateTime.now(),
            token: triviaToken.token,
          );
          await _storage.set(SecretCards.token, newToken);
          state = TokenState.active(newToken);
        } else {
          state = const TokenState.none();
        }
      } else if (result case TriviaError(:final error, :final stack)) {
        log('$TokenNotifier.resetToken -> result is $error, $stack');
        state = TokenState.error('Error during token reset process: $error');
      }
    } else {
      await fetchNewToken();
    }
  }

  @override
  @protected
  String toString() =>
      super.toString().replaceFirst('Instance of ', '').replaceAll("'", '');
}
