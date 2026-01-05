import 'package:flutter/foundation.dart';

/// Logger utility for consistent logging throughout the app.
///
/// Usage:
/// ```dart
/// AppLogger.info('User logged in');
/// AppLogger.error('Failed to fetch data', error: e, stackTrace: s);
/// ```
abstract class AppLogger {
  static const String _tag = 'PushUp';

  /// Log info message
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      print('💙 [${tag ?? _tag}] INFO: $message');
    }
  }

  /// Log warning message
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      print('💛 [${tag ?? _tag}] WARNING: $message');
    }
  }

  /// Log error message
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      print('❤️ [${tag ?? _tag}] ERROR: $message');
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }

  /// Log debug message (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      print('💜 [${tag ?? _tag}] DEBUG: $message');
    }
  }

  /// Log success message
  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      print('💚 [${tag ?? _tag}] SUCCESS: $message');
    }
  }
}
