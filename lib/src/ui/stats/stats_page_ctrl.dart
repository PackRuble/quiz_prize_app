import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/domain/bloc/trivia_quiz/trivia_quiz_bloc.dart';

class StatsPageCtrl {
  StatsPageCtrl({
    required Ref ref,
    required this.triviaStatsBloc,
  }) : _ref = ref;

  final Ref _ref;
  final TriviaStatsBloc triviaStatsBloc;

  static final instance = AutoDisposeProvider<StatsPageCtrl>(
    (ref) => StatsPageCtrl(
      ref: ref,
      triviaStatsBloc: ref.watch(TriviaStatsBloc.instance),
    ),
  );
}
