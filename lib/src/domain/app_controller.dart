import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/local_storage/app_storage.dart';

class AppProvider extends AppBloc {
  AppProvider._({required super.appStorage});

  static final instance = AutoDisposeProvider(
    (ref) => AppProvider._(
      appStorage: ref.watch(AppStorage.instance),
    ),
  );

  late final themeMode = AutoDisposeProvider(
    (ref) => _appStorage.attach(
      AppCard.themeMode,
      (value) => ref.state = value,
      detacher: ref.onDispose,
    ),
  );

  late final themeColor = AutoDisposeProvider(
    (ref) => _appStorage.attach(
      AppCard.themeColor,
      (value) => ref.state = value,
      detacher: ref.onDispose,
    ),
  );
}

class AppBloc {
  AppBloc({
    required AppStorage appStorage,
  }) : _appStorage = appStorage;

  final AppStorage _appStorage;

  // there are some design issues on high resolution mobile devices
  // const preferredSize = Size(864.0, 684.0);
  final preferredSize = const Size.fromWidth(864.0);

  bool usePreferredSize(Size size) =>
      size.width >= preferredSize.width || size.height >= preferredSize.height;

  // ***************************************************************************
  // theme mode

  Future<void> selectThemeMode(ThemeMode mode) async =>
      _appStorage.set<ThemeMode>(AppCard.themeMode, mode);

  // ***************************************************************************
  // theme color

  Future<void> selectThemeColor(Color color) async =>
      _appStorage.set<Color>(AppCard.themeColor, color);
}
