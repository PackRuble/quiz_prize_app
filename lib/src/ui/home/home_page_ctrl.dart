import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/trivia/model_dto/category/category.dto.dart';
import 'package:trivia_app/src/domain/app_controller.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quiz_config/quiz_config_notifier.dart';

class HomePageCtrl {
  HomePageCtrl({
    required Ref ref,
    required QuizConfigNotifier quizConfigNotifier,
    required AppProvider appProvider,
  })  : _quizConfigNotifier = quizConfigNotifier,
        _appProvider = appProvider,
        _ref = ref;

  static final instance = AutoDisposeProvider(
    (ref) => HomePageCtrl(
      ref: ref,
      quizConfigNotifier: ref.watch(QuizConfigNotifier.instance.notifier),
      appProvider: ref.watch(AppProvider.instance),
    ),
  );

  final Ref _ref;
  final QuizConfigNotifier _quizConfigNotifier;
  final AppProvider _appProvider;

  late final currentCategory = AutoDisposeProvider<CategoryDTO>(
    (ref) => ref.watch(
        QuizConfigNotifier.instance.select((value) => value.quizCategory)),
  );

  /// We want to keep the result of the request for the entire life cycle of the
  /// application.
  late final fetchedCategories =
      StateProvider<AsyncValue<List<CategoryDTO>>>((ref) {
    ref.listenSelf((_, next) {
      // initialization method
      if (next.isLoading) {
        fetchCategories();
      }
    });
    return const AsyncLoading();
  });

  AutoDisposeProvider<ThemeMode> get themeMode => _appProvider.themeMode;

  Future<void> selectThemeMode(ThemeMode mode) async =>
      _appProvider.selectThemeMode(mode);

  AutoDisposeProvider<Color> get themeColor => _appProvider.themeColor;

  Future<void> selectThemeColor(Color color) async =>
      _appProvider.selectThemeColor(color);

  void _updFetchedCategories(AsyncValue<List<CategoryDTO>> value) =>
      _ref.read(fetchedCategories.notifier).update((_) => value);

  Future<void> fetchCategories() async {
    final result = await AsyncValue.guard(_quizConfigNotifier.fetchCategories);
    _updFetchedCategories(result);
  }

  Future<void> selectCategory(CategoryDTO category) async {
    await _quizConfigNotifier.setCategory(category);
  }

  Future<void> reloadCategories() async {
    _updFetchedCategories(const AsyncLoading());
  }
}
