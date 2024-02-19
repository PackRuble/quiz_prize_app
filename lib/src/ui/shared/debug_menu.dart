import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/domain/bloc/trivia/cached_quizzes/cached_quizzes_notifier.dart';

import 'cardpad.dart';

final _debugCachedQuizzesNotifier = AutoDisposeProvider<QuizzesNotifier>(
      (ref) => ref.watch(QuizzesNotifier.instance.notifier),
);

final _debugAmountCachedQuizzes = AutoDisposeProvider<int>(
  (ref) => ref.watch(QuizzesNotifier.instance).length,
);

class DebugDialog extends ConsumerWidget {
  const DebugDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mq = MediaQuery.of(context);

    final cachedQuizzesNotifier = ref.watch(_debugCachedQuizzesNotifier);
    final cachedQuizzesCount = ref.watch(_debugAmountCachedQuizzes);

    return AlertDialog(
      scrollable: true,
      title: const Text('Debug menu'),
      content: SizedBox(
        width: mq.size.width * .7,
        child: Column(
          children: [
            CardPad(
              padding: EdgeInsets.zero,
              margin: const EdgeInsets.all(4.0),
              child: ListTile(
                title: Text('Cached quizzes: $cachedQuizzesCount'),
                trailing: IconButton(
                  onPressed: cachedQuizzesNotifier.clearAll,
                  icon: const Icon(Icons.cleaning_services_rounded),
                ),
              ),
            ),
          ],
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
