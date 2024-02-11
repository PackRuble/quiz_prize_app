// ignore_for_file: avoid_public_notifier_properties
import 'dart:async';
import 'dart:developer';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_app/internal/debug_flags.dart';
import 'package:trivia_app/src/data/local_storage/game_storage.dart';
import 'package:trivia_app/src/data/trivia/model_dto/quiz/quiz.dto.dart';
import 'package:trivia_app/src/data/trivia/trivia_repository.dart';

import '../model/quiz.model.dart';
import '../quiz_config/quiz_config_notifier.dart';
import '../quiz_game/quiz_game_result.dart';

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
  late TriviaRepository _triviaRepository;
  late QuizConfigNotifier _quizConfigNotifier;
  final bool debugUseMockData;

  @override
  List<Quiz> build() {
    _storage = ref.watch(GameStorage.instance);
    _triviaRepository = TriviaRepository(
      client: http.Client(),
      useMockData: debugUseMockData,
    );
    _quizConfigNotifier = ref.watch(QuizConfigNotifier.instance.notifier);

    // The `attach` method provides a reactive state change while storing
    // the new value in storage
    return _storage.attach(
      GameCard.quizzes,
      (value) => state = value,
      detacher: ref.onDispose,
    );
  }

  Future<void> cacheQuizzes(List<Quiz> fetched) async {
    await _storage.set<List<Quiz>>(
      GameCard.quizzes,
      [...state, ...fetched]..shuffle(),
    );
  }

  // todo(08.02.2024): move in TriviaStatsBloc + create dependencies
  Future<void> moveQuizAsPlayed(Quiz quiz) async {
    final quizzes = state;

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
