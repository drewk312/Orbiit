import 'package:flutter/material.dart';

import '../../core/app_logger.dart';
import '../../core/database/database.dart';
import '../fusion/design_system.dart';
import '../services/usb_loader_service.dart';

/// Screen for exporting covers to SD card for jailbroken Wii USB loaders
/// Redesigned for Midnight Aurora (Glassmorphism + OLED Black)
class SDCardExportScreen extends StatefulWidget {
  final AppDatabase database;

  const SDCardExportScreen({required this.database, super.key});

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
    try {
      final drives = await USBLoaderService.detectSDCards();
      if (mounted) {
        setState(() {
          _detectedDrives = drives;
          _selectedDrive = drives.isNotEmpty ? drives.first : null;
          _scanning = false;
        });
      }
    } catch (e) {
      AppLogger.instance.error('Failed to scan for SD cards', error: e);
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _exportCovers() async {
    if (_selectedDrive == null) {
      _showSnack('Please select an SD card', isError: true);
      return;
    }

    setState(() {
      _exporting = true;
      _currentGame = 0;
      _totalGames = 0;
    });

    try {
      AppLogger.instance.info('Starting cover export to $_selectedDrive');

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

      if (wiiGames.isEmpty) {
        _showSnack('No Wii games found in database', isError: true);
        return;
      }

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
        _showSnack('✓ Covers exported successfully!');
        AppLogger.instance.info('Cover export completed successfully');
      }
    } catch (e) {
      AppLogger.instance.error('Export failed', error: e);
      if (mounted) {
        _showSnack('Export failed: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? FusionColors.error : FusionColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: FusionColors.deepSpaceGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: FusionColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title:
              const Text('Export to SD Card', style: FusionText.headlineMedium),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER CARD
              GlassCard(
                borderRadius: BorderRadius.circular(FusionRadius.xl),
                glowColor: FusionColors.wii,
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C2FF), Color(0xFFB000FF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF00C2FF).withValues(alpha: 0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: const Icon(Icons.sd_card,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Prepare Covers for Wii',
                            style: FusionText.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Export covers to SD card for USB Loader GX & WiiFlow. Automatic resizing and structuring included.',
                            style: FusionText.bodyMedium
                                .copyWith(color: FusionColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              const SizedBox(height: 32),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN: Configuration
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        // SD CARD SELECTION
                        GlassCard(
                          borderRadius: BorderRadius.circular(FusionRadius.lg),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Target SD Card',
                                      style: FusionText.labelLarge),
                                  if (_scanning)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: FusionColors.wii),
                                    )
                                  else
                                    IconButton(
                                      icon: const Icon(Icons.refresh,
                                          size: 20,
                                          color: FusionColors.textSecondary),
                                      onPressed: _scanForSDCards,
                                      tooltip: 'Rescan',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_detectedDrives.isEmpty && !_scanning)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: FusionColors.error
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: FusionColors.error
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber,
                                          color: FusionColors.error),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'No Wii SD cards detected. Insert an SD card with /wbfs or /apps folder.',
                                          style: FusionText.bodySmall.copyWith(
                                              color: FusionColors.error),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: FusionColors.borderSubtle),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedDrive,
                                      isExpanded: true,
                                      dropdownColor: const Color(0xFF1A1D24),
                                      style: FusionText.bodyMedium,
                                      icon: const Icon(Icons.arrow_drop_down,
                                          color: FusionColors.textSecondary),
                                      items: _detectedDrives.map((drive) {
                                        return DropdownMenuItem(
                                          value: drive,
                                          child: Text('$drive (Wii SD Card)',
                                              style: const TextStyle(
                                                  color: FusionColors
                                                      .textPrimary)),
                                        );
                                      }).toList(),
                                      onChanged: (val) =>
                                          setState(() => _selectedDrive = val),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // LOADER SELECTION
                        GlassCard(
                          borderRadius: BorderRadius.circular(FusionRadius.lg),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Target Loader',
                                  style: FusionText.labelLarge),
                              const SizedBox(height: 16),
                              _LoaderOption(
                                title: 'USB Loader GX',
                                description:
                                    '4 cover types: 3D, 2D, Full, Disc',
                                value: 'usb_loader_gx',
                                groupValue: _selectedLoader,
                                onChanged: (v) =>
                                    setState(() => _selectedLoader = v!),
                              ),
                              const SizedBox(height: 12),
                              _LoaderOption(
                                title: 'WiiFlow Lite',
                                description: '2 cover types: Boxcover, 2D',
                                value: 'wiiflow',
                                groupValue: _selectedLoader,
                                onChanged: (v) =>
                                    setState(() => _selectedLoader = v!),
                              ),
                              const SizedBox(height: 12),
                              _LoaderOption(
                                title: 'Both (Recommended)',
                                description:
                                    'All cover types (best compatibility)',
                                value: 'both',
                                groupValue: _selectedLoader,
                                onChanged: (v) =>
                                    setState(() => _selectedLoader = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 32),

                  // RIGHT COLUMN: Status & Action
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        if (_exporting)
                          GlassCard(
                            borderRadius:
                                BorderRadius.circular(FusionRadius.lg),
                            glowColor: FusionColors.wii,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Exporting...',
                                    style: FusionText.labelLarge
                                        .copyWith(color: FusionColors.wii)),
                                const SizedBox(height: 16),
                                LinearProgressIndicator(
                                  value: _totalGames > 0
                                      ? _currentGame / _totalGames
                                      : 0,
                                  backgroundColor: Colors.black26,
                                  color: FusionColors.wii,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$_currentGame / $_totalGames',
                                      style: FusionText.bodySmall.copyWith(
                                          // Changed UiType.mono to bodySmall (no mono in FusionText yet, or use generic style)
                                          color: FusionColors.textSecondary,
                                          fontFamily: 'monospace'),
                                    ),
                                    Text(
                                      '${((_totalGames > 0 ? _currentGame / _totalGames : 0) * 100).toInt()}%',
                                      style: FusionText.bodySmall.copyWith(
                                          color: FusionColors.wii,
                                          fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                                if (_currentGameId.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Processing: $_currentGameId',
                                    style: FusionText.bodySmall.copyWith(
                                        color: FusionColors.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: GlowButton(
                            label:
                                _exporting ? 'Processing...' : 'Start Export',
                            icon: _exporting
                                ? Icons.hourglass_top
                                : Icons.rocket_launch,
                            onPressed: (_exporting || _selectedDrive == null)
                                ? null
                                : _exportCovers,
                            color: FusionColors.wii,
                            glowColor: FusionColors.wii,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Note: This process may take several minutes depending on your SD card speed.',
                          style: FusionText.bodySmall.copyWith(
                              color: FusionColors.textMuted,
                              fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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
    final isSelected = value == groupValue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? FusionColors.wii.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? FusionColors.wii : FusionColors.borderSubtle,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Radio<String>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: FusionColors.wii,
                fillColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? FusionColors.wii
                      : FusionColors.textSecondary;
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: FusionText.bodyMedium.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? FusionColors.wii
                            : FusionColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: FusionText.bodySmall
                          .copyWith(color: FusionColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
