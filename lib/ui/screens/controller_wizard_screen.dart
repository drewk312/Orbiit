import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gamepads/gamepads.dart';
import 'package:wiigc_fusion/models/controller_config.dart';

class ControllerWizardScreen extends StatefulWidget {
  const ControllerWizardScreen({super.key});

  @override
  State<ControllerWizardScreen> createState() => _ControllerWizardScreenState();
}

class _ControllerWizardScreenState extends State<ControllerWizardScreen> {
  final NintendontConfig _config = NintendontConfig();
  StreamSubscription<GamepadEvent>? _subscription;

  // The mapping sequence
  final List<String> _mappingSequence = [
    'A', 'B', 'X', 'Y', 'Z', 'L', 'R', 'Start',
    'Up', 'Down', 'Left',
    'Right', // Stick / DPad depending on mode, usually Stick first
    'C-Up', 'C-Down', 'C-Left', 'C-Right',
  ];

  int _currentIndex = 0;
  bool _isListening = false;
  String? _lastInputName;
  String? _controllerName;

  @override
  void initState() {
    super.initState();
    _identifyController();
    _startListening();
  }

  Future<void> _identifyController() async {
    try {
      final gamepads = await Gamepads.list();
      if (gamepads.isNotEmpty) {
        if (mounted) {
          setState(() {
            _controllerName = gamepads.first.name;
            _config.name = gamepads.first.name;
            // extract VID/PID if available in id or name string
            // Typical format [1234:5678] Name
            final pidRegex = RegExp(r'\[([0-9A-Fa-f]{4}):([0-9A-Fa-f]{4})\]');
            final match = pidRegex.firstMatch(_config.name);
            if (match != null) {
              _config.vid = match.group(1) ?? '0000';
              _config.pid = match.group(2) ?? '0000';
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error identifying controller: $e");
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _startListening() {
    _subscription = Gamepads.events.listen((event) {
      if (!_isListening) return;

      // Filter noise: Axis usually sits at 0.0 or -1.0/1.0.
      // We accept Button presses (value 1.0) or Axis movements > 0.6
      bool valid = false;
      if (event.type == KeyType.button && event.value == 1.0) {
        valid = true;
      } else if (event.type == KeyType.analog && event.value.abs() > 0.6) {
        valid = true;
      }

      if (valid) {
        _handleInput(event);
      }
    });

    if (mounted) {
      setState(() {
        _isListening = true;
      });
    }
  }

  void _handleInput(GamepadEvent event) {
    if (!mounted) return;

    setState(() {
      _isListening = false;
      _lastInputName = '${event.key} (Btn:${event.type.name})';

      _applyToConfig(_mappingSequence[_currentIndex], event);

      if (_currentIndex < _mappingSequence.length - 1) {
        _currentIndex++;

        Timer(const Duration(milliseconds: 400), () {
          if (mounted) {
            setState(() {
              _isListening = true;
              _lastInputName = null;
            });
          }
        });
      }
    });
  }

  void _applyToConfig(String target, GamepadEvent event) {
    // Simplified Binding: just store offset,mask
    // We assume 0 offset for now content with the key ID
    _config.bindings[target] = "0,${event.key}";
  }

  void _showResultDialog() {
    final iniContent = _config.toIni();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF2D2D2D),
              title: const Text("Configuration Generated",
                  style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Save this as .ini file in /controllers folder:",
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.black,
                      width: double.maxFinite,
                      child: SelectableText(
                        iniContent,
                        style: const TextStyle(
                            color: Colors.greenAccent, fontFamily: 'monospace'),
                      ),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Close")),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: const Text("Done"))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final bool isComplete = _currentIndex >= _mappingSequence.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Controller Wizard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1E1E1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_controllerName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Chip(
                  avatar: const Icon(Icons.usb, color: Colors.white),
                  label: Text(_controllerName!,
                      style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.blueGrey,
                ),
              ),
            const Icon(Icons.gamepad, size: 80, color: Colors.deepPurpleAccent),
            const SizedBox(height: 40),
            if (!isComplete) ...[
              Text(
                'Press Button for:',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.white54),
              ),
              const SizedBox(height: 10),
              Text(
                _mappingSequence[_currentIndex],
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 20),
              if (_lastInputName != null)
                Text(
                  'Detected: $_lastInputName',
                  style: const TextStyle(color: Colors.greenAccent),
                ),
            ] else ...[
              const Text(
                'Mapping Complete!',
                style: TextStyle(color: Colors.greenAccent, fontSize: 24),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("View INI"),
                onPressed: _showResultDialog,
              )
            ],
            const SizedBox(height: 60),
            if (!isComplete)
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _currentIndex / _mappingSequence.length,
                  backgroundColor: Colors.white10,
                  color: Colors.deepPurpleAccent,
                ),
              )
          ],
        ),
      ),
    );
  }
}
