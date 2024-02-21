import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/trivia/model_dto/trivia_config_models.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quizzes/model/quiz.model.dart';
import 'package:trivia_app/src/domain/bloc/trivia/stats_notifier.dart';

class StatsPageCtrl extends AutoDisposeNotifier<void> {
  static final instance = AutoDisposeNotifierProvider<StatsPageCtrl, void>(
    StatsPageCtrl.new,
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

  static final statsOnDifficulty = AutoDisposeProvider<
      Map<TriviaQuizDifficulty, (int correctly, int uncorrectly)>>(
    (ref) => ref.watch(
      QuizStatsNotifier.instance.select((stats) => stats.onDifficulty),
    ),
  );

  static final statsOnCategory =
      AutoDisposeProvider<Map<String, (int correctly, int uncorrectly)>>(
    (ref) => ref.watch(
      QuizStatsNotifier.instance.select((stats) => stats.onCategory),
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
