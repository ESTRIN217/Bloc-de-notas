import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel {
  verbose(0, 'V'),
  debug(1, 'D'),
  info(2, 'I'),
  warning(3, 'W'),
  error(4, 'E');

  final int priority;
  final String tag;
  const LogLevel(this.priority, this.tag);
}

class LogService {
  LogService._();
  static final LogService _instance = LogService._();
  factory LogService() => _instance;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  void init() {
    _initialized = true;
    i('LogService initialized');
  }

  void v(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.verbose, message, error, stackTrace);
  }

  void d(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  void i(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  void w(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  void e(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  void _log(LogLevel level, String message, [Object? error, StackTrace? stackTrace]) {
    if (!kDebugMode && level == LogLevel.verbose) return;
    if (!kDebugMode && level == LogLevel.debug) return;

    final logMessage = error != null
        ? '$message | error: $error'
        : message;

    developer.log(
      logMessage,
      name: 'BlocDeNotas',
      level: level.priority * 250,
      error: error,
      stackTrace: stackTrace,
    );

    if (kDebugMode) {
      final prefix = '[${level.tag}] BlocDeNotas';
      if (level == LogLevel.error) {
        debugPrint('$prefix $logMessage');
        if (stackTrace != null) {
          debugPrint('$prefix StackTrace: $stackTrace');
        }
      } else {
        debugPrint('$prefix $logMessage');
      }
    }
  }
}

final Log = LogService();
