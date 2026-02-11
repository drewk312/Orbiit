// ============================================================================
// FUSION CONTROLLER FORGE
// ============================================================================
// The ultimate controller customization suite.
// Visual mapping, wizard mode, and deep configuration.
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wiigc_fusion/models/controller_config.dart'; // The "Brain"
import 'package:wiigc_fusion/services/nintendont/nintendont_controller_service.dart';

import '../ui/fusion/design_system.dart';
import '../ui/screens/controller_wizard_screen.dart';

class ControllerForgeScreen extends StatefulWidget {
  const ControllerForgeScreen({super.key});

  @override
  State<ControllerForgeScreen> createState() => _ControllerForgeScreenState();
}

class _ControllerForgeScreenState extends State<ControllerForgeScreen>
    with TickerProviderStateMixin {
  // Services
  final _controllerService = NintendontControllerService();

  // State
  DetectedController? _selectedController;
  List<DetectedController> _controllers = [];
  bool _isScanning = false;

  // "Brain" Config
  late NintendontConfig _currentConfig;

  // Animation
  late TabController _tabController;
  String _hoveredButton = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentConfig = NintendontConfig();
    _scanControllers();
  }

  Future<void> _scanControllers() async {
    setState(() => _isScanning = true);
    try {
      // Use existing service to find basic controllers
      final list = await _controllerService.scanForControllers();
      setState(() {
        _controllers = list;
        _isScanning = false;
        if (list.isNotEmpty && _selectedController == null) {
          _selectedController = list.first;
          _currentConfig.name = list.first.name;
          // Extract VID/PID
          _currentConfig.vid =
              list.first.vendorId.toRadixString(16).toUpperCase();
          _currentConfig.pid =
              list.first.productId.toRadixString(16).toUpperCase();
        }
      });
    } catch (e) {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FusionColors.bgPrimary,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: FusionColors.deepSpaceGradient,
              ),
            ),
          ),

          // Content
          Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Row(
                  children: [
                    // Left Panel: Device Selection & Wizard Access
                    SizedBox(
                      width: 320,
                      child: _buildSidebar(),
                    ),

                    // Right Panel: The Forge (Visual Mapper)
                    Expanded(
                      child: _buildForgeWorkspace(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _selectedController != null
          ? FloatingActionButton.extended(
              onPressed: _exportConfig,
              backgroundColor: FusionColors.nebulaCyan,
              icon: const Icon(Icons.sd_card),
              label: const Text('Export INI'),
            )
          : null,
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: FusionColors.glassWhite(0.06),
        border: Border(
          bottom: BorderSide(color: FusionColors.glassWhite(0.1)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          IconButton(
            icon:
                const Icon(Icons.arrow_back, color: FusionColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: FusionColors.auroraGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.settings_input_component, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONTROLLER FORGE',
                style: FusionText.headlineMedium.copyWith(letterSpacing: 1.5),
              ),
              Text(
                'Nintendont Input Mapper',
                style: FusionText.bodySmall
                    .copyWith(color: FusionColors.nebulaCyan),
              ),
            ],
          ),
          const Spacer(),
          // Mode Switcher
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: FusionColors.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FusionColors.glassWhite(0.1)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: BoxDecoration(
                color: FusionColors.nebulaCyan.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: FusionColors.nebulaCyan.withValues(alpha: 0.5)),
              ),
              labelColor: FusionColors.nebulaCyan,
              unselectedLabelColor: FusionColors.textSecondary,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('VISUAL MAPPER'))),
                Tab(
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('ADVANCED'))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: FusionColors.bgSecondary,
        border: Border(right: BorderSide(color: FusionColors.glassWhite(0.1))),
      ),
      child: Column(
        children: [
          // Wizard Call to Action
          Padding(
            padding: const EdgeInsets.all(20),
            child: InkWell(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ControllerWizardScreen())),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      FusionColors.nebulaPurple.withValues(alpha: 0.2),
                      FusionColors.nebulaViolet.withValues(alpha: 0.1)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: FusionColors.nebulaPurple.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                        color: FusionColors.nebulaPurple.withValues(alpha: 0.1),
                        blurRadius: 12),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_fix_high,
                        color: FusionColors.nebulaPurple, size: 32),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Setup Wizard',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text('Auto-detect & Map',
                              style: TextStyle(
                                  color: FusionColors.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: FusionColors.glassWhite(0.5)),
                  ],
                ),
              ),
            ),
          ),

          Divider(height: 1, color: FusionColors.glassWhite(0.1)),

          // Device List Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                const Text('DETECTED DEVICES',
                    style: TextStyle(
                        color: FusionColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_isScanning)
                  const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: FusionColors.nebulaCyan))
                else
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        size: 16, color: FusionColors.textSecondary),
                    onPressed: _scanControllers,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          // Device List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _controllers.length,
              itemBuilder: (context, index) {
                final c = _controllers[index];
                final isSelected = c == _selectedController;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() {
                        _selectedController = c;
                        // Reload config binding logic here
                        _currentConfig = NintendontConfig(); // Reset
                        _currentConfig.name = c.name;
                        _currentConfig.vid =
                            c.vendorId.toRadixString(16).toUpperCase();
                        _currentConfig.pid =
                            c.productId.toRadixString(16).toUpperCase();
                      }),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? FusionColors.nebulaCyan.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? FusionColors.nebulaCyan.withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.gamepad,
                                color: isSelected
                                    ? FusionColors.nebulaCyan
                                    : FusionColors.textMuted),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name,
                                      style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : FusionColors.textSecondary,
                                          fontWeight: FontWeight.w500)),
                                  Text('${c.vendorId}:${c.productId}',
                                      style: const TextStyle(
                                          color: FusionColors.textMuted,
                                          fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgeWorkspace() {
    if (_selectedController == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.usb_off, size: 64, color: FusionColors.textMuted),
            const SizedBox(height: 16),
            const Text('No Controller Selected',
                style: TextStyle(color: FusionColors.textSecondary)),
            const SizedBox(height: 8),
            // Replaced ActionButton with GlowButton (wrapped)
            SizedBox(
              height: 40,
              child: GlowButton(
                  label: 'Connect & Scan',
                  icon: Icons.usb,
                  onPressed: _scanControllers,
                  color: FusionColors.nebulaCyan,
                  isCompact: true),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Workspace Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: FusionColors.glassWhite(0.05))),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mapping Configuration',
                      style: TextStyle(
                          color: FusionColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('VID: ${_currentConfig.vid}',
                          style: const TextStyle(
                              color: FusionColors.nebulaCyan,
                              fontFamily: 'monospace')),
                      const SizedBox(width: 12),
                      Text('PID: ${_currentConfig.pid}',
                          style: const TextStyle(
                              color: FusionColors.nebulaCyan,
                              fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Options
              Switch(
                  value: _currentConfig.dpadType == 1,
                  onChanged: (v) =>
                      setState(() => _currentConfig.dpadType = v ? 1 : 0),
                  activeThumbColor: FusionColors.nebulaCyan),
              const Text('  Hat D-Pad',
                  style: TextStyle(color: FusionColors.textSecondary)),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildVisualMapper(),
              _buildAdvancedList(),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // VISUAL MAPPER
  // --------------------------------------------------------------------------
  Widget _buildVisualMapper() {
    return Row(
      children: [
        // Visual Representation (Center)
        Expanded(
          flex: 3,
          child: Center(
            child: SizedBox(
              width: 380,
              height: 280,
              child: Stack(
                children: [
                  // Base Controller Image/Shape
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: FusionColors.bgSurface,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                            color: FusionColors.glassWhite(0.1), width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10)),
                        ],
                      ),
                      // Placeholder for actual controller SVG/Image
                      child: CustomPaint(painter: ControllerOutlinePainter()),
                    ),
                  ),

                  // Interactive Buttons (GameCube Layout)
                  _buildVisualButton('A', Alignment.centerRight,
                      const Offset(-30, -10), Colors.green),
                  _buildVisualButton('B', Alignment.centerRight,
                      const Offset(-60, 20), Colors.red),
                  _buildVisualButton('X', Alignment.centerRight,
                      const Offset(-20, -50), Colors.grey),
                  _buildVisualButton('Y', Alignment.centerRight,
                      const Offset(-60, -40), Colors.grey),
                  _buildVisualButton('Z', Alignment.topRight,
                      const Offset(-40, 10), Colors.purple),

                  _buildVisualButton('Start', Alignment.center,
                      const Offset(0, 0), Colors.grey),

                  _buildVisualButton('L', Alignment.topLeft,
                      const Offset(30, 10), Colors.grey),
                  _buildVisualButton('R', Alignment.topRight,
                      const Offset(-30, 10), Colors.grey),

                  _buildVisualStick(
                      'Stick', Alignment.centerLeft, const Offset(50, -20)),
                  _buildVisualStick(
                      'C-Stick', Alignment.centerRight, const Offset(-60, 60)),

                  _buildVisualDpad(Alignment.bottomLeft, const Offset(70, -40)),
                ],
              ),
            ),
          ),
        ),

        // Property Inspector (Right)
        Container(
          width: 250,
          decoration: BoxDecoration(
            color: FusionColors.bgSecondary,
            border:
                Border(left: BorderSide(color: FusionColors.glassWhite(0.05))),
          ),
          child: _buildPropertyInspector(),
        ),
      ],
    );
  }

  Widget _buildVisualButton(
      String label, Alignment align, Offset offset, Color color) {
    // The clean key used in config (e.g. "A", "Start")
    final key = label;
    final isHovered = _hoveredButton == key;
    final isMapped = _currentConfig.bindings.containsKey(key);

    return Align(
      alignment: align,
      child: Transform.translate(
        offset: offset,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoveredButton = key),
          onExit: (_) => setState(() => _hoveredButton = ''),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () =>
                setState(() => _hoveredButton = key), // Select for editing
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isMapped
                    ? color.withValues(alpha: 0.8)
                    : color.withValues(alpha: 0.2),
                border: Border.all(
                  color: isHovered ? Colors.white : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isMapped
                    ? [
                        BoxShadow(
                            color: color.withValues(alpha: 0.5), blurRadius: 10)
                      ]
                    : null,
              ),
              child: Center(
                  child: Text(label.substring(0, 1),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Colors.white))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualStick(String label, Alignment align, Offset offset) {
    return Align(
      alignment: align,
      child: Transform.translate(
        offset: offset,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: FusionColors.glassWhite(0.1),
            border: Border.all(color: FusionColors.glassWhite(0.2)),
          ),
          child: const Center(
              child: Icon(Icons.control_camera,
                  size: 24, color: FusionColors.textMuted)),
        ),
      ),
    );
  }

  Widget _buildVisualDpad(Alignment align, Offset offset) {
    return Align(
      alignment: align,
      child: Transform.translate(
        offset: offset,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: FusionColors.glassWhite(0.1),
          ),
          child: const Icon(Icons.import_export, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildPropertyInspector() {
    if (_hoveredButton.isEmpty) {
      return const Center(
          child: Text('Select a button\nto configure',
              textAlign: TextAlign.center,
              style: TextStyle(color: FusionColors.textMuted)));
    }

    final currentValue =
        _currentConfig.bindings[_hoveredButton] ?? 'Not Mapped';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 24, color: FusionColors.nebulaCyan),
              const SizedBox(width: 8),
              Text('$_hoveredButton Button',
                  style: FusionText
                      .headlineMedium), // headingSmall -> headlineMedium
            ],
          ),
          const SizedBox(height: 24),
          const Text('CURRENT MAPPING', style: FusionText.labelMedium),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FusionColors.bgPrimary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FusionColors.glassWhite(0.1)),
            ),
            child: Text(currentValue,
                style: const TextStyle(
                    fontFamily: 'monospace', color: FusionColors.nebulaCyan)),
          ),
          const SizedBox(height: 24),
          const Text('MANUAL OVERRIDE', style: FusionText.labelMedium),
          const SizedBox(height: 8),
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'offset,mask',
              hintStyle: const TextStyle(color: FusionColors.textMuted),
              filled: true,
              fillColor: FusionColors.glassWhite(0.05),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
            ),
            onChanged: (v) {
              _currentConfig.bindings[_hoveredButton] = v;
            },
            controller: TextEditingController(
                text: _currentConfig.bindings[_hoveredButton]),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Clear Mapping'),
              style:
                  OutlinedButton.styleFrom(foregroundColor: FusionColors.error),
              onPressed: () {
                setState(() => _currentConfig.bindings.remove(_hoveredButton));
              },
            ),
          )
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // LIST EDITOR
  // --------------------------------------------------------------------------
  Widget _buildAdvancedList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: NintendontConfig.mappingOrder.length,
      itemBuilder: (context, index) {
        final key = NintendontConfig.mappingOrder[index];
        final val = _currentConfig.bindings[key] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: FusionColors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FusionColors.glassWhite(0.05)),
          ),
          child: Row(
            children: [
              SizedBox(
                  width: 80,
                  child: Text(key,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white))),
              const Icon(Icons.arrow_right_alt,
                  color: FusionColors.textMuted, size: 16),
              const SizedBox(width: 16),
              Expanded(
                child: Text(val.isEmpty ? 'Unmapped' : val,
                    style: TextStyle(
                        fontFamily: 'monospace',
                        color: val.isEmpty
                            ? FusionColors.textMuted
                            : FusionColors.nebulaCyan)),
              ),
              IconButton(
                icon: const Icon(Icons.edit,
                    size: 16, color: FusionColors.textSecondary),
                onPressed: () {
                  // Focus visual mapper on this key
                  _tabController.animateTo(0);
                  setState(() => _hoveredButton = key);
                },
              )
            ],
          ),
        );
      },
    );
  }

  void _exportConfig() {
    // Show dialog with INI content
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: FusionColors.bgSecondary,
              title: const Text('Configuration Output',
                  style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: SelectableText(
                  _currentConfig.toIni(),
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      color: FusionColors.textSecondary),
                ),
              ),
              actions: [
                TextButton(
                    child: const Text('Close'),
                    onPressed: () => Navigator.pop(ctx)),
                ElevatedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                    onPressed: () {
                      // Copy to clipboard logic would go here
                      Navigator.pop(ctx);
                    })
              ],
            ));
  }
}

class ControllerOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw generic gamepad shape
    final path = Path();
    path.moveTo(60, 40);
    path.quadraticBezierTo(20, 40, 20, 100); // Left handle top
    path.quadraticBezierTo(20, 200, 60, 240); // Left handle bottom
    path.lineTo(100, 200);
    path.quadraticBezierTo(
        size.width / 2, 220, size.width - 100, 200); // Bottom curve
    path.lineTo(size.width - 60, 240); // Right handle bottom
    path.quadraticBezierTo(
        size.width - 20, 200, size.width - 20, 100); // Right handle top
    path.quadraticBezierTo(
        size.width - 20, 40, size.width - 60, 40); // Right top
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
