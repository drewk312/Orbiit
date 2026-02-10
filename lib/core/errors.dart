// ═══════════════════════════════════════════════════════════════════════════
// WiiGC-Fusion Application Errors
// ═══════════════════════════════════════════════════════════════════════════
// Structured error types for better error handling and user messaging.
// Each error type includes context for debugging and user-friendly messages.
// ═══════════════════════════════════════════════════════════════════════════

import '../globals.dart';

/// Base class for all WiiGC-Fusion errors
sealed class AppError implements Exception {
  /// Technical error message for logging
  String get message;

  /// User-friendly error message for display
  String get userMessage;

  /// Optional underlying error
  Object? get cause;

  /// Optional stack trace
  StackTrace? get stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NETWORK ERRORS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Errors related to network operations
sealed class NetworkError extends AppError {
  final String url;

  NetworkError({required this.url});
}

/// HTTP request failed with an error status code
final class HttpError extends NetworkError {
  final int statusCode;
  final String? responseBody;

  @override
  final Object? cause;

  @override
  final StackTrace? stackTrace;

  HttpError({
    required super.url,
    required this.statusCode,
    this.responseBody,
    this.cause,
    this.stackTrace,
  });

  @override
  String get message => 'HTTP $statusCode for $url';

  @override
  String get userMessage {
    if (statusCode == 404) return 'Resource not found';
    if (statusCode == 401 || statusCode == 403) return 'Access denied';
    if (statusCode >= 500) return 'Server error. Please try again later.';
    return 'Network request failed (Error $statusCode)';
  }

  /// Check if this is a client error (4xx)
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Check if this is a server error (5xx)
  bool get isServerError => statusCode >= 500;

  /// Check if this error is likely temporary and retry makes sense
  bool get isRetryable => statusCode >= 500 || statusCode == 429;
}

/// Network connection failed
final class ConnectionError extends NetworkError {
  @override
  final Object? cause;

  @override
  final StackTrace? stackTrace;

  ConnectionError({
    required super.url,
    this.cause,
    this.stackTrace,
  });

  @override
  String get message => 'Connection failed for $url: $cause';

  @override
  String get userMessage =>
      'Could not connect. Check your internet connection.';
}

/// Request timed out
final class TimeoutError extends NetworkError {
  final Duration timeout;

  @override
  final Object? cause;

  @override
  final StackTrace? stackTrace;

  TimeoutError({
    required super.url,
    required this.timeout,
    this.cause,
    this.stackTrace,
  });

  @override
  String get message => 'Request to $url timed out after ${timeout.inSeconds}s';

  @override
  String get userMessage => 'Request timed out. Please try again.';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// FILE ERRORS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Errors related to file operations
sealed class FileError extends AppError {
  final String path;

  FileError({required this.path});
}

/// File not found
final class FileNotFoundError extends FileError {
  @override
  final Object? cause;

  @override
  final StackTrace? stackTrace;

  FileNotFoundError({
    required super.path,
    this.cause,
    this.stackTrace,
  });

  @override
  String get message => 'File not found: $path';

  @override
  String get userMessage => 'File not found';
}

/// File access denied
final class FileAccessError extends FileError {
  @override
  final Object? cause;

  @override
  final StackTrace? stackTrace;

  FileAccessError({
    required super.path,
    this.cause,
    this.stackTrace,
  });

  @override
  String get message => 'Access denied for: $path';

  @override
  String get userMessage => 'Cannot access file. Check permissions.';
}

/// File is corrupted or invalid
final class FileCorruptError extends FileError {
  final String reason;

  @override
  final Object? cause;

  @override
  final StackTrace? stackTrace;

  FileCorruptError({
    required super.path,
    required this.reason,
    this.cause,
    this.stackTrace,
  });

  @override
  String get message => 'Corrupted file at $path: $reason';

  @override
  String get userMessage => 'File appears to be corrupted.';
}

/// Not enough disk space
final class InsufficientSpaceError extends FileError {
  final int requiredBytes;
  final int availableBytes;

  @override
  final Object? cause;

  @override
  final StackTrace? stackTrace;

