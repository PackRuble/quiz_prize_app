import 'dart:async';

import 'package:cardoteka/cardoteka.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'src/domain/app_controller.dart';
import 'src/ui/game/game_page.dart';
import 'src/ui/home/home_page.dart';
import 'src/ui/shared/background.dart';
import 'src/ui/stats/stats_page.dart';

void log(
  String name, {
  required Object error,
  StackTrace? stackTrace,
}) {
  print(name);
  print(error);
  print(stackTrace);
}

void main() async {
  await runZonedGuarded(body, (error, stack) {
    log('runZonedGuarded:', error: error, stackTrace: stack);
  });
}

Future<void> body() async {
  // логгирование ошибок flutter framework
  FlutterError.onError = (details) {
    log('Flutter Error', error: details.exception, stackTrace: details.stack);
  };

  // логгирование ошибок платформы
  PlatformDispatcher.instance.onError = (error, stack) {
    log('PlatformDispatcher Error', error: error, stackTrace: stack);
    return true;
  };

  // todo the extremely important thing to add to the redmi db
  WidgetsFlutterBinding.ensureInitialized();
  await Cardoteka.init();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSize = MediaQuery.of(context).size;

    final appController = ref.watch(AppController.instance);
    final usePreferredSize = appController.usePreferredSize(currentSize);

    const transitions = FadeUpwardsPageTransitionsBuilder();
    final Map<TargetPlatform, PageTransitionsBuilder> buildersTransitions =
        usePreferredSize
            ? {for (var pl in TargetPlatform.values) pl: transitions}
            : {};

    final themeMode = ref.watch(appController.themeMode);
    final themeColor = ref.watch(appController.themeColor);

    final themeData = ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: buildersTransitions,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeColor,
        brightness: switch (themeMode) {
          ThemeMode.light => Brightness.light,
          ThemeMode.dark => Brightness.dark,
          // _ => Theme.of(context).brightness,
          _ => MediaQuery.of(context).platformBrightness,
        },
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(seconds: 1),
      ),
    );

    return MaterialApp(
      title: 'Trivia App',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      themeMode: themeMode,
      initialRoute: HomePage.path,
      builder: (context, child) {
        return ResponsiveWindow(
          child: SafeArea(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: child!,
            ),
          ),
        );
      },
      routes: <String, WidgetBuilder>{
        HomePage.path: (context) => const HomePage(),
        GamePage.path: (context) => const GamePage(),
        StatsPage.path: (context) => const StatsPage(),
      },
    );
  }
}
