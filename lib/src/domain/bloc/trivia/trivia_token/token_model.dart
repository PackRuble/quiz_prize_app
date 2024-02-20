import 'package:cardoteka/cardoteka.dart' show Converters;
import 'package:flutter/foundation.dart' show immutable;

@immutable
class TokenModel {
  const TokenModel({
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

  TokenModel copyWith({DateTime? dateOfRenewal}) {
    return TokenModel(
      token: token,
      dateOfReceipt: dateOfReceipt,
      dateOfRenewal: dateOfRenewal ?? this.dateOfRenewal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'dateOfReceipt': _dateConverter.to(dateOfReceipt),
      'dateOfRenewal':
          dateOfRenewal != null ? _dateConverter.to(dateOfRenewal!) : null,
    };
  }

  factory TokenModel.fromJson(Map<String, dynamic> map) {
    final dateOfRenewal = map['dateOfRenewal'] as String?;
    return TokenModel(
      token: map['token'] as String,
      dateOfReceipt: _dateConverter.from(map['dateOfReceipt'] as String),
      dateOfRenewal:
          dateOfRenewal != null ? _dateConverter.from(dateOfRenewal) : null,
    );
  }

  static const _dateConverter = Converters.dateTimeAsString;
}
