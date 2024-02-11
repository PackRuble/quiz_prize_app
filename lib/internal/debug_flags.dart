

import 'package:flutter/foundation.dart' show kDebugMode;

abstract final class DebugFlags {

   static const _isRelease = kDebugMode;

   static const triviaRepoUseMock = false || !_isRelease;
}
