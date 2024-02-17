import 'dart:convert';
import 'dart:developer' show log;

import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;

import 'model_dto/category/category.dto.dart';
import 'model_dto/quiz/quiz.dto.dart';
import 'model_dto/trivia_config_models.dart';

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

  rateLimit(
      5,
      "Rate Limit Too many requests have occurred. "
      "Each IP can only access the API once every 5 seconds."),
  ;

  const TriviaException(this.code, this.message);

  final int code;
  final String message;
}

/// Each method in this [TriviaRepository] returns [TriviaResult]<[T]>.
sealed class TriviaResult<T> {
  const TriviaResult();

  const factory TriviaResult.data(T data) = TriviaData;
  const factory TriviaResult.exceptionApi(TriviaException exception) =
      TriviaExceptionApi;
  const factory TriviaResult.error(Object error, StackTrace stack) =
      TriviaError;
}

class TriviaData<T> extends TriviaResult<T> {
  const TriviaData(this.data);
  final T data;
}

class TriviaExceptionApi<T> extends TriviaResult<T> {
  const TriviaExceptionApi(this.exception);
  final TriviaException exception;
}

class TriviaError<T> extends TriviaResult<T> {
  const TriviaError(this.error, this.stack);
  final Object error;
  final StackTrace stack;
}

// todo(02/17/2024): `TriviaRepository` can become an `abstract base` class that
//  will have some useful methods and required parameters.
//  At the same time, the heirs will look exactly like `TriviaTokenRepository`.
//  This can be left as an example of different approaches.

/// Use [TriviaRepository] to get list of categories or to fetch a quiz.
class TriviaRepository {
  const TriviaRepository({
    required this.client,
    required this.useMockData,
  });

  final http.Client client;
  final bool useMockData;

  static const _baseUrl = 'opentdb.com';
  static const _responseCodeKey = 'response_code';

  String _convertUnescapeHtml(String data) => HtmlUnescape().convert(data);

  TriviaError<T> _makeTriviaError<T>(
    http.Response response, [
    String message = '',
    TriviaException? triviaExc,
  ]) {
    return TriviaError<T>(
      '$message '
      '${triviaExc == null ? '' : '${triviaExc.code}:${triviaExc.name}, ${triviaExc.message}. '}'
      'Status code ${response.statusCode}, message: ${response.reasonPhrase}',
      StackTrace.current,
    );
  }
}

/// Repository for working with Trivia API session tokens.
///
/// Trivia API says:
/// >Session Tokens are unique keys that will help keep track of the questions
/// the API has already retrieved. By appending a Session Token to a API Call,
/// the API will never give you the same question twice. Over the lifespan of
/// a Session Token, there will eventually reach a point where you have exhausted
/// all the possible questions in the database. At this point, the API
/// will respond with the appropriate "Response Code". From here, you can either
/// "Reset" the Token, which will wipe all past memory, or you can ask for a new one.
///
/// > *Session Tokens will be deleted after 6 hours of inactivity*.
class TriviaTokenRepository extends TriviaRepository {
  TriviaTokenRepository({required super.client}) : super(useMockData: false);

  static const _tokenApiPath = 'api_token.php';
  static const _dataKey = 'token';

  /// Trivia API says:
  /// > Session Tokens will be deleted after 6 hours of inactivity.
  static const tokenLifetime = Duration(hours: 6);

  /// Retrieve a Session Token.
  Future<TriviaResult<String>> fetchToken() async {
    log('$TriviaRepository.fetchToken been called');

    final uri = Uri.https(
      TriviaRepository._baseUrl,
      _tokenApiPath,
      {'command': 'request'},
    );

    log('-> by url: $uri');

    final http.Response response;
    try {
      response = await client.get(uri);
    } catch (e, s) {
      return TriviaResult.error(e, s);
    }

    if (response.statusCode != 200) {
      return _makeTriviaError(response, 'Failed to fetch Token.');
    }

    final decoded = json.decode(response.body) as Map;
    final responseCode = decoded[TriviaRepository._responseCodeKey] as int?;

    return switch (responseCode) {
      null => _makeTriviaError(response, 'Response Code is "null".'),
      0 => () {
          final token = decoded[_dataKey] as String;

          return TriviaResult<String>.data(token);
        }.call(),
      > 0 when responseCode < TriviaException.values.length =>
        TriviaResult.exceptionApi(TriviaException.values[responseCode]),
      _ =>
        _makeTriviaError(response, 'Trivia Api response code $responseCode.'),
    };
  }

