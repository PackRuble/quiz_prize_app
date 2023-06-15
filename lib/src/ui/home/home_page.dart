import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:trivia_app/extension/hex_color.dart';
import 'package:trivia_app/src/data/trivia/category/category.dto.dart';
import 'package:trivia_app/src/data/trivia/models.dart';
import 'package:trivia_app/src/domain/bloc/trivia_quiz/trivia_quiz_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../game/game_page.dart';
import '../shared/cardpad.dart';
import '../stats/stats_page.dart';
import 'home_page_ctrl.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  static const path = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CardPad(
        child: Column(
          // if that's not enough - use SingleChildScrollView
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _ThemeColorSelector(),
                Expanded(
                  child: Text(
                    'Trivia Quiz',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
                const _ThemeModeSelector(), // todo: add color selector
              ],
            ),
            const Spacer(),
            _ChapterButton(
              chapter: 'Play',
              onTap: () async {
                await Navigator.of(context).pushNamed(GamePage.path);
              },
            ),
            const SizedBox(height: 12),
            _ChapterButton(
              chapter: 'Statistics',
              onTap: () {
                unawaited(Navigator.of(context).pushNamed(StatsPage.path));
              },
            ),
            const SizedBox(height: 12),
            const Flexible(
              flex: 2,
              child: SizedBox(height: 32),
            ),
            // SizedBox(height: 44)),
            const _CategoryButton(),
            const SizedBox(height: 12),
            const FittedBox(
              fit: BoxFit.scaleDown,
              child: _DifficultyButton(),
            ),
            const SizedBox(height: 12),
            const FittedBox(
              fit: BoxFit.scaleDown,
              child: _QuizTypeSelector(),
            ),
            const Spacer(flex: 3),
            const _ShieldsBar(),
            const _InfoWidget(),
          ],
        ),
      ),
    );
  }
}

class _ChapterButton extends ConsumerWidget {
  const _ChapterButton({
    super.key,
    required this.onTap,
    required this.chapter,
  });

  final VoidCallback onTap;
  final String chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FilledButton.tonal(
        style: const ButtonStyle(
          padding: MaterialStatePropertyAll(EdgeInsets.all(18)),
        ),
        onPressed: onTap,
        child: Text(
          chapter,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      );
}

class _ThemeModeSelector extends ConsumerWidget {
  const _ThemeModeSelector({
    super.key,
  });

  static const themeModes = <ThemeMode, IconData>{
    ThemeMode.light: Icons.light_mode_rounded,
    ThemeMode.dark: Icons.dark_mode_rounded,
    ThemeMode.system: Icons.contrast_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageCtrl = ref.watch(HomePageCtrl.instance);
    final themeMode = ref.watch(pageCtrl.themeMode);

    void nextMode() {
      final mode =
          themeModes.keys.toList()[themeMode.index % themeModes.keys.length];

      unawaited(pageCtrl.selectThemeMode(mode));
    }

    return IconButton(
      onPressed: nextMode,
      icon: Icon(themeModes[themeMode]),
    );
  }
}

class _ThemeColorSelector extends ConsumerWidget {
  const _ThemeColorSelector({
    super.key,
  });

  static const colors = Colors.primaries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageCtrl = ref.watch(HomePageCtrl.instance);
    final color = ref.watch(pageCtrl.themeColor);

    void nextMode() {
      var index = colors.indexWhere((element) => element.value == color.value);

      unawaited(
        pageCtrl.selectThemeColor(colors[++index % colors.length]),
      );
    }

    return IconButton(
      onPressed: nextMode,
      icon: Icon(color: color, Icons.circle_rounded),
    );
  }
}

class _QuizTypeSelector extends ConsumerWidget {
  const _QuizTypeSelector({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bloc = ref.watch(TriviaQuizBloc.instance);
    final type = ref.watch(bloc.quizType);

    return SegmentedButton<TriviaQuizType>(
      segments: TriviaQuizType.values
          .map(
            (e) => ButtonSegment<TriviaQuizType>(
              value: e,
              label: Text(e.name),
            ),
          )
          .toList(),
      selected: {type},
      onSelectionChanged: (selected) {
        unawaited(bloc.setQuizType(selected.single));
      },
    );
  }
}

class _DifficultyButton extends ConsumerWidget {
  const _DifficultyButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bloc = ref.watch(TriviaQuizBloc.instance);
    final difficulty = ref.watch(bloc.quizDifficulty);

