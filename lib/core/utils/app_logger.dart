import 'package:flutter/foundation.dart';

/// Lightweight logging for failures that must not be swallowed silently.
class AppLogger {
  AppLogger._();

  static void error(String context, Object error, [StackTrace? stackTrace]) {
    debugPrint('[HupWorks:$context] $error');
    if (stackTrace != null) {
      debugPrint('$stackTrace');
    }
  }

  static void warn(String context, String message) {
    debugPrint('[HupWorks:$context] $message');
  }
}
