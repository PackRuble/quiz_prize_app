import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quiz.model.dart';
import 'package:trivia_app/src/domain/bloc/trivia/trivia_bloc.dart';

@immutable
class GameState {
  const GameState({
    required this.quiz,
    required this.amountQuizzes,
  });

  final Quiz quiz;
  final int amountQuizzes;

  GameState copyWith({
    Quiz? quiz,
    int? amountQuizzes,
  }) {
    return GameState(
      quiz: quiz ?? this.quiz,
      amountQuizzes: amountQuizzes ?? this.amountQuizzes,
    );
  }
}

class GamePageBloc extends AutoDisposeAsyncNotifier<GameState> {
  // ignore: avoid_public_notifier_properties
  static final instance =
      AutoDisposeAsyncNotifierProvider<GamePageBloc, GameState>(
    GamePageBloc.new,
  );

  @override
  Future<GameState> build() async {
    final triviaBloc = ref.watch(TriviaBloc.instance);
    final quiz = await triviaBloc.getQuiz();
    final amountQuizzes = ref.watch(triviaBloc.quizzes).length;

    return GameState(quiz: quiz, amountQuizzes: amountQuizzes);
  }

  Future<void> checkAnswer(String answer) async {
    final triviaBloc = ref.read(TriviaBloc.instance);

    final quiz = state.requireValue.quiz;

    final newQuiz = await triviaBloc.checkMyAnswer(quiz, answer);

    state = AsyncData(state.requireValue.copyWith(quiz: newQuiz));
  }

  Future<void> onNextQuiz() async {
    state = const AsyncLoading();

    final triviaBloc = ref.read(TriviaBloc.instance);
    final quiz = await triviaBloc.getQuiz();
    final amountQuizzes = ref.read(triviaBloc.quizzes).length;

    state = AsyncData(GameState(quiz: quiz, amountQuizzes: amountQuizzes));
  }
}
