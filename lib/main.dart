import 'dart:async';

import 'package:cardoteka/cardoteka.dart';
import 'package:flutter/foundation.dart' show PlatformDispatcher, kDebugMode;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'src/domain/app_notifiers.dart';
import 'src/ui/const/app_size.dart';
import 'src/ui/game/game_page.dart';
import 'src/ui/home/home_page.dart';
import 'src/ui/shared/background.dart';
import 'src/ui/stats/stats_page.dart';

void log(
  Object? message, {
  required Object error,
  StackTrace? stackTrace,
}) {
  if (kDebugMode) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        context: ErrorDescription(message.toString()),
      ),
    );
  }
}

void main() async {
  await runZonedGuarded(body, (error, stack) {
    log('runZonedGuarded:', error: error, stackTrace: stack);
  });
}

Future<void> body() async {
  // platform error logging
  PlatformDispatcher.instance.onError = (error, stack) {
    log('PlatformDispatcher Error', error: error, stackTrace: stack);
    return true;
  };

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
    final size = MediaQuery.sizeOf(context);
    final isPreferredSize = AppSize.isPreferredSize(size);

    final themeColor = ref.watch(AppNotifiers.themeColor);
    final themeMode = ref.watch(AppNotifiers.themeMode);

    const transitions = FadeUpwardsPageTransitionsBuilder();
    final Map<TargetPlatform, PageTransitionsBuilder> buildersTransitions =
        isPreferredSize
            ? {for (final pl in TargetPlatform.values) pl: transitions}
            : {};

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
          _ => MediaQuery.platformBrightnessOf(context),
        },
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(seconds: 1),
      ),
    );

    return MaterialApp(
      title: 'Trivia App',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      localeResolutionCallback: (locale, _) => locale ?? const Locale('en'),
      theme: themeData,
      themeMode: themeMode,
      builder: (context, child) {
        final scrollBehavior = ScrollConfiguration.of(context);

        return ResponsiveWindow(
          child: SafeArea(
            child: ScrollConfiguration(
              behavior: scrollBehavior.copyWith(
                dragDevices: {
                  ...scrollBehavior.dragDevices,
                  PointerDeviceKind.mouse,
                },
              ),
              child: child!,
            ),
          ),
        );
      },
      initialRoute: HomePage.path,
      routes: <String, WidgetBuilder>{
        HomePage.path: (context) => const HomePage(),
        GamePage.path: (context) => const GamePage(),
        StatsPage.path: (context) => const StatsPage(),
      },
    );
  }
}
