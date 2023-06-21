import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/trivia/models.dart';
import 'package:trivia_app/src/domain/bloc/trivia_quiz/model/quiz.model.dart';
import 'package:trivia_app/src/domain/bloc/trivia_quiz/trivia_quiz_bloc.dart';

class StatsPageCtrl {
  StatsPageCtrl({
    required Ref ref,
    required TriviaStatsBloc triviaStatsBloc,
  })  : _triviaStatsBloc = triviaStatsBloc,
        _ref = ref;

  final Ref _ref;
  final TriviaStatsBloc _triviaStatsBloc;

  static final instance = AutoDisposeProvider<StatsPageCtrl>(
    (ref) => StatsPageCtrl(
      ref: ref,
      triviaStatsBloc: ref.watch(TriviaStatsBloc.instance),
    ),
  );

  AutoDisposeProvider<List<Quiz>> get quizzesPlayed =>
      _triviaStatsBloc.quizzesPlayed;
  AutoDisposeProvider<int> get solvedCount => _triviaStatsBloc.winning;
  AutoDisposeProvider<int> get unsolvedCount => _triviaStatsBloc.losing;
  AutoDisposeProvider<
          Map<TriviaQuizDifficulty, (int correctly, int uncorrectly)>>
      get statsOnDifficulty => _triviaStatsBloc.statsOnDifficulty;
  AutoDisposeProvider<Map<String, (int correctly, int uncorrectly)>>
      get statsOnCategory => _triviaStatsBloc.statsOnCategory;

  Future<void> resetStatistics() async => _triviaStatsBloc.resetStats();
}
