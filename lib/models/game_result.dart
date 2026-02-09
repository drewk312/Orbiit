// ═══════════════════════════════════════════════════════════════════════════
// Game Result Model
// ═══════════════════════════════════════════════════════════════════════════
// Unified model representing a game from any discovery source.
// Used across search results, downloads, and library management.
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';

/// Represents a game discovered from any source (Archive.org, Myrient, etc.)
///
/// This is the primary model passed between:
/// - Discovery providers (search results)
/// - Forge provider (download queue)
/// - Library state (local collection)
@immutable
class GameResult {
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CORE PROPERTIES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Display title of the game
  final String title;

  /// Platform: "Wii", "GameCube"
  final String platform;

  /// Region code: "USA", "EUR", "JPN", "PAL"
  final String region;

  /// Source provider: "Archive.org", "Myrient", etc.
  final String provider;

  /// URL to the game's page on the source site
  final String pageUrl;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // OPTIONAL PROPERTIES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Unique slug for homebrew apps (e.g. "usbloader_gx")
  final String? slug;

  /// Direct download URL (if available)
  final String? downloadUrl;

  /// Cover art URL
  final String? coverUrl;

  /// 6-character game ID (e.g., "RMGE01")
  final String? gameId;

  /// File size in megabytes
  final int? fileSizeMb;

  /// Human-readable size string (e.g., "4.3 GB")
  final String? size;

  /// Version/revision if known
  final String? version;

  /// Short description of the game/app
  final String? description;

  /// Archive.org identifier for metadata resolution
  final String? sourceIdentifier;

  /// Game format (e.g. ISO, WBFS, RVZ)
  final String? format;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DOWNLOAD FLAGS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// True if download requires browser automation
  final bool requiresBrowser;

  /// True if downloadUrl can be fetched directly
  final bool isDirectDownload;

  const GameResult({
    required this.title,
    required this.platform,
    required this.region,
    required this.provider,
    required this.pageUrl,
    this.slug,
    this.downloadUrl,
    this.coverUrl,
    this.gameId,
    this.fileSizeMb,
    this.size,
    this.version,
    this.description,
    this.requiresBrowser = false,
    this.isDirectDownload = false,
    this.sourceIdentifier,
    this.format,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'platform': platform,
        'region': region,
        'provider': provider,
        'pageUrl': pageUrl,
        'slug': slug,
        'downloadUrl': downloadUrl,
        'coverUrl': coverUrl,
        'gameId': gameId,
        'fileSizeMb': fileSizeMb,
        'size': size,
        'version': version,
        'description': description,
        'requiresBrowser': requiresBrowser,
        'isDirectDownload': isDirectDownload,
        'sourceIdentifier': sourceIdentifier,
        'format': format,
      };

  factory GameResult.fromJson(Map<String, dynamic> json) => GameResult(
        title: json['title'] ?? '',
        platform: json['platform'] ?? '',
        region: json['region'] ?? 'USA',
        provider: json['provider'] ?? '',
        pageUrl: json['pageUrl'] ?? '',
        slug: json['slug'],
        downloadUrl: json['downloadUrl'],
        coverUrl: json['coverUrl'],
        gameId: json['gameId'],
        fileSizeMb: json['fileSizeMb'],
        size: json['size'],
        version: json['version'],
        description: json['description'],
        requiresBrowser: json['requiresBrowser'] ?? false,
        isDirectDownload: json['isDirectDownload'] ?? false,
        sourceIdentifier: json['sourceIdentifier'],
        format: json['format'],
      );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // COMPUTED PROPERTIES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// True if this game is for Nintendo Wii
  bool get isWii => platform.toLowerCase() == 'wii';

  /// True if this game is for Nintendo GameCube
  bool get isGameCube =>
      platform.toLowerCase() == 'gamecube' || platform.toLowerCase() == 'gc';

  /// True if game ID is available and valid
  bool get hasValidGameId =>
      gameId != null &&
      gameId!.isNotEmpty &&
      RegExp(r'^[A-Z0-9]{6}$').hasMatch(gameId!);

  /// True if a direct download is possible
  bool get canDirectDownload =>
      isDirectDownload && downloadUrl != null && downloadUrl!.isNotEmpty;

  /// True if we need to resolve URL from Archive.org identifier
  bool get needsUrlResolution =>
      !canDirectDownload &&
      sourceIdentifier != null &&
      sourceIdentifier!.isNotEmpty;

  /// Get a safe filename based on title and game ID
  String get safeFilename {
    final safeName = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
    final id = hasValidGameId ? ' [$gameId]' : '';
    return '$safeName$id';
  }

  /// Get formatted file size
  String get formattedSize {
    if (size != null && size!.isNotEmpty) return size!;
    if (fileSizeMb == null) return 'Unknown';
    if (fileSizeMb! >= 1024)
      return '${(fileSizeMb! / 1024).toStringAsFixed(1)} GB';
    return '$fileSizeMb MB';
  }

  /// Get region flag emoji
  String get regionEmoji {
    switch (region.toUpperCase()) {
      case 'USA':
      case 'US':
      case 'NTSC-U':
        return '🇺🇸';
      case 'EUR':
      case 'PAL':
        return '🇪🇺';
      case 'JPN':
      case 'NTSC-J':
        return '🇯🇵';
      case 'KOR':
        return '🇰🇷';
      default:
        return '🌍';
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // COPY WITH
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Create a copy with modified fields
  GameResult copyWith({
    String? title,
    String? platform,
    String? region,
    String? provider,
    String? pageUrl,
    String? downloadUrl,
    String? coverUrl,
    String? gameId,
    int? fileSizeMb,
    String? size,
    String? version,
    bool? requiresBrowser,
    bool? isDirectDownload,
    String? sourceIdentifier,
    String? format,
  }) {
    return GameResult(
      title: title ?? this.title,
      platform: platform ?? this.platform,
      region: region ?? this.region,
      provider: provider ?? this.provider,
      pageUrl: pageUrl ?? this.pageUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      gameId: gameId ?? this.gameId,
      fileSizeMb: fileSizeMb ?? this.fileSizeMb,
      size: size ?? this.size,
      version: version ?? this.version,
      requiresBrowser: requiresBrowser ?? this.requiresBrowser,
      isDirectDownload: isDirectDownload ?? this.isDirectDownload,
      sourceIdentifier: sourceIdentifier ?? this.sourceIdentifier,
      format: format ?? this.format,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // EQUALITY & HASH
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GameResult) return false;

    // Primary match by game ID if available
    if (hasValidGameId && other.hasValidGameId) {
      return gameId == other.gameId;
    }

    // Fallback to pageUrl match
    return pageUrl == other.pageUrl;
  }

  @override
  int get hashCode {
    if (hasValidGameId) return gameId.hashCode;
    return pageUrl.hashCode;
  }

  @override
  String toString() => 'GameResult($title [$gameId] - $platform $region)';
}
