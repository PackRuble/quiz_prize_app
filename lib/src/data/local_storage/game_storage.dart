import 'dart:convert';

import 'package:cardoteka/cardoteka.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/trivia/model_dto/category/category.dto.dart';
import 'package:trivia_app/src/data/trivia/model_dto/trivia_models.dart';
import 'package:trivia_app/src/domain/bloc/trivia/model/quiz.model.dart';

/// Define our storage class with the necessary mixins and parameters.
class GameStorage extends Cardoteka with WatcherImpl {
  GameStorage._() : super(config: GameCard._config);

  /// Using the riverpod state manager to create a single storage instance.
  /// Putting the provider inside the class for an explicit singleton analogy.
  static final instance = Provider<GameStorage>((ref) => GameStorage._());
}

/// [Card]s related to the process of the game.
///
/// You can use named parameters. Also, it is preferable to use a custom [key]
/// as parameter.
///
/// Your [T] type can also be extended from [Object]? to use null values as
/// [defaultValue]. To access such a value, use [Cardoteka.getOrNull]
/// and [Cardoteka.setOrNull]. [defaultValue]s must be constant.
enum GameCard<T extends Object> implements Card<T> {
  quizzes<List<Quiz>>(DataType.stringList, []),
  quizzesPlayed<List<Quiz>>(DataType.stringList, []),
  winning<int>(DataType.int, 0),
  losing<int>(DataType.int, 0),
  quizDifficulty<TriviaQuizDifficulty>(
      DataType.string, TriviaQuizDifficulty.any),
  quizType<TriviaQuizType>(DataType.string, TriviaQuizType.any),
  quizCategory<CategoryDTO>(DataType.string, CategoryDTO.any),
  ;

  const GameCard(this.type, this.defaultValue);

  @override
  final T defaultValue;

  /// It is preferable to use custom names so as not to accidentally change
  /// the value of the enumeration (for example, by globally renaming in ide).
  @override
  String get key => name;

  @override
  final DataType type;

  /// To preserve syntactic sugar, the config is defined in this class.
  /// Otherwise, you would have to use [GameCard.].
  ///
  /// [CardConfig.name] must choose a unique name that will be used only once
  /// when implementing from [Card].
  ///
  /// Provide converters if necessary. This may be necessary if the object
  /// is complex and is not one of the possible [DataType].
  static const _config = CardConfig(
    name: 'GameCard',
    cards: values,
    converters: {
      quizzes: _QuizzesConverter(),
      quizzesPlayed: _QuizzesConverter(),
      quizDifficulty: EnumAsStringConverter(TriviaQuizDifficulty.values),
      quizType: _QuizTypeConverter(),
      quizCategory: _QuizCategoryConverter(),
    },
  );
}

/// Converter for [TriviaQuizType] processing.
///
/// This is what the custom converter looks like. In this case,
/// it duplicates the [EnumAsStringConverter].
/// However, you can program it to your liking.
class _QuizTypeConverter extends Converter<TriviaQuizType, String> {
  const _QuizTypeConverter();

  @override
  TriviaQuizType from(String source) => TriviaQuizType.values.byName(source);

  @override
  String to(TriviaQuizType object) => object.name;
}

/// A special converter for processing a collection of elements [Quiz].
///
/// All you need is to implement [objFrom] and [objTo] to transform the item.
/// To use [ListConverter], it must be extended, not implemented.
class _QuizzesConverter extends ListConverter<Quiz> {
  const _QuizzesConverter();

  @override
  Quiz objFrom(String element) =>
      Quiz.fromJson(jsonDecode(element) as Map<String, dynamic>);

  @override
  String objTo(Quiz obj) => jsonEncode(obj.toJson());
}

class _QuizCategoryConverter extends Converter<CategoryDTO, String> {
  const _QuizCategoryConverter();

  @override
  CategoryDTO from(String source) =>
      CategoryDTO.fromJson(jsonDecode(source) as Map<String, dynamic>);

  @override
  String to(CategoryDTO object) => jsonEncode(object.toJson());
}
