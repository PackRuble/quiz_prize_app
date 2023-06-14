import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_app/src/data/local_storage/app_storage.dart';

class AppController {
  AppController._({
    required AppStorage appStorage,
  }) : _appStorage = appStorage;

  static final instance = AutoDisposeProvider(
    (ref) => AppController._(
      appStorage: ref.watch(AppStorage.instance),
    ),
  );

  final AppStorage _appStorage;

  // there are some design issues on high resolution mobile devices
  // const preferredSize = Size(864.0, 684.0);
  final preferredSize = const Size.fromWidth(864.0);

  bool usePreferredSize(Size size) =>
      size.width >= preferredSize.width || size.height >= preferredSize.height;

  // ***************************************************************************
  // theme mode

  late final themeMode = AutoDisposeProvider(
    (ref) => _appStorage.attach(
      AppCard.themeMode,
      (value) => ref.state = value,
      detacher: ref.onDispose,
    ),
  );

  Future<void> selectThemeMode(ThemeMode mode) async =>
      _appStorage.set<ThemeMode>(AppCard.themeMode, mode);

  // ***************************************************************************
  // theme color

  late final themeColor = AutoDisposeProvider(
    (ref) => _appStorage.attach(
      AppCard.themeColor,
      (value) => ref.state = value,
      detacher: ref.onDispose,
    ),
  );

  Future<void> selectThemeColor(Color color) async =>
      _appStorage.set<Color>(AppCard.themeColor, color);
}
