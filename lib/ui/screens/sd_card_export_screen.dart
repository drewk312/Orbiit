import 'package:flutter/material.dart';
import '../../core/database/database.dart';
import '../services/usb_loader_service.dart';

/// Screen for exporting covers to SD card for jailbroken Wii USB loaders
class SDCardExportScreen extends StatefulWidget {
  final AppDatabase database;

  const SDCardExportScreen({super.key, required this.database});

  @override
  State<SDCardExportScreen> createState() => _SDCardExportScreenState();
}

class _SDCardExportScreenState extends State<SDCardExportScreen> {
  List<String> _detectedDrives = [];
  String? _selectedDrive;
  String _selectedLoader = 'both'; // usb_loader_gx, wiiflow, both
  bool _scanning = false;
  bool _exporting = false;
  int _currentGame = 0;
  int _totalGames = 0;
  String _currentGameId = '';

  @override
  void initState() {
    super.initState();
    _scanForSDCards();
  }

  Future<void> _scanForSDCards() async {
    setState(() => _scanning = true);
    final drives = await USBLoaderService.detectSDCards();
    setState(() {
      _detectedDrives = drives;
      _selectedDrive = drives.isNotEmpty ? drives.first : null;
      _scanning = false;
    });
  }

  Future<void> _exportCovers() async {
    if (_selectedDrive == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an SD card')),
      );
      return;
    }

    setState(() {
      _exporting = true;
      _currentGame = 0;
      _totalGames = 0;
    });

    try {
      // Get all Wii games
      final titles = await widget.database.getAllTitles();
      final wiiGames = titles
          .where((t) => t.platform.toLowerCase() == 'wii')
          .map((t) => {
                'gameId': t.gameId,
                'platform': t.platform,
                'region': t.region ?? 'USA',
              })
          .toList();

      setState(() {
        _totalGames = _selectedLoader == 'both'
            ? USBLoaderService.getBothLoadersCoverCount(wiiGames.length)
            : _selectedLoader == 'usb_loader_gx'
                ? USBLoaderService.getUSBLoaderGXCoverCount(wiiGames.length)
                : USBLoaderService.getWiiFlowCoverCount(wiiGames.length);
      });

      void onProgress(int current, int total, String gameId) {
        setState(() {
          _currentGame = current;
          _currentGameId = gameId;
        });
      }

      switch (_selectedLoader) {
        case 'usb_loader_gx':
          await USBLoaderService.prepareForUSBLoaderGX(
            _selectedDrive!,
            wiiGames,
            onProgress: onProgress,
          );
          break;
        case 'wiiflow':
          await USBLoaderService.prepareForWiiFlow(
            _selectedDrive!,
            wiiGames,
            onProgress: onProgress,
          );
          break;
        case 'both':
          await USBLoaderService.prepareForBothLoaders(
            _selectedDrive!,
            wiiGames,
            onProgress: onProgress,
          );
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Covers exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF12121A) : Colors.white,
        title: const Text('Export to SD Card'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF12121A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C2FF), Color(0xFFB000FF)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.sd_card, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Prepare Covers for Wii',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Export covers to SD card for USB Loader GX & WiiFlow',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // SD Card Selection
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF12121A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'SD Card Drive',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_scanning)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: _scanForSDCards,
                          tooltip: 'Rescan',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_detectedDrives.isEmpty && !_scanning)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No Wii SD cards detected. Insert an SD card with /wbfs or /apps folder.',
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedDrive,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _detectedDrives
                          .map((drive) => DropdownMenuItem(
                                value: drive,
                                child: Text('$drive\\ (Wii SD Card)'),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedDrive = value),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Loader Selection
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF12121A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Target USB Loader',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _LoaderOption(
                    title: 'USB Loader GX',
                    description: '4 cover types: 3D, 2D, Full, Disc',
                    value: 'usb_loader_gx',
                    groupValue: _selectedLoader,
                    onChanged: (v) => setState(() => _selectedLoader = v!),
                  ),
                  const SizedBox(height: 8),
                  _LoaderOption(
                    title: 'WiiFlow Lite',
                    description: '2 cover types: Boxcover, 2D',
                    value: 'wiiflow',
                    groupValue: _selectedLoader,
                    onChanged: (v) => setState(() => _selectedLoader = v!),
                  ),
                  const SizedBox(height: 8),
                  _LoaderOption(
                    title: 'Both (Recommended)',
                    description:
                        '6 cover types total (compatible with all loaders)',
                    value: 'both',
                    groupValue: _selectedLoader,
                    onChanged: (v) => setState(() => _selectedLoader = v!),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Export Progress
            if (_exporting) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF12121A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _totalGames > 0 ? _currentGame / _totalGames : 0,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Exporting $_currentGame / $_totalGames covers',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_currentGameId.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _currentGameId,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Export Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _exporting || _selectedDrive == null ? null : _exportCovers,
                icon: _exporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  _exporting ? 'Exporting...' : 'Export Covers to SD Card',
                  style: const TextStyle(fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoaderOption extends StatelessWidget {
  final String title;
  final String description;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _LoaderOption({
    required this.title,
    required this.description,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value == groupValue
              ? (isDark
                  ? Colors.blue.withValues(alpha: 0.1)
                  : Colors.blue.withValues(alpha: 0.05))
              : Colors.transparent,
          border: Border.all(
            color: value == groupValue
                ? Colors.blue
                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
