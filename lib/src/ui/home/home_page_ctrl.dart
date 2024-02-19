import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/trivia/model_dto/category/category.dto.dart';
import 'package:trivia_app/src/domain/bloc/trivia/cached_quizzes/cached_quizzes_notifier.dart';
import 'package:trivia_app/src/domain/bloc/trivia/categories_notifier.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quiz_config/quiz_config_notifier.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quiz_game/quiz_game_notifier.dart';
import 'package:trivia_app/src/domain/bloc/trivia/stats/trivia_stats_bloc.dart';

class HomePageCtrl extends AutoDisposeNotifier<void> {
  static final instance = AutoDisposeNotifierProvider<HomePageCtrl, void>(
    HomePageCtrl.new,
  );

  static final solvedCountProvider = AutoDisposeProvider<int>(
    (ref) => ref.watch(ref.watch(TriviaStatsProvider.instance).winning),
  );

  static final unSolvedCountProvider = AutoDisposeProvider<int>(
    (ref) => ref.watch(ref.watch(TriviaStatsProvider.instance).losing),
  );

  static final currentCategory = AutoDisposeProvider<CategoryDTO>(
    (ref) => ref.watch(
      QuizConfigNotifier.instance.select((config) => config.quizCategory),
    ),
  );

  static final fetchedCategories = AutoDisposeFutureProvider<List<CategoryDTO>>(
    (ref) => ref.watch(CategoriesNotifier.instance.future),
  );

  late QuizConfigNotifier _quizConfigNotifier;
  late QuizGameNotifier _quizGameNotifier;
  late CategoriesNotifier _categoriesNotifier;

  @override
  void build() {
    _quizConfigNotifier = ref.watch(QuizConfigNotifier.instance.notifier);
    _quizGameNotifier = ref.watch(QuizGameNotifier.instance.notifier);
    _categoriesNotifier = ref.watch(CategoriesNotifier.instance.notifier);
  }

  Future<void> onResetFilters() async {
    // todo(19.02.2024): use this
    await _quizGameNotifier.resetQuizConfig();
  }

  Future<void> onReloadCategories() async {
    await _categoriesNotifier.refetchCategories();
  }

  Future<void> selectCategory(CategoryDTO category) async {
    await _quizConfigNotifier.setCategory(category);
  }
}
