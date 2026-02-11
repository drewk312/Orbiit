import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/app_logger.dart';

/// Service for detecting and setting up Wii SD card structure
class SDCardService {
  /// Expected Wii folder structure
  static const List<String> requiredFolders = [
    'apps',
    'private',
    'savegames',
    'wbfs', // Standard Wii games folder
    'games', // Nintendont/GameCube games folder
  ];

  /// Optional folders for specific mods
  static const List<String> optionalFolders = [
    'Project+',
    'codes',
    'riivolution',
    'sneek', // NAND emulation
    'wad', // WAD files
  ];

  /// Detects all removable drives that might be SD cards or USB drives
  Future<List<SDCardInfo>> detectSDCards() async {
    final logger = AppLogger.instance;
    final List<SDCardInfo> cards = [];

    if (!Platform.isWindows) {
      return cards; // Only Windows for now
    }

    // METHOD 1: PowerShell / CIM (Fast & Reliable)
    try {
      final result = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          'Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID, DriveType, VolumeName | ConvertTo-Json -Compress'
        ],
        runInShell: true,
      );

      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        final output = result.stdout.toString().trim();
        List<dynamic> drives = [];

        try {
          if (output.startsWith('[')) {
            drives = jsonDecode(output);
          } else {
            drives = [jsonDecode(output)];
          }
        } catch (jsonErr) {
          logger.warning('Failed to parse drive JSON: $jsonErr');
          // Fall through to legacy method
        }

