// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz.dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

QuizDTO _$QuizDTOFromJson(Map<String, dynamic> json) {
  return _QuizDTO.fromJson(json);
}

/// @nodoc
mixin _$QuizDTO {
  /// The name of category
  @JsonKey(name: 'category')
  String get category => throw _privateConstructorUsedError;

  /// The type of the question multiple or True/False.
  @JsonKey(name: 'type')
  TriviaQuizType get type => throw _privateConstructorUsedError;

  /// The difficulty of the question.
  @JsonKey(name: 'difficulty')
  TriviaQuizDifficulty get difficulty => throw _privateConstructorUsedError;

  /// The actual question.
  @JsonKey(name: 'question')
  String get question => throw _privateConstructorUsedError;

  /// Holds the correct answer.
  @JsonKey(name: 'correct_answer')
  String get correctAnswer => throw _privateConstructorUsedError;

  /// Contains 3 wrong answers.
  @JsonKey(name: 'incorrect_answers')
  List<String> get incorrectAnswers => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QuizDTOCopyWith<QuizDTO> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuizDTOCopyWith<$Res> {
  factory $QuizDTOCopyWith(QuizDTO value, $Res Function(QuizDTO) then) =
      _$QuizDTOCopyWithImpl<$Res, QuizDTO>;
  @useResult
  $Res call(
      {@JsonKey(name: 'category') String category,
      @JsonKey(name: 'type') TriviaQuizType type,
      @JsonKey(name: 'difficulty') TriviaQuizDifficulty difficulty,
      @JsonKey(name: 'question') String question,
      @JsonKey(name: 'correct_answer') String correctAnswer,
      @JsonKey(name: 'incorrect_answers') List<String> incorrectAnswers});
}

/// @nodoc
class _$QuizDTOCopyWithImpl<$Res, $Val extends QuizDTO>
    implements $QuizDTOCopyWith<$Res> {
  _$QuizDTOCopyWithImpl(this._value, this._then);

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
    Object? incorrectAnswers = null,
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
      incorrectAnswers: null == incorrectAnswers
          ? _value.incorrectAnswers
          : incorrectAnswers // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_QuizDTOCopyWith<$Res> implements $QuizDTOCopyWith<$Res> {
  factory _$$_QuizDTOCopyWith(
          _$_QuizDTO value, $Res Function(_$_QuizDTO) then) =
      __$$_QuizDTOCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'category') String category,
      @JsonKey(name: 'type') TriviaQuizType type,
      @JsonKey(name: 'difficulty') TriviaQuizDifficulty difficulty,
      @JsonKey(name: 'question') String question,
      @JsonKey(name: 'correct_answer') String correctAnswer,
      @JsonKey(name: 'incorrect_answers') List<String> incorrectAnswers});
}

/// @nodoc
class __$$_QuizDTOCopyWithImpl<$Res>
    extends _$QuizDTOCopyWithImpl<$Res, _$_QuizDTO>
    implements _$$_QuizDTOCopyWith<$Res> {
  __$$_QuizDTOCopyWithImpl(_$_QuizDTO _value, $Res Function(_$_QuizDTO) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? type = null,
    Object? difficulty = null,
    Object? question = null,
    Object? correctAnswer = null,
    Object? incorrectAnswers = null,
  }) {
    return _then(_$_QuizDTO(
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
      incorrectAnswers: null == incorrectAnswers
          ? _value._incorrectAnswers
          : incorrectAnswers // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_QuizDTO implements _QuizDTO {
  const _$_QuizDTO(
      {@JsonKey(name: 'category')
          required this.category,
      @JsonKey(name: 'type')
          required this.type,
      @JsonKey(name: 'difficulty')
          required this.difficulty,
      @JsonKey(name: 'question')
          required this.question,
      @JsonKey(name: 'correct_answer')
          required this.correctAnswer,
      @JsonKey(name: 'incorrect_answers')
          required final List<String> incorrectAnswers})
      : _incorrectAnswers = incorrectAnswers;

  factory _$_QuizDTO.fromJson(Map<String, dynamic> json) =>
      _$$_QuizDTOFromJson(json);

  /// The name of category
  @override
  @JsonKey(name: 'category')
  final String category;

  /// The type of the question multiple or True/False.
  @override
  @JsonKey(name: 'type')
  final TriviaQuizType type;

  /// The difficulty of the question.
  @override
  @JsonKey(name: 'difficulty')
  final TriviaQuizDifficulty difficulty;

  /// The actual question.
  @override
  @JsonKey(name: 'question')
  final String question;

  /// Holds the correct answer.
  @override
  @JsonKey(name: 'correct_answer')
  final String correctAnswer;

  /// Contains 3 wrong answers.
  final List<String> _incorrectAnswers;

  /// Contains 3 wrong answers.
  @override
  @JsonKey(name: 'incorrect_answers')
  List<String> get incorrectAnswers {
    if (_incorrectAnswers is EqualUnmodifiableListView)
      return _incorrectAnswers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_incorrectAnswers);
  }

  @override
  String toString() {
    return 'QuizDTO(category: $category, type: $type, difficulty: $difficulty, question: $question, correctAnswer: $correctAnswer, incorrectAnswers: $incorrectAnswers)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_QuizDTO &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.question, question) ||
                other.question == question) &&
            (identical(other.correctAnswer, correctAnswer) ||
                other.correctAnswer == correctAnswer) &&
            const DeepCollectionEquality()
                .equals(other._incorrectAnswers, _incorrectAnswers));
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
      const DeepCollectionEquality().hash(_incorrectAnswers));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_QuizDTOCopyWith<_$_QuizDTO> get copyWith =>
      __$$_QuizDTOCopyWithImpl<_$_QuizDTO>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_QuizDTOToJson(
      this,
    );
  }
}

abstract class _QuizDTO implements QuizDTO {
  const factory _QuizDTO(
      {@JsonKey(name: 'category')
          required final String category,
      @JsonKey(name: 'type')
          required final TriviaQuizType type,
      @JsonKey(name: 'difficulty')
          required final TriviaQuizDifficulty difficulty,
      @JsonKey(name: 'question')
          required final String question,
      @JsonKey(name: 'correct_answer')
          required final String correctAnswer,
      @JsonKey(name: 'incorrect_answers')
          required final List<String> incorrectAnswers}) = _$_QuizDTO;

  factory _QuizDTO.fromJson(Map<String, dynamic> json) = _$_QuizDTO.fromJson;

  @override

  /// The name of category
  @JsonKey(name: 'category')
  String get category;
  @override

  /// The type of the question multiple or True/False.
  @JsonKey(name: 'type')
  TriviaQuizType get type;
  @override

  /// The difficulty of the question.
  @JsonKey(name: 'difficulty')
  TriviaQuizDifficulty get difficulty;
  @override

  /// The actual question.
  @JsonKey(name: 'question')
  String get question;
  @override

  /// Holds the correct answer.
  @JsonKey(name: 'correct_answer')
  String get correctAnswer;
  @override

  /// Contains 3 wrong answers.
  @JsonKey(name: 'incorrect_answers')
  List<String> get incorrectAnswers;
  @override
  @JsonKey(ignore: true)
  _$$_QuizDTOCopyWith<_$_QuizDTO> get copyWith =>
      throw _privateConstructorUsedError;
}
