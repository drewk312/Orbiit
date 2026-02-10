// lib/models/controller_config.dart
class NintendontConfig {
  String vid = '';
  String pid = '';
  String name = 'Unknown Controller';
  int pollType = 1;
  int dpadType = 1; // 1 = Hat, 0 = Buttons
  int digitalLR = 1; // 1 = Clicky triggers

  // Bindings map: 'A' -> 'offset,mask'
  final Map<String, String> bindings = {};

  // For the UI to know what to ask next
  static const List<String> mappingOrder = [
    'A', 'B', 'X', 'Y', 'Z',
    'L', 'R', 'Start',
    'Up', 'Down', 'Left', 'Right', // D-Pad
    'Stick X', 'Stick Y', // Main Analog
    'C-Stick X', 'C-Stick Y', // C-Stick
    'L Analog', 'R Analog' // Analog Triggers
  ];

  String toIni() {
    final buffer = StringBuffer();
    // Header format: [VID_PID]
    buffer.writeln('[${vid}_${pid}]');
    buffer.writeln('Name=$name');
    buffer.writeln('Polltype=$pollType');
    buffer.writeln('DPAD=$dpadType');
    buffer.writeln('DigitalLR=$digitalLR');

    // Write stick radii (standard defaults)
    buffer.writeln('StickX=64');
    buffer.writeln('StickY=64');
    buffer.writeln('CStickX=64');
    buffer.writeln('CStickY=64');

    bindings.forEach((key, value) {
      // Remove spaces for INI keys (Stick X -> StickX)
      final cleanKey = key.replaceAll(' ', '').replaceAll('-', '');
      buffer.writeln('$cleanKey=$value');
    });

    return buffer.toString();
  }
}
