// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz.dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_QuizDTO _$$_QuizDTOFromJson(Map<String, dynamic> json) => _$_QuizDTO(
      category: json['category'] as String,
      type: $enumDecode(_$TriviaQuizTypeEnumMap, json['type']),
      difficulty: $enumDecode(_$TriviaQuizDifficultyEnumMap, json['difficulty']),
      question: json['question'] as String,
      correctAnswer: json['correct_answer'] as String,
      incorrectAnswers:
          (json['incorrect_answers'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$_QuizDTOToJson(_$_QuizDTO instance) => <String, dynamic>{
      'category': instance.category,
      'type': _$TriviaQuizTypeEnumMap[instance.type]!,
      'difficulty': _$TriviaQuizDifficultyEnumMap[instance.difficulty]!,
      'question': instance.question,
      'correct_answer': instance.correctAnswer,
      'incorrect_answers': instance.incorrectAnswers,
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
