import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Hardware Service - Manages external drives for Wii/GameCube
class HardwareService {
  /// Check if a drive is the system/OS drive (NEVER allow operations on this)
  static bool isSystemDrive(String driveLetter) {
    final letter =
        driveLetter.toUpperCase().replaceAll(':', '').replaceAll('\\', '');

    // Get Windows system drive from environment
    final systemRoot = Platform.environment['SystemRoot'] ??
        Platform.environment['SYSTEMROOT'] ??
        'C:\\Windows';
    final systemDrive =
        systemRoot.isNotEmpty ? systemRoot[0].toUpperCase() : 'C';

    return letter == systemDrive;
  }

  /// Get warning message for a drive
  static String? getDriveWarning(String driveLetter) {
    if (isSystemDrive(driveLetter)) {
      return '⚠️ SYSTEM DRIVE - Operations not allowed on your Windows drive!';
    }
    return null;
  }

  /// Detect connected drives using PowerShell (wmic is deprecated)
  Future<List<String>> getConnectedDrives() async {
    final drives = <String>[];

    if (Platform.isWindows) {
      try {
        // Use PowerShell Get-PSDrive instead of deprecated wmic
        final result = await Process.run(
          'powershell',
          [
            '-Command',
            'Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root'
          ],
        );

        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          for (final line in lines) {
            final drive = line.trim();
            if (drive.isNotEmpty && drive.contains(':')) {
              // Just get the drive letter with colon (e.g., "C:")
              final driveLetter = drive.substring(0, 2);

              // CRITICAL: Filter out system drive immediately
              if (!isSystemDrive(driveLetter) &&
                  !drives.contains(driveLetter)) {
                drives.add(driveLetter);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[HardwareService] Error detecting drives: $e');
        // Fallback: just return common drives, EXCLUDING system drive
        // Always safer to assume C: is system and exclude it
        drives.addAll(['D:', 'E:', 'F:', 'G:']);
      }
    }

    return drives;
  }

  /// Get detailed info for connected drives (letter, fs, size, name, removable)
  Future<List<Map<String, dynamic>>> getConnectedDrivesDetailed() async {
    final details = <Map<String, dynamic>>[];

    if (Platform.isWindows) {
      try {
        final result = await Process.run(
          'powershell',
          [
            '-Command',
            'Get-CimInstance Win32_LogicalDisk | ConvertTo-Json -Depth 3'
          ],
        );

        if (result.exitCode == 0) {
          final stdoutStr = result.stdout.toString().trim();
          final dynamic parsed =
              json.decode(stdoutStr.isEmpty ? '[]' : stdoutStr);
          final List<dynamic> list =
              parsed is List ? parsed : <dynamic>[parsed];

          for (final item in list) {
            final deviceId = (item['DeviceID'] ?? '').toString(); // e.g., "D:"
            if (deviceId.isEmpty) continue;
            if (isSystemDrive(deviceId)) continue;

            final driveType = item['DriveType'] ?? 0; // 2 removable, 3 local
            final fs = (item['FileSystem'] ?? 'Unknown').toString();
            final size = int.tryParse((item['Size'] ?? '0').toString()) ?? 0;
            final name = (item['VolumeName'] ?? 'USB Drive').toString();

            details.add({
              'letter': deviceId,
              'fs': fs,
              'size': size,
              'name': name,
              'removable': driveType == 2,
            });
          }
        }
      } catch (e) {
        debugPrint('[HardwareService] Error getting drive details: $e');
        final basic = await getConnectedDrives();
        for (final d in basic) {
          details.add({
            'letter': d,
            'fs': 'Unknown',
            'size': 0,
            'name': 'USB Drive',
            'removable': true,
          });
        }
      }
    }

    return details;
  }

  /// Get only removable/safe drives (excludes OS drive)
  Future<List<String>> getRemovableDrives() async {
    final allDrives = await getConnectedDrives();
    // Filter out system drive - NEVER allow operations on it
    return allDrives.where((drive) => !isSystemDrive(drive)).toList();
  }

  /// Validate drive selection - throws if attempting to select OS drive
  static void validateDriveSelection(String drivePath) {
    final driveLetter = drivePath.isNotEmpty ? drivePath[0] : '';
    if (isSystemDrive(driveLetter)) {
      throw Exception('Cannot select system drive ($driveLetter:). '
          'Please choose an external drive or SD card to protect your Windows installation.');
    }
  }

  /// Prepare a drive for Wii (deployment check)
  Future<bool> isDriveReady(String drivePath) async {
    // Safety check - never operate on system drive
    validateDriveSelection(drivePath);

    final wbfsDir = Directory('$drivePath/wbfs');
    final gamesDir = Directory('$drivePath/games');
    return await wbfsDir.exists() || await gamesDir.exists();
  }

  /// Deploy Wii structure to a drive
  Future<void> deployWiiStructure(String drivePath) async {
    // Safety check - never operate on system drive
    validateDriveSelection(drivePath);

    await Directory('$drivePath/wbfs').create(recursive: true);
    await Directory('$drivePath/games').create(recursive: true);
    await Directory('$drivePath/apps').create(recursive: true);
  }

  /// Format advice for Wii
  String getRecommendedFormat() {
    return 'FAT32 with 32KB Cluster Size';
  }
}
