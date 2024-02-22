import 'dart:async';
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:quiz_prize_app/internal/debug_flags.dart';
import 'package:quiz_prize_app/src/data/local_storage/game_storage.dart';
import 'package:quiz_prize_app/src/data/trivia/model_dto/category/category.dto.dart';
import 'package:quiz_prize_app/src/data/trivia/trivia_repository.dart';
import 'package:quiz_prize_app/src/domain/storage_notifiers.dart';

/// This notifier is responsible for caching the received categories. We only
/// want the data to be loaded the first time, so we use a caching instance
/// of [AsyncNotifierProvider].
class CategoriesNotifier extends AsyncNotifier<List<CategoryDTO>> {
  static final instance =
      AsyncNotifierProvider<CategoriesNotifier, List<CategoryDTO>>(
    CategoriesNotifier.new,
    name: '$CategoriesNotifier',
  );

  late GameStorage _gameStorage;
  late TriviaRepository _triviaRepository;

  @override
  FutureOr<List<CategoryDTO>> build() async {
    _gameStorage = ref.watch(StorageNotifiers.game);
    _triviaRepository = TriviaRepository(
      client: http.Client(),
      useMockData: DebugFlags.triviaRepoUseMock,
    );

    return await _fetchCategories();
  }

  Future<void> refetchCategories() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchCategories);
  }

  /// Get all sorts of categories of quizzes.
  Future<List<CategoryDTO>> _fetchCategories() async {
    return switch (await _triviaRepository.getCategories()) {
      TriviaData<List<CategoryDTO>>(data: final list) => () async {
          await _gameStorage.set(GameCard.allCategories, list);
          return list;
        }.call(),
      TriviaError(error: final e) =>
        e is SocketException || e is TimeoutException
            ? _gameStorage.get(GameCard.allCategories)
            : throw Exception(e),
      _ => throw Exception('$this.fetchCategories() failed'),
    };
  }
}
