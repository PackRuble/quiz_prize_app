import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:trivia_app/extension/hex_color.dart';
import 'package:trivia_app/src/data/trivia/model_dto/category/category.dto.dart';
import 'package:trivia_app/src/data/trivia/model_dto/trivia_models.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quiz/trivia_quiz_bloc.dart';
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
    final useScrollNotifier = useState(true);
    final scrollController = useScrollController();
    final useScroll = useScrollNotifier.value;

    bool handleScrollNotification(ScrollMetricsNotification notification) {
      if (notification.metrics.extentAfter == 0.0 &&
          notification.metrics.extentBefore == 0.0) {
        useScrollNotifier.value = true;
      }
      return true;
    }

    final children = <Widget>[
      if (useScroll) const Spacer(),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _ThemeColorSelector(),
          Expanded(
            child: Text(
              'Trivia Quiz',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall, // todo shadow
            ),
          ),
          const _ThemeModeSelector(),
        ],
      ),
      if (useScroll) const Spacer(),
      const SizedBox(height: 8),
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
      if (useScroll)
        Flexible(
          child: LayoutBuilder(
            builder: (context, constraints) {
              WidgetsBinding.instance.addPostFrameCallback((dur) {
                if (constraints.maxHeight == 0) useScrollNotifier.value = false;
              });

              return const SizedBox(height: 32);
            },
          ),
        ),
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
      if (useScroll) const Spacer(flex: 3),
      const _ShieldsBar(),
      const _InfoWidget(),
    ];

    final child = Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: children,
    );

    return Scaffold(
      body: CardPad(
        child: useScroll
            ? child
            : NotificationListener<ScrollMetricsNotification>(
                onNotification: handleScrollNotification,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: child,
                ),
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
    final bloc = ref.watch(TriviaQuizProvider.instance);
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
    final bloc = ref.watch(TriviaQuizProvider.instance);
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
          error: (error, _) => [ListTile(title: Text('$error'))],
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
          onPressed: () => launch(Uri.https('habr.com', 'ru/users/PackRuble')),
          icon: Icon(
            SimpleIcons.habr,
            color: ColorHex.fromHex('#65A3BE'), // corporate color
          ),
        ),
      ],
    );
  }
}

class _InfoWidget extends StatelessWidget {
  const _InfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      children: [
        Text(
          '© 2023 by Ruble',
          style: textTheme.labelMedium,
        ),
        const SizedBox(width: 150, child: Divider(height: 4)),
        Text(
          'Open Trivia Database',
          style: textTheme.labelSmall,
        ),
        InkWell(
          onTap: () async => launchUrl(
            Uri.https('opentdb.com'),
            mode: LaunchMode.externalNonBrowserApplication,
          ),
          child: Text(
            'opentdb.com',
            style: textTheme.labelSmall?.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: Colors.blue,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}
