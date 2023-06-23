import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/trivia/model_dto/category/category.dto.dart';
import 'package:trivia_app/src/domain/app_controller.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quiz/trivia_quiz_bloc.dart';

class HomePageCtrl {
  HomePageCtrl({
    required Ref ref,
    required TriviaQuizProvider triviaQuizProvider,
    required AppProvider appProvider,
  })  : _triviaQuizProvider = triviaQuizProvider,
        _appProvider = appProvider,
        _ref = ref;

  static final instance = AutoDisposeProvider(
    (ref) => HomePageCtrl(
      ref: ref,
      triviaQuizProvider: ref.watch(TriviaQuizProvider.instance),
      appProvider: ref.watch(AppProvider.instance),
    ),
  );

  final Ref _ref;
  final TriviaQuizProvider _triviaQuizProvider;
  final AppProvider _appProvider;

  AutoDisposeProvider<CategoryDTO> get currentCategory =>
      _triviaQuizProvider.quizCategory;

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
    final result = await AsyncValue.guard(_triviaQuizProvider.fetchCategories);
    _updFetchedCategories(result);
  }

  Future<void> selectCategory(CategoryDTO category) async {
    await _triviaQuizProvider.setCategory(category);
  }

  Future<void> reloadCategories() async {
    _updFetchedCategories(const AsyncLoading());
  }
}
