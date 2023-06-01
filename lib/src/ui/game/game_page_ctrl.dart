import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_app/src/domain/bloc/trivia_quiz/model/quiz.model.dart';
import 'package:trivia_app/src/domain/bloc/trivia_quiz/trivia_quiz_bloc.dart';

class GamePageCtrl {
  GamePageCtrl({
    required Ref ref,
    required TriviaQuizBloc triviaQuizBloc,
  })  : _triviaQuizBloc = triviaQuizBloc,
        _ref = ref;

  final Ref _ref;
  final TriviaQuizBloc _triviaQuizBloc;

  static final instance = AutoDisposeProvider<GamePageCtrl>(
    (ref) => GamePageCtrl(
      ref: ref,
      triviaQuizBloc: ref.watch(TriviaQuizBloc.instance),
    ),
  );

  Future<AsyncValue<Quiz>> _getQuiz() =>
      AsyncValue.guard(_triviaQuizBloc.getQuiz);

  late final currentQuiz = AutoDisposeStateProvider<AsyncValue<Quiz>>((ref) {
    ref.listenSelf((_, next) async {
      await next.whenOrNull(
        loading: () async => ref.controller.state = await _getQuiz(),
      );
    });
    return const AsyncValue.loading();
  });

  late final amountQuizzes = AutoDisposeProvider<int>(
      (ref) => ref.watch(_triviaQuizBloc.quizzes).length);

  Future<void> checkAnswer(String answer) async {
    final quiz = await _triviaQuizBloc.checkMyAnswer(answer);

    _ref.read(currentQuiz.notifier).update((_) => AsyncValue.data(quiz));
  }

  Future<void> onNextQuiz() async {
    _ref.invalidate(currentQuiz);
  }
}
