import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_app/src/domain/bloc/trivia_quiz/model/quiz.model.dart';
import 'package:trivia_app/src/domain/bloc/trivia_quiz/trivia_quiz_bloc.dart';

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
    final triviaBloc = ref.watch(TriviaQuizBloc.instance);
    final quiz = await triviaBloc.getQuiz();
    final amountQuizzes = ref.read(triviaBloc.quizzes).length; // todo
    return GameState(quiz: quiz, amountQuizzes: amountQuizzes);
  }

  Future<void> checkAnswer(String answer) async {
    final triviaBloc = ref.read(TriviaQuizBloc.instance);

    final quiz = await triviaBloc.checkMyAnswer(answer);

    state = AsyncData(state.requireValue.copyWith(quiz: quiz));
  }

  Future<void> onNextQuiz() async {
    state = const AsyncLoading();

    final triviaBloc = ref.read(TriviaQuizBloc.instance);
    final quiz = await triviaBloc.getQuiz();
    final amountQuizzes = ref.read(triviaBloc.quizzes).length;

    state = AsyncData(GameState(quiz: quiz, amountQuizzes: amountQuizzes));
  }
}
