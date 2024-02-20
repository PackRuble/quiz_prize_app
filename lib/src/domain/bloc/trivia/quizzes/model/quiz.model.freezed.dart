// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz.model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Quiz _$QuizFromJson(Map<String, dynamic> json) {
  return _Quiz.fromJson(json);
}

/// @nodoc
mixin _$Quiz {
  /// The name of category
  String get category => throw _privateConstructorUsedError;

  /// The type of the question multiple or True/False.
  TriviaQuizType get type => throw _privateConstructorUsedError;

  /// The difficulty of the question.
  TriviaQuizDifficulty get difficulty => throw _privateConstructorUsedError;

  /// The actual question.
  String get question => throw _privateConstructorUsedError;

  /// Holds the correct answer.
  String get correctAnswer => throw _privateConstructorUsedError;

  /// Holds the your answer.
  String? get yourAnswer => throw _privateConstructorUsedError;

  /// Mixed answers in the amount of 4 pieces. The correct answer included.
  List<String> get answers => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QuizCopyWith<Quiz> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuizCopyWith<$Res> {
  factory $QuizCopyWith(Quiz value, $Res Function(Quiz) then) =
      _$QuizCopyWithImpl<$Res, Quiz>;
  @useResult
  $Res call(
      {String category,
      TriviaQuizType type,
      TriviaQuizDifficulty difficulty,
      String question,
      String correctAnswer,
      String? yourAnswer,
      List<String> answers});
}

/// @nodoc
class _$QuizCopyWithImpl<$Res, $Val extends Quiz>
    implements $QuizCopyWith<$Res> {
  _$QuizCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? type = null,
    Object? difficulty = null,
    Object? question = null,
    Object? correctAnswer = null,
    Object? yourAnswer = freezed,
    Object? answers = null,
  }) {
    return _then(_value.copyWith(
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TriviaQuizType,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as TriviaQuizDifficulty,
      question: null == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as String,
      correctAnswer: null == correctAnswer
          ? _value.correctAnswer
          : correctAnswer // ignore: cast_nullable_to_non_nullable
              as String,
      yourAnswer: freezed == yourAnswer
          ? _value.yourAnswer
          : yourAnswer // ignore: cast_nullable_to_non_nullable
              as String?,
      answers: null == answers
          ? _value.answers
          : answers // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuizImplCopyWith<$Res> implements $QuizCopyWith<$Res> {
  factory _$$QuizImplCopyWith(
          _$QuizImpl value, $Res Function(_$QuizImpl) then) =
      __$$QuizImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String category,
      TriviaQuizType type,
      TriviaQuizDifficulty difficulty,
      String question,
      String correctAnswer,
      String? yourAnswer,
      List<String> answers});
}

/// @nodoc
class __$$QuizImplCopyWithImpl<$Res>
    extends _$QuizCopyWithImpl<$Res, _$QuizImpl>
    implements _$$QuizImplCopyWith<$Res> {
  __$$QuizImplCopyWithImpl(_$QuizImpl _value, $Res Function(_$QuizImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? type = null,
    Object? difficulty = null,
    Object? question = null,
    Object? correctAnswer = null,
    Object? yourAnswer = freezed,
    Object? answers = null,
  }) {
    return _then(_$QuizImpl(
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TriviaQuizType,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as TriviaQuizDifficulty,
      question: null == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as String,
      correctAnswer: null == correctAnswer
          ? _value.correctAnswer
          : correctAnswer // ignore: cast_nullable_to_non_nullable
              as String,
      yourAnswer: freezed == yourAnswer
          ? _value.yourAnswer
          : yourAnswer // ignore: cast_nullable_to_non_nullable
              as String?,
      answers: null == answers
          ? _value._answers
          : answers // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuizImpl extends _Quiz with DiagnosticableTreeMixin {
  const _$QuizImpl(
      {required this.category,
      required this.type,
      required this.difficulty,
      required this.question,
      required this.correctAnswer,
      this.yourAnswer = null,
      required final List<String> answers})
      : _answers = answers,
        super._();

  factory _$QuizImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuizImplFromJson(json);

  /// The name of category
  @override
  final String category;

  /// The type of the question multiple or True/False.
  @override
  final TriviaQuizType type;

  /// The difficulty of the question.
  @override
  final TriviaQuizDifficulty difficulty;

  /// The actual question.
  @override
  final String question;

  /// Holds the correct answer.
  @override
  final String correctAnswer;

  /// Holds the your answer.
  @override
  @JsonKey()
  final String? yourAnswer;

  /// Mixed answers in the amount of 4 pieces. The correct answer included.
  final List<String> _answers;

  /// Mixed answers in the amount of 4 pieces. The correct answer included.
  @override
  List<String> get answers {
    if (_answers is EqualUnmodifiableListView) return _answers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_answers);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Quiz(category: $category, type: $type, difficulty: $difficulty, question: $question, correctAnswer: $correctAnswer, yourAnswer: $yourAnswer, answers: $answers)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Quiz'))
      ..add(DiagnosticsProperty('category', category))
      ..add(DiagnosticsProperty('type', type))
      ..add(DiagnosticsProperty('difficulty', difficulty))
      ..add(DiagnosticsProperty('question', question))
      ..add(DiagnosticsProperty('correctAnswer', correctAnswer))
      ..add(DiagnosticsProperty('yourAnswer', yourAnswer))
      ..add(DiagnosticsProperty('answers', answers));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuizImpl &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.question, question) ||
                other.question == question) &&
            (identical(other.correctAnswer, correctAnswer) ||
                other.correctAnswer == correctAnswer) &&
            (identical(other.yourAnswer, yourAnswer) ||
                other.yourAnswer == yourAnswer) &&
            const DeepCollectionEquality().equals(other._answers, _answers));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      category,
      type,
      difficulty,
      question,
      correctAnswer,
      yourAnswer,
      const DeepCollectionEquality().hash(_answers));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QuizImplCopyWith<_$QuizImpl> get copyWith =>
      __$$QuizImplCopyWithImpl<_$QuizImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuizImplToJson(
      this,
    );
  }
}

abstract class _Quiz extends Quiz {
  const factory _Quiz(
      {required final String category,
      required final TriviaQuizType type,
      required final TriviaQuizDifficulty difficulty,
      required final String question,
      required final String correctAnswer,
      final String? yourAnswer,
      required final List<String> answers}) = _$QuizImpl;
  const _Quiz._() : super._();

  factory _Quiz.fromJson(Map<String, dynamic> json) = _$QuizImpl.fromJson;

  @override

  /// The name of category
  String get category;
  @override

  /// The type of the question multiple or True/False.
  TriviaQuizType get type;
  @override

  /// The difficulty of the question.
  TriviaQuizDifficulty get difficulty;
  @override

  /// The actual question.
  String get question;
  @override

  /// Holds the correct answer.
  String get correctAnswer;
  @override

  /// Holds the your answer.
  String? get yourAnswer;
  @override

  /// Mixed answers in the amount of 4 pieces. The correct answer included.
  List<String> get answers;
  @override
  @JsonKey(ignore: true)
  _$$QuizImplCopyWith<_$QuizImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
