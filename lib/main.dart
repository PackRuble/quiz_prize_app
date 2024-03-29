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

  WidgetsFlutterBinding.ensureInitialized();
  await Cardoteka.init();

  runApp(const ProviderScope(child: QuizPrizeApp()));
}

class QuizPrizeApp extends ConsumerWidget {
  const QuizPrizeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final isPreferredSize = AppSize.isPreferredSize(size);

    final themeColor = ref.watch(AppNotifiers.themeColor);
    final themeMode = ref.watch(AppNotifiers.themeMode);

    const fadeUpTransitions = FadeUpwardsPageTransitionsBuilder();
    const zoomTransitions = ZoomPageTransitionsBuilder(
      // fixdep(22.02.2024): [Unexpected Ink Splash with Material3 when navigating · Issue #119897 · flutter/flutter](https://github.com/flutter/flutter/issues/119897)
      // this eliminates the button "blinking" but looks sharper
      allowEnterRouteSnapshotting: false,
    );
    final Map<TargetPlatform, PageTransitionsBuilder> buildersTransitions = {
      for (final platform in TargetPlatform.values)
        if (isPreferredSize)
          platform: fadeUpTransitions
        else if (platform case TargetPlatform.android)
          platform: zoomTransitions,
    };

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
      title: 'Quiz Prize',
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
