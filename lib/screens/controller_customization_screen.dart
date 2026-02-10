// ============================================================================
// UNIFIED CONTROLLER CUSTOMIZATION SCREEN
// ============================================================================
// Full customization for Wii, Wii U, and GameCube controller mappings.
// Supports modern controllers (Xbox, PlayStation, Switch) mapped to each console.
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../ui/screens/controller_wizard_screen.dart';
import 'package:wiigc_fusion/services/nintendont/nintendont_controller_service.dart';
import 'package:wiigc_fusion/services/hardware_service.dart';

/// Supported console types for controller mapping
enum ConsoleTarget {
  gamecube,
  wii,
  wiiu,
}

extension ConsoleTargetExtension on ConsoleTarget {
  String get displayName => switch (this) {
        ConsoleTarget.gamecube => 'GameCube',
        ConsoleTarget.wii => 'Wii',
        ConsoleTarget.wiiu => 'Wii U',
      };

  String get description => switch (this) {
        ConsoleTarget.gamecube => 'Map buttons for Nintendont & GameCube games',
        ConsoleTarget.wii => 'Map buttons for Wii games via USB Loader',
        ConsoleTarget.wiiu => 'Map buttons for vWii mode',
      };

  Color get accentColor => switch (this) {
        ConsoleTarget.gamecube => const Color(0xFF6B4EFF), // Purple
        ConsoleTarget.wii => const Color(0xFF00C2FF), // Cyan
        ConsoleTarget.wiiu => const Color(0xFF00C875), // Green
      };

  IconData get icon => switch (this) {
        ConsoleTarget.gamecube => Icons.videogame_asset_rounded,
        ConsoleTarget.wii => Icons.sports_esports_rounded,
        ConsoleTarget.wiiu => Icons.gamepad_rounded,
      };
}

class ControllerCustomizationScreen extends StatefulWidget {
  const ControllerCustomizationScreen({super.key});

  @override
  State<ControllerCustomizationScreen> createState() =>
      _ControllerCustomizationScreenState();
}

