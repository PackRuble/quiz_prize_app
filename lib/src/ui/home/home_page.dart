import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:trivia_app/src/data/local_storage/game_storage.dart';
import 'package:trivia_app/src/data/trivia/models.dart';
import 'package:trivia_app/src/domain/bloc/trivia_quiz/trivia_quiz_bloc.dart';
import 'package:trivia_app/src/ui/game/game_page.dart';

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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Супер Игра'),
                  Spacer(),
                  Column(
                    children: [
                      _ChapterButton(
                        chapter: 'Play',
                        onTap: () async {
                          await Navigator.of(context).pushNamed(GamePage.path);
                        },
                      ),
                      const SizedBox(height: 10),
                      const _CategoryButton(),
                      const SizedBox(height: 10),
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _DifficultyButton(),
                      ),
                      const SizedBox(height: 10),
                      _ChapterButton(
                        chapter: 'Statistics',
                        onTap: () async {
                          // await Navigator.of(context).pushNamed(GamePage.path);
                        },
                      ),
                    ],
                  ),
                  Spacer(),
                  Row(
                    children: [CircleAvatar(radius: 12), _Shield()],
                  ),
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () async {
        await showModalBottomSheet(
          constraints: BoxConstraints.expand(
            width: double.infinity,
          ),
          showDragHandle: true,
          context: context,
          builder: (context) {
            return Column(
              children: [
                Text('Категория 1'),
              ],
            );
          },
        );
      },
      child: Text('Текущая категория'),
    );
  }
}

class _Shield extends HookConsumerWidget {
  const _Shield({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = 'https://cdn.simpleicons.org/telegram/2DABE7';

    return Row(
      children: [
        SvgPicture.network(
          link,
          width: 28,
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(SimpleIcons.telegram),
        ),
      ],
    );
  }
}
