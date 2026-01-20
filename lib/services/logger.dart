import 'package:logger/logger.dart';

/// Centralized logging service for the application
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log XML file operations
  static void logFileOperation(String operation, String filePath,
      {bool success = true}) {
    if (success) {
      info('$operation: $filePath');
    } else {
      error('Failed $operation: $filePath');
    }
  }

  /// Log bulk operations
  static void logBulkOperation(String operation, int claimCount) {
    info('Bulk operation - $operation: $claimCount claims');
  }

  /// Log validation errors
  static void logValidation(String field, String error) {
    warning('Validation error - $field: $error');
  }
}
