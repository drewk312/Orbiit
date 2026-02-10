// ═══════════════════════════════════════════════════════════════════════════
// WiiGC-Fusion Result Type
// ═══════════════════════════════════════════════════════════════════════════
// A robust Result type for functional error handling.
// Eliminates null checks and try-catch blocks in favor of explicit success/failure.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';

/// A Result type that represents either success (Ok) or failure (Err).
///
/// Usage:
/// ```dart
/// Result<User, String> fetchUser(int id) {
///   try {
///     final user = await api.getUser(id);
///     return Ok(user);
///   } catch (e) {
///     return Err('Failed to fetch user: $e');
///   }
/// }
///
/// // Handle result
/// final result = await fetchUser(123);
/// result.when(
///   ok: (user) => print('Got user: ${user.name}'),
///   err: (error) => print('Error: $error'),
/// );
///
/// // Or use pattern matching
/// switch (result) {
///   case Ok(:final value):
///     print('Success: $value');
///   case Err(:final error):
///     print('Failed: $error');
/// }
/// ```
sealed class Result<T, E> {
  const Result();

  /// Returns true if the result is Ok
  bool get isOk => this is Ok<T, E>;

  /// Returns true if the result is Err
  bool get isErr => this is Err<T, E>;

  /// Gets the value if Ok, otherwise returns null
  T? get valueOrNull => switch (this) {
        Ok(:final value) => value,
        Err() => null,
      };

  /// Gets the error if Err, otherwise returns null
  E? get errorOrNull => switch (this) {
        Ok() => null,
        Err(:final error) => error,
      };

  /// Gets the value if Ok, otherwise throws
  T get valueOrThrow => switch (this) {
        Ok(:final value) => value,
        Err(:final error) => throw Exception('Result was Err: $error'),
      };

  /// Gets the value if Ok, otherwise returns the default
  T valueOr(T defaultValue) => switch (this) {
        Ok(:final value) => value,
        Err() => defaultValue,
      };

  /// Maps the success value to a new type
  Result<U, E> map<U>(U Function(T value) mapper) => switch (this) {
        Ok(:final value) => Ok(mapper(value)),
        Err(:final error) => Err(error),
      };

  /// Maps the error to a new type
  Result<T, F> mapErr<F>(F Function(E error) mapper) => switch (this) {
        Ok(:final value) => Ok(value),
        Err(:final error) => Err(mapper(error)),
      };

  /// Flat maps the success value
  Result<U, E> flatMap<U>(Result<U, E> Function(T value) mapper) =>
      switch (this) {
        Ok(:final value) => mapper(value),
        Err(:final error) => Err(error),
      };

  /// Execute callbacks based on success or failure
  R when<R>({
    required R Function(T value) ok,
    required R Function(E error) err,
  }) =>
      switch (this) {
        Ok(:final value) => ok(value),
        Err(:final error) => err(error),
      };

  /// Execute a callback if Ok, return self for chaining
  Result<T, E> ifOk(void Function(T value) action) {
    if (this case Ok(:final value)) {
      action(value);
    }
    return this;
  }

  /// Execute a callback if Err, return self for chaining
  Result<T, E> ifErr(void Function(E error) action) {
    if (this case Err(:final error)) {
      action(error);
    }
    return this;
  }
}

/// Success variant of Result
final class Ok<T, E> extends Result<T, E> {
  final T value;
  const Ok(this.value);

  @override
  String toString() => 'Ok($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Ok<T, E> && other.value == value);

  @override
  int get hashCode => value.hashCode;
}

/// Failure variant of Result
final class Err<T, E> extends Result<T, E> {
  final E error;
  const Err(this.error);

  @override
  String toString() => 'Err($error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Err<T, E> && other.error == error);

  @override
  int get hashCode => error.hashCode;
}

/// Extension for async Result operations
extension ResultFuture<T, E> on Future<Result<T, E>> {
  /// Awaits and maps the success value
  Future<Result<U, E>> mapAsync<U>(U Function(T value) mapper) async {
    return (await this).map(mapper);
  }

  /// Awaits and flat maps the success value
  Future<Result<U, E>> flatMapAsync<U>(
    FutureOr<Result<U, E>> Function(T value) mapper,
  ) async {
    return switch (await this) {
      Ok(:final value) => await mapper(value),
      Err(:final error) => Err(error),
    };
  }
}

/// Convenience function to wrap try-catch in a Result
Result<T, String> tryResult<T>(T Function() operation) {
  try {
    return Ok(operation());
  } catch (e) {
    return Err(e.toString());
  }
}

/// Async version of tryResult
Future<Result<T, String>> tryResultAsync<T>(
  FutureOr<T> Function() operation,
) async {
  try {
    return Ok(await operation());
  } catch (e) {
    return Err(e.toString());
  }
}

/// Combines multiple Results into one
/// Returns Err with first error if any fail, otherwise Ok with list of values
Result<List<T>, E> combineResults<T, E>(List<Result<T, E>> results) {
  final values = <T>[];

  for (final result in results) {
    switch (result) {
      case Ok(:final value):
        values.add(value);
      case Err(:final error):
        return Err(error);
    }
  }

  return Ok(values);
}
