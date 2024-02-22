import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:quiz_prize_app/src/data/trivia/model_dto/category/category.dto.dart';
import 'package:quiz_prize_app/src/domain/bloc/trivia/categories_notifier.dart';
import 'package:quiz_prize_app/src/domain/bloc/trivia/quiz_config/quiz_config_notifier.dart';
import 'package:quiz_prize_app/src/domain/quiz_game/quiz_game_notifier.dart';

class HomePagePresenter extends AutoDisposeNotifier<void> {
  static final instance = AutoDisposeNotifierProvider<HomePagePresenter, void>(
    HomePagePresenter.new,
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

  Future<void> onReloadCategories() async {
    await _categoriesNotifier.refetchCategories();
  }

  Future<void> selectCategory(CategoryDTO category) async {
    await _quizConfigNotifier.setCategory(category);
  }
}
