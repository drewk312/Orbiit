import 'package:flutter/foundation.dart';

class SmartSearchService {
  /// Basic typo correction map for popular titles
  static final Map<String, String> _commonTypos = {
    'maro': 'Mario',
    'mario party': 'Mario Party',
    'zelda': 'The Legend of Zelda',
    'smash bros': 'Super Smash Bros',
    'twilight princess': 'Twilight Princess',
    'galaxy': 'Super Mario Galaxy',
    'mk': 'Mario Kart',
  };

  /// Detect probable platforms based on query keywords
  List<String> detectPlatformHints(String query) {
    final lower = query.toLowerCase();
    final hints = <String>{};

    // Explicit platform names
    if (lower.contains('wii')) hints.add('wii');
    if (lower.contains('gamecube') || lower.contains('gc')) {
      hints.add('gamecube');
    }
    if (lower.contains('n64') || lower.contains('64')) hints.add('n64');
    if (lower.contains('gba') || lower.contains('advance')) hints.add('gba');
    if (lower.contains('snes') || lower.contains('super nintendo')) {
      hints.add('snes');
    }
    if (lower.contains('nes') || lower.contains('nintendo entertainment')) {
      hints.add('nes');
    }
    if (lower.contains('ds') && !lower.contains('3ds')) hints.add('nds');
    if (lower.contains('3ds')) hints.add('3ds');

    // Franchise mapping
    if (lower.contains('mario kart')) {
      hints.addAll(['wii', 'gamecube', 'n64', 'gba', 'snes', 'nds']);
    }
    if (lower.contains('super smash')) {
      hints.addAll(['wii', 'gamecube', 'n64']);
    }
    if (lower.contains('pokemon')) {
      hints.addAll(['gba', 'gbc', 'nds', '3ds', 'gameboy']);
    }
    if (lower.contains('metroid prime')) {
      hints.addAll(['gamecube', 'wii']);
    }
    if (lower.contains('skyward sword') ||
        lower.contains('twilight princess')) {
      hints.addAll(['wii', 'gamecube']);
    }
    if (lower.contains('wind waker')) {
      hints.add('gamecube');
    }

    return hints.toList();
  }

  /// Cleans and corrects the query
  String processQuery(String query) {
    if (query.isEmpty) return '';

    String cleaned = query.trim().toLowerCase();

    // Direct typo fix
    for (final typo in _commonTypos.keys) {
      if (cleaned.contains(typo)) {
        debugPrint(
            '[SmartSearch] Correcting typo: "$typo" -> "${_commonTypos[typo]}"');
        cleaned = cleaned.replaceAll(typo, _commonTypos[typo]!.toLowerCase());
      }
    }

    // Capitalize for display/search consistency
    return cleaned.split(' ').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }
}
