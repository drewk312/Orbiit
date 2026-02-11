import 'package:path/path.dart' as p;

class UniversalOrganizer {
  // ─────────────────────────────────────────────────────────────────────────
  // CONFIGURATION: Where does each console live?
  // ─────────────────────────────────────────────────────────────────────────
  static const Map<String, String> _standardPaths = {
    // Disc Consoles (Strict naming required)
    'Wii': 'wbfs', // USB Loader GX / WiiFlow
    'GameCube': 'games', // Nintendont (Strict!)
    'PS1': 'isos/psx', // WiiSXRX / Wiistation
    'PS2': 'isos/ps2', // WiiSX2 (Experimental)

    // Cartridge Consoles (Flexible naming, usually /roms)
    'N64': 'roms/n64', // Wii64 / Not64
    'SNES': 'roms/snes', // Snes9x GX
    'NES': 'roms/nes', // FCE Ultra GX
    'GBA': 'roms/gba', // Visual Boy Advance GX
    'GBC': 'roms/gbc', // Visual Boy Advance GX
    'GB': 'roms/gb', // Visual Boy Advance GX
    'Genesis': 'roms/gen', // Genesis Plus GX
    'MasterSystem': 'roms/sms',
    'GameGear': 'roms/gg',
    'Arcade': 'roms/mame',
  };

  /// Calculates the PRECISE path where the file should be saved.
  ///
  /// Returns a Map:
  /// - `fullPath`: The complete destination for the file.
  /// - `folder`: The parent directory (for creation).
  /// - `cleanName`: The sanitized name of the game (for display).
  static Map<String, String> getDestination(
      String rootDrive, String platform, String rawFilename) {
    // 1. Clean the filename to get a nice Title
    final ext = p.extension(rawFilename); // .iso, .wbfs, .zip
    final cleanTitle = _cleanTitle(rawFilename);
    final id = _extractId(rawFilename);

    // ───────────────────────────────────────────────────────────────────────
    // RULE 1: GameCube (Nintendont)
    // STRICT RULE: /games/Title [ID]/game.iso
    // ───────────────────────────────────────────────────────────────────────
    if (platform == 'GameCube') {
      // If we don't have an ID, we make a "No ID" folder.
      // Nintendont MIGHT run it without ID if folder path is simple,
      // but standard practice is Title [ID].
      final folderName = id != null ? '$cleanTitle [$id]' : cleanTitle;

      // Nintendont REQUIRED filename: "game.iso" (or game.ciso)
      // We rename it during download.
      final strictFileName = 'game$ext';

      return {
        'fullPath': p.join(rootDrive, 'games', folderName, strictFileName),
        'folder': p.join(rootDrive, 'games', folderName),
        'cleanName': cleanTitle,
      };
    }

    // ───────────────────────────────────────────────────────────────────────
    // RULE 2: Wii (USB Loader GX)
    // STANDARD: /wbfs/Title [ID]/ID.wbfs
    // ───────────────────────────────────────────────────────────────────────
    if (platform == 'Wii') {
      // Wii games MUST have an ID6 to be identified properly by loaders.
      // If we found one, use it. If not, fallback to filename (risky but better than crashing).
      final safeId = id ?? 'GAMEID';
      final folderName = '$cleanTitle [$safeId]';

      // Loaders prefer the file named as the ID (e.g., RMGE01.wbfs)
      // But they also accept Title.wbfs inside the folder.
      // We stick to the ID naming convention for maximum compatibility.
      final strictFileName = '$safeId$ext';

      return {
        'fullPath': p.join(rootDrive, 'wbfs', folderName, strictFileName),
        'folder': p.join(rootDrive, 'wbfs', folderName),
        'cleanName': cleanTitle,
      };
    }

    // ───────────────────────────────────────────────────────────────────────
    // RULE 3: PS1 (WiiSXRX)
    // STANDARD: /isos/psx/Title.bin
    // ───────────────────────────────────────────────────────────────────────
    if (platform == 'PS1') {
      // PS1 loaders usually scan a flat folder or subfolders.
      // Flat folder is safer for compatibility.
      final subFolder = _standardPaths['PS1']!;
      return {
        'fullPath': p.join(rootDrive, subFolder,
            rawFilename), // Keep original filename for compatibility (.cue sheets)
        'folder': p.join(rootDrive, subFolder),
        'cleanName': cleanTitle,
      };
    }

    // ───────────────────────────────────────────────────────────────────────
    // RULE 4: Retro / Hacks (N64, SNES, GBA, etc.)
    // STANDARD: /roms/console/Title (Hack Info).zip
    // ───────────────────────────────────────────────────────────────────────

    // Logic: For hacks like "Super Mario 74", we WANT to keep the specific version
    // info in the filename (e.g. "Hotfix 3") so the user knows which version it is.
    // We do NOT rename these to generic titles.

    final subFolder = _standardPaths[platform] ?? 'roms/misc';

    return {
      'fullPath': p.join(rootDrive, subFolder, rawFilename),
      'folder': p.join(rootDrive, subFolder),
      'cleanName': cleanTitle,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS (The "Janitor" Logic)
  // ─────────────────────────────────────────────────────────────────────────

  /// Extracts [GAMEID] (e.g., [RMGE01] or [SMNE01])
  /// Common in Redump/Myrient naming conventions.
  static String? _extractId(String filename) {
    // 1. Look for standard 6-char ID in brackets: [RMGE01]
    final bracketMatch = RegExp(r'\[([A-Z0-9]{6})\]').firstMatch(filename);
    if (bracketMatch != null) return bracketMatch.group(1);

    // 2. Look for ID at start of string (less common in Myrient, but possible)
    final startMatch = RegExp(r'^([A-Z0-9]{6})').firstMatch(filename);
    if (startMatch != null) return startMatch.group(1);

    return null;
  }

  /// Cleans up "Messy" Scene Release names for folders
  /// Input:  "Super Mario Galaxy (USA) (En,Fr,Es).rvz"
  /// Output: "Super Mario Galaxy"
  static String _cleanTitle(String filename) {
    var title = filename;

    // Remove Extension
    title = p.basenameWithoutExtension(title);

    // Remove ID [RMGE01]
    title = title.replaceAll(RegExp(r'\[[A-Z0-9]{6}\]'), '');

    // Remove Region (USA), (Europe), (Japan)
    title = title.replaceAll(
        RegExp(r'\((USA|Europe|Japan|En,Fr,Es|World)\)', caseSensitive: false),
        '');

    // Remove "Disc 1", "v1.0", etc if you want super clean folders
    // title = title.replaceAll(RegExp(r'\(Disc \d\)'), '');

    // Trim extra spaces
    return title.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
