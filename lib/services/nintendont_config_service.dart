import 'dart:io';
import 'package:path/path.dart' as p;
import '../core/app_logger.dart';

/// Service for generating and managing Nintendont controller configurations
class NintendontConfigService {
  static const List<String> gcButtons = [
    'A', 'B', 'X', 'Y',
    'L', 'R', 'Z',
    'S', // Start
    'DUp', 'DDown', 'DLeft', 'DRight',
  ];

  static const List<String> gcAxes = [
    'LeftStickX',
    'LeftStickY',
    'RightStickX',
    'RightStickY',
    'LAnalog',
    'RAnalog',
  ];

  /// Generate Nintendont .ini config file
  Future<String> generateConfig({
    required String vid,
    required String pid,
    required String name,
    required Map<String, ButtonMapping> buttonMappings,
    required Map<String, AxisMapping> axisMappings,
  }) async {
    final buffer = StringBuffer();

    buffer.writeln('[Controller]');
    buffer.writeln('VID=$vid');
    buffer.writeln('PID=$pid');
    buffer.writeln('Name=$name');
    buffer.writeln('Polltype=1');
    buffer.writeln('DPAD=1');
    buffer.writeln();

    // Button mappings
    buffer.writeln('# Button Mappings');
    for (final entry in buttonMappings.entries) {
      buffer.writeln('${entry.key}=${entry.value.toIniFormat()}');
    }
    buffer.writeln();

    // Axis mappings
    buffer.writeln('# Axis Mappings');
    for (final entry in axisMappings.entries) {
      buffer.writeln('${entry.key}=${entry.value.axisIndex}');
    }

    return buffer.toString();
  }

  /// Save controller config to SD card
  Future<bool> saveConfigToSD({
    required String sdCardPath,
    required String vid,
    required String pid,
    required String configContent,
  }) async {
    try {
      // Ensure controllers directory exists
      final controllersDir = p.join(sdCardPath, 'controllers');
      final dir = Directory(controllersDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Save config file
      final filename = '${vid}_$pid.ini';
      final configPath = p.join(controllersDir, filename);
      await File(configPath).writeAsString(configContent);

      return true;
    } catch (e, stack) {
      AppLogger.instance
          .error('Error saving config: $e', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Load existing config from SD card
  Future<String?> loadConfig(String sdCardPath, String vid, String pid) async {
    try {
      final filename = '${vid}_$pid.ini';
      final configPath = p.join(sdCardPath, 'controllers', filename);
      final file = File(configPath);

      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e, stack) {
      AppLogger.instance
          .error('Error loading config: $e', error: e, stackTrace: stack);
    }
    return null;
  }

  /// Get config file path
  String getConfigPath(String sdCardPath, String vid, String pid) {
    final filename = '${vid}_$pid.ini';
    return p.join(sdCardPath, 'controllers', filename);
  }

  /// Validate config content
  bool validateConfig(String content) {
    // Check for required fields
    return content.contains('[Controller]') &&
        content.contains('VID=') &&
        content.contains('PID=');
  }

  /// Get preset configs for common controllers
  Map<String, String> getPresetConfigs() {
    return {
      // Xbox 360 Controller
      '045E_028E': '''
[Controller]
VID=045E
PID=028E
Name=Xbox 360 Controller
Polltype=1
DPAD=1
A=3,10
B=3,20
X=3,40
Y=3,80
L=3,01
R=3,02
Z=3,04
S=3,08
LeftStickX=0
LeftStickY=1
RightStickX=3
RightStickY=4
LAnalog=2
RAnalog=5
''',

      // Xbox One Controller
      '045E_02EA': '''
[Controller]
VID=045E
PID=02EA
Name=Xbox One Controller
Polltype=1
DPAD=1
A=3,10
B=3,20
X=3,40
Y=3,80
L=3,01
R=3,02
Z=3,04
S=3,08
LeftStickX=0
LeftStickY=1
RightStickX=3
RightStickY=4
LAnalog=2
RAnalog=5
''',

      // PS4 DualShock 4
      '054C_09CC': '''
[Controller]
VID=054C
PID=09CC
Name=PS4 DualShock 4
Polltype=1
DPAD=1
A=5,20
B=5,40
X=5,10
Y=5,80
L=6,01
R=6,02
Z=6,04
S=6,08
LeftStickX=1
LeftStickY=2
RightStickX=3
RightStickY=4
LAnalog=8
RAnalog=9
''',

      // PS3 DualShock 3
      '054C_0268': '''
[Controller]
VID=054C
PID=0268
Name=PS3 DualShock 3
Polltype=1
DPAD=1
A=2,02
B=2,04
X=2,01
Y=2,08
L=2,10
R=2,20
S=2,08
Z=2,40
LeftStickX=0
LeftStickY=1
RightStickX=2
RightStickY=3
LAnalog=18
RAnalog=19
''',
    };
  }
}

/// Button mapping configuration
class ButtonMapping {
  final int byte;
  final int bitmask;

  const ButtonMapping({required this.byte, required this.bitmask});

  String toIniFormat() {
    final maskHex = bitmask.toRadixString(16).toUpperCase().padLeft(2, '0');
    return '$byte,$maskHex';
  }

  factory ButtonMapping.fromIniFormat(String format) {
    final parts = format.split(',');
    return ButtonMapping(
      byte: int.parse(parts[0]),
      bitmask: int.parse(parts[1], radix: 16),
    );
  }
}

/// Axis mapping configuration
class AxisMapping {
  final int axisIndex;
  final bool invert;

  const AxisMapping({required this.axisIndex, this.invert = false});

  factory AxisMapping.fromIndex(int index) {
    return AxisMapping(axisIndex: index);
  }
}

/// Controller information
class ControllerInfo {
  final String vid;
  final String pid;
  final String name;
  final bool hasPreset;

  const ControllerInfo({
    required this.vid,
    required this.pid,
    required this.name,
    this.hasPreset = false,
  });

  String get displayName => '$name (VID: $vid, PID: $pid)';
  String get configKey => '${vid}_$pid';
}
