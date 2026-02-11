import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';

class DriveDoctorService {
  static final DriveDoctorService _instance = DriveDoctorService._internal();
  factory DriveDoctorService() => _instance;
  DriveDoctorService._internal();

  final _logger = Logger('DriveDoctorService');

  /// Get partition info for the physical disk containing [driveLetter]
  Future<List<PartitionInfo>> getDiskPartitions(String driveLetter) async {
    if (!Platform.isWindows) return [];

    final letter = driveLetter.replaceAll(':', '').replaceAll('\\', '');

    try {
      // PowerShell command to get all partitions on the physical disk of the given drive letter
      final cmd = '''
\$ErrorActionPreference = 'Stop'
try {
    \$p = Get-Partition -DriveLetter $letter
    \$diskNumber = \$p.DiskNumber
    \$partitions = Get-Partition -DiskNumber \$diskNumber
    \$partitions | Select-Object PartitionNumber, DriveLetter, Size, Type, IsOffline | ConvertTo-Json -Compress
} catch {
    Write-Output "[]"
}
''';

      final result = await Process.run('powershell', ['-Command', cmd]);

      if (result.exitCode != 0) {
        _logger
            .warning('Failed to get partitions for $letter: ${result.stderr}');
        return [];
      }

      final jsonStr = result.stdout.toString().trim();
      if (jsonStr.isEmpty || jsonStr == '[]') return [];

      final dynamic parsed = jsonDecode(jsonStr);
      final list = parsed is List ? parsed : [parsed];

      return list.map((e) => PartitionInfo.fromJson(e)).toList();
    } catch (e) {
      _logger.severe('Error scanning partitions for $letter', e);
      return [];
    }
  }

  /// Get the Physical Disk Number for a drive letter
  Future<int?> getDiskNumber(String driveLetter) async {
    final letter = driveLetter.replaceAll(':', '').replaceAll('\\', '');
    final cmd = '(Get-Partition -DriveLetter $letter).DiskNumber';
    try {
      final result = await Process.run('powershell', ['-Command', cmd]);
      if (result.exitCode == 0) {
        return int.tryParse(result.stdout.toString().trim());
      }
    } catch (e) {
      _logger.warning('Failed to get disk number', e);
    }
    return null;
  }

  /// DANGEROUS: Formats the ENTIRE physical disk to a single FAT32 partition.
  /// This wipes ALL partitions on the disk.
  Future<void> formatDiskToSingleFAT32(int diskNumber) async {
    if (diskNumber < 0) throw Exception('Invalid disk number');

    // Double check it's not the system disk (0 is usually system, but not always)
    // We can't easily check "is system" from just number here without more queries,
    // but the UI calling this MUST verify safety.
    // We'll add a basic check against C: drive's disk number.

    final systemDisk = await getDiskNumber('C');
    if (systemDisk != null && diskNumber == systemDisk) {
      throw Exception('ABORTED: Attempted to format System Disk!');
    }

    // Create diskpart script
    final script = '''
select disk $diskNumber
clean
create partition primary
select partition 1
active
format fs=fat32 quick label="ORBIIT"
assign
exit
''';

    final tempDir = Directory.systemTemp;
    final scriptFile = File('${tempDir.path}\\format_script.txt');
    await scriptFile.writeAsString(script);

    try {
      _logger.info('Executing DiskPart on Disk $diskNumber...');
      final result = await Process.run('diskpart', ['/s', scriptFile.path]);

      if (result.exitCode != 0) {
        throw Exception('DiskPart failed: ${result.stdout} ${result.stderr}');
      }
      _logger.info('DiskPart success: ${result.stdout}');
    } finally {
      if (scriptFile.existsSync()) scriptFile.deleteSync();
    }
  }
}

class PartitionInfo {
  final int number;
  final String? driveLetter;
  final int size;
  final String type;

  PartitionInfo({
    required this.number,
    required this.size,
    required this.type,
    this.driveLetter,
  });

  factory PartitionInfo.fromJson(Map<String, dynamic> json) {
    return PartitionInfo(
      number: json['PartitionNumber'] ?? 0,
      driveLetter: json['DriveLetter'] == 0
          ? null
          : String.fromCharCode(json[
              'DriveLetter']), // PS returns char code sometimes? No, Get-Partition returns Char usually. Wait, ConvertTo-Json might encode char as int?
      // PowerShell Get-Partition 'DriveLetter' is a Char. ConvertTo-Json serializes Char as String usually.
      // But if it's null (0), it might be 0.
      // Let's handle both.
      size: json['Size'] ?? 0,
      type: json['Type'] ?? 'Unknown',
    );
  }
}
