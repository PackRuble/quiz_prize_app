import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/local_storage/app_storage.dart';

//
// class ThemeModeNotifier extends Notifier<ThemeMode> {
//   static final instance = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
//
//   late AppStorage _appStorage;
//
//   @override
//   ThemeMode build() {
//     _appStorage = ref.watch(AppStorage.instance);
//
//     return _appStorage.attach(
//       AppCard.themeMode,
//       (value) => state = value,
//       detacher: ref.onDispose,
//     );
//   }
//
//   Future<void> changeThemeMode(ThemeMode mode) async =>
//       _appStorage.set<ThemeMode>(AppCard.themeMode, mode);
// }

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

  // static final themeMode = AutoDisposeProvider(
  //   (ref) => ref.watch(instance)._appStorage.attach(
  //         AppCard.themeMode,
  //         (value) => ref.state = value,
  //         detacher: ref.onDispose,
  //       ),
  // );

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

  final preferredSize = const Size(684.0, 864.0);

  bool isPreferredSize(Size size) =>
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
