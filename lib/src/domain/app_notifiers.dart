import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/local_storage/app_storage.dart';

final class AppNotifiers {
  AppNotifiers._();

  static final themeMode = NotifierProvider<ThemeModeNotifier, ThemeMode>(
    ThemeModeNotifier.new,
    name: '$ThemeModeNotifier',
  );

  static final themeColor = NotifierProvider<ThemeColorNotifier, Color>(
    ThemeColorNotifier.new,
    name: '$ThemeColorNotifier',
  );
}

class ThemeModeNotifier extends Notifier<ThemeMode> {
  late AppStorage _appStorage;

  @override
  ThemeMode build() {
    _appStorage = ref.watch(AppStorage.instance);

    return _appStorage.attach(
      AppCard.themeMode,
      (value) => state = value,
      detacher: ref.onDispose,
      onRemove: null,
    );
  }

  Future<void> changeThemeMode(ThemeMode mode) async =>
      _appStorage.set<ThemeMode>(AppCard.themeMode, mode);
}

class ThemeColorNotifier extends Notifier<Color> {
  late AppStorage _appStorage;

  @override
  Color build() {
    _appStorage = ref.watch(AppStorage.instance);

    return _appStorage.attach(
      AppCard.themeColor,
      (value) => state = value,
      detacher: ref.onDispose,
      onRemove: null,
    );
  }

  Future<void> changeThemeColor(Color color) async =>
      _appStorage.set<Color>(AppCard.themeColor, color);
}
