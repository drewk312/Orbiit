import 'package:flutter/material.dart';
import '../services/hardware_service.dart';
import '../services/drive_doctor_service.dart';
import '../services/library_state_service.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/forge_provider.dart';
import '../widgets/immersive_glass_header.dart';

/// Hardware Wizard Screen - USB Drive Setup and Game Deployment
class HardwareWizardScreen extends StatefulWidget {
  const HardwareWizardScreen({super.key});

  @override
  State<HardwareWizardScreen> createState() => _HardwareWizardScreenState();
}

class _HardwareWizardScreenState extends State<HardwareWizardScreen>
    with SingleTickerProviderStateMixin {
  final HardwareService _hardware = HardwareService();
  final LibraryStateService _library = LibraryStateService();

  List<DriveInfo> _drives = [];
  DriveInfo? _selectedDrive;
  bool _isScanning = false;
  bool _isDeploying = false;
  double _deployProgress = 0.0;

  String _deployStatus = '';

  // Drive Doctor State
  final DriveDoctorService _doctor = DriveDoctorService();
  bool _checkingPartitions = false;
  List<PartitionInfo> _partitions = [];
  bool _hasPartitionIssue = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _scanDrives();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _scanDrives() async {
    if (!mounted) return;
    setState(() => _isScanning = true);

    try {
      final driveDetails = await _hardware.getConnectedDrivesDetailed();
      final drives = <DriveInfo>[];

      for (final detail in driveDetails) {
        if (!mounted) return;
        final info = await _getDriveInfo(detail['letter'], detail);
        if (info != null) {
          drives.add(info);
        }
      }

      if (!mounted) return;
      setState(() {
        _drives = drives;
        _isScanning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isScanning = false);
    }
  }

  Future<DriveInfo?> _getDriveInfo(String letter,
      [Map<String, dynamic>? detail]) async {
    try {
      final path = letter.endsWith('\\') ? letter : '$letter\\';
      final dir = Directory(path);

      if (!await dir.exists()) return null;

      // Check for Wii structure
      final hasWbfs = await Directory('${path}wbfs').exists();
      final hasGames = await Directory('${path}games').exists();
      final hasApps = await Directory('${path}apps').exists();

      // Count games
      int gameCount = 0;
      if (hasWbfs) {
        gameCount += await _countFiles('${path}wbfs', ['.wbfs', '.iso']);
      }
      if (hasGames) {
        gameCount += await _countFiles('${path}games', [
          '.wbfs',
          '.iso',
          '.gcm',
        ]);
      }

      return DriveInfo(
        letter: letter,
        path: path,
        isRemovable:
            detail?['removable'] ?? !letter.toUpperCase().startsWith('C'),
        hasWiiStructure: hasWbfs || hasGames,
        hasAppsFolder: hasApps,
        gameCount: gameCount,
        label: detail?['name'] ?? 'USB Drive',
        sizeGb: (detail?['size'] ?? 0) / (1024 * 1024 * 1024),
        fs: detail?['fs'] ?? 'Unknown',
      );
    } catch (e) {
      return null;
    }
  }

  Future<int> _countFiles(String path, List<String> extensions) async {
    int count = 0;
    try {
      final dir = Directory(path);
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final lower = entity.path.toLowerCase();
          if (extensions.any((ext) => lower.endsWith(ext))) {
            count++;
          }
        }
      }
    } catch (_) {}
    return count;
  }

  Future<void> _setupDrive(DriveInfo drive) async {
    setState(() {
      _isDeploying = true;
      _deployProgress = 0.0;
      _deployStatus = 'Creating folder structure...';
    });

    try {
      await _hardware.deployWiiStructure(drive.path);
      setState(() {
        _deployProgress = 0.3;
        _deployStatus = 'Wii folders created!';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _deployProgress = 1.0;
        _deployStatus = 'Drive is ready for games!';
        _isDeploying = false;
      });

      // Refresh drive info
      _scanDrives();
    } catch (e) {
      setState(() {
        _isDeploying = false;
        _deployStatus = 'Error: $e';
      });
    }
  }

  Future<void> _checkDriveHealth(DriveInfo drive) async {
    setState(() {
      _checkingPartitions = true;
      _partitions = [];
      _hasPartitionIssue = false;
    });

    try {
      final parts = await _doctor.getDiskPartitions(drive.letter);
      final issue = parts.length >
          1; // More than 1 partition is suspicious for Wii/GameCube

      setState(() {
        _partitions = parts;
        _hasPartitionIssue = issue;
        _checkingPartitions = false;
      });
    } catch (e) {
      debugPrint('Doctor Check Error: $e');
      setState(() => _checkingPartitions = false);
    }
  }

  Future<void> _fixPartitions(DriveInfo drive) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ NUKE & PAVE WARNING'),
        backgroundColor: const Color(0xFF2D1B1B), // Dark Red tint
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will COMPLETELY WIPE the physical disk.',
              style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Drive: ${drive.letter} (${drive.label})\n'
              'All partitions will be deleted.\n'
              'Disk will be initialized as Single FAT32 Partition.\n\n'
              'Are you absolutely sure?',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('CANCEL', style: TextStyle(color: Colors.white))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('NUKE IT (FORMAT)',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeploying = true;
      _deployProgress = 0.0;
      _deployStatus = 'Analyzing Disk Structure...';
    });

    try {
      final diskNum = await _doctor.getDiskNumber(drive.letter);
      if (diskNum == null)
        throw Exception('Could not determine physical disk number');

      setState(() => _deployStatus =
          'Formatting Disk $diskNum (This may take a moment)...');

      await _doctor.formatDiskToSingleFAT32(diskNum);

      setState(() {
        _deployStatus = 'Success! Disk is now clean FAT32.';
        _deployProgress = 1.0;
      });

      await Future.delayed(const Duration(seconds: 2));
      _scanDrives(); // Refresh everything
    } catch (e) {
      setState(() => _deployStatus = 'Fix Failed: $e');
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isDeploying = false);
    }
  }

  Future<void> _formatDrive(DriveInfo drive) async {
    final forgeProvider = Provider.of<ForgeProvider>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Format'),
        content: Text(
            'Warning: This will ERASE everything on ${drive.letter} (${drive.label}).\n\nNintendont requires FAT32 with 32KB clusters. Fusion will execute native formatting.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('FORMAT'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeploying = true;
      _deployProgress = 0.0;
      _deployStatus = 'Executing Native Format...';
    });

    try {
      final success =
          await forgeProvider.formatDrive(drive.letter, label: 'Orbiit');

      if (success) {
        setState(() {
          _deployProgress = 1.0;
          _deployStatus = 'Drive formatted successfully!';
        });
      } else {
        setState(() {
          _deployStatus = 'Format failed. Ensure Administrator privileges.';
        });
      }

      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isDeploying = false);
      _scanDrives();
    } catch (e) {
      setState(() {
        _isDeploying = false;
        _deployStatus = 'Format error: $e';
      });
    }
  }

  Future<void> _deployGames(DriveInfo drive) async {
    final games = _library.games;
    if (games.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No games in library to deploy')),
      );
      return;
    }

    setState(() {
      _isDeploying = true;
      _deployProgress = 0.0;
      _deployStatus = 'Deploying ${games.length} games...';
    });

    int deployed = 0;
    for (final game in games) {
      try {
        final platform = game.platform.toLowerCase();
        final safeTitle = _sanitizeFilename(game.title);
        final safeId = _sanitizeFilename(game.gameId ?? 'GAMEID');
        String destPath;

        // 🟢 Wii Logic: wbfs/Title [ID]/id.wbfs
        if (platform == 'wii') {
          final folderName = '$safeTitle [$safeId]';
          final folderPath = '${drive.path}wbfs\\$folderName';
          await Directory(folderPath).create(recursive: true);

          // Keep original extension (usually .wbfs or .iso)
          final ext = game.fileName.split('.').last;
          destPath = '$folderPath\\$safeId.$ext';
        }
        // 🟣 GameCube Logic: games/Title [ID]/game.iso
        else if (platform == 'gamecube' || platform == 'gc') {
          final folderName = '$safeTitle [$safeId]';
          final folderPath = '${drive.path}games\\$folderName';
          await Directory(folderPath).create(recursive: true);

          // Nintendont requires game.iso
          destPath = '$folderPath\\game.iso';
        }
        // ⚪ Other Logic: games/Platform/Title.iso (Fallback)
        else {
          final folderPath = '${drive.path}games\\${game.platform}';
          await Directory(folderPath).create(recursive: true);
          destPath = '$folderPath\\${game.fileName}';
        }

        final sourceFile = File(game.path);
        if (await sourceFile.exists()) {
          // If dest exists, skip or overwrite? For now, skip to save time/writes
          if (!await File(destPath).exists()) {
            await sourceFile.copy(destPath);
          }
          deployed++;
        }

        setState(() {
          _deployProgress = deployed / games.length;
          _deployStatus = 'Deployed $deployed of ${games.length}...';
        });
      } catch (e) {
        // Skip failed files
        debugPrint('Deploy error for ${game.title}: $e');
      }
    }

    setState(() {
      _isDeploying = false;
      _deployProgress = 1.0;
      _deployStatus = 'Deployed $deployed games!';
    });

    _scanDrives();
  }

  String _sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ImmersiveAppShell(
      title: 'WIZARD',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format Guide Card
            _buildFormatGuide(primaryColor, isDark),
            const SizedBox(height: 24),

            // Drives Section
            Row(
              children: [
                Text(
                  'Detected Drives',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _isScanning ? null : _scanDrives,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Rescan drives',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Drives Grid
            Expanded(
              child: _drives.isEmpty
                  ? _buildEmptyState(primaryColor, isDark)
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _drives.length,
                      itemBuilder: (context, index) =>
                          _buildDriveCard(_drives[index], primaryColor, isDark),
                    ),
            ),

            if (_isDeploying) _buildDeploymentProgress(primaryColor),

            // Drive Doctor Panel (Only when drive selected)
            if (_selectedDrive != null && !_isDeploying)
              _buildDoctorPanel(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorPanel(Color color) {
    if (_checkingPartitions) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _hasPartitionIssue
            ? Colors.orange.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _hasPartitionIssue
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _hasPartitionIssue
                    ? Icons.warning_amber_rounded
                    : Icons.verified_user,
                color: _hasPartitionIssue ? Colors.orange : Colors.green,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasPartitionIssue
                        ? 'Optimization Alert'
                        : 'Drive Health Good',
                    style: TextStyle(
                      color: _hasPartitionIssue ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (_hasPartitionIssue)
                    Text(
                      'Multiple partitions detected (${_partitions.length}). Wii may have trouble reading this.',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                ],
              ),
              const Spacer(),
              if (_hasPartitionIssue)
                ElevatedButton.icon(
                  onPressed: () => _fixPartitions(_selectedDrive!),
                  icon: const Icon(Icons.build, size: 16),
                  label: const Text('FIX (FORMAT DISK)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          // Partition Visualizer if needed, implies simple bar
          if (_partitions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Partition Layout:',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: _partitions.map((p) {
                  return Expanded(
                    flex: p.size > 0 ? p.size : 1, // Crude sizing visualisation
                    child: Container(
                      height: 8,
                      color: p.driveLetter == _selectedDrive?.letter
                          ? color
                          : Colors.grey.withValues(alpha: 0.3),
                      margin: const EdgeInsets.only(right: 2),
                    ),
                  );
                }).toList(),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildFormatGuide(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.15),
            primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_outline, color: primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended Format',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'FAT32 with 32KB cluster size. Use Rufus or guiformat for drives > 32GB.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Rufus Guide'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.usb_off,
            size: 64,
            color: primaryColor.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No USB drives detected',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect a USB drive and click Refresh',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriveCard(DriveInfo drive, Color primaryColor, bool isDark) {
    final isSelected = _selectedDrive?.letter == drive.letter;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedDrive = drive);
        _checkDriveHealth(drive);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: drive.hasWiiStructure
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      drive.hasWiiStructure
                          ? Icons.check_circle
                          : Icons.pending,
                      color:
                          drive.hasWiiStructure ? Colors.green : Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    drive.letter,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (drive.hasWiiStructure)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'READY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                drive.hasWiiStructure
                    ? '${drive.gameCount} games on drive'
                    : 'Not configured for Wii',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!drive.hasWiiStructure)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _setupDrive(drive),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Setup'),
                      ),
                    ),
                  if (drive.hasWiiStructure) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _deployGames(drive),
                        child: const Text('Deploy'),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  // NATIVE FORMAT BUTTON
                  IconButton(
                    onPressed: () => _formatDrive(drive),
                    icon: const Icon(Icons.cleaning_services, size: 20),
                    tooltip: 'Native Format (FAT32/32K)',
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
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

  Widget _buildDeploymentProgress(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _deployStatus,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _deployProgress,
            backgroundColor: primaryColor.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(primaryColor),
          ),
        ],
      ),
    );
  }
}

class DriveInfo {
  final String letter;
  final String path;
  final bool isRemovable;
  final bool hasWiiStructure;
  final bool hasAppsFolder;
  final int gameCount;
  final String label;
  final double sizeGb;
  final String fs;

  DriveInfo({
    required this.letter,
    required this.path,
    required this.isRemovable,
    required this.hasWiiStructure,
    required this.hasAppsFolder,
    required this.gameCount,
    this.label = 'USB Drive',
    this.sizeGb = 0,
    this.fs = 'Unknown',
  });
}
