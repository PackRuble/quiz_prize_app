import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_app/src/domain/bloc/trivia_quiz/model/quiz.model.dart';
import 'package:trivia_app/src/domain/bloc/trivia_quiz/trivia_quiz_bloc.dart';

class GamePageCtrl {
  GamePageCtrl({
    required Ref ref,
    required TriviaQuizBloc triviaQuizBloc,
    required this.triviaStatsBloc,
  })  : _triviaQuizBloc = triviaQuizBloc,
        _ref = ref;

  final Ref _ref;
  final TriviaQuizBloc _triviaQuizBloc;
  final TriviaStatsBloc triviaStatsBloc;

  static final instance = AutoDisposeProvider<GamePageCtrl>(
    (ref) => GamePageCtrl(
      ref: ref,
      triviaQuizBloc: ref.watch(TriviaQuizBloc.instance),
      triviaStatsBloc: ref.watch(TriviaStatsBloc.instance),
    ),
  );

  late final currentQuiz = AutoDisposeStateProvider<AsyncValue<Quiz>>((ref) {
    ref.listenSelf((_, next) async {
      if (next is AsyncLoading) {
        ref.controller.state = await AsyncValue.guard(_triviaQuizBloc.getQuiz);
      }
    });
    return const AsyncLoading();
  });

  late final amountQuizzes = AutoDisposeProvider<int>(
      (ref) => ref.watch(_triviaQuizBloc.quizzes).length);

  Future<void> checkAnswer(String answer) async {
    final quiz = await _triviaQuizBloc.checkMyAnswer(answer);

    _ref.read(currentQuiz.notifier).update((_) => AsyncValue.data(quiz));
  }

  Future<void> onNextQuiz() async {
    // we need to return the value immediately without waiting.
    // ignore: unused_result
    _ref.refresh(currentQuiz);
  }
}
