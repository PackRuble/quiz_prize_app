import 'package:flutter/material.dart' show Color, Colors;

final class AppColors {
  AppColors._();

  static Color correctCounterText = Colors.green.shade900;
  static Color unCorrectCounterText = Colors.red.shade900;

  static Color myAnswer = Colors.deepPurpleAccent.withOpacity(0.7);
  static Color correctAnswer = Colors.green.withOpacity(0.8);
  static Color unCorrectAnswer = Colors.red.withOpacity(0.6);
}