    return SegmentedButton<TriviaQuizDifficulty>(
      segments: TriviaQuizDifficulty.values
          .map(
            (e) => ButtonSegment<TriviaQuizDifficulty>(
              value: e,
              label: Text(e.name),
            ),
          )
          .toList(),
      selected: {difficulty},
      onSelectionChanged: (selected) {
        unawaited(bloc.setQuizDifficulty(selected.single));
      },
    );
  }
}

class _CategoryButton extends ConsumerWidget {
  const _CategoryButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageCtrl = ref.watch(HomePageCtrl.instance);
    final current = ref.watch(pageCtrl.currentCategory);

    return FilledButton.tonal(
      style: const ButtonStyle(
        splashFactory: NoSplash.splashFactory,
        overlayColor: MaterialStatePropertyAll(Colors.transparent),
        padding: MaterialStatePropertyAll(EdgeInsets.all(18)),
      ),
      onPressed: () {},
      child: Column(
        children: [
          Text(
            current.name,
            textAlign: TextAlign.center,
          ),
          const SizedBox(width: 200, child: Divider(height: 4)),
          TextButton(
            child: const Text(
              'Select category',
              textAlign: TextAlign.center,
            ),
            onPressed: () async {
              await showModalBottomSheet(
                constraints: const BoxConstraints.expand(
                  width: double.infinity,
                ),
                showDragHandle: true,
                context: context,
                builder: (_) => const _FetchedCategories(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FetchedCategories extends ConsumerWidget {
  const _FetchedCategories({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageCtrl = ref.watch(HomePageCtrl.instance);
    final categories = ref.watch(pageCtrl.fetchedCategories);
    final current = ref.watch(pageCtrl.currentCategory);

    return ListView(
      children: [
        _CategoryTile(
          leading: 'Current:',
          title: current.name,
          selected: true,
          onTap: null,
          trailing: IconButton(
            icon: const Icon(Icons.cloud_sync_rounded),
            onPressed: pageCtrl.reloadCategories,
          ),
        ),
        const Divider(height: 0.0),
        ...categories.when<List<Widget>>(
          data: (data) => [CategoryDTO.any, ...data].map(
            (category) {
              if (category == current) return const SizedBox.shrink();

              return _CategoryTile(
                onTap: () {
                  unawaited(pageCtrl.selectCategory(category));
                  Navigator.of(context).pop();
                },
                selected: false,
                title: category.name,
              );
            },
          ).toList(),
          error: (error, stackTrace) => [Text('$error')],
          loading: () => [const LinearProgressIndicator()],
        ),
      ],
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({
    super.key,
    this.leading,
    this.trailing,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String? leading;
  final Widget? trailing;
  final String title;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      dense: true,
      selected: selected,
      leading: leading != null ? Text(leading!) : null,
      trailing: trailing,
      title: Text(title),
      onTap: onTap,
    );
  }
}

class _ShieldsBar extends HookConsumerWidget {
  const _ShieldsBar({
    super.key,
  });

  void launch(Uri uri) {
    unawaited(
      launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => launch(Uri.https('t.me', 'rublepack')),
          icon: Icon(
            SimpleIcons.telegram,
            color: ColorHex.fromHex('#26A5E4'), // corporate color
          ),
        ),
        IconButton(
          onPressed: () =>
              launch(Uri.https('github.com', 'PackRuble/trivia_app')),
          icon: Icon(
            SimpleIcons.github,
            color: ColorHex.fromHex('#181717'), // corporate color
          ),
        ),
        IconButton(
          onPressed: () => launch(Uri.https('habr.com', 'ru/users/PackRuble/')),
          icon: Icon(
            SimpleIcons.habr,
            color: ColorHex.fromHex('#65A3BE'), // corporate color
          ),
        ),
        // todo: add others
      ],
    );
  }
}

class _InfoWidget extends StatelessWidget {
  const _InfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('© 2023 by Ruble');
  }
}
