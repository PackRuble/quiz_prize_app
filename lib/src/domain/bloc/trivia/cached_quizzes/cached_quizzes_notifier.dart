// ignore_for_file: avoid_public_notifier_properties
import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/internal/debug_flags.dart';
import 'package:trivia_app/src/data/local_storage/game_storage.dart';

import '../model/quiz.model.dart';

/// Notifier contains a state of cached quizzes.
///
/// Has methods for retrieving quizzes from the Internet and storing them in storage.
class QuizzesNotifier extends AutoDisposeNotifier<List<Quiz>> {
  QuizzesNotifier({required this.debugUseMockData});

  static final instance =
      AutoDisposeNotifierProvider<QuizzesNotifier, List<Quiz>>(() {
    return QuizzesNotifier(
      debugUseMockData: DebugFlags.triviaRepoUseMock,
    );
  });

  late GameStorage _storage;

  final bool debugUseMockData;

  @override
  List<Quiz> build() {
    _storage = ref.watch(GameStorage.instance);

    // The `attach` method provides a reactive state change while storing
    // the new value in storage
    return _storage.attach(
      GameCard.quizzes,
      (value) => state = List.of(value),
      detacher: ref.onDispose,
      onRemove: () => state = [],
    );
  }

  Future<void> cacheQuizzes(List<Quiz> fetched) async {
    await _storage.set<List<Quiz>>(
      GameCard.quizzes,
      [...state, ...fetched]..shuffle(),
    );
  }

  Future<void> clearAll() async {
    await _storage.remove(GameCard.quizzes);
  }

  // todo(08.02.2024): move in TriviaStatsBloc + create dependencies
  Future<void> moveQuizAsPlayed(Quiz quiz) async {
    final quizzes = List.of(state);

    final removedIndex = quizzes.indexWhere(
      (q) =>
          q.correctAnswer == quiz.correctAnswer && q.question == quiz.question,
    );
    await _storage.set<List<Quiz>>(
      GameCard.quizzes,
      quizzes..removeAt(removedIndex),
    );

    final quizzesPlayed = _storage.get(GameCard.quizzesPlayed);
    await _storage.set<List<Quiz>>(
      GameCard.quizzesPlayed,
      [quiz, ...quizzesPlayed],
    );
  }

  @override
  String toString() =>
      super.toString().replaceFirst('Instance of ', '').replaceAll("'", '');
}
