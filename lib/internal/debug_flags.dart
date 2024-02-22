// ignore_for_file: dead_code

import 'package:flutter/foundation.dart' show kDebugMode;

/// Flags for debugging. Change only the first operand.
abstract final class DebugFlags {
  static const _isRelease = !kDebugMode;

  static const triviaRepoUseMock = false && !_isRelease;
}
