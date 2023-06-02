import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_app/src/data/trivia/category/category.dto.dart';

import 'package:trivia_app/src/domain/bloc/trivia_quiz/trivia_quiz_bloc.dart';

class HomePageCtrl {
  HomePageCtrl({
    required Ref ref,
    required TriviaQuizBloc triviaQuizBloc,
  })  : _triviaQuizBloc = triviaQuizBloc,
        _ref = ref;

  static final instance = AutoDisposeProvider<HomePageCtrl>(
    (ref) => HomePageCtrl(
      ref: ref,
      triviaQuizBloc: ref.watch(TriviaQuizBloc.instance),
    ),
  );

  final Ref _ref;
  final TriviaQuizBloc _triviaQuizBloc;

  AutoDisposeProvider<CategoryDTO> get currentCategory =>
      _triviaQuizBloc.quizCategory;

  late final fetchedCategories =
      StateProvider<AsyncValue<List<CategoryDTO>>>((ref) {
    return const AsyncLoading();
  });

  void _updFetchedCategories(AsyncValue<List<CategoryDTO>> value) =>
      _ref.read(fetchedCategories.notifier).update((_) => value);

  Future<void> fetchCategories() async {
    final fetched = _ref.read(fetchedCategories);
    if (fetched.isLoading || fetched.hasError) {
      final result = await AsyncValue.guard(_triviaQuizBloc.fetchCategories);

      _updFetchedCategories(result);
    }
  }

  Future<void> selectCategory(CategoryDTO category) async {
    await _triviaQuizBloc.setCategory(category);
  }

  Future<void> reloadCategories() async {
    _updFetchedCategories(const AsyncLoading());
    await fetchCategories();
  }
}
