import 'dart:async';

import 'package:cardoteka/cardoteka.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/ui/game/game_page.dart';
import 'src/ui/home/home_page.dart';

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
  // логгирование ошибок flutter framework
  FlutterError.onError = (details) {
    log('Flutter Error', error: details.exception, stackTrace: details.stack);
  };

  // логгирование ошибок платформы
  PlatformDispatcher.instance.onError = (error, stack) {
    log('PlatformDispatcher Error', error: error, stackTrace: stack);
    return true;
  };

  await Cardoteka.init();

  void body() => runApp(
        const ProviderScope(
          // overrides: [
          //   gameStorageProvider.overrideWithValue(gameStorage),
          // ],
          child: MyApp(),
        ),
      );

  runZonedGuarded(body, (error, stack) {
    log('runZonedGuarded:', error: error, stackTrace: stack);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trivia App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: HomePage.path,
      builder: (context, child) => ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: child!,
      ),
      routes: <String, WidgetBuilder>{
        HomePage.path: (context) => const HomePage(),
        GamePage.path: (context) => const GamePage(),
      },
    );
  }
}