  /// Reset a Session Token.
  ///
  /// - if returned `true` -> token reset request was successful
  /// - if returned `false` -> token not found on server
  /// - else [TriviaError]
  Future<TriviaResult<bool> /*[TriviaData] or [TriviaError] */ > resetToken(
    String token,
  ) async {
    log('$TriviaRepository.resetToken been called');

    final uri = Uri.https(
      TriviaRepository._baseUrl,
      _tokenApiPath,
      {'command': 'reset', 'token': token},
    );

    log('-> by url: $uri');

    final http.Response response;
    try {
      response = await client.get(uri);
    } catch (e, s) {
      return TriviaResult.error(e, s);
    }

    if (response.statusCode != 200) {
      return _makeTriviaError(response, 'Failed to reset Token.');
    }

    final decoded = json.decode(response.body) as Map;
    final responseCode = decoded[TriviaRepository._responseCodeKey] as int?;

    return switch (responseCode) {
      0 => const TriviaResult.data(true), // [TriviaException.success]
      3 => const TriviaResult.data(false), // [TriviaException.tokenNotFound]
      _ =>
        _makeTriviaError(response, 'Trivia Api response code $responseCode.'),
    };
  }
}

extension TriviaCategoryX on TriviaRepository {
  static const _categoriesApi = 'api_category.php';
  static const _dataKey = 'trivia_categories';

  /// Returns list of categories [List]<[CategoryDTO]>.
  /// Each category [CategoryDTO] is represented by name and id.
  Future<TriviaResult<List<CategoryDTO>>> getCategories() async {
    log('$TriviaRepository.getCategories been called');

    final uri = Uri.https(TriviaRepository._baseUrl, _categoriesApi);
    log('-> by url: $uri');

    final http.Response response;
    if (useMockData) {
      log('-> mock request');

      response = http.Response(_categoriesMockRaw, 200);
    } else {
      try {
        response = await client.get(uri);
      } catch (e, s) {
        return TriviaResult.error(e, s);
      }
    }

    if (response.statusCode != 200) {
      return _makeTriviaError(response, 'Failed to get categories.');
    }

    final body = json.decode(response.body) as Map;
    final categoriesJson =
        (body[_dataKey] as List).cast<Map<String, dynamic>>();
    return TriviaResult.data(categoriesJson.map(CategoryDTO.fromJson).toList());
  }
}

extension TriviaQuizX on TriviaRepository {
  static const _quizzesApi = 'api.php';
  static const _resultsKey = 'results';

  /// Returns list of quiz [List]<[QuizDTO]> by specified category, difficulty and type.
  ///
  /// This method may throw exception:
  /// - if status code from API was not 200. [Exception]
  /// - if response code was not 0. [TriviaException]
  ///
  /// Trivia API is still set up in such a way that it can't just give
  /// the maximum number of questions remaining. This means that if you ask for 20 quizzes
  /// and the server can only return 19, the error [TriviaException.noResults] will occur.
  ///
  /// I don't know what would have prevented just returning the remaining amount
  /// from the server. 🤷
  ///
  /// Updates
  ///
  /// 10.02.2024: On top of that, there is a limit on the number of requests on the current IP.
  /// Therefore, [TriviaException.rateLimit] was added.
  ///
  Future<TriviaResult<List<QuizDTO>>> getQuizzes({
    required CategoryDTO category,
    required TriviaQuizDifficulty difficulty,
    required TriviaQuizType type,
    int amount = 50,
    String? token,
  }) async {
    assert(0 < amount && amount <= 50);

    log('$TriviaRepository.getQuizzes been called');

    final uri = Uri.https(
      TriviaRepository._baseUrl,
      _quizzesApi,
      _makeQueryParams(
        category: category,
        difficulty: difficulty,
        type: type,
        amount: amount,
      )..addAll({'token': token ?? ''}),
    );

    log('-> by url: $uri');

    final http.Response response;
    if (useMockData) {
      log('-> mock request');

      response = http.Response(_quizzesMockRaw, 200);
    } else {
      try {
        response = await client.get(uri);
      } catch (e, s) {
        return TriviaResult.error(e, s);
      }
    }

    if (response.statusCode != 200) {
      if (response.statusCode == 429) {
        return const TriviaResult.exceptionApi(TriviaException.rateLimit);
      }
      return _makeTriviaError(response, 'Failed to get quiz.');
    }

    final decoded = json.decode(response.body) as Map;
    final responseCode = decoded[TriviaRepository._responseCodeKey] as int?;

    return switch (responseCode) {
      null => _makeTriviaError(response, 'Response Code is "null".'),
      0 => () {
          final quizzes = _sanitizeQuizzes(decoded[_resultsKey] as List);

          return TriviaResult.data(quizzes.map(QuizDTO.fromJson).toList());
        }.call(),
      > 0 when responseCode < TriviaException.values.length =>
        TriviaResult.exceptionApi(TriviaException.values[responseCode]),
      _ =>
        _makeTriviaError(response, 'Trivia Api response code $responseCode.'),
    };
  }

