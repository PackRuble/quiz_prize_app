import 'package:cardoteka/cardoteka.dart';
import 'package:flutter/material.dart' show Color, Colors, ThemeMode;

class AppStorage extends Cardoteka with WatcherImpl {
  AppStorage() : super(config: AppCard._config);
}

enum AppCard<T extends Object> implements Card<T> {
  themeMode<ThemeMode>(DataType.string, ThemeMode.system),
  themeColor<Color>(DataType.int, Colors.deepPurple),
  ;

  const AppCard(this.type, this.defaultValue);

  @override
  final T defaultValue;

  @override
  String get key => name;

  @override
  final DataType type;

  static const _config = CardotekaConfig(
    name: 'AppCard',
    cards: values,
    converters: {
      themeMode: EnumAsStringConverter(ThemeMode.values),
      themeColor: Converters.colorAsInt,
    },
  );
}
