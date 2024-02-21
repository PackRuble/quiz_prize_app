import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/local_storage/game_storage.dart';
import 'package:trivia_app/src/data/trivia/model_dto/trivia_config_models.dart';
import 'package:trivia_app/src/domain/storage_notifiers.dart';

import 'quizzes/model/quiz.model.dart';

typedef StatsAmount = (int correctly, int uncorrectly);
typedef _CategoryName = String;

class StatsModel {
  late Map<TriviaQuizDifficulty, StatsAmount> onDifficulty;
  late Map<_CategoryName, StatsAmount> onCategory;
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
        (value) {
          stats
            ..quizzesPlayed = value
            ..onDifficulty = _calcOnDifficulty(value)
            ..onCategory = _calcOnCategory(value);
          ref.notifyListeners();
        },
        detacher: ref.onDispose,
        onRemove: () {
          stats
            ..quizzesPlayed = []
            ..onDifficulty = _calcOnDifficulty([])
            ..onCategory = _calcOnCategory([]);
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

  Map<TriviaQuizDifficulty, StatsAmount> _calcOnDifficulty(List<Quiz> quizzes) {
    final result = <TriviaQuizDifficulty, StatsAmount>{};

    for (final q in quizzes) {
      var (int correctly, int uncorrectly) = result[q.difficulty] ?? (0, 0);

      if (q.correctlySolved!) {
        result[q.difficulty] = (++correctly, uncorrectly);
      } else {
        result[q.difficulty] = (correctly, ++uncorrectly);
      }
    }

    return result;
  }

  Map<_CategoryName, StatsAmount> _calcOnCategory(List<Quiz> quizzes) {
    final result = <_CategoryName, StatsAmount>{};

    for (final q in quizzes) {
      var (int correctly, int uncorrectly) = result[q.category] ?? (0, 0);

      if (q.correctlySolved!) {
        result[q.category] = (++correctly, uncorrectly);
      } else {
        result[q.category] = (correctly, ++uncorrectly);
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
