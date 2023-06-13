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
  //
}
