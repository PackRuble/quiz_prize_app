import 'dart:convert';
import 'dart:developer';

import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;

import 'category/category.dto.dart';
import 'models.dart';
import 'quiz/quiz.dto.dart';

enum TriviaException implements Exception {
  success(0, 'Success. Returned results successfully.'),

  noResults(
      1,
      "No Results. Could not return results. "
      "The API doesn't have enough questions for your query. "
      "(Ex. Asking for 50 Questions in a Category that only has 20.)"),

  invalidParameter(
      2,
      "Invalid Parameter. Contains an invalid parameter. "
      "Arguments passed in aren't valid. (Ex. Amount = Five)"),

  tokenNotFound(3, 'Token Not Found. Session Token does not exist'),

  tokenEmptySession(
      4,
      "Token Empty Session. Token has returned all possible questions "
      "for the specified query. Resetting the Token is necessary."),
  ;

  const TriviaException(this.code, this.message);

  final int code;
  final String message;
}

/// Use [TriviaRepository] to get list of categories or to fetch a quiz
class TriviaRepository {
  TriviaRepository({required this.client});

  final http.Client client;

  static const _baseUrl = 'opentdb.com';
  static const _responseCodeKey = 'response_code';

  String _convertUnescapeHtml(String data) => HtmlUnescape().convert(data);
}

extension GetCategories on TriviaRepository {
  /// Returns list of categories [List]<[CategoryDTO]>.
  /// Each category [CategoryDTO] is represented by name and id.
  Future<List<CategoryDTO>> getCategories() async {
    log('$TriviaRepository.getCategories been called');

    final uri = Uri.https(TriviaRepository._baseUrl, 'api_category.php');

    log('url: $uri');

    final http.Response response;

    try {
      response = await client.get(uri);

      if (response.statusCode == 200) {
        throw Exception(
          ['Failed to get quiz. Status code ${response.statusCode}'],
        );
      }
    } catch (e, s) {
      print(e);
      print(s);
      throw Exception(e);
    }

    final body = json.decode(response.body) as Map;

    final categoriesJson =
        (body["trivia_categories"] as List).cast<Map<String, dynamic>>();

    return categoriesJson.map(CategoryDTO.fromJson).toList();
  }
}

extension GetQuizzes on TriviaRepository {
  static const _quizzesApi = 'api.php';
  static const _resultsKey = 'results';

  /// Returns list of quiz [List]<[QuizDTO]> by specified category, difficulty and type.
  ///
  /// This method may throw exception:
  /// - if status code from API was not 200. [Exception]
  /// - if response code was not 0. [TriviaException]
  ///
  Future<List<QuizDTO>> getQuizzes({
    required CategoryDTO category,
    required TriviaQuizDifficulty difficulty,
    required TriviaQuizType type,
    int amount = 50,
  }) async {
    assert(0 < amount && amount <= 50);

    log('$TriviaRepository.getQuizzes been called');

    final uri = Uri.https(
      TriviaRepository._baseUrl,
      _quizzesApi,
      _getQueryParams(
        category: category,
        difficulty: difficulty,
        type: type,
        amount: amount,
      ),
    );

    log('url: $uri');

    final http.Response response;
    try {
      response = await client.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          ['Failed to get quiz. Status code ${response.statusCode}'],
        );
      }
    } catch (e, s) {
      print(e);
      print(s);
      throw Exception(e);
      return []; // todo: impl
    }

    final decoded = json.decode(response.body) as Map;

    final responseCode = decoded[TriviaRepository._responseCodeKey] as int;
    switch (responseCode) {
      case >= 1 && <= 4:
        throw TriviaException.values[responseCode];
    }

    final quizzes = _sanitizeQuizzes(decoded[_resultsKey] as List);

    return quizzes.map(QuizDTO.fromJson).toList();
  }

  List<Map<String, dynamic>> _sanitizeQuizzes(List data) => data
      .map(
        (q) => (q as Map<String, dynamic>)
          ..update(
            "question",
            (value) => _convertUnescapeHtml(value as String),
          )
          ..update(
            "correct_answer",
            (value) => _convertUnescapeHtml(value as String),
          )
          ..update(
            "incorrect_answers",
            (value) => (value as List)
                .map(
                  (e) => _convertUnescapeHtml(e as String),
                )
                .toList(),
          ),
      )
      .toList();

  Map<String, String> _getQueryParams({
    required CategoryDTO category,
    required TriviaQuizDifficulty difficulty,
    required TriviaQuizType type,
    required int amount,
  }) =>
      {
        'amount': amount.toString(),
        'category': category.id.toString(),
        'difficulty': difficulty.param,
        'type': type.param,
      };
}

extension on TriviaQuizDifficulty {
  String get param => switch (this) {
        TriviaQuizDifficulty.any => '',
        TriviaQuizDifficulty.easy => 'easy',
        TriviaQuizDifficulty.medium => 'medium',
        TriviaQuizDifficulty.hard => 'hard',
      };
}

extension on TriviaQuizType {
  String get param => switch (this) {
        TriviaQuizType.any => '',
        TriviaQuizType.boolean => 'boolean',
        TriviaQuizType.multiple => 'multiple',
      };
}
