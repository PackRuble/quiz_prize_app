import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_app/src/data/local_storage/game_storage.dart';
import 'package:trivia_app/src/data/trivia/trivia_repository.dart';

@immutable
class TriviaToken {
  const TriviaToken({
    required this.token,
    required this.dateOfReceipt,
    this.dateOfRenewal,
  });

  final String token;
  final DateTime dateOfReceipt;
  final DateTime? dateOfRenewal;

  @override
  String toString() {
    return 'TriviaToken{ token: $token, dateOfReceipt: $dateOfReceipt, dateOfRenewal: $dateOfRenewal }';
  }

  TriviaToken copyWith({DateTime? dateOfRenewal}) {
    return TriviaToken(
      token: token,
      dateOfReceipt: dateOfReceipt,
      dateOfRenewal: dateOfRenewal ?? this.dateOfRenewal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'dateOfReceipt': dateOfReceipt,
      'dateOfRenewal': dateOfRenewal,
    };
  }

  factory TriviaToken.fromJson(Map<String, dynamic> map) {
    return TriviaToken(
      token: map['token'] as String,
      dateOfReceipt: map['dateOfReceipt'] as DateTime,
      dateOfRenewal: map['dateOfRenewal'] as DateTime?,
    );
  }
}

/// Notifier contains methods for working with the [TriviaToken].
class TokenNotifier extends Notifier<TriviaToken?> {
  static final instance = NotifierProvider<TokenNotifier, TriviaToken?>(
    TokenNotifier.new,
  );

  late GameStorage _storage;
  late TriviaTokenRepository _tokenRepository;

  @override
  TriviaToken? build() {
    _tokenRepository = TriviaTokenRepository(client: http.Client());

    return _storage.attach(
      GameCard.token,
      (value) => state = value,
      detacher: ref.onDispose,
      onRemove: () => state = null,
    );
  }

  /// Local token verification. If the token has not been used, it will be reset
  /// via [TriviaTokenRepository.tokenLifetime].
  bool isValidToken() {
    final token = state;
    if (token == null) return false;

    final date = token.dateOfRenewal ?? token.dateOfReceipt;
    return date.difference(DateTime.now()) <
        TriviaTokenRepository.tokenLifetime;
  }

  /// Get a new token that lives [TriviaTokenRepository.tokenLifetime] time.
  ///
  /// if return true -> token successfully updated
  /// if return false -> the request was unsuccessful/token not received
  Future<bool> updateToken() async {
    final result = await _tokenRepository.fetchToken();

    final bool isSuccess;
    switch (result) {
      case TriviaData<String>(data: final token):
        await _storage.set(
          GameCard.token,
          TriviaToken(dateOfReceipt: DateTime.now(), token: token),
        );
        isSuccess = true;
      case TriviaExceptionApi(:final exception):
        log('$TokenNotifier.updateToken -> result is $exception');
        isSuccess = false;
      case TriviaError(:final error, :final stack):
        log('$TokenNotifier.updateToken -> result is $error, $stack');
        isSuccess = false;
    }

    return isSuccess;
  }

  /// Reset token on server.
  ///
  /// if return null -> the request was unsuccessful/token not reset
  /// if return true -> token successfully reset
  /// if return false -> token was not found (possibly reset earlier)
  Future<bool?> resetToken() async {
    final token = state;
    if (token == null) return false;

    final result = await _tokenRepository.resetToken(token.token);
    await _storage.setOrNull<TriviaToken>(GameCard.token, null);

    final bool? isSuccess;
    switch (result) {
      case TriviaData<bool>(data: final success):
        isSuccess = success;
      case TriviaExceptionApi(:final exception):
        log('$TokenNotifier.resetToken -> result is $exception');
        isSuccess = null;
      case TriviaError(:final error, :final stack):
        log('$TokenNotifier.resetToken -> result is $error, $stack');
        isSuccess = null;
    }

    return isSuccess;
  }
}
