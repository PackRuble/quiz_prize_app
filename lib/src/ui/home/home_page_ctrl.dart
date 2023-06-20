import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/local_storage/app_storage.dart';
import 'package:trivia_app/src/data/trivia/category/category.dto.dart';
import 'package:trivia_app/src/domain/app_controller.dart';

import 'package:trivia_app/src/domain/bloc/trivia_quiz/trivia_quiz_bloc.dart';

class HomePageCtrl {
  HomePageCtrl({
    required Ref ref,
    required TriviaQuizBloc triviaQuizBloc,
    required AppStorage appStorage,
    required AppController appController,
  })  : _triviaQuizBloc = triviaQuizBloc,
        _appStorage = appStorage,
        _appController = appController,
        _ref = ref;

  static final instance = AutoDisposeProvider(
    (ref) => HomePageCtrl(
      ref: ref,
      triviaQuizBloc: ref.watch(TriviaQuizBloc.instance),
      appController: ref.watch(AppController.instance),
      appStorage: ref.watch(AppStorage.instance),
    ),
  );

  final Ref _ref;
  final TriviaQuizBloc _triviaQuizBloc;
  final AppStorage _appStorage;
  final AppController _appController;

  AutoDisposeProvider<CategoryDTO> get currentCategory =>
      _triviaQuizBloc.quizCategory;

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

  AutoDisposeProvider<ThemeMode> get themeMode => _appController.themeMode;

  Future<void> selectThemeMode(ThemeMode mode) async =>
      _appController.selectThemeMode(mode);

  AutoDisposeProvider<Color> get themeColor => _appController.themeColor;

  Future<void> selectThemeColor(Color color) async =>
      _appController.selectThemeColor(color);

  void _updFetchedCategories(AsyncValue<List<CategoryDTO>> value) =>
      _ref.read(fetchedCategories.notifier).update((_) => value);

  Future<void> fetchCategories() async {
    final result = await AsyncValue.guard(_triviaQuizBloc.fetchCategories);
    _updFetchedCategories(result);
  }

  Future<void> selectCategory(CategoryDTO category) async {
    await _triviaQuizBloc.setCategory(category);
  }

  Future<void> reloadCategories() async {
    _updFetchedCategories(const AsyncLoading());
  }
}