  InsufficientSpaceError({
    required super.path,
    required this.requiredBytes,
    required this.availableBytes,
    this.cause,
    this.stackTrace,
  });

  @override
  String get message =>
      'Insufficient space at $path: need $requiredBytes, have $availableBytes';

  @override
  String get userMessage => 'Not enough disk space.';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DOWNLOAD ERRORS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Errors during download operations
sealed class DownloadError extends AppError {
  final String url;
  final String? gameTitle;

  DownloadError({required this.url, this.gameTitle});
}

/// Download was cancelled
final class DownloadCancelledError extends DownloadError {
  @override
  final Object? cause;

  @override
  final StackTrace? stackTrace;

  DownloadCancelledError({
    required super.url,
    super.gameTitle,
    this.cause,
    this.stackTrace,
  });

  @override
  String get message => 'Download cancelled: ${gameTitle ?? url}';

  @override
  String get userMessage => 'Download was cancelled';
}

/// Downloaded file is too small (likely error page or empty)
final class DownloadTooSmallError extends DownloadError {
  final int actualSize;
  final int minimumSize;

  @override
  final Object? cause;

  @override
  final StackTrace? stackTrace;

  DownloadTooSmallError({
    required super.url,
    super.gameTitle,
    required this.actualSize,
    required this.minimumSize,
    this.cause,
    this.stackTrace,
  });

  @override
  String get message =>
      'Downloaded file too small: $actualSize bytes (minimum: $minimumSize)';

  @override
  String get userMessage => 'Download failed - file is incomplete or invalid.';
}

/// No download source found
final class NoSourceError extends DownloadError {
  @override
  final Object? cause;

  @override
  final StackTrace? stackTrace;

  NoSourceError({
    required super.url,
    super.gameTitle,
    this.cause,
    this.stackTrace,
  });

  @override
  String get message => 'No download source available for: ${gameTitle ?? url}';

  @override
  String get userMessage => 'No download source found for this game.';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NATIVE/FFI ERRORS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Errors from native C++ code
sealed class NativeError extends AppError {}

/// Native library not found
final class NativeLibraryNotFoundError extends NativeError {
  final String libraryName;

  @override
  final Object? cause;

  @override
  final StackTrace? stackTrace;

  NativeLibraryNotFoundError({
    required this.libraryName,
    this.cause,
    this.stackTrace,
  });

  @override
  String get message => 'Native library not found: $libraryName';

  @override
  String get userMessage =>
      'Core library missing. Please reinstall the application.';
}

/// Native function call failed
final class NativeCallError extends NativeError {
  final String function;
  final String reason;

  @override
  final Object? cause;

  @override
  final StackTrace? stackTrace;

  NativeCallError({
    required this.function,
    required this.reason,
    this.cause,
    this.stackTrace,
  });

  @override
  String get message => 'Native call to $function failed: $reason';

  @override
  String get userMessage => 'Operation failed. Please try again.';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// VALIDATION ERRORS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Validation/input errors
sealed class ValidationError extends AppError {}

/// Invalid game ID format
final class InvalidGameIdError extends ValidationError {
  final String gameId;

  @override
  final Object? cause;

  @override
  final StackTrace? stackTrace;

  InvalidGameIdError({
    required this.gameId,
    this.cause,
    this.stackTrace,
  });

  @override
  String get message => 'Invalid game ID format: $gameId';

  @override
  String get userMessage =>
      'Invalid game ID. Expected 6-character code (e.g., RMGE01).';
}

/// Invalid URL format
final class InvalidUrlError extends ValidationError {
  final String url;

  @override
  final Object? cause;

  @override
  final StackTrace? stackTrace;

  InvalidUrlError({
    required this.url,
    this.cause,
    this.stackTrace,
  });

  @override
  String get message => 'Invalid URL format: $url';

  @override
  String get userMessage => 'Invalid URL provided.';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// HELPER EXTENSIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension AppErrorExtensions on AppError {
  /// Log this error with the app logger
  void log() {
    // Import dynamically to avoid circular imports
    AppLogger.error(message, 'AppError', cause, stackTrace);
  }
}
