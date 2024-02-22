import 'dart:convert';

import 'package:cardoteka/cardoteka.dart';
import 'package:quiz_prize_app/src/domain/bloc/trivia/trivia_token/token_model.dart';

/// Please note that this storage will not use [Watcher].
class SecretStorage extends Cardoteka {
  SecretStorage() : super(config: SecretCards._config);
}

/// [Card]s related with secret data.
enum SecretCards<T> implements Card<T> {
  token<TokenModel?>(DataType.string, null),
  ;

  const SecretCards(this.type, this.defaultValue);

  @override
  final T defaultValue;

  @override
  String get key => name;

  @override
  final DataType type;

  static const _config = CardotekaConfig(
    name: 'secrets',
    cards: values,
    converters: {
      token: _TokenConverter(),
    },
  );
}

class _TokenConverter extends Converter<TokenModel, String> {
  const _TokenConverter();

  @override
  TokenModel from(String element) =>
      TokenModel.fromJson(jsonDecode(element) as Map<String, dynamic>);

  @override
  String to(TokenModel object) => jsonEncode(object.toJson());
}
