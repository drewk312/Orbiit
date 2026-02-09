// ============================================================================
// NINTENDONT CONTROLLER MAPPING SCREEN
// ============================================================================
// Interactive UI for detecting controllers, viewing/editing mappings,
// and exporting configurations to SD card for Nintendont.
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wiigc_fusion/services/nintendont/nintendont_controller_service.dart';
import 'package:wiigc_fusion/services/hardware_service.dart';

class NintendontControllerScreen extends StatefulWidget {
  const NintendontControllerScreen({super.key});

  @override
  State<NintendontControllerScreen> createState() =>
      _NintendontControllerScreenState();
}

// Back button mixin for consistent navigation

class _NintendontControllerScreenState extends State<NintendontControllerScreen>
    with SingleTickerProviderStateMixin {
  final _controllerService = NintendontControllerService();
  final _hardwareService = HardwareService();

  List<DetectedController> _controllers = [];
  DetectedController? _selectedController;
  ControllerConfig? _currentConfig;
  List<Map<String, dynamic>> _drives = [];
  String? _selectedDrive;
  bool _isScanning = false;
  bool _isSaving = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  StreamSubscription<List<DetectedController>>? _controllerSub;

  @override
  void initState() {
    super.initState();

    // Pulse animation for scanning indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Listen to controller changes
    _controllerSub = _controllerService.controllerStream.listen((controllers) {
      if (mounted) {
        setState(() => _controllers = controllers);
      }
    });

    // Initial scans
    _scanControllers();
    _loadDrives();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controllerSub?.cancel();
    super.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          'Controller Mapper',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _isScanning ? null : _scanControllers,
            tooltip: 'Rescan Controllers',
          ),
        ],
      ),
      body: Row(
        children: [
          // Left panel - Controller list
          _buildControllerList(isDark),

          // Right panel - Config editor
          Expanded(
            child: _selectedController == null
                ? _buildEmptyState(isDark)
                : _buildConfigEditor(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildControllerList(bool isDark) {
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
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isScanning ? _pulseAnimation.value : 1.0,
                      child: Icon(
                        Icons.gamepad,
                        color: _isScanning ? Colors.cyan : Colors.grey,
                        size: 28,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  'Controllers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                if (_isScanning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.cyan,
                    ),
                  ),
              ],
            ),
          ),

          // Controller list
          Expanded(
            child: _controllers.isEmpty
                ? _buildNoControllersFound(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _controllers.length,
                    itemBuilder: (context, index) {
                      final controller = _controllers[index];
                      final isSelected = _selectedController == controller;

                      return _buildControllerCard(
                        controller,
                        isSelected,
                        isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildControllerCard(
    DetectedController controller,
    bool isSelected,
    bool isDark,
  ) {
    final color = _getControllerColor(controller.type);

    return GestureDetector(
      onTap: () => _selectController(controller),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12)]
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'VID:${controller.vendorId.toRadixString(16).toUpperCase()}',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PID:${controller.productId.toRadixString(16).toUpperCase()}',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                      if (controller.isWireless) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.bluetooth,
                          size: 14,
                          color: Colors.blue[400],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Selection indicator
            if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNoControllersFound(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.gamepad_outlined,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No controllers found',
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect a USB or Bluetooth controller',
            style: TextStyle(
              color: isDark ? Colors.grey[600] : Colors.grey[500],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _scanControllers,
            icon: const Icon(Icons.refresh),
            label: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
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
                  Colors.purple.withValues(alpha: 0.3),
                  Colors.cyan.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_esports,
              size: 56,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select a Controller',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a controller from the list to configure mappings',
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigEditor(bool isDark) {
    if (_currentConfig == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(isDark),
          const SizedBox(height: 32),
          Center(
            child: _buildVisualMapper(isDark),
          ),
          const SizedBox(height: 32),
          _buildDeadzoneSliders(isDark),
          const SizedBox(height: 32),
          _buildExportSection(isDark),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    final controller = _selectedController!;
    final color = _getControllerColor(controller.type);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(
                      'VID: 0x${controller.vendorId.toRadixString(16).toUpperCase().padLeft(4, '0')}',
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      'PID: 0x${controller.productId.toRadixString(16).toUpperCase().padLeft(4, '0')}',
                      isDark,
                    ),
                    if (controller.isWireless) ...[
                      const SizedBox(width: 8),
                      _buildInfoChip('Wireless', isDark, icon: Icons.bluetooth),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                'Config File',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  controller.configFileName,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: isDark ? Colors.cyan : Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, bool isDark, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey[200],
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
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualMapper(bool isDark) {
    return Column(
      children: [
        Text(
          'Interactive Mapper',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap a button on the controller below to map it',
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 400,
          height: 300,
          child: Stack(
            children: [
              CustomPaint(
                size: const Size(400, 300),
                painter: ControllerPainter(
                  color: isDark ? Colors.white24 : Colors.black12,
                  outlineColor: isDark ? Colors.white : Colors.black,
                ),
              ),

              // Sticks
              _buildTouchZone('Main Stick', 65, 110, 80, 80, GCAxis.mainX),
              _buildTouchZone('C-Stick', 255, 150, 70, 70, GCAxis.cX),

              // D-Pad
              _buildTouchZone('D-Pad', 125, 150, 70, 70, GCButton.dpadUp),

              // Face Buttons
              _buildTouchZone('Y', 315, 80, 35, 35, GCButton.y),
              _buildTouchZone('B', 280, 110, 35, 35, GCButton.b),
              _buildTouchZone('A', 315, 140, 35, 35, GCButton.a),
              _buildTouchZone('X', 350, 110, 35, 35, GCButton.x),

              // Center
              _buildTouchZone('Start', 220, 110, 40, 20, GCButton.start),

              // Shoulders
              _buildTouchZone('L/Z', 40, 20, 100, 40, GCButton.l),
              _buildTouchZone('R/Z', 260, 20, 100, 40, GCButton.r),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTouchZone(String label, double left, double top, double width,
      double height, dynamic target) {
    bool isMapped = false;
    String mappedTo = 'Unmapped';

    if (target is GCButton) {
      final m = _currentConfig?.buttonMappings[target];
      if (m != null && m.sourceButton != -1) {
        isMapped = true;
        mappedTo = 'Btn ${m.sourceButton}';
      }
    } else if (target is GCAxis) {
      final m = _currentConfig?.axisMappings[target];
      if (m != null && m.sourceAxis != null) {
        isMapped = true;
        mappedTo = 'Axis ${m.sourceAxis}';
      }
    }

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showMappingDialog(target),
          borderRadius: BorderRadius.circular(width / 2),
          child: Container(
            decoration: BoxDecoration(
              color: isMapped
                  ? Colors.blue.withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.1),
              border: Border.all(
                color: isMapped ? Colors.blue : Colors.red.withValues(alpha: 0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              isMapped ? mappedTo : '?',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 2, color: Colors.black)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMappingDialog(dynamic target) async {
    String targetName = '';
    if (target is GCButton) targetName = target.name.toUpperCase();
    if (target is GCAxis) targetName = target.name.toUpperCase();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: Text('Map $targetName',
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select the input ID from your controller.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              width: 300,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(32, (index) {
                    return ChoiceChip(
                      label: Text('$index'),
                      selected: false,
                      onSelected: (selected) {
                        _updateMapping(target, index);
                        Navigator.of(ctx).pop();
                      },
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _updateMapping(dynamic target, int sourceId) {
    if (_currentConfig == null) return;

    setState(() {
      if (target is GCButton) {
        final newMappings = Map<GCButton, ControllerMapping>.from(
            _currentConfig!.buttonMappings);
        final current = newMappings[target] ??
            ControllerMapping(targetButton: target, sourceButton: -1);

        newMappings[target] = current.copyWith(sourceButton: sourceId);

        _currentConfig = _currentConfig!.copyWith(buttonMappings: newMappings);
      } else if (target is GCAxis) {
        final newMappings =
            Map<GCAxis, ControllerMapping>.from(_currentConfig!.axisMappings);
        final current = newMappings[target] ??
            ControllerMapping(targetAxis: target, sourceAxis: 0);

        newMappings[target] = current.copyWith(sourceAxis: sourceId);

        _currentConfig = _currentConfig!.copyWith(axisMappings: newMappings);
      }
    });
  }

  void _updateDeadzone(GCAxis axis, int value) {
    if (_currentConfig == null) return;

    setState(() {
      final newMappings =
          Map<GCAxis, ControllerMapping>.from(_currentConfig!.axisMappings);
      final current = newMappings[axis] ??
          ControllerMapping(targetAxis: axis, sourceAxis: 0);

      newMappings[axis] = current.copyWith(deadzone: value);

      _currentConfig = _currentConfig!.copyWith(axisMappings: newMappings);
    });
  }

  Widget _buildDeadzoneSliders(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deadzone Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildSlider('Main Stick Deadzone', GCAxis.mainX, 0, 100),
        _buildSlider('C-Stick Deadzone', GCAxis.cX, 0, 100),
        _buildSlider('L/R Trigger Deadzone', GCAxis.lAnalog, 0, 100),
      ],
    );
  }

  Widget _buildSlider(String label, GCAxis axis, double min, double max) {
    final mapping = _currentConfig?.axisMappings[axis];
    final value = mapping?.deadzone.toDouble() ?? 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(value.round().toString(),
                style: const TextStyle(color: Colors.white)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 100,
          activeColor: Colors.blue,
          onChanged: (newValue) => _updateDeadzone(axis, newValue.round()),
        ),
      ],
    );
  }

  Widget _buildExportSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sd_storage, color: Colors.blue, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Save mappings to SD Card for Nintendont',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDrive,
                hint: const Text('Select SD Card / USB Drive'),
                isExpanded: true,
                items: _drives.map((drive) {
                  return DropdownMenuItem<String>(
                    value: drive['path'],
                    child: Text('${drive['letter']} (${drive['label']})'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedDrive = value),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveConfig,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Configuration'),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
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

class ControllerPainter extends CustomPainter {
  final Color color;
  final Color outlineColor;

  ControllerPainter({required this.color, required this.outlineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(w * 0.2, h * 0.3);
    path.quadraticBezierTo(w * 0.5, h * 0.25, w * 0.8, h * 0.3);
    path.quadraticBezierTo(w * 1.0, h * 0.4, w * 0.95, h * 0.7);
    path.quadraticBezierTo(w * 0.9, h * 0.95, w * 0.75, h * 0.8);
    path.quadraticBezierTo(w * 0.7, h * 0.65, w * 0.5, h * 0.65);
    path.quadraticBezierTo(w * 0.3, h * 0.65, w * 0.25, h * 0.8);
    path.quadraticBezierTo(w * 0.1, h * 0.95, w * 0.05, h * 0.7);
    path.quadraticBezierTo(w * 0.0, h * 0.4, w * 0.2, h * 0.3);

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    _drawCircle(canvas, w * 0.25, h * 0.45, 35, paint);
    _drawCircle(canvas, w * 0.72, h * 0.58, 35, paint);

    _drawRect(canvas, w * 0.35, h * 0.58, 20, 60, paint);
    _drawRect(canvas, w * 0.30, h * 0.65, 60, 20, paint);

    _drawCircle(canvas, w * 0.88, h * 0.35, 12, paint);
    _drawCircle(canvas, w * 0.95, h * 0.42, 12, paint);
    _drawCircle(canvas, w * 0.81, h * 0.42, 12, paint);
    _drawCircle(canvas, w * 0.88, h * 0.50, 12, paint);

    _drawRect(canvas, w * 0.58, h * 0.45, 25, 12, paint);
  }

  void _drawCircle(Canvas canvas, double x, double y, double r, Paint paint) {
    canvas.drawCircle(Offset(x, y), r, paint);
  }

  void _drawRect(
      Canvas canvas, double x, double y, double w, double h, Paint paint) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h), const Radius.circular(4)),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
