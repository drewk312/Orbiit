import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/nintendont_config_service.dart';
import '../services/sd_card_service.dart';

/// Controller setup screen for Nintendont
/// Allows users to configure USB controllers with preset support
class ControllerSetupScreen extends StatefulWidget {
  const ControllerSetupScreen({super.key});

  @override
  State<ControllerSetupScreen> createState() => _ControllerSetupScreenState();
}

class _ControllerSetupScreenState extends State<ControllerSetupScreen> {
  final NintendontConfigService _configService = NintendontConfigService();
  final SDCardService _sdService = SDCardService();

  List<SDCardInfo> _sdCards = [];
  String? _selectedSDCard;

  bool _isScanning = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _scanForSDCards();
  }

  Future<void> _scanForSDCards() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning for SD cards...';
    });

    try {
      final cards = await _sdService.detectSDCards();
      setState(() {
        _sdCards = cards;
        _isScanning = false;
        if (cards.isNotEmpty) {
          _selectedSDCard = cards.first.path;
          _statusMessage = 'Found ${cards.length} SD card(s)';
        } else {
          _statusMessage = 'No SD cards found';
        }
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _installPreset(String presetKey, String controllerName) async {
    if (_selectedSDCard == null) {
      _showError(
          'No SD card selected! Please select your SD card root folder first.');
      _browseForSDCard(); // Auto-trigger browse
      return;
    }

    setState(() {
      _isScanning = true;
      _statusMessage = 'Installing $controllerName preset...';
    });

    try {
      final presets = _configService.getPresetConfigs();
      final config = presets[presetKey];

      if (config == null) {
        throw Exception('Preset not found');
      }

      final parts = presetKey.split('_');
      final success = await _configService.saveConfigToSD(
        sdCardPath: _selectedSDCard!,
        vid: parts[0],
        pid: parts[1],
        configContent: config,
      );

      setState(() {
        _isScanning = false;
        if (success) {
          _statusMessage = '✓ $controllerName configured successfully!';
        } else {
          _statusMessage = '✗ Failed to save configuration';
        }
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _browseForSDCard() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select SD Card Root Directory',
    );

    if (result != null) {
      setState(() {
        _selectedSDCard = result;
        _statusMessage = 'Selected: $result';
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('Orbiit Controller Config'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
            tooltip: 'Help',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F1E), Color(0xFF1A1A2E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSDCardSelector(),
          const SizedBox(height: 24),
          _buildPresetControllers(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: const Color(0xFF1A1A2E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.gamepad, color: Colors.purple, size: 32),
                SizedBox(width: 12),
                Text(
                  'Controller Configuration',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Configure USB controllers for use with Nintendont on your Wii.\n'
              'Select a preset below to automatically generate the config file.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isScanning ? Icons.hourglass_empty : Icons.info_outline,
                      color: _statusMessage!.startsWith('✓')
                          ? Colors.green
                          : _statusMessage!.startsWith('✗')
                              ? Colors.red
                              : Colors.blue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSDCardSelector() {
    return Card(
      color: const Color(0xFF1A1A2E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.sd_card, color: Colors.orange, size: 24),
                SizedBox(width: 12),
                Text(
                  'SD Card Selection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_sdCards.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.sd_card_alert,
                        size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 12),
                    Text(
                      'No SD cards detected',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _browseForSDCard,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Browse for SD Card'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedSDCard,
                decoration: const InputDecoration(
                  labelText: 'Select SD Card',
                  border: OutlineInputBorder(),
                ),
                dropdownColor: const Color(0xFF2A2A3E),
                style: const TextStyle(color: Colors.white),
                items: _sdCards.map((card) {
                  return DropdownMenuItem(
                    value: card.path,
                    child: Text(card.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSDCard = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _scanForSDCards,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _browseForSDCard,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Browse...'),
                  ),
                ],
              ),
              if (_selectedSDCard != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Config path: ${_configService.getConfigPath(_selectedSDCard!, "VID", "PID")}',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPresetControllers() {
    return Card(
      color: const Color(0xFF1A1A2E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Colors.blue, size: 24),
                SizedBox(width: 12),
                Text(
                  'Preset Configurations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Install pre-configured controller mappings',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            _buildPresetCard(
              '045E_028E',
              'Xbox 360 Controller',
              Icons.gamepad,
              Colors.green,
              'Full button mapping for Xbox 360 wired/wireless controller',
            ),
            const SizedBox(height: 12),
            _buildPresetCard(
              '045E_02EA',
              'Xbox One Controller',
              Icons.gamepad,
              Colors.green,
              'Xbox One / Series X controller config',
            ),
            const SizedBox(height: 12),
            _buildPresetCard(
              '054C_09CC',
              'PS4 DualShock 4',
              Icons.gamepad,
              Colors.blue,
              'PlayStation 4 DualShock 4 controller',
            ),
            const SizedBox(height: 12),
            _buildPresetCard(
              '054C_0268',
              'PS3 DualShock 3',
              Icons.gamepad,
              Colors.blue,
              'PlayStation 3 DualShock 3 controller',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetCard(
    String presetKey,
    String name,
    IconData icon,
    Color color,
    String description,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        trailing: ElevatedButton.icon(
          onPressed: _isScanning ? null : () => _installPreset(presetKey, name),
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Install'),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 4,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Nintendont Controller Setup Help',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How to use:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Insert your SD card\n'
                '2. Click "Refresh" to detect it\n'
                '3. Select your controller preset\n'
                '4. Click "Install"\n'
                '5. Eject SD card and insert into Wii\n'
                '6. Connect USB controller to Wii\n'
                '7. Launch Nintendont - controller should work!',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              const Text(
                'Config Location:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'SD:/controllers/VID_PID.ini',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
