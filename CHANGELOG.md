## [2.0.0] - 29-02-2024

- reworked the `domain` layer
  - now uses `NotifierProvider` instead of `Provider` to implement business logic
  - improved data processing in `QuizGameNotifier`
  - re-delegated responsibilities: improvement of the SRP principle
  - added `QuizIteratorBloc`, `CategoriesNotifier`, `TokenNotifier`, `QuizConfigNotifier`
- added method of getting and resetting `TriviaTokenRepository` token
- fixed a bug in limiting the number of requests per second to the Trivia service
- the project has been renamed the "Quiz Prize".
- fixed small bugs in the interface
- added bonus for those who completed the entire quiz 🎉
- optimized query to the service of receiving quizzes and processed all possible server exceptions
- reorganization of folders in `ui` layer, now instead of controllers we use more semantically succinct presenters
- additional examples for working with "Cardoteka" were demonstrated
- better documentation and commenting of complex code points
- configured github actions processes for building and publishing apk artifacts
- screen has become limited in height (as it was previously limited in width)

## [1.0.2] - 29-06-2023

First public release 🎊

- implemented Trivia repository with methods of getting quizzes and getting categories
- fully organized gameplay
- implementation of "Cardoteka" as a data warehouse
- using `Provider` from "Riverpod" for state management
- game screen, stats screen, home screen
- choosing the difficulty of the quiz and its type
- tested on windows, android, web
- optimized to work on different screen sizes
- deploy application to web on github pages

## [0.0.1] - 24-05-2023

- 🎰 Beginning of development