  List<Map<String, dynamic>> _sanitizeQuizzes(List data) => data
      .map(
        (q) => (q as Map<String, dynamic>)
          ..update(
            "category",
            (value) => _convertUnescapeHtml(value as String),
          )
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

  Map<String, String> _makeQueryParams({
    required CategoryDTO category,
    required TriviaQuizDifficulty difficulty,
    required TriviaQuizType type,
    required int amount,
  }) =>
      // even with empty parameters in the url request is processed successfully
      {
        'amount': amount.toString(),
        'category': category.param,
        'difficulty': difficulty.param,
        'type': type.param,
      };
}

extension on CategoryDTO {
  String get param => isAny ? '' : id.toString();
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

/// https://opentdb.com/api.php?amount=50
///
/// Mock quizzes in the amount of 50 pieces.
const _quizzesMockRaw =
    '''{"response_code":0,"results":[{"category":"Entertainment: Musicals & Theatres","type":"multiple","difficulty":"medium","question":"When was the play &quot;Macbeth&quot; written?","correct_answer":"1606","incorrect_answers":["1605","1723","1628"]},{"category":"Entertainment: Cartoon & Animations","type":"multiple","difficulty":"easy","question":"Which of the following did not feature in the cartoon &#039;Wacky Races&#039;?","correct_answer":"The Dragon Wagon","incorrect_answers":["The Bouldermobile","The Crimson Haybailer","The Compact Pussycat"]},{"category":"History","type":"multiple","difficulty":"medium","question":"Which king was killed at the Battle of Bosworth Field in 1485? ","correct_answer":"Richard III","incorrect_answers":["Edward V","Henry VII","James I"]},{"category":"Entertainment: Video Games","type":"boolean","difficulty":"easy","question":"The Mann Co. Store from Team Fortress 2 has the slogan &quot;We hire mercenaries and get in fights&quot;.","correct_answer":"False","incorrect_answers":["True"]},{"category":"General Knowledge","type":"multiple","difficulty":"medium","question":"A doctor with a PhD is a doctor of what?","correct_answer":"Philosophy","incorrect_answers":["Psychology","Phrenology","Physical Therapy"]},{"category":"Entertainment: Video Games","type":"boolean","difficulty":"medium","question":"Super Mario Bros. was released in 1990.","correct_answer":"False","incorrect_answers":["True"]},{"category":"Science & Nature","type":"multiple","difficulty":"medium","question":"What mineral has the lowest number on the Mohs scale?","correct_answer":"Talc","incorrect_answers":["Quartz","Diamond","Gypsum"]},{"category":"Entertainment: Video Games","type":"multiple","difficulty":"easy","question":"If a &quot;360 no-scope&quot; is one full rotation before shooting, how many rotations would a &quot;1080 no-scope&quot; be?","correct_answer":"3","incorrect_answers":["4","2","5"]},{"category":"Science: Computers","type":"multiple","difficulty":"medium","question":"Which of the following languages is used as a scripting language in the Unity 3D game engine?","correct_answer":"C#","incorrect_answers":["Java","C++","Objective-C"]},{"category":"Entertainment: Music","type":"multiple","difficulty":"medium","question":"Which country is singer Kyary Pamyu Pamyu from?","correct_answer":"Japan","incorrect_answers":["South Korea","China","Vietnam"]},{"category":"General Knowledge","type":"multiple","difficulty":"easy","question":"What is the name of the Jewish New Year?","correct_answer":"Rosh Hashanah","incorrect_answers":["Elul","New Year","Succoss"]},{"category":"Geography","type":"multiple","difficulty":"medium","question":"The land of Gotland is located in which European country?","correct_answer":"Sweden","incorrect_answers":["Denmark","Norway","Germany"]},{"category":"Entertainment: Film","type":"multiple","difficulty":"medium","question":"What is the name of the first &quot;Star Wars&quot; film by release order?","correct_answer":"A New Hope","incorrect_answers":["The Phantom Menace","The Force Awakens","Revenge of the Sith"]},{"category":"Entertainment: Music","type":"multiple","difficulty":"hard","question":"What is the name of the 2016 mixtape released by Venezuelan electronic producer Arca?","correct_answer":"Entra&ntilde;as","incorrect_answers":["&amp;&amp;&amp;&amp;&amp;&amp;","Sheep","Xen"]},{"category":"Science: Computers","type":"multiple","difficulty":"medium","question":"While Apple was formed in California, in which western state was Microsoft founded?","correct_answer":"New Mexico","incorrect_answers":["Washington","Colorado","Arizona"]},{"category":"Entertainment: Cartoon & Animations","type":"multiple","difficulty":"medium","question":"Which city did Anger berate for ruining pizza in &quot;Inside Out&quot;?","correct_answer":"San Francisco","incorrect_answers":["Minnesota","Washington","California"]},{"category":"Entertainment: Music","type":"multiple","difficulty":"hard","question":"Which of the following is NOT a real song from the band Thousand Foot Krutch?","correct_answer":"Limitless Fury","incorrect_answers":["Let The Sparks Fly","Down","Give Up The Ghost"]},{"category":"Entertainment: Video Games","type":"multiple","difficulty":"easy","question":"In what city in the dystopia alternate future of Half-Life 2 do you first start in?","correct_answer":"City 17","incorrect_answers":["City 18","City 6","City 45"]},{"category":"General Knowledge","type":"multiple","difficulty":"medium","question":"Who is the founder of &quot;The Lego Group&quot;?","correct_answer":"Ole Kirk Christiansen","incorrect_answers":[" Jens Niels Christiansen","Kirstine Christiansen"," Gerhardt Kirk Christiansen"]},{"category":"Entertainment: Video Games","type":"multiple","difficulty":"medium","question":"Capcom&#039;s survival horror title Dead Rising, canonically starts on what day of September 2006?","correct_answer":"September 19th","incorrect_answers":["September 21st","September 30th","September 14th"]},{"category":"Entertainment: Music","type":"multiple","difficulty":"easy","question":"In Mean Girls, who has breasts that tell when it&#039;s raining?","correct_answer":"Karen Smith","incorrect_answers":["Gretchen Weiners","Janice Ian","Cady Heron"]},{"category":"Celebrities","type":"multiple","difficulty":"medium","question":"When was Elvis Presley born?","correct_answer":"January 8, 1935","incorrect_answers":["December 13, 1931","July 18, 1940","April 17, 1938"]},{"category":"Entertainment: Comics","type":"multiple","difficulty":"medium","question":"In &quot;Sonic the Hedgehog&quot; comic, who was the creator of Roboticizer? ","correct_answer":"Professor Charles the Hedgehog","incorrect_answers":["Julian Robotnik","Ivo Robotnik","Snively Robotnik"]},{"category":"Entertainment: Television","type":"multiple","difficulty":"medium","question":"In &quot;The Big Bang Theory&quot;, what is Howard Wolowitz&#039;s nickname in World of Warcraft?","correct_answer":"Wolowizard","incorrect_answers":["Sheldor","Rajesh","Priya"]},{"category":"Entertainment: Video Games","type":"multiple","difficulty":"easy","question":"What is the maximum HP in Terraria?","correct_answer":"500","incorrect_answers":["400","1000","100"]},{"category":"Entertainment: Books","type":"multiple","difficulty":"hard","question":"Where does the book &quot;The Silence of the Lambs&quot; get its title from?","correct_answer":"The main character&#039;s trauma in childhood","incorrect_answers":["The relation it has with killing the innocents","The villain&#039;s favourite meal","The voice of innocent people being shut by the powerful"]},{"category":"Entertainment: Comics","type":"multiple","difficulty":"medium","question":"Who authored The Adventures of Tintin?","correct_answer":"Herg&eacute;","incorrect_answers":["E.P. Jacobs","Rin Tin Tin","Chic Young"]},{"category":"Celebrities","type":"multiple","difficulty":"medium","question":"Where was Kanye West born?","correct_answer":"Atlanta, Georgia","incorrect_answers":["Chicago, Illinois","Los Angeles, California","Detroit, Michigan"]},{"category":"Animals","type":"boolean","difficulty":"easy","question":"A caterpillar has more muscles than humans do.","correct_answer":"True","incorrect_answers":["False"]},{"category":"Entertainment: Video Games","type":"multiple","difficulty":"easy","question":"Which &quot;Fallout: New Vegas&quot; quest is NOT named after a real-life song?","correct_answer":"They Went That-a-Way","incorrect_answers":["Come Fly With Me","Ain&#039;t That a Kick in the Head","Ring-a-Ding Ding"]},{"category":"Geography","type":"boolean","difficulty":"medium","question":"Norway has a larger land area than Sweden.","correct_answer":"False","incorrect_answers":["True"]},{"category":"Entertainment: Video Games","type":"multiple","difficulty":"hard","question":"Which game in the &quot;Monster Hunter&quot; series introduced the monster &quot;Gobul&quot;?","correct_answer":"Monster Hunter Tri","incorrect_answers":["Monster Hunter Freedom Unite","Monster Hunter Frontier","Monster Hunter Generations"]},{"category":"Entertainment: Video Games","type":"multiple","difficulty":"medium","question":"Sean Bean voices the character of &quot;Martin Septim&quot; in which Elder Scrolls game?","correct_answer":"The Elder Scrolls IV: Oblivion","incorrect_answers":["The Elder Scrolls V: Skyrim","The Elder Scrolls III: Morrowind ","The Elder Scrolls Online"]},{"category":"Entertainment: Film","type":"multiple","difficulty":"medium","question":"Leonardo Di Caprio won his first Best Actor Oscar for his performance in which film?","correct_answer":"The Revenant","incorrect_answers":["The Wolf Of Wall Street","Shutter Island","Inception"]},{"category":"Entertainment: Film","type":"multiple","difficulty":"medium","question":"In the &quot;Jurassic Park&quot; universe, what is the name of the island that contains InGen&#039;s Site B?","correct_answer":"Isla Sorna","incorrect_answers":["Isla Nublar","Isla Pena","Isla Muerta"]},{"category":"Entertainment: Video Games","type":"multiple","difficulty":"medium","question":"What is the name of the 8th installment in the Fire Emblem series?","correct_answer":"The Sacred Stones","incorrect_answers":["Blazing Sword","Awakening","Path of Radiance"]},{"category":"Entertainment: Video Games","type":"multiple","difficulty":"easy","question":"What were the first two blocks in &quot;Minecraft&quot;?","correct_answer":"Grass and Cobblestone","incorrect_answers":["Grass and Stone","Crafting Table and Cobblestone","Cobblestone and Stone"]},{"category":"Science & Nature","type":"multiple","difficulty":"medium","question":"Which planet did the &quot;Viking 1&quot; spacecraft send surface images of, starting in 1976?","correct_answer":"Mars","incorrect_answers":["Saturn","Jupiter","Venus"]},{"category":"Entertainment: Books","type":"multiple","difficulty":"hard","question":"In the Magic: The Gathering universe,  the Antiquities, Ice Age, and Alliances expansions take place on which continent?","correct_answer":"Terisiare","incorrect_answers":["Aerona","Shiv","Jamuraa"]},{"category":"Geography","type":"multiple","difficulty":"easy","question":"Where would you find the &quot;Spanish Steps&quot;?","correct_answer":"Rome, Italy","incorrect_answers":["Barcelona, Spain","Berlin, Germany","London, England"]},{"category":"Entertainment: Music","type":"multiple","difficulty":"easy","question":"The &quot;British Invasion&quot; was a cultural phenomenon in music where British boy bands became popular in the USA in what decade?","correct_answer":"60&#039;s","incorrect_answers":["50&#039;s","40&#039;s","30&#039;s"]},{"category":"Geography","type":"multiple","difficulty":"medium","question":"Where is Hadrian&#039;s Wall located?","correct_answer":"Carlisle, England","incorrect_answers":["Rome, Italy","Alexandria, Egypt","Dublin, Ireland"]},{"category":"Entertainment: Japanese Anime & Manga","type":"multiple","difficulty":"easy","question":"What name is the main character Chihiro given in the 2001 movie &quot;Spirited Away&quot;?","correct_answer":"Sen (Thousand)","incorrect_answers":["Hyaku (Hundred)","Ichiman (Ten thousand)","Juu (Ten)"]},{"category":"Science & Nature","type":"multiple","difficulty":"medium","question":"What is the name of the cognitive bias wherein a person with low ability in a particular skill mistake themselves as being superior?","correct_answer":"Dunning-Kruger effect","incorrect_answers":["Meyers-Briggs effect","M&uuml;ller-Lyer effect","Freud-Hall effect"]},{"category":"Entertainment: Video Games","type":"multiple","difficulty":"hard","question":"Which drive form was added into Kingdom Hearts II Final Mix?","correct_answer":"Limit Form","incorrect_answers":["Valor Form","Wisdom Form","Anti Form"]},{"category":"Science & Nature","type":"multiple","difficulty":"easy","question":"Which of these Elements is a metalloid?","correct_answer":"Antimony","incorrect_answers":["Tin","Bromine","Rubidium"]},{"category":"Science & Nature","type":"multiple","difficulty":"medium","question":"What is the molecular formula of the active component of chili peppers(Capsaicin)?","correct_answer":"C18H27NO3","incorrect_answers":["C21H23NO3","C6H4Cl2","C13H25NO4"]},{"category":"Entertainment: Japanese Anime & Manga","type":"boolean","difficulty":"hard","question":"The protagonist in &quot;Humanity Has Declined&quot; has no discernable name and is simply referred to as &#039;I&#039; for most of the series.","correct_answer":"True","incorrect_answers":["False"]},{"category":"Entertainment: Video Games","type":"boolean","difficulty":"easy","question":"In Resident Evil 4, the Chicago Typewriter has infinite ammo.","correct_answer":"True","incorrect_answers":["False"]},{"category":"Animals","type":"boolean","difficulty":"easy","question":"The freshwater amphibian, the Axolotl, can regrow it&#039;s limbs.","correct_answer":"True","incorrect_answers":["False"]}]}''';

/// https://opentdb.com/api_category.php
///
/// Mock all categories.
const _categoriesMockRaw =
    '''{"trivia_categories":[{"id":9,"name":"General Knowledge"},{"id":10,"name":"Entertainment: Books"},{"id":11,"name":"Entertainment: Film"},{"id":12,"name":"Entertainment: Music"},{"id":13,"name":"Entertainment: Musicals & Theatres"},{"id":14,"name":"Entertainment: Television"},{"id":15,"name":"Entertainment: Video Games"},{"id":16,"name":"Entertainment: Board Games"},{"id":17,"name":"Science & Nature"},{"id":18,"name":"Science: Computers"},{"id":19,"name":"Science: Mathematics"},{"id":20,"name":"Mythology"},{"id":21,"name":"Sports"},{"id":22,"name":"Geography"},{"id":23,"name":"History"},{"id":24,"name":"Politics"},{"id":25,"name":"Art"},{"id":26,"name":"Celebrities"},{"id":27,"name":"Animals"},{"id":28,"name":"Vehicles"},{"id":29,"name":"Entertainment: Comics"},{"id":30,"name":"Science: Gadgets"},{"id":31,"name":"Entertainment: Japanese Anime & Manga"},{"id":32,"name":"Entertainment: Cartoon & Animations"}]}''';
