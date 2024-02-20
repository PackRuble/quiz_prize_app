// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuizImpl _$$QuizImplFromJson(Map<String, dynamic> json) => _$QuizImpl(
      category: json['category'] as String,
      type: $enumDecode(_$TriviaQuizTypeEnumMap, json['type']),
      difficulty:
          $enumDecode(_$TriviaQuizDifficultyEnumMap, json['difficulty']),
      question: json['question'] as String,
      correctAnswer: json['correctAnswer'] as String,
      yourAnswer: json['yourAnswer'] as String? ?? null,
      answers:
          (json['answers'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$QuizImplToJson(_$QuizImpl instance) =>
    <String, dynamic>{
      'category': instance.category,
      'type': _$TriviaQuizTypeEnumMap[instance.type]!,
      'difficulty': _$TriviaQuizDifficultyEnumMap[instance.difficulty]!,
      'question': instance.question,
      'correctAnswer': instance.correctAnswer,
      'yourAnswer': instance.yourAnswer,
      'answers': instance.answers,
    };

const _$TriviaQuizTypeEnumMap = {
  TriviaQuizType.any: 'any',
  TriviaQuizType.multiple: 'multiple',
  TriviaQuizType.boolean: 'boolean',
};

const _$TriviaQuizDifficultyEnumMap = {
  TriviaQuizDifficulty.any: 'any',
  TriviaQuizDifficulty.easy: 'easy',
  TriviaQuizDifficulty.medium: 'medium',
  TriviaQuizDifficulty.hard: 'hard',
};
