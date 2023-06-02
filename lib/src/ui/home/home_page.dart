import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:trivia_app/extension/hex_color.dart';
import 'package:trivia_app/src/data/local_storage/game_storage.dart';
import 'package:trivia_app/src/data/trivia/models.dart';
import 'package:trivia_app/src/domain/bloc/trivia_quiz/trivia_quiz_bloc.dart';
import 'package:trivia_app/src/ui/game/game_page.dart';

import 'home_page_ctrl.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  static const path = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: SizedBox(
          width: double.infinity,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                // if that's not enough - use SingleChildScrollView
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Spacer(),
                  Text(
                    'Trivia Quiz',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
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
                    onTap: () async {
                      // await Navigator.of(context).pushNamed(GamePage.path);
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
                  const Spacer(flex: 3),
                  const _ShieldsBar(),
                  const _InfoWidget(),
                ],
              ),
            ),
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
        unawaited(bloc.storage.set(GameCard.quizDifficulty, selected.single));
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
          onTap: () {},
          trailing: IconButton(
            icon: const Icon(Icons.cloud_sync_rounded),
            onPressed: pageCtrl.reloadCategories,
          ),
        ),
        const Divider(height: 0.0),
        ...categories.when<List<Widget>>(
          data: (data) => (data..remove(current))
              .map(
                (category) => _CategoryTile(
                  onTap: () {
                    unawaited(pageCtrl.selectCategory(category));
                    Navigator.of(context).pop();
                  },
                  selected: false,
                  title: category.name,
                ),
              )
              .toList(),
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
  final VoidCallback onTap;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {},
          icon: Icon(
            SimpleIcons.telegram,
            color: ColorHex.fromHex('#26A5E4'), // corporate color
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            SimpleIcons.github,
            color: ColorHex.fromHex('#181717'), // corporate color
          ),
        ),
        IconButton(
          onPressed: () {},
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
