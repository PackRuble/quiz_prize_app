import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../bloc/trivia/quizzes/model/quiz.model.dart';

class QuizIteratorBloc {
  QuizIteratorBloc(List<Quiz> quizzes) {
    quizzes.shuffle();
    _quizzesIterator = quizzes.iterator;
  }

  late Iterator<Quiz> _quizzesIterator;

  Quiz? getCachedQuiz(bool Function(Quiz quiz) matchFilter) {
    while (_quizzesIterator.moveNext()) {
      final quiz = _quizzesIterator.current;

      if (matchFilter(quiz)) {
        log('$this-> Quiz found in cache, hash:${quiz.hashCode}');
        return quiz;
      }
    }

    return null;
  }

  @override
  @protected
  String toString() =>
      super.toString().replaceFirst('Instance of ', '').replaceAll("'", '');
}