class _ControllerCustomizationScreenState
    extends State<ControllerCustomizationScreen>
    with SingleTickerProviderStateMixin {
  final _controllerService = NintendontControllerService();
  final _hardwareService = HardwareService();

  late TabController _tabController;
  ConsoleTarget _selectedConsole = ConsoleTarget.gamecube;

  List<DetectedController> _controllers = [];
  DetectedController? _selectedController;
  ControllerConfig? _currentConfig;
  List<Map<String, dynamic>> _drives = [];
  String? _selectedDrive;
  bool _isScanning = false;
  bool _isSaving = false;

  // Editable mappings for each button
  final Map<String, int> _customButtonMappings = {};
  final Map<String, Map<String, dynamic>> _customAxisMappings = {};

  StreamSubscription<List<DetectedController>>? _controllerSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    _controllerSub = _controllerService.controllerStream.listen((controllers) {
      if (mounted) {
        setState(() => _controllers = controllers);
      }
    });

    _scanControllers();
    _loadDrives();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controllerSub?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedConsole = ConsoleTarget.values[_tabController.index];
      });
    }
  }

  Future<void> _scanControllers() async {
    setState(() => _isScanning = true);

    try {
      final controllers = await _controllerService.scanForControllers();
      if (mounted) {
        setState(() {
          _controllers = controllers;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        _showError('Failed to scan controllers: $e');
      }
    }
  }

  Future<void> _loadDrives() async {
    final drives = await _hardwareService.getConnectedDrivesDetailed();
    if (mounted) {
      setState(() => _drives = drives);
    }
  }

  void _selectController(DetectedController controller) {
    final config = _controllerService.getPresetMapping(controller);
    setState(() {
      _selectedController = controller;
      _currentConfig = config;

      // Initialize custom mappings from preset
      _customButtonMappings.clear();
      _customAxisMappings.clear();

      for (final entry in config.buttonMappings.entries) {
        _customButtonMappings[entry.key.name] = entry.value.sourceButton;
      }
      for (final entry in config.axisMappings.entries) {
        _customAxisMappings[entry.key.name] = {
          'axis': entry.value.sourceAxis,
          'inverted': entry.value.inverted,
          'deadzone': entry.value.deadzone,
        };
      }
    });
  }

  Future<void> _saveConfig() async {
    if (_currentConfig == null || _selectedDrive == null) return;

    setState(() => _isSaving = true);

    try {
      final success = await _controllerService.saveConfigToDevice(
        _currentConfig!,
        _selectedDrive!,
      );

      if (mounted) {
        setState(() => _isSaving = false);

        if (success) {
          _showSuccess('Controller config saved to $_selectedDrive!');
        } else {
          _showError('Failed to save config');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showError('Error: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _selectedConsole.accentColor;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Controller Customization',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _isScanning ? null : _scanControllers,
            tooltip: 'Rescan Controllers',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildConsoleTabs(),
        ),
      ),
      body: Column(
        children: [
          // Console info banner
          _buildConsoleInfoBanner(accentColor),

          // Main content
          Expanded(
            child: Row(
              children: [
                // Left panel - Controller list
                _buildControllerList(),

                // Right panel - Config editor
                Expanded(
                  child: _selectedController == null
                      ? _buildEmptyState()
                      : _buildConfigEditor(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleTabs() {
    return TabBar(
      controller: _tabController,
      indicatorColor: _selectedConsole.accentColor,
      indicatorWeight: 3,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey,
      tabs: ConsoleTarget.values.map((console) {
        return Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(console.icon, size: 20),
              const SizedBox(width: 8),
              Text(console.displayName),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConsoleInfoBanner(Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.2),
            accentColor.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: accentColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _selectedConsole.icon,
              color: accentColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedConsole.displayName} Controller Mapping',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedConsole.description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedConsole == ConsoleTarget.gamecube)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_fix_high, size: 18),
                label: const Text("Wizard"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor.withValues(alpha: 0.8),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ControllerWizardScreen()),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControllerList() {
    final accentColor = _selectedConsole.accentColor;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.gamepad,
                  color: _isScanning ? accentColor : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Controllers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (_isScanning)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  ),
              ],
            ),
          ),

          // Controller list
          Expanded(
            child: _controllers.isEmpty
                ? _buildNoControllersFound()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _controllers.length,
                    itemBuilder: (context, index) {
                      final controller = _controllers[index];
                      final isSelected = _selectedController == controller;
                      return _buildControllerCard(controller, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildControllerCard(DetectedController controller, bool isSelected) {
    final accentColor = _selectedConsole.accentColor;
    final color = _getControllerColor(controller.type);

    return GestureDetector(
      onTap: () => _selectController(controller),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: accentColor.withValues(alpha: 0.3), blurRadius: 12)
                ]
              : null,
        ),
        child: Row(
          children: [
            // Controller icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getControllerIcon(controller.type),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Controller info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildVidPidChip(
                          'VID:${controller.vendorId.toRadixString(16).toUpperCase()}'),
                      const SizedBox(width: 6),
                      _buildVidPidChip(
                          'PID:${controller.productId.toRadixString(16).toUpperCase()}'),
                      if (controller.isWireless) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.bluetooth,
                            size: 14, color: Colors.blue[400]),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            if (isSelected)
              Icon(Icons.check_circle, color: accentColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVidPidChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontFamily: 'monospace',
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildNoControllersFound() {
    final accentColor = _selectedConsole.accentColor;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.gamepad_outlined,
            size: 64,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'No controllers found',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect a USB or Bluetooth controller',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _scanControllers,
            style: OutlinedButton.styleFrom(
              foregroundColor: accentColor,
              side: BorderSide(color: accentColor),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final accentColor = _selectedConsole.accentColor;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  accentColor.withValues(alpha: 0.3),
                  accentColor.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedConsole.icon,
              size: 56,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Select a Controller',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a controller to customize for ${_selectedConsole.displayName}',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigEditor() {
    if (_currentConfig == null) return const SizedBox();

    final accentColor = _selectedConsole.accentColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          _buildHeaderCard(accentColor),

          const SizedBox(height: 24),

          // Button mappings
          _buildMappingsSection(accentColor),

          const SizedBox(height: 24),

          // Axis mappings
          _buildAxisSection(accentColor),

          const SizedBox(height: 24),

          // Export section
          _buildExportSection(accentColor),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Color accentColor) {
    final controller = _selectedController!;
    final color = _getControllerColor(controller.type);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.2),
            accentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getControllerIcon(controller.type),
              color: color,
              size: 36,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(
                        'VID: 0x${controller.vendorId.toRadixString(16).toUpperCase().padLeft(4, '0')}'),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                        'PID: 0x${controller.productId.toRadixString(16).toUpperCase().padLeft(4, '0')}'),
                    if (controller.isWireless) ...[
                      const SizedBox(width: 8),
                      _buildInfoChip('Wireless', icon: Icons.bluetooth),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                'Target',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _selectedConsole.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.blue[400]),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: icon == null ? 'monospace' : null,
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingsSection(Color accentColor) {
    final config = _currentConfig!;
    final buttons = _getButtonsForConsole();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.touch_app, color: accentColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Button Mappings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _resetButtonMappings,
              icon: const Icon(Icons.restore, size: 16),
              label: const Text('Reset'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              _buildMappingHeader(),
              ...buttons.map((button) {
                return _buildEditableMappingRow(
                  button['name']!,
                  button['label']!,
                  _customButtonMappings[button['name']] ?? 0,
                  accentColor,
                  onChanged: (value) {
                    setState(() {
                      _customButtonMappings[button['name']!] = value;
                    });
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  List<Map<String, String>> _getButtonsForConsole() {
    switch (_selectedConsole) {
      case ConsoleTarget.gamecube:
        return [
          {'name': 'a', 'label': 'A (Main Action)'},
          {'name': 'b', 'label': 'B (Secondary)'},
          {'name': 'x', 'label': 'X Button'},
          {'name': 'y', 'label': 'Y Button'},
          {'name': 'z', 'label': 'Z Shoulder'},
          {'name': 'start', 'label': 'Start/Pause'},
          {'name': 'l', 'label': 'L Trigger (Digital)'},
          {'name': 'r', 'label': 'R Trigger (Digital)'},
          {'name': 'dpadUp', 'label': 'D-Pad Up'},
          {'name': 'dpadDown', 'label': 'D-Pad Down'},
          {'name': 'dpadLeft', 'label': 'D-Pad Left'},
          {'name': 'dpadRight', 'label': 'D-Pad Right'},
        ];
      case ConsoleTarget.wii:
        return [
          {'name': 'a', 'label': 'A Button'},
          {'name': 'b', 'label': 'B Trigger'},
          {'name': '1', 'label': '1 Button'},
          {'name': '2', 'label': '2 Button'},
          {'name': 'plus', 'label': '+ (Plus)'},
          {'name': 'minus', 'label': '- (Minus)'},
          {'name': 'home', 'label': 'Home Button'},
          {'name': 'dpadUp', 'label': 'D-Pad Up'},
          {'name': 'dpadDown', 'label': 'D-Pad Down'},
          {'name': 'dpadLeft', 'label': 'D-Pad Left'},
          {'name': 'dpadRight', 'label': 'D-Pad Right'},
          {'name': 'c', 'label': 'C (Nunchuk)'},
          {'name': 'z', 'label': 'Z (Nunchuk)'},
        ];
      case ConsoleTarget.wiiu:
        return [
          {'name': 'a', 'label': 'A Button'},
          {'name': 'b', 'label': 'B Button'},
          {'name': 'x', 'label': 'X Button'},
          {'name': 'y', 'label': 'Y Button'},
          {'name': 'l', 'label': 'L Shoulder'},
          {'name': 'r', 'label': 'R Shoulder'},
          {'name': 'zl', 'label': 'ZL Trigger'},
          {'name': 'zr', 'label': 'ZR Trigger'},
          {'name': 'plus', 'label': '+ (Plus)'},
          {'name': 'minus', 'label': '- (Minus)'},
          {'name': 'home', 'label': 'Home Button'},
          {'name': 'dpadUp', 'label': 'D-Pad Up'},
          {'name': 'dpadDown', 'label': 'D-Pad Down'},
          {'name': 'dpadLeft', 'label': 'D-Pad Left'},
          {'name': 'dpadRight', 'label': 'D-Pad Right'},
        ];
    }
  }

  Widget _buildMappingHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _selectedConsole.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Source Button',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildEditableMappingRow(
    String name,
    String label,
    int currentValue,
    Color accentColor, {
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white10),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  'Button $currentValue',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Colors.cyan,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.remove, size: 16, color: Colors.grey[400]),
                  onPressed: currentValue > 0
                      ? () => onChanged(currentValue - 1)
                      : null,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: Icon(Icons.add, size: 16, color: Colors.grey[400]),
                  onPressed: currentValue < 15
                      ? () => onChanged(currentValue + 1)
                      : null,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _resetButtonMappings() {
    if (_currentConfig != null) {
      setState(() {
        _customButtonMappings.clear();
        for (final entry in _currentConfig!.buttonMappings.entries) {
          _customButtonMappings[entry.key.name] = entry.value.sourceButton;
        }
      });
    }
  }

  Widget _buildAxisSection(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.control_camera, color: accentColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Analog Stick & Trigger Mappings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildAxisRow('Left Stick X', 0, accentColor),
              _buildAxisRow('Left Stick Y', 1, accentColor),
              _buildAxisRow('Right Stick X', 2, accentColor),
              _buildAxisRow('Right Stick Y', 3, accentColor),
              _buildAxisRow('Left Trigger', 4, accentColor),
              _buildAxisRow('Right Trigger', 5, accentColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAxisRow(String label, int axis, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Axis $axis',
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.cyan,
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Row(
              children: [
                const Text('Deadzone:',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '15%',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.save_alt, color: accentColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Export to SD Card / USB',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getExportDescription(),
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDrive,
                      hint: Text(
                        'Select drive...',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1A1A2E),
                      items: _drives.map((drive) {
                        final letter = drive['letter'] as String;
                        final name = drive['name'] as String;
                        final removable = drive['removable'] as bool;

                        return DropdownMenuItem(
                          value: letter,
                          child: Row(
                            children: [
                              Icon(
                                removable ? Icons.usb : Icons.storage,
                                size: 18,
                                color: removable ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 10),
                              Text('$letter  $name',
                                  style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedDrive = value);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed:
                    _selectedDrive != null && !_isSaving ? _saveConfig : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Config'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getExportDescription() {
    switch (_selectedConsole) {
      case ConsoleTarget.gamecube:
        return 'Save config to /controllers/ folder for Nintendont.';
      case ConsoleTarget.wii:
        return 'Save config to /wiiflow/controllers/ for Wii USB Loader.';
      case ConsoleTarget.wiiu:
        return 'Save config to /wiiu/controllers/ for vWii mode.';
    }
  }

  Color _getControllerColor(ControllerType type) {
    switch (type) {
      case ControllerType.xbox360:
      case ControllerType.xboxOne:
      case ControllerType.xboxSeries:
        return Colors.green;
      case ControllerType.dualShock3:
      case ControllerType.dualShock4:
      case ControllerType.dualSense:
        return Colors.blue;
      case ControllerType.switchPro:
      case ControllerType.switchJoyconPair:
        return Colors.red;
      case ControllerType.generic8BitDo:
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  IconData _getControllerIcon(ControllerType type) {
    switch (type) {
      case ControllerType.xbox360:
      case ControllerType.xboxOne:
      case ControllerType.xboxSeries:
        return Icons.sports_esports;
      case ControllerType.dualShock3:
      case ControllerType.dualShock4:
      case ControllerType.dualSense:
        return Icons.gamepad;
      case ControllerType.switchPro:
      case ControllerType.switchJoyconPair:
        return Icons.videogame_asset;
      default:
        return Icons.gamepad_outlined;
    }
  }
}
