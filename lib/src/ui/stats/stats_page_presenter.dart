import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:quiz_prize_app/src/data/trivia/model_dto/trivia_config_models.dart';
import 'package:quiz_prize_app/src/domain/bloc/trivia/quizzes/model/quiz.model.dart';
import 'package:quiz_prize_app/src/domain/bloc/trivia/stats_notifier.dart';

class StatsPagePresenter extends AutoDisposeNotifier<void> {
  static final instance = AutoDisposeNotifierProvider<StatsPagePresenter, void>(
    StatsPagePresenter.new,
  );

  static final solvedCount = AutoDisposeProvider<int>(
    (ref) => ref.watch(
      QuizStatsNotifier.instance.select((stats) => stats.winning),
    ),
  );

  static final unsolvedCount = AutoDisposeProvider<int>(
    (ref) => ref.watch(
      QuizStatsNotifier.instance.select((stats) => stats.losing),
    ),
  );

  static final statsByDifficulty =
      AutoDisposeProvider<Map<TriviaQuizDifficulty, StatsAmount>>(
    (ref) => ref.watch(
      QuizStatsNotifier.instance.select((stats) => stats.byDifficulty),
    ),
  );

  static final statsByCategory =
      AutoDisposeProvider<Map<CategoryName, StatsAmount>>(
    (ref) => ref.watch(
      QuizStatsNotifier.instance.select((stats) => stats.byCategory),
    ),
  );

  static final quizzesPlayed = AutoDisposeProvider<List<Quiz>>(
    (ref) => ref.watch(
      QuizStatsNotifier.instance.select((stats) => stats.quizzesPlayed),
    ),
  );

  late QuizStatsNotifier _quizStatsNotifier;

  @override
  void build() {
    _quizStatsNotifier = ref.watch(QuizStatsNotifier.instance.notifier);
  }

  Future<void> resetStatistics() async => _quizStatsNotifier.resetStats();
}
