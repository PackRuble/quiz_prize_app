import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/trivia/model_dto/trivia_config_models.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quizzes/model/quiz.model.dart';
import 'package:trivia_app/src/domain/bloc/trivia/stats_notifier.dart';

class StatsPageCtrl {
  StatsPageCtrl({
    required Ref ref,
    required TriviaStatsProvider triviaStatsProvider,
  })  : _triviaStatsProvider = triviaStatsProvider,
        _ref = ref;

  // ignore: unused_field
  final Ref _ref;
  final TriviaStatsProvider _triviaStatsProvider;

  static final instance = AutoDisposeProvider<StatsPageCtrl>(
    (ref) => StatsPageCtrl(
      ref: ref,
      triviaStatsProvider: ref.watch(TriviaStatsProvider.instance),
    ),
  );

  AutoDisposeProvider<List<Quiz>> get quizzesPlayed =>
      _triviaStatsProvider.quizzesPlayed;
  AutoDisposeProvider<int> get solvedCount => _triviaStatsProvider.winning;
  AutoDisposeProvider<int> get unsolvedCount => _triviaStatsProvider.losing;

  AutoDisposeProvider<
          Map<TriviaQuizDifficulty, (int correctly, int uncorrectly)>>
      get statsOnDifficulty => _triviaStatsProvider.statsOnDifficulty;

  AutoDisposeProvider<Map<String, (int correctly, int uncorrectly)>>
      get statsOnCategory => _triviaStatsProvider.statsOnCategory;

  static final solvedCountProvider = AutoDisposeProvider<int>(
    (ref) => ref.watch(ref.watch(TriviaStatsProvider.instance).winning),
  );

  static final unSolvedCountProvider = AutoDisposeProvider<int>(
    (ref) => ref.watch(ref.watch(TriviaStatsProvider.instance).losing),
  );

  Future<void> resetStatistics() async => _triviaStatsProvider.resetStats();
}
