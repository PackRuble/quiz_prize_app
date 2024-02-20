import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/local_storage/app_storage.dart';
import 'package:trivia_app/src/data/local_storage/game_storage.dart';
import 'package:trivia_app/src/data/local_storage/token_storage.dart';

// ignore_for_file: avoid_classes_with_only_static_members

/// Using the riverpod state manager to create a single storage instance.
/// Putting the provider inside the class for an explicit singleton analogy.
abstract final class StorageNotifiers {
  static final secret = Provider((_) => SecretStorage());
  static final app = Provider((_) => AppStorage());

  /// You can pass the [GameCard]-configuration using constructor if
  /// it may depend on other providers.
  static final game = Provider((_) => GameStorage(config: GameCard.config));
}