        if (drives.isNotEmpty) {
          for (final d in drives) {
            final deviceId = d['DeviceID']?.toString() ?? ''; // "C:"
            final driveType = d['DriveType'] is int
                ? d['DriveType']
                : int.tryParse(d['DriveType'].toString()) ?? 0;
            final label = d['VolumeName']?.toString() ?? '';
            final path = '$deviceId\\';

            // DriveType 2 = Removable, 3 = Fixed (HDD/SSD)
            if (driveType != 2 && driveType != 3) {
              continue;
            }

            // CRITICAL: Skip system drive (C:)
            if (_isSystemDrive(path)) {
              continue;
            }

            // Check if drive is actually accessible (ready)
            try {
              if (await Directory(path).exists()) {
                cards.add(await _buildCardInfo(path, label, driveType));
              }
            } catch (e) {
              logger.warning('Drive $path detected but not accessible: $e');
            }
          }

          if (cards.isNotEmpty) return cards;
        }
      }
    } catch (e) {
      logger.error('PowerShell drive detection failed', error: e);
    }

    // METHOD 2: Legacy Fallback (A-Z Loop)
    // Only use this if PowerShell failed completely
    logger.info('Falling back to legacy drive scan...');

    for (int i = 65; i <= 90; i++) {
      final driveLetter = String.fromCharCode(i);
      final drivePath = '$driveLetter:\\';
      final drive = Directory(drivePath);

      try {
        if (await drive.exists()) {
          if (_isSystemDrive(drivePath)) continue;

          // Check if it's a supported drive
          final driveInfo = await _getDriveInfoLegacy(drivePath);
          if (driveInfo.isRemovable) {
            cards.add(await _buildCardInfo(drivePath, driveInfo.label, 2));
          }
        }
      } catch (e) {
        continue;
      }
    }

    return cards;
  }

  Future<SDCardInfo> _buildCardInfo(
      String path, String label, int driveType) async {
    return SDCardInfo(
      path: path,
      label: label.isEmpty
          ? (driveType == 2 ? 'Removable Disk' : 'Local Disk')
          : label,
      isWiiReady: await _isWiiReady(path),
      hasBootElf: await File(p.join(path, 'boot.elf')).exists(),
      existingFolders: await _getExistingFolders(path),
    );
  }

  /// Checks if drive has proper Wii folder structure
  Future<bool> _isWiiReady(String drivePath) async {
    try {
      // Check for either boot.elf OR apps/ folder
      final hasBootElf = await File(p.join(drivePath, 'boot.elf')).exists();
      final hasApps = await Directory(p.join(drivePath, 'apps')).exists();
      return hasBootElf || hasApps;
    } catch (e) {
      return false;
    }
  }

  /// Get list of existing Wii folders
  Future<List<String>> _getExistingFolders(String drivePath) async {
    final existing = <String>[];
    final allFolders = [...requiredFolders, ...optionalFolders];

    for (final folder in allFolders) {
      final folderPath = p.join(drivePath, folder);
      if (await Directory(folderPath).exists()) {
        existing.add(folder);
      }
    }

    return existing;
  }

  /// Legacy method: Get drive information using wmic (Windows)
  Future<_DriveInfo> _getDriveInfoLegacy(String drivePath) async {
    try {
      final deviceId = drivePath.endsWith('\\')
          ? drivePath.substring(0, drivePath.length - 1)
          : drivePath;

      final result = await Process.run(
        'wmic',
        [
          'logicaldisk',
          'where',
          'DeviceID="$deviceId"',
          'get',
          'DriveType,VolumeName'
        ],
        runInShell: true,
      );

      final output = result.stdout.toString();
      final lines =
          output.split('\n').where((l) => l.trim().isNotEmpty).toList();

      if (lines.length > 1) {
        final parts = lines[1].trim().split(RegExp(r'\s{2,}'));
        final driveType = int.tryParse(parts[0]) ?? 0;
        final label = parts.length > 1 ? parts[1] : '';
        // 2=Removable, 3=Fixed
        final isSupportedType = driveType == 2 || driveType == 3;

        return _DriveInfo(
          isRemovable: isSupportedType,
          label: label.isNotEmpty
              ? label
              : (driveType == 3 ? 'Local Disk' : 'Removable Disk'),
        );
      }
    } catch (e) {
      // Fallback: assume it's removable/supported if it's not C:
      return _DriveInfo(
        isRemovable: drivePath[0].toUpperCase() != 'C',
        label: 'Unknown Drive',
      );
    }
    return _DriveInfo(isRemovable: false, label: '');
  }

  /// Check if a drive path is the system drive (C:)
  bool _isSystemDrive(String drivePath) {
    if (drivePath.isEmpty) return false;
    final letter = drivePath[0].toUpperCase();

    // Get Windows system drive from environment
    final systemRoot = Platform.environment['SystemRoot'] ??
        Platform.environment['SYSTEMROOT'] ??
        'C:\\Windows';
    final systemDrive =
        systemRoot.isNotEmpty ? systemRoot[0].toUpperCase() : 'C';

    return letter == systemDrive;
  }

  /// Setup Wii folder structure on SD card
  Future<SDCardSetupResult> setupSDCard(
    String drivePath, {
    bool createRequired = true,
    bool createOptional = false,
  }) async {
    final created = <String>[];
    final errors = <String>[];

    try {
      // Create required folders
      if (createRequired) {
        for (final folder in requiredFolders) {
          final folderPath = p.join(drivePath, folder);
          try {
            final dir = Directory(folderPath);
            if (!await dir.exists()) {
              await dir.create(recursive: true);
              created.add(folder);
            }
          } catch (e) {
            errors.add('Failed to create $folder: $e');
          }
        }
      }

      // Create optional folders
      if (createOptional) {
        for (final folder in optionalFolders) {
          final folderPath = p.join(drivePath, folder);
          try {
            final dir = Directory(folderPath);
            if (!await dir.exists()) {
              await dir.create(recursive: true);
              created.add(folder);
            }
          } catch (e) {
            errors.add('Failed to create $folder: $e');
          }
        }
      }

      return SDCardSetupResult(
        success: errors.isEmpty,
        created: created,
        errors: errors,
      );
    } catch (e) {
      return SDCardSetupResult(
        success: false,
        created: created,
        errors: ['Setup failed: $e'],
      );
    }
  }

  /// Get save location path (SD:/savegames/)
  String getSaveLocation(String drivePath) {
    return p.join(drivePath, 'savegames');
  }
}

/// Information about a detected SD card
class SDCardInfo {
  final String path;
  final String label;
  final bool isWiiReady;
  final bool hasBootElf;
  final List<String> existingFolders;
  final String busType;
  final String freeSpace;

  SDCardInfo({
    required this.path,
    required this.label,
    required this.isWiiReady,
    required this.hasBootElf,
    required this.existingFolders,
    this.busType = 'SD',
    this.freeSpace = 'Unknown',
  });

  /// Display name for the SD card
  String get displayName => '$label ($path)';

  /// Missing required folders
  List<String> get missingFolders {
    return SDCardService.requiredFolders
        .where((f) => !existingFolders.contains(f))
        .toList();
  }

  /// Is the SD card fully set up for Wii
  bool get isComplete => missingFolders.isEmpty && hasBootElf;
}

/// Result of SD card setup operation
class SDCardSetupResult {
  final bool success;
  final List<String> created;
  final List<String> errors;

  SDCardSetupResult({
    required this.success,
    required this.created,
    required this.errors,
  });
}

/// Private class for drive info
class _DriveInfo {
  final bool isRemovable;
  final String label;

  _DriveInfo({required this.isRemovable, required this.label});
}
