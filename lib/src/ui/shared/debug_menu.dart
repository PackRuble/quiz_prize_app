import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quiz/trivia_quiz_bloc.dart';

import 'cardpad.dart';

class DebugDialog extends ConsumerWidget {
  const DebugDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final triviaProvider = ref.watch(TriviaQuizProvider.instance);
    final cachedQuizzesCount = ref.watch(triviaProvider.quizzes).length;

    return AlertDialog.adaptive(
      title: const Text('Debug menu'),
      content: SingleChildScrollView(
        child: CardPad(
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              ListTile(
                title: const Text('Cached quizzes'),
                trailing: Text(cachedQuizzesCount.toString()),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}
