import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/local_storage/game_storage.dart';
import 'package:trivia_app/src/data/trivia/model_dto/trivia_config_models.dart';
import 'package:trivia_app/src/domain/storage_notifiers.dart';

import 'quizzes/model/quiz.model.dart';

typedef StatsAmount = (int correctly, int incorrectly);
typedef CategoryName = String;

class StatsModel {
  late Map<TriviaQuizDifficulty, StatsAmount> byDifficulty;
  late Map<CategoryName, StatsAmount> byCategory;
  late List<Quiz> quizzesPlayed;
  late int winning;
  late int losing;
}

class QuizStatsNotifier extends AutoDisposeNotifier<StatsModel> {
  static final instance =
      AutoDisposeNotifierProvider<QuizStatsNotifier, StatsModel>(
    QuizStatsNotifier.new,
  );

  late GameStorage _storage;

  @override
  StatsModel build() {
    _storage = ref.watch(StorageNotifiers.game);

    final stats = StatsModel();

    return stats
      ..quizzesPlayed = _storage.attach(
        GameCard.quizzesPlayed,
        (quizzes) {
          final (byDifficulty, byCategory) = _calcAll(quizzes);
          stats
            ..quizzesPlayed = quizzes
            ..byDifficulty = byDifficulty
            ..byCategory = byCategory;
          ref.notifyListeners();
        },
        detacher: ref.onDispose,
        onRemove: () {
          stats
            ..quizzesPlayed = []
            ..byDifficulty = {}
            ..byCategory = {};
          ref.notifyListeners();
        },
        fireImmediately: true,
      )
      ..winning = _storage.attach(
        GameCard.winning,
        (value) {
          state.winning = value;
          ref.notifyListeners();
        },
        detacher: ref.onDispose,
        onRemove: () {
          state.winning = 0;
          ref.notifyListeners();
        },
      )
      ..losing = _storage.attach(
        GameCard.losing,
        (value) {
          state.losing = value;
          ref.notifyListeners();
        },
        detacher: ref.onDispose,
        onRemove: () {
          state.losing = 0;
          ref.notifyListeners();
        },
      );
  }

  (Map<TriviaQuizDifficulty, StatsAmount>, Map<CategoryName, StatsAmount>)
      _calcAll(List<Quiz> quizzes) {
    final byDifficulty = <TriviaQuizDifficulty, StatsAmount>{};
    final byCategory = <CategoryName, StatsAmount>{};

    for (final q in quizzes) {
      var (int corDif, int incorDif) = byDifficulty[q.difficulty] ?? (0, 0);
      var (int corCat, int incorCat) = byCategory[q.category] ?? (0, 0);

      final isSolved = q.correctlySolved;
      if (isSolved == null) continue;

      if (isSolved) {
        byDifficulty[q.difficulty] = (++corDif, incorDif);
        byCategory[q.category] = (++corCat, incorCat);
      } else {
        byDifficulty[q.difficulty] = (corDif, ++incorDif);
        byCategory[q.category] = (corCat, ++incorCat);
      }
    }

    return (byDifficulty, byCategory);
  }

  Map<TriviaQuizDifficulty, StatsAmount> _calcByDifficulty(List<Quiz> quizzes) {
    final result = <TriviaQuizDifficulty, StatsAmount>{};

    for (final q in quizzes) {
      var (int correctly, int incorrectly) = result[q.difficulty] ?? (0, 0);

      if (q.correctlySolved!) {
        result[q.difficulty] = (++correctly, incorrectly);
      } else {
        result[q.difficulty] = (correctly, ++incorrectly);
      }
    }

    return result;
  }

  Map<CategoryName, StatsAmount> _calcByCategory(List<Quiz> quizzes) {
    final result = <CategoryName, StatsAmount>{};

    for (final q in quizzes) {
      var (int correctly, int incorrectly) = result[q.category] ?? (0, 0);

      if (q.correctlySolved!) {
        result[q.category] = (++correctly, incorrectly);
      } else {
        result[q.category] = (correctly, ++incorrectly);
      }
    }

    return result;
  }

  /// Use only in the scope `domain`.
  Future<void> savePoints(bool isWin) async {
    isWin
        ? await _storage.set<int>(
            GameCard.winning,
            _storage.get(GameCard.winning) + 1,
          )
        : await _storage.set<int>(
            GameCard.losing,
            _storage.get(GameCard.losing) + 1,
          );
  }

  Future<void> resetStats() async {
    await _storage.remove(GameCard.winning);
    await _storage.remove(GameCard.losing);
    await _storage.remove(GameCard.quizzesPlayed);
  }
}
