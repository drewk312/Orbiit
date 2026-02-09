// ═══════════════════════════════════════════════════════════════════════════
// WiiGC-Fusion Extensions
// ═══════════════════════════════════════════════════════════════════════════
// Useful extension methods on built-in types.
// Import this file to enhance Dart's standard types with domain-specific utilities.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STRING EXTENSIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension StringExtensions on String {
  /// Check if string is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Check if string has content
  bool get hasContent => isNotEmpty;

  /// Capitalize first letter
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Title case (capitalize each word)
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalized).join(' ');
  }

  /// Remove all whitespace
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Truncate with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Make safe for filesystem
  String get asSafeFilename {
    return replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  /// Extract game ID from filename pattern [GAMEID]
  String? get extractGameId {
    final match = RegExp(r'\[([A-Z0-9]{6})\]').firstMatch(this);
    return match?.group(1);
  }

  /// Check if this is a valid 6-character game ID
  bool get isValidGameId => RegExp(r'^[A-Z0-9]{6}$').hasMatch(this);

  /// Return null if empty, otherwise return self
  String? get nullIfEmpty => isEmpty ? null : this;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// INTEGER EXTENSIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension IntExtensions on int {
  /// Format as file size (bytes to human readable)
  String get asFileSize {
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB';
    if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Format as duration (seconds to human readable)
  String get asDuration {
    if (this < 60) return '${this}s';
    if (this < 3600) return '${this ~/ 60}m ${this % 60}s';
    return '${this ~/ 3600}h ${(this % 3600) ~/ 60}m';
  }

  /// Clamp to percentage (0-100)
  int get asPercentage => clamp(0, 100).toInt();

  /// Is this a valid HTTP success status code?
  bool get isHttpSuccess => this >= 200 && this < 300;

  /// Is this a valid HTTP error status code?
  bool get isHttpError => this >= 400;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DOUBLE EXTENSIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension DoubleExtensions on double {
  /// Format as percentage string
  String get asPercentString => '${(this * 100).toStringAsFixed(1)}%';

  /// Format as integer percentage
  String get asIntPercentString => '${(this * 100).toInt()}%';

  /// Clamp to valid progress value (0.0-1.0)
  double get asProgress => clamp(0.0, 1.0).toDouble();

  /// Format as speed (bytes per second)
  String get asBytesPerSecond {
    if (this < 1024) return '${toStringAsFixed(0)} B/s';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB/s';
    return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  /// Format as file size
  String get asFileSize => toInt().asFileSize;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DURATION EXTENSIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension DurationExtensions on Duration {
  /// Format as human readable
  String get formatted {
    if (inHours > 0) {
      return '${inHours}h ${inMinutes.remainder(60)}m';
    }
    if (inMinutes > 0) {
      return '${inMinutes}m ${inSeconds.remainder(60)}s';
    }
    return '${inSeconds}s';
  }

  /// Format as compact string (e.g., "1:23:45")
  String get compact {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DATETIME EXTENSIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension DateTimeExtensions on DateTime {
  /// Format as relative time (e.g., "2 hours ago")
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  /// Format as short date (e.g., "Jan 26")
  String get shortDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[month - 1]} $day';
  }

  /// Format for filenames (safe characters only)
  String get asFilename =>
      toIso8601String().replaceAll(':', '-').split('.').first;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LIST EXTENSIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension ListExtensions<T> on List<T> {
  /// Safe get at index (returns null if out of bounds)
  T? safeGet(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Get first or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Separate into chunks
  List<List<T>> chunked(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, (i + size).clamp(0, length)));
    }
    return chunks;
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MAP EXTENSIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension MapExtensions<K, V> on Map<K, V> {
  /// Get value or default
  V getOr(K key, V defaultValue) => this[key] ?? defaultValue;

  /// Get value or compute default
  V getOrPut(K key, V Function() defaultValue) {
    return this[key] ?? (this[key] = defaultValue());
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// FILE EXTENSIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension FileExtensions on File {
  /// Get file size as human readable string
  Future<String> get sizeFormatted async {
    if (!await exists()) return 'N/A';
    return (await length()).asFileSize;
  }

  /// Get file extension (lowercase, without dot)
  String get extension {
    final name = path.split(Platform.pathSeparator).last;
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  /// Check if file is a game file
  bool get isGameFile {
    const gameExtensions = ['iso', 'wbfs', 'rvz', 'gcz', 'wia', 'ciso'];
    return gameExtensions.contains(extension);
  }
}

extension DirectoryExtensions on Directory {
  /// Get total size of directory contents
  Future<int> get totalSize async {
    if (!await exists()) return 0;

    int total = 0;
    await for (final entity in list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  /// Get file count in directory
  Future<int> get fileCount async {
    if (!await exists()) return 0;

    int count = 0;
    await for (final entity in list(recursive: true)) {
      if (entity is File) count++;
    }
    return count;
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NULLABLE EXTENSIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension NullableExtensions<T> on T? {
  /// Execute function if not null
  R? let<R>(R Function(T value) transform) {
    if (this != null) return transform(this as T);
    return null;
  }

  /// Get value or throw with message
  T orThrow(String message) {
    if (this == null) throw Exception(message);
    return this!;
  }
}
