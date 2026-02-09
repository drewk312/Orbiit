import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import '../../core/database/database.dart';
import '../../screens/cover_art_manager_screen.dart';
import '../../screens/storage_organizer_screen.dart';
import '../../screens/wiiload_screen.dart';
import '../../screens/controller_setup_screen.dart';
import '../../screens/file_import_screen.dart';
import '../services/wiitdb_service.dart';
import '../services/checksum_service.dart';
import '../services/archive_service.dart';
import '../services/banner_service.dart';
import '../services/cheat_code_service.dart';
import '../services/file_utility_service.dart';
import '../services/file_splitter_service.dart';
import '../services/duplicate_detection_service.dart';
import '../../widgets/sd_card_setup_widget.dart';
import '../fusion/design_system.dart'; // FusionColors
import '../fusion_ui/fusion_ui.dart'; // Unified Design System

/// Tools and utilities screen
/// Exposes all advanced features like TinyWii's tools.rs
class ToolsScreen extends StatefulWidget {
  final bool embedInWrapper;

  const ToolsScreen({super.key, this.embedInWrapper = false});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  // All services use static methods

  bool _isProcessing = false;
  String _statusMessage = '';
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    if (widget.embedInWrapper) {
      return _isProcessing ? _buildProcessingView() : _buildToolsGrid();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tools & Utilities'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isProcessing ? _buildProcessingView() : _buildToolsGrid(),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (_progress > 0) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text('${(_progress * 100).toStringAsFixed(0)}%'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToolsGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SD Card Setup Widget
          const SDCardSetupWidget(),
          const SizedBox(height: 24),

          // Smart Import (NEW!)
          _buildSection(
            'Smart Organization',
            Icons.auto_awesome,
            FusionColors.nebulaPurple,
            [
              _buildToolCard(
                'Smart File Import',
                'Auto-detect platform and organize games',
                Icons.auto_fix_high,
                FusionColors.nebulaPurple,
                _openSmartImport,
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSection(
            'Database & Metadata',
            Icons.download,
            Colors.blue,
            [
              _buildToolCard(
                'Download WiiTDB Database',
                'Get latest game metadata',
                Icons.cloud_download,
                FusionColors.nebulaCyan,
                _downloadWiiTDB,
              ),
              _buildToolCard(
                'Database Info',
                'View database status',
                Icons.info,
                FusionColors.nebulaCyan,
                _showDatabaseInfo,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Game Verification',
            Icons.verified,
            Colors.green,
            [
              _buildToolCard(
                'Calculate Checksum',
                'CRC32, MD5, SHA-1',
                Icons.calculate,
                Colors.green,
                _calculateChecksum,
              ),
              _buildToolCard(
                'Find Duplicates',
                'Detect duplicate games',
                Icons.content_copy,
                Colors.teal,
                _findDuplicates,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Archive Tools',
            Icons.folder_zip,
            Colors.orange,
            [
              _buildToolCard(
                'Extract Archive',
                'ZIP, 7Z, RAR, GZ, BZ2',
                Icons.unarchive,
                Colors.orange,
                _extractArchive,
              ),
              _buildToolCard(
                'Split for FAT32',
                'Split files >4GB',
                Icons.call_split,
                Colors.deepOrange,
                _splitFile,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Downloads',
            Icons.download_for_offline,
            Colors.purple,
            [
              _buildToolCard(
                'Cover Art Manager',
                'Download game covers',
                Icons.image,
                Colors.purple,
                _openCoverArtManager,
              ),
              _buildToolCard(
                'GameCube Banners',
                'Download animated banners',
                Icons.video_library,
                Colors.purple[300]!,
                _downloadBanners,
              ),
              _buildToolCard(
                'Cheat Codes',
                'Download Gecko codes',
                Icons.code,
                Colors.deepPurple,
                _downloadCheats,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'File Utilities',
            Icons.build,
            Colors.amber,
            [
              _buildToolCard(
                'Sanitize Filename',
                'Fix invalid characters',
                Icons.text_fields,
                Colors.amber,
                _sanitizeFilename,
              ),
              _buildToolCard(
                'Disk Space Info',
                'Check available space',
                Icons.storage,
                Colors.orange[700]!,
                _checkDiskSpace,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Nintendont & GameCube',
            Icons.sports_esports,
            Colors.deepPurple,
            [
              _buildToolCard(
                'Nintendont Compatibility',
                'Check GameCube game compatibility',
                Icons.check_circle,
                Colors.deepPurple,
                _openNintendontCompatibility,
              ),
              _buildToolCard(
                'Nintendont Controller Setup',
                'Configure USB controllers for Nintendont',
                Icons.gamepad,
                Colors.deepPurple[300]!,
                _openNintendontControllerSetup,
              ),
              _buildToolCard(
                'GC Memory Card Manager',
                'Manage GameCube saves',
                Icons.sd_card,
                Colors.purple,
                _openGCMemoryManager,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Save Data & Backups',
            Icons.save,
            Colors.blue,
            [
              _buildToolCard(
                'Wii Save Manager',
                'Backup & restore Wii saves',
                Icons.backup,
                Colors.blue,
                _openWiiSaveManager,
              ),
              _buildToolCard(
                'NAND Backup Guide',
                'Full system backup with BootMii',
                Icons.security,
                Colors.blue[300]!,
                _openNANDBackupGuide,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Online Services',
            Icons.public,
            Colors.green,
            [
              _buildToolCard(
                'Wiimmfi Setup',
                'Play online after Nintendo WFC shutdown',
                Icons.wifi,
                Colors.green,
                _openWiimmfiSetup,
              ),
              _buildToolCard(
                'WiiLink Setup',
                'Restore WiiConnect24 services',
                Icons.cloud,
                Colors.green[300]!,
                _openWiiLinkSetup,
              ),
              _buildToolCard(
                'RiiConnect24',
                'News, Weather, and more',
                Icons.rss_feed,
                Colors.teal,
                _openRiiConnect24Setup,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Wireless Transfer',
            Icons.wifi,
            Colors.cyan,
            [
              _buildToolCard(
                'WiiLoad Transfer',
                'Send files to Wii wirelessly',
                Icons.send,
                Colors.cyan,
                _openWiiLoad,
              ),
              _buildToolCard(
                'FTP Server Guide',
                'Access Wii files from PC',
                Icons.folder_shared,
                Colors.cyan[300]!,
                _openFTPGuide,
              ),
              _buildToolCard(
                'Storage Organizer',
                'Manage & organize your library',
                Icons.folder_special,
                Colors.teal,
                _openStorageOrganizer,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Game Mods & Patching',
            Icons.extension,
            Colors.indigo,
            [
              _buildToolCard(
                'Riivolution Manager',
                'On-the-fly disc patching for mods',
                Icons.build_circle,
                Colors.indigo,
                _openRiivolutionManager,
              ),
              _buildToolCard(
                'Project+ Installer',
                'Install Smash Bros Brawl mod',
                Icons.sports_mma,
                Colors.indigo[300]!,
                _openProjectPlusInstaller,
              ),
              _buildToolCard(
                'Game Backup Manager',
                'Copy & manage Wii game backups',
                Icons.backup,
                Colors.indigoAccent,
                _openGameBackupManager,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Emulators Guide',
            Icons.videogame_asset,
            Colors.green,
            [
              _buildToolCard(
                'Emulator Setup Guide',
                'NES, SNES, N64, GBA & more',
                Icons.play_circle,
                Colors.green,
                _openEmulatorGuide,
              ),
              _buildToolCard(
                'RetroArch Setup',
                'Multi-system emulator',
                Icons.apps,
                Colors.green[300]!,
                _openRetroArchGuide,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Troubleshooting & Recovery',
            Icons.healing,
            Colors.red,
            [
              _buildToolCard(
                'Banner Brick Fix',
                'Recover from bad WAD installs',
                Icons.warning_amber,
                Colors.red,
                _openBannerBrickFix,
              ),
              _buildToolCard(
                'System Recovery Guide',
                'Fix common Wii issues',
                Icons.restore,
                Colors.red[300]!,
                _openSystemRecoveryGuide,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Customization & Themes',
            Icons.palette,
            Colors.pink,
            [
              _buildToolCard(
                'Wii Themes Manager',
                'Install custom Wii Menu themes',
                Icons.brush,
                Colors.pink,
                _openWiiThemesManager,
              ),
              _buildToolCard(
                'USB Loader GX Themes',
                'Download & install loader themes',
                Icons.color_lens,
                Colors.pink[300]!,
                _openUSBLoaderThemes,
              ),
              _buildToolCard(
                'Homebrew Channel Themes',
                'Customize HBC appearance',
                Icons.home,
                Colors.pinkAccent,
                _openHBCThemes,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: children,
        ),
      ],
    );
  }

  Widget _buildToolCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tool implementations

  Future<void> _downloadWiiTDB() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Downloading WiiTDB database...';
      _progress = 0.0;
    });

    try {
      await WiiTDBService.downloadDatabase(
        onProgress: (current, total) {
          setState(() {
            _progress = current / total;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('WiiTDB database downloaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _showDatabaseInfo() async {
    final isCached = await WiiTDBService.isDatabaseCached();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Database Info'),
        content: Text(
          isCached
              ? 'WiiTDB database is downloaded and ready to use.'
              : 'WiiTDB database not found. Download it first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _calculateChecksum() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select game file to checksum',
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.first.path!;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Calculating checksums...';
      _progress = 0.0;
    });

    try {
      final checksumService = ChecksumService();
      final checksums = await checksumService.calculateAllFile(
        filePath,
        onProgress: (current, total) {
          setState(() {
            _progress = current / total;
          });
        },
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Checksums'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('File: ${result.files.first.name}'),
                const SizedBox(height: 16),
                Text('CRC32: ${checksums.crc32}'),
                const SizedBox(height: 8),
                Text('MD5: ${checksums.md5}'),
                const SizedBox(height: 8),
                Text('SHA-1: ${checksums.sha1}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _findDuplicates() async {
    final database = Provider.of<AppDatabase>(context, listen: false);
    final games = await database.getAllTitles();

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Scanning for duplicates...';
      _progress = 0.0;
    });

    try {
      final duplicateService = DuplicateDetectionService();
      final duplicates = await duplicateService.findDuplicates(
        games,
        checkCRC: false, // Fast mode - just game ID
        onProgress: (current, total) {
          setState(() {
            _progress = current / total;
          });
        },
      );

      if (mounted) {
        Navigator.pop(context);
        // Show results screen (would need to create this)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Found ${duplicates.length} duplicate groups')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _extractArchive() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select archive to extract',
      type: FileType.custom,
      allowedExtensions: ['zip', '7z', 'rar', 'gz', 'bz2'],
    );

    if (result == null || result.files.isEmpty) return;

    final archivePath = result.files.first.path!;

    // Pick output directory
    final outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select output directory',
    );

    if (outputDir == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Extracting archive...';
      _progress = 0.0;
    });

    try {
      final gamePath = await ArchiveExtractionService.extractArchive(
        archivePath,
        outputDir,
        onProgress: (current, total, fileName) {
          setState(() {
            _progress = current / total;
            _statusMessage = 'Extracting: $fileName';
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extracted to: $gamePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _splitFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select file to split for FAT32',
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.first.path!;

    // Check if actually needs splitting
    if (!await FileSplitterService.needsSplitting(filePath)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('File is under 4GB - no splitting needed')),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Splitting file for FAT32...';
      _progress = 0.0;
    });

    try {
      final parts = await FileSplitterService.splitFile(
        filePath,
        onProgress: (current, total) {
          setState(() {
            _progress = current / total;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Split into ${parts.length} parts')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _downloadBanners() async {
    final database = Provider.of<AppDatabase>(context, listen: false);
    final games = await database.getAllTitles();

    // Filter to GameCube games only
    final gcGames = games.where((g) => g.platform == 'GameCube').toList();

    if (gcGames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No GameCube games found')),
      );
      return;
    }

    // Convert to Map format
    final gamesMaps = gcGames
        .map((g) => {
              'gameId': g.gameId,
              'platform': g.platform,
              'title': g.title,
            })
        .toList();

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Downloading GameCube banners...';
      _progress = 0.0;
    });

    try {
      await BannerService.downloadBannersForGames(
        gamesMaps,
        onProgress: (current, total, gameId) {
          setState(() {
            _progress = current / total;
            _statusMessage = 'Downloading banners... ($current/$total)';
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banners downloaded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _downloadCheats() async {
    final database = Provider.of<AppDatabase>(context, listen: false);
    final games = await database.getAllTitles();

    // Convert to Map format
    final gamesMaps = games
        .map((g) => {
              'gameId': g.gameId,
              'platform': g.platform,
              'title': g.title,
            })
        .toList();

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Downloading cheat codes...';
      _progress = 0.0;
    });

    try {
      await CheatCodeService.downloadCheatsForGames(
        gamesMaps,
        onProgress: (current, total, gameId) {
          setState(() {
            _progress = current / total;
            _statusMessage = 'Downloading cheats... ($current/$total)';
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cheat codes downloaded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _sanitizeFilename() async {
    // Show dialog to input filename
    String? input;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sanitize Filename'),
        content: TextField(
          onChanged: (value) => input = value,
          decoration: const InputDecoration(
            hintText: 'Enter filename',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (input != null) {
                final sanitized = FileUtilityService.sanitizeFilename(input!);
                Navigator.pop(context);

                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sanitized Filename'),
                    content: Text(sanitized),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Sanitize'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkDiskSpace() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select directory to check',
    );

    if (path == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Calculating disk usage...';
    });

    try {
      final usage = await FileUtilityService.getDiskUsage(path);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Disk Space'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Path: $path'),
                const SizedBox(height: 16),
                Text('Total: ${usage.totalFormatted}'),
                Text('Used: ${usage.usedFormatted}'),
                Text('Free: ${usage.freeFormatted}'),
                if (usage.totalBytes > 0)
                  Text('Usage: ${usage.usedPercentage.toStringAsFixed(1)}%'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _openCoverArtManager() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CoverArtManagerScreen(),
      ),
    );
  }

  void _openNintendontControllerSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ControllerSetupScreen(),
      ),
    );
  }

  void _openWiiLoad() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WiiLoadScreen(),
      ),
    );
  }

  void _openSmartImport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FileImportScreen(),
      ),
    );
  }

  void _openStorageOrganizer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StorageOrganizerScreen(),
      ),
    );
  }

  void _openWiiThemesManager() {
    showDialog(
      context: context,
      builder: (context) => const WiiThemesManagerDialog(),
    );
  }

  void _openUSBLoaderThemes() {
    showDialog(
      context: context,
      builder: (context) => const USBLoaderThemesDialog(),
    );
  }

  void _openHBCThemes() {
    showDialog(
      context: context,
      builder: (context) => const HBCThemesDialog(),
    );
  }

  void _openRiivolutionManager() {
    showDialog(
      context: context,
      builder: (context) => const RiivolutionManagerDialog(),
    );
  }

  void _openProjectPlusInstaller() {
    showDialog(
      context: context,
      builder: (context) => const ProjectPlusInstallerDialog(),
    );
  }

  void _openGameBackupManager() {
    showDialog(
      context: context,
      builder: (context) => const GameBackupManagerDialog(),
    );
  }

  void _openEmulatorGuide() {
    showDialog(
      context: context,
      builder: (context) => const EmulatorGuideDialog(),
    );
  }

  void _openRetroArchGuide() {
    showDialog(
      context: context,
      builder: (context) => const RetroArchGuideDialog(),
    );
  }

  void _openBannerBrickFix() {
    showDialog(
      context: context,
      builder: (context) => const BannerBrickFixDialog(),
    );
  }

  void _openSystemRecoveryGuide() {
    showDialog(
      context: context,
      builder: (context) => const SystemRecoveryGuideDialog(),
    );
  }

  void _openNintendontCompatibility() {
    showDialog(
      context: context,
      builder: (context) => const NintendontCompatibilityDialog(),
    );
  }

  void _openGCMemoryManager() {
    showDialog(
      context: context,
      builder: (context) => const GCMemoryManagerDialog(),
    );
  }

  void _openWiiSaveManager() {
    showDialog(
      context: context,
      builder: (context) => const WiiSaveManagerDialog(),
    );
  }

  void _openNANDBackupGuide() {
    showDialog(
      context: context,
      builder: (context) => const NANDBackupGuideDialog(),
    );
  }

  void _openWiimmfiSetup() {
    showDialog(
      context: context,
      builder: (context) => const WiimmfiSetupDialog(),
    );
  }

  void _openWiiLinkSetup() {
    showDialog(
      context: context,
      builder: (context) => const WiiLinkSetupDialog(),
    );
  }

  void _openRiiConnect24Setup() {
    showDialog(
      context: context,
      builder: (context) => const RiiConnect24SetupDialog(),
    );
  }

  void _openFTPGuide() {
    showDialog(
      context: context,
      builder: (context) => const FTPGuideDialog(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WII THEMES MANAGER DIALOG
// Complete theming solution based on https://wii.hacks.guide/themes
// ═══════════════════════════════════════════════════════════════════════════

class WiiThemesManagerDialog extends StatefulWidget {
  const WiiThemesManagerDialog({super.key});

  @override
  State<WiiThemesManagerDialog> createState() => _WiiThemesManagerDialogState();
}

class _WiiThemesManagerDialogState extends State<WiiThemesManagerDialog> {
  String _selectedRegion = 'USA';
  String _selectedVersion = '4.3';
  String? _sdCardPath;
  bool _isDownloading = false;
  String _status = '';
  double _progress = 0.0;

  final List<Map<String, String>> _themeSources = [
    {
      'name': 'Wii Theme Team Creations',
      'url': 'https://gbatemp.net/threads/wii-theme-team-creations.260327/',
      'type': '.mym',
    },
    {
      'name': 'Wii Theme Google Drive',
      'url':
          'https://drive.google.com/drive/folders/1H8aiZwP3rH5Y9VjVBpVCKCgRQZPy6q7Y',
      'type': '.mym',
    },
    {
      'name': 'GBAtemp Wii Themes',
      'url': 'https://gbatemp.net/download/categories/other-files-for-wii.35/',
      'type': '.mym',
    },
    {
      'name': 'Wii Themer (Auto CSM)',
      'url': 'https://wiithemer.org/',
      'type': '.csm ready',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.pink.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.pink.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.pink.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.brush, color: Colors.pink, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wii Themes Manager',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Install custom Wii Menu themes safely',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
            ),

            // Warning banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'IMPORTANT: Ensure you have BootMii and Priiloader installed for brick protection before installing themes!',
                      style: TextStyle(
                        color: Colors.red[300],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Region & Version selection
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'Region',
                            _selectedRegion,
                            ['USA', 'EUR', 'JPN', 'KOR'],
                            (val) => setState(() => _selectedRegion = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            'System Menu',
                            _selectedVersion,
                            ['4.3', '4.2', '4.1', '4.0'],
                            (val) => setState(() => _selectedVersion = val!),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // SD Card selection
                    _buildSDCardSelector(),

                    const SizedBox(height: 24),

                    // Quick Setup
                    _buildSectionHeader('Quick Setup', Icons.rocket_launch),
                    const SizedBox(height: 12),
                    _buildQuickSetupCard(),

                    const SizedBox(height: 24),

                    // Theme Sources
                    _buildSectionHeader('Theme Sources', Icons.palette),
                    const SizedBox(height: 12),
                    ..._themeSources
                        .map((source) => _buildThemeSourceCard(source)),

                    const SizedBox(height: 24),

                    // How It Works
                    _buildSectionHeader('How It Works', Icons.help_outline),
                    const SizedBox(height: 12),
                    _buildHowItWorksCard(),
                  ],
                ),
              ),
            ),

            // Status/Progress
            if (_isDownloading)
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(Colors.pink),
                    ),
                    const SizedBox(height: 8),
                    Text(_status,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: const Color(0xFF1A1A24),
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSDCardSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sd_card, color: Colors.pink, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SD Card / USB',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Text(
                  _sdCardPath ?? 'Not selected',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _selectSDCard,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink.withValues(alpha: 0.2),
              foregroundColor: Colors.pink,
            ),
            child: const Text('Browse'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.pink, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSetupCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pink.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Auto-Setup Theme Tools',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Download csm-installer and set up the themes folder automatically',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sdCardPath != null ? _setupThemeTools : null,
              icon: const Icon(Icons.download),
              label: const Text('Download & Setup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSourceCard(Map<String, String> source) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pink.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.folder, color: Colors.pink, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source['name']!,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Format: ${source['type']}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _openUrl(source['url']!),
            child: const Text('Open', style: TextStyle(color: Colors.pink)),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStep('1', 'Download a .mym theme from sources above'),
          _buildStep('2', 'Use csm-installer to get base theme OR ThemeMii'),
          _buildStep('3', 'Build .csm file matching your region & version'),
          _buildStep('4', 'Place .csm in /themes folder on SD'),
          _buildStep('5', 'Run csm-installer on Wii to apply theme'),
          const SizedBox(height: 12),
          Text(
            'File types: .MYM = theme assets, .CSM = ready to install',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.pink.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(number,
                style: const TextStyle(
                    color: Colors.pink,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectSDCard() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select SD Card or USB Drive',
    );
    if (path != null) {
      setState(() => _sdCardPath = path);
    }
  }

  Future<void> _setupThemeTools() async {
    if (_sdCardPath == null) return;

    setState(() {
      _isDownloading = true;
      _status = 'Creating themes folder...';
      _progress = 0.1;
    });

    try {
      // Create themes folder
      final themesDir = Directory('$_sdCardPath/themes');
      if (!await themesDir.exists()) {
        await themesDir.create(recursive: true);
      }

      setState(() {
        _status = 'Creating apps folder...';
        _progress = 0.3;
      });

      // Create apps folder for csm-installer
      final appsDir = Directory('$_sdCardPath/apps/csm-installer');
      if (!await appsDir.exists()) {
        await appsDir.create(recursive: true);
      }

      setState(() {
        _status = 'Setup complete!';
        _progress = 1.0;
      });

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme folders created at $_sdCardPath'),
            backgroundColor: Colors.green,
          ),
        );

        // Show next steps dialog
        _showNextStepsDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  void _showNextStepsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text('Setup Complete!',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Folders created:',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
            const SizedBox(height: 8),
            _buildFolderChip('/themes'),
            _buildFolderChip('/apps/csm-installer'),
            const SizedBox(height: 16),
            Text(
              'Next steps:\n1. Download csm-installer.zip from GitHub\n2. Extract to /apps/csm-installer\n3. Download .mym themes to /themes\n4. Run csm-installer on your Wii',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openUrl(
                  'https://github.com/csm-installer/csm-installer/releases');
            },
            child: const Text('Get csm-installer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderChip(String path) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.pink.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(path,
          style: const TextStyle(
              color: Colors.pink, fontFamily: 'monospace', fontSize: 12)),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open: $url')),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// USB LOADER GX THEMES DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class USBLoaderThemesDialog extends StatefulWidget {
  const USBLoaderThemesDialog({super.key});

  @override
  State<USBLoaderThemesDialog> createState() => _USBLoaderThemesDialogState();
}

class _USBLoaderThemesDialogState extends State<USBLoaderThemesDialog> {
  String? _sdCardPath;

  final List<Map<String, String>> _themes = [
    {
      'name': 'USB Loader GX Dark Theme Pack',
      'desc': 'Collection of dark themes'
    },
    {'name': 'Clean Modern', 'desc': 'Minimalist design'},
    {'name': 'Nintendo Switch Style', 'desc': 'Switch-inspired UI'},
    {'name': 'Retro Classic', 'desc': 'Classic gaming aesthetic'},
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.2),
                    Colors.transparent
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.color_lens, color: Colors.purple, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('USB Loader GX Themes',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Customize your USB Loader',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Installation Path:',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'SD:/apps/usbloader_gx/theme/',
                        style: TextStyle(
                            color: Colors.green, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Instructions:',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      '1. Download theme .zip file\n'
                      '2. Extract to apps/usbloader_gx/ folder\n'
                      '3. In USB Loader GX: Settings → Theme Menu\n'
                      '4. Select and apply your theme',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.6),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _openUrl(
                              'https://gbatemp.net/threads/official-usb-loader-gx-themes-v3-x.535894/');
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Browse Themes Online'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open: $url')),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HOMEBREW CHANNEL THEMES DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class HBCThemesDialog extends StatelessWidget {
  const HBCThemesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 550),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.cyan.withValues(alpha: 0.2),
                    Colors.transparent
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home, color: Colors.cyan, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Homebrew Channel Themes',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Customize HBC appearance',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Installation Path:',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'SD:/apps/<theme_name>/',
                      style: TextStyle(
                          color: Colors.green, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Instructions:',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    '1. Download theme .zip from WiiBrew\n'
                    '2. Extract to SD:/apps/ folder\n'
                    '3. Launch HBC and select the theme app\n'
                    '4. Theme will be applied automatically',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        const url =
                            'https://wiibrew.org/wiki/List_of_Homebrew_Channel_themes';
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Could not open: $url')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Browse WiiBrew Themes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
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

// ═══════════════════════════════════════════════════════════════════════════
// RIIVOLUTION MANAGER DIALOG
// Based on https://wiki.hacks.guide/wiki/Wii:Riivolution
// ═══════════════════════════════════════════════════════════════════════════

class RiivolutionManagerDialog extends StatefulWidget {
  const RiivolutionManagerDialog({super.key});

  @override
  State<RiivolutionManagerDialog> createState() =>
      _RiivolutionManagerDialogState();
}

class _RiivolutionManagerDialogState extends State<RiivolutionManagerDialog> {
  String? _sdCardPath;
  bool _isSetup = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(
                'Riivolution Manager',
                'On-the-fly disc patcher for game mods',
                Icons.build_circle,
                Colors.indigo),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner
                    _buildInfoBanner(
                      'Riivolution patches game discs in real-time, allowing you to play mods without modifying the original game.',
                      Colors.indigo,
                    ),

                    const SizedBox(height: 20),

                    // Requirements
                    _buildSectionTitle('Requirements'),
                    _buildRequirementsList([
                      'A Wii with Homebrew Channel',
                      'SD card or USB drive',
                      'Clean physical game disc',
                      'Working disc drive',
                      'Mod files for your game',
                    ]),

                    const SizedBox(height: 20),

                    // SD Card selector
                    _buildSDCardSelector(),

                    const SizedBox(height: 20),

                    // File Structure
                    _buildSectionTitle('File Structure'),
                    _buildFileStructure(),

                    const SizedBox(height: 20),

                    // Setup button
                    _buildSetupButton(),

                    const SizedBox(height: 20),

                    // Instructions
                    _buildSectionTitle('How to Use'),
                    _buildInstructionsList([
                      'Extract Riivolution to /apps folder',
                      'Extract mod files to SD root (follow mod\'s structure)',
                      'Launch Riivolution from Homebrew Channel',
                      'Insert game disc',
                      'Enable mod options and select Launch',
                    ]),

                    const SizedBox(height: 16),

                    // Warning
                    _buildWarningBanner(
                        'NTSC = US/Japan, PAL = Europe/Korea. Use correct region mods!'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.2), Colors.transparent]),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(color: Colors.orange[300], fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRequirementsList(List<String> items) {
    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(item,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13))),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildInstructionsList(List<String> items) {
    return Column(
      children: items
          .asMap()
          .entries
          .map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text('${entry.key + 1}',
                          style: const TextStyle(
                              color: Colors.indigo,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(entry.value,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13))),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildSDCardSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sd_card, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SD Card / USB',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Text(_sdCardPath ?? 'Not selected',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final path = await FilePicker.platform.getDirectoryPath();
              if (path != null) setState(() => _sdCardPath = path);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.withValues(alpha: 0.2),
                foregroundColor: Colors.indigo),
            child: const Text('Browse'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileStructure() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '💾 SD Card Root:\n'
        ' ├── 📂 apps/\n'
        ' │   └── 📂 Riivolution/\n'
        ' │       ├── 📄 boot.dol\n'
        ' │       ├── 📄 icon.png\n'
        ' │       └── 📄 meta.xml\n'
        ' ├── 📂 Riivolution/\n'
        ' │   ├── 📂 config/\n'
        ' │   │   └── 📄 mod_name.xml\n'
        ' │   └── 📄 mod_name.xml\n'
        ' └── 📂 GameFiles/ (mod data)',
        style: TextStyle(
            color: Colors.green,
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.4),
      ),
    );
  }

  Widget _buildSetupButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _sdCardPath != null ? _setupRiivolution : null,
        icon: const Icon(Icons.download),
        label: const Text('Setup Riivolution Folders'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Future<void> _setupRiivolution() async {
    if (_sdCardPath == null) return;

    try {
      // Create folder structure
      await Directory('$_sdCardPath/apps/Riivolution').create(recursive: true);
      await Directory('$_sdCardPath/Riivolution/config')
          .create(recursive: true);

      setState(() => _isSetup = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Riivolution folders created! Download Riivolution from OSC.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROJECT PLUS INSTALLER DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class ProjectPlusInstallerDialog extends StatefulWidget {
  const ProjectPlusInstallerDialog({super.key});

  @override
  State<ProjectPlusInstallerDialog> createState() =>
      _ProjectPlusInstallerDialogState();
}

class _ProjectPlusInstallerDialogState
    extends State<ProjectPlusInstallerDialog> {
  String? _sdCardPath;
  String _selectedMethod = 'homebrew';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 750),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.orange.withValues(alpha: 0.2),
                  Colors.transparent
                ]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_mma, color: Colors.orange, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Project+ Installer',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Super Smash Bros. Brawl Mod',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),

            // Warning
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Project+ ONLY works with NTSC-U (US) disc! PAL/NTSC-J will NOT work.',
                      style: TextStyle(color: Colors.red[300], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Method selector
                    const Text('Installation Method:',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildMethodSelector(),

                    const SizedBox(height: 20),

                    // SD Card selector
                    _buildSDCardSelector(),

                    const SizedBox(height: 20),

                    // Method-specific instructions
                    _buildMethodInstructions(),

                    const SizedBox(height: 20),

                    // File Structure
                    const Text('File Structure:',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildFileStructure(),

                    const SizedBox(height: 20),

                    // Setup button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _sdCardPath != null ? _setupProjectPlus : null,
                        icon: const Icon(Icons.download),
                        label: const Text('Setup Project+ Folders'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Download link
                    TextButton.icon(
                      onPressed: () => _openUrl('https://projectplusgame.com/'),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Download from projectplusgame.com'),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.orange),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Row(
      children: [
        _buildMethodChip('Homebrew', 'homebrew', Icons.apps),
        const SizedBox(width: 8),
        _buildMethodChip('USB Loader', 'usb', Icons.usb),
        const SizedBox(width: 8),
        _buildMethodChip('Hackless', 'hackless', Icons.disc_full),
      ],
    );
  }

  Widget _buildMethodChip(String label, String value, IconData icon) {
    final isSelected = _selectedMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected
                  ? Colors.orange
                  : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: isSelected ? Colors.orange : Colors.white54),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.orange : Colors.white70,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSDCardSelector() {
    final isHackless = _selectedMethod == 'hackless';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sd_card, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isHackless ? 'SD Card (2GB only!)' : 'SD Card / USB',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                    Text(_sdCardPath ?? 'Not selected',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final path = await FilePicker.platform.getDirectoryPath();
                  if (path != null) setState(() => _sdCardPath = path);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    foregroundColor: Colors.orange),
                child: const Text('Browse'),
              ),
            ],
          ),
          if (isHackless) ...[
            const SizedBox(height: 8),
            Text('⚠️ Hackless method ONLY works with 2GB SD cards!',
                style: TextStyle(color: Colors.yellow[700], fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodInstructions() {
    switch (_selectedMethod) {
      case 'hackless':
        return _buildInstructions([
          'Delete ALL custom stages in Brawl (including default 3)',
          'Extract Project+ to SD card root',
          'Boot Brawl WITHOUT SD card',
          'Go to Stage Builder, insert SD card',
          'Exploit runs automatically',
        ]);
      case 'usb':
        return _buildInstructions([
          'Convert Brawl ISO using Game Backup Manager',
          'Extract Project+ to SD card root',
          'Place game backup on USB in /wbfs/',
          'Launch Project+ from Homebrew Channel',
          'No disc needed!',
        ]);
      default:
        return _buildInstructions([
          'Extract Project+ to SD card root',
          'Insert Brawl disc',
          'Launch Project+ from Homebrew Channel',
          'Game will boot with mod applied',
        ]);
    }
  }

  Widget _buildInstructions(List<String> steps) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: steps
            .asMap()
            .entries
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text('${e.key + 1}',
                            style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(e.value,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13))),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildFileStructure() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8)),
      child: const Text(
        '💾 SD Root:\n'
        ' ├── 📂 apps/\n'
        ' ├── 📂 private/\n'
        ' ├── 📂 Project+/\n'
        ' └── 📄 boot.elf',
        style: TextStyle(
            color: Colors.green, fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }

  Future<void> _setupProjectPlus() async {
    if (_sdCardPath == null) return;
    try {
      await Directory('$_sdCardPath/apps').create(recursive: true);
      await Directory('$_sdCardPath/private').create(recursive: true);
      await Directory('$_sdCardPath/Project+').create(recursive: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Project+ folders created! Download from projectplusgame.com'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GAME BACKUP MANAGER DIALOG
// Replacement for Wii Backup Manager
// ═══════════════════════════════════════════════════════════════════════════

class GameBackupManagerDialog extends StatefulWidget {
  const GameBackupManagerDialog({super.key});

  @override
  State<GameBackupManagerDialog> createState() =>
      _GameBackupManagerDialogState();
}

class _GameBackupManagerDialogState extends State<GameBackupManagerDialog> {
  String? _sourcePath;
  String? _destPath;
  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = '';

  Future<String?> _getGameId(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;

    RandomAccessFile? handle;
    try {
      handle = await file.open();
      // Check first 4 bytes for WBFS
      final header = await handle.read(4);
      String magic = String.fromCharCodes(header);

      if (magic == 'WBFS') {
        await handle.setPosition(512); // standard WBFS header is 512 bytes
        final idBytes = await handle.read(6);
        return String.fromCharCodes(idBytes)
            .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      } else {
        // Assume ISO/GCM/RVZ
        await handle.setPosition(0);
        final idBytes = await handle.read(6);
        return String.fromCharCodes(idBytes)
            .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      }
    } catch (e) {
      return null;
    } finally {
      await handle?.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 550,
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.teal.withValues(alpha: 0.2),
                  Colors.transparent
                ]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.backup, color: Colors.teal, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Game Backup Manager',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Copy & organize Wii/GC game backups',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'This tool automatically organizes Wii and GameCube games for USB Loaders (USB Loader GX, Wiiflow, Nintendont).',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Source selector
                    _buildPathSelector(
                        'Source (Game File)', _sourcePath, Icons.gamepad,
                        (path) {
                      setState(() => _sourcePath = path);
                    }, isFile: true),

                    const SizedBox(height: 16),

                    // Destination selector
                    _buildPathSelector(
                        'Destination (USB/SD Root)', _destPath, Icons.usb,
                        (path) {
                      setState(() => _destPath = path);
                    }, isFile: false),

                    const SizedBox(height: 20),

                    // Output structure display
                    if (_sourcePath != null && _destPath != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_forward,
                                color: Colors.teal, size: 16),
                            const SizedBox(width: 8),
                            const Expanded(
                                child: Text(
                              'Will be copied to correct /wbfs/ or /games/ folder automatically.',
                              style: TextStyle(
                                  color: Colors.tealAccent, fontSize: 12),
                            )),
                          ],
                        ),
                      ),

                    // Progress
                    if (_isProcessing) ...[
                      LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.white12,
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.teal)),
                      const SizedBox(height: 8),
                      Text('$_statusMessage ${(_progress * 100).toInt()}%',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 16),
                    ],

                    // Copy button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_sourcePath != null &&
                                _destPath != null &&
                                !_isProcessing)
                            ? _copyGame
                            : null,
                        icon: const Icon(Icons.copy),
                        label: const Text('Install Game'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathSelector(
      String label, String? path, IconData icon, Function(String) onSelect,
      {bool isFile = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Text(path ?? 'Not selected',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              String? result;
              if (isFile) {
                final res = await FilePicker.platform
                    .pickFiles(dialogTitle: 'Select Game File');
                result = res?.files.single.path;
              } else {
                result = await FilePicker.platform.getDirectoryPath();
              }
              if (result != null) onSelect(result);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.withValues(alpha: 0.2),
                foregroundColor: Colors.teal),
            child: const Text('Browse'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyGame() async {
    if (_sourcePath == null || _destPath == null) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _statusMessage = 'Reading game info...';
    });

    try {
      final sourceFile = File(_sourcePath!);
      final fileSize = await sourceFile.length();
      final gameId = await _getGameId(_sourcePath!);
      final fileName = p.basename(_sourcePath!);
      final title = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');

      if (gameId == null || gameId.length != 6) {
        throw Exception(
            'Could not read valid Game ID. File may be corrupted or unsupported.');
      }

      String targetDir;
      String targetName;

      // Determine GameCube vs Wii
      // Standard: GameCube IDs start with G (also D, P, U)
      // Wii IDs start with R, S, etc.
      // But checking first char isn't 100% reliable for obscure discs, but 99% fine.
      // Better check: Is it 1.35GB (GC) vs 4.3/8GB (Wii)?
      // But scrubbed/mini ISOs exist.
      // Let's use ID heuristic + Magic number check in _getGameId for WBFS.
      // If it has WBFS magic, it's Wii for sure.

      if (gameId.startsWith('G') ||
          gameId.startsWith('D') ||
          gameId.startsWith('P') ||
          (gameId.startsWith('U') && fileSize < 2000000000)) {
        // GameCube
        targetDir = p.join(_destPath!, 'games', '$title [$gameId]');
        targetName = 'game.iso';
      } else {
        // Wii
        targetDir = p.join(_destPath!, 'wbfs', '$title [$gameId]');
        targetName = '$gameId.wbfs'; // Rename logical ID
        // If source is .iso and not .wbfs, we should ideally convert, but here we just copy.
        // If user provides .iso, we'll name it .iso if we aren't converting.
        final ext = p.extension(_sourcePath!).toLowerCase();
        if (ext == '.iso') targetName = '$gameId.iso';
        if (ext == '.wbfs') targetName = '$gameId.wbfs';
        if (ext == '.rvz') targetName = '$gameId.rvz';
      }

      await Directory(targetDir).create(recursive: true);
      final targetFile = File(p.join(targetDir, targetName));

      setState(() => _statusMessage = 'Copying...');

      // Stream copy
      final reader = sourceFile.openRead();
      final writer = targetFile.openWrite();

      int bytesCopied = 0;
      await reader.listen((chunk) {
        writer.add(chunk);
        bytesCopied += chunk.length;
        if (fileSize > 0) {
          // Avoid div by zero
          setState(() {
            _progress = bytesCopied / fileSize;
          });
        }
      }).asFuture();

      await writer.close();

      setState(() {
        _isProcessing = false;
        _progress = 1.0;
        _statusMessage = 'Complete!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Installed to: $targetDir'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Failed.';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// EMULATOR GUIDE DIALOG
// Based on https://wiki.hacks.guide/wiki/Wii:Emulators
// ═══════════════════════════════════════════════════════════════════════════

class EmulatorGuideDialog extends StatelessWidget {
  const EmulatorGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final emulators = [
      {
        'system': 'NES/Famicom',
        'app': 'FCE Ultra GX',
        'status': 'Excellent',
        'color': Colors.red
      },
      {
        'system': 'SNES',
        'app': 'Snes9x GX',
        'status': 'Excellent',
        'color': Colors.purple
      },
      {
        'system': 'Nintendo 64',
        'app': 'Not64',
        'status': 'Good',
        'color': Colors.green
      },
      {
        'system': 'Game Boy / GBC / GBA',
        'app': 'mGBA / VBA GX',
        'status': 'Excellent',
        'color': Colors.blue
      },
      {
        'system': 'Sega Genesis/MD',
        'app': 'Genesis Plus GX',
        'status': 'Excellent',
        'color': Colors.indigo
      },
      {
        'system': 'PlayStation',
        'app': 'WiiStation',
        'status': 'Limited',
        'color': Colors.grey
      },
      {
        'system': 'GameCube',
        'app': 'Nintendont (Native)',
        'status': 'Perfect',
        'color': Colors.deepPurple
      },
      {
        'system': 'Arcade',
        'app': 'MAME-Wii',
        'status': 'Good',
        'color': Colors.amber
      },
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.green.withValues(alpha: 0.2),
                  Colors.transparent
                ]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videogame_asset,
                      color: Colors.green, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Emulator Setup Guide',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Play retro games on your Wii',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'The Wii can emulate most consoles up to the N64/PS1 era. GameCube runs natively via Nintendont.',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Emulator list
                    ...emulators.map((emu) => _buildEmulatorCard(emu)),

                    const SizedBox(height: 20),

                    // Not supported
                    const Text('NOT Supported:',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          ['PS2+', 'PSP', 'Xbox', 'Dreamcast', '3DS', 'Switch']
                              .map((s) => Chip(
                                    label: Text(s,
                                        style: const TextStyle(
                                            color: Colors.red, fontSize: 11)),
                                    backgroundColor:
                                        Colors.red.withValues(alpha: 0.1),
                                  ))
                              .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmulatorCard(Map<String, dynamic> emu) {
    final color = emu['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.videogame_asset, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emu['system'] as String,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Text(emu['app'] as String,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(emu['status'] as String,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RETROARCH GUIDE DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class RetroArchGuideDialog extends StatelessWidget {
  const RetroArchGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 550),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.purple.withValues(alpha: 0.2),
                  Colors.transparent
                ]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.apps, color: Colors.purple, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RetroArch Setup',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Multi-system emulator',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RetroArch Wii is a multi-system emulator supporting many consoles. It uses "cores" for each system.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  const Text('Popular Cores:',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'FCEUmm (NES)',
                      'Snes9x',
                      'Genesis Plus',
                      'mGBA',
                      'PicoDrive'
                    ]
                        .map((c) => Chip(
                              label:
                                  Text(c, style: const TextStyle(fontSize: 11)),
                              backgroundColor:
                                  Colors.purple.withValues(alpha: 0.2),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Install Path:',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4)),
                    child: const Text('SD:/apps/retroarch/',
                        style: TextStyle(
                            color: Colors.green,
                            fontFamily: 'monospace',
                            fontSize: 12)),
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

// ═══════════════════════════════════════════════════════════════════════════
// BANNER BRICK FIX DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class BannerBrickFixDialog extends StatelessWidget {
  const BannerBrickFixDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 550,
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.red.withValues(alpha: 0.2),
                  Colors.transparent
                ]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Banner Brick Fix',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Recover from bad WAD installs',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'A Banner Brick occurs when installing a channel with an invalid banner. '
                        'Symptoms: black screen, freeze after Health & Safety, or "system files corrupted" error.',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Requirements:',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...[
                      'SD card or USB drive',
                      'YAWM ModMii Edition',
                      'Priiloader installed (recommended)'
                    ].map((r) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 14),
                              const SizedBox(width: 8),
                              Text(r,
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      fontSize: 13)),
                            ],
                          ),
                        )),
                    const SizedBox(height: 20),
                    const Text('Fix Steps (with Priiloader):',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildStepsList([
                      'Hold RESET while turning on Wii to enter Priiloader',
                      'Navigate to Homebrew Channel',
                      'Launch YAWM ModMii Edition',
                      'Select your source device (SD/USB)',
                      'Find the bad WAD, press A',
                      'Press RIGHT to change to "Uninstall WAD"',
                      'Press A to uninstall',
                      'Press HOME → Return to System Menu',
                    ]),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb,
                              color: Colors.orange, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'If you don\'t have Priiloader, you\'ll need to use str2hax or another exploit to access HBC.',
                              style: TextStyle(
                                  color: Colors.orange[300], fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStepsList(List<String> steps) {
    return Column(
      children: steps
          .asMap()
          .entries
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(11)),
                      child: Text('${e.key + 1}',
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(e.value,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13))),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SYSTEM RECOVERY GUIDE DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class SystemRecoveryGuideDialog extends StatelessWidget {
  const SystemRecoveryGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.amber.withValues(alpha: 0.2),
                  Colors.transparent
                ]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restore, color: Colors.amber, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('System Recovery Guide',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Common Wii troubleshooting',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIssueCard('Black Screen',
                        'Try Priiloader (hold RESET on boot)', Colors.grey),
                    _buildIssueCard('No HBC',
                        'Use str2hax or Letterbomb exploit', Colors.blue),
                    _buildIssueCard('Games not loading',
                        'Check USB format (must be FAT32)', Colors.orange),
                    _buildIssueCard(
                        'Error -001', 'Need cIOS installed', Colors.red),
                    _buildIssueCard('Disc read errors',
                        'Clean disc or disc drive issue', Colors.purple),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Prevention: Always have Priiloader and BootMii installed!',
                              style: TextStyle(
                                  color: Colors.green[300],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueCard(String issue, String solution, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(solution,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NINTENDONT COMPATIBILITY DIALOG
// Based on https://wiki.gbatemp.net/wiki/Nintendont_Compatibility_List
// ═══════════════════════════════════════════════════════════════════════════

class NintendontCompatibilityDialog extends StatefulWidget {
  const NintendontCompatibilityDialog({super.key});

  @override
  State<NintendontCompatibilityDialog> createState() =>
      _NintendontCompatibilityDialogState();
}

class _NintendontCompatibilityDialogState
    extends State<NintendontCompatibilityDialog> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Sample compatibility data - in production would fetch from GBAtemp wiki
  final List<Map<String, dynamic>> _games = [
    {
      'title': 'Super Smash Bros. Melee',
      'id': 'GALE01',
      'status': 'Perfect',
      'notes': 'Full compatibility'
    },
    {
      'title': 'The Legend of Zelda: Wind Waker',
      'id': 'GZLE01',
      'status': 'Perfect',
      'notes': 'Full compatibility'
    },
    {
      'title': 'Mario Kart: Double Dash!!',
      'id': 'GM4E01',
      'status': 'Perfect',
      'notes': 'LAN works with patches'
    },
    {
      'title': 'Metroid Prime',
      'id': 'GM8E01',
      'status': 'Perfect',
      'notes': 'Full compatibility'
    },
    {
      'title': 'Super Mario Sunshine',
      'id': 'GMSE01',
      'status': 'Perfect',
      'notes': 'Full compatibility'
    },
    {
      'title': 'Animal Crossing',
      'id': 'GAFE01',
      'status': 'Perfect',
      'notes': 'Memory card required'
    },
    {
      'title': 'F-Zero GX',
      'id': 'GFZE01',
      'status': 'Perfect',
      'notes': 'Full compatibility'
    },
    {
      'title': 'Resident Evil 4',
      'id': 'G4BE08',
      'status': 'Perfect',
      'notes': 'Full compatibility'
    },
    {
      'title': 'Paper Mario: TTYD',
      'id': 'G8ME01',
      'status': 'Perfect',
      'notes': 'Full compatibility'
    },
    {
      'title': 'Pikmin 2',
      'id': 'GPVE01',
      'status': 'Perfect',
      'notes': 'Full compatibility'
    },
    {
      'title': 'Tales of Symphonia',
      'id': 'GQSEAF',
      'status': 'Perfect',
      'notes': 'Multi-disc works'
    },
    {
      'title': 'Phantasy Star Online',
      'id': 'GPOE8P',
      'status': 'Playable',
      'notes': 'Online via private servers'
    },
    {
      'title': 'Zelda: Twilight Princess',
      'id': 'GZ2E01',
      'status': 'Perfect',
      'notes': 'Full compatibility'
    },
    {
      'title': 'Luigi\'s Mansion',
      'id': 'GLME01',
      'status': 'Perfect',
      'notes': 'Full compatibility'
    },
    {
      'title': 'Kirby Air Ride',
      'id': 'GKYE01',
      'status': 'Perfect',
      'notes': 'LAN works'
    },
  ];

  List<Map<String, dynamic>> get _filteredGames {
    if (_searchQuery.isEmpty) return _games;
    return _games
        .where((g) =>
            (g['title'] as String)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (g['id'] as String)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.deepPurple.withValues(alpha: 0.2),
                  Colors.transparent
                ]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.deepPurple, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nintendont Compatibility',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('GameCube game compatibility checker',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by game title or ID...',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.deepPurple),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Info banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.green, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nintendont has near-perfect compatibility. Most GameCube games work flawlessly!',
                      style: TextStyle(color: Colors.green[300], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Game list
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _filteredGames.length,
                itemBuilder: (context, index) {
                  final game = _filteredGames[index];
                  final status = game['status'] as String;
                  final statusColor =
                      status == 'Perfect' ? Colors.green : Colors.orange;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.album,
                              color: Colors.deepPurple, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(game['title'] as String,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              Text('${game['id']} • ${game['notes']}',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(status,
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: TextButton.icon(
                onPressed: () => _openUrl(
                    'https://wiki.gbatemp.net/wiki/Nintendont_Compatibility_List'),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('View Full Compatibility List on GBAtemp'),
                style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GC MEMORY CARD MANAGER DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class GCMemoryManagerDialog extends StatelessWidget {
  const GCMemoryManagerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 550),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogHeader('GC Memory Card Manager',
                'Manage GameCube saves', Icons.sd_card, Colors.purple, context),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoBox(
                    'Nintendont can use virtual memory cards stored on your SD/USB. '
                    'Saves are stored in /saves/ folder.',
                    Colors.purple,
                  ),
                  const SizedBox(height: 20),
                  const Text('Memory Card Locations:',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildPathBox('Slot A: /saves/[GameID]_A.raw'),
                  const SizedBox(height: 4),
                  _buildPathBox('Slot B: /saves/[GameID]_B.raw'),
                  const SizedBox(height: 20),
                  const Text('Recommended Tools:',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildToolItem(
                      'GCMM', 'GameCube Memory Manager - backup/restore'),
                  _buildToolItem('Dolphin', 'Can import/export GC saves'),
                  _buildToolItem(
                      'SaveGame Manager GX', 'All-in-one Wii & GC saves'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(String title, String subtitle, IconData icon,
      Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.2), Colors.transparent]),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
    );
  }

  Widget _buildPathBox(String path) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4)),
      child: Text(path,
          style: const TextStyle(
              color: Colors.green, fontFamily: 'monospace', fontSize: 12)),
    );
  }

  Widget _buildToolItem(String name, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.purple, size: 16),
          const SizedBox(width: 8),
          Text('$name - ',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          Expanded(
              child: Text(desc,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13))),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WII SAVE MANAGER DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class WiiSaveManagerDialog extends StatelessWidget {
  const WiiSaveManagerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 550),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.blue.withValues(alpha: 0.2),
                  Colors.transparent
                ]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.backup, color: Colors.blue, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Wii Save Manager',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Backup & restore Wii saves',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'SaveGame Manager GX is the recommended tool for backing up and restoring Wii game saves, Miis, and more.',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Features:',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...[
                    'Backup all Wii game saves to SD/USB',
                    'Restore saves from backup',
                    'Extract and inject Miis',
                    'Copy saves between NAND and storage',
                    'Works with save-protected games',
                  ].map((f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.blue, size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(f,
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                        fontSize: 13))),
                          ],
                        ),
                      )),
                  const SizedBox(height: 20),
                  const Text('Save Location:',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4)),
                    child: const Text('SD:/savegames/',
                        style: TextStyle(
                            color: Colors.green,
                            fontFamily: 'monospace',
                            fontSize: 12)),
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

// ═══════════════════════════════════════════════════════════════════════════
// NAND BACKUP GUIDE DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class NANDBackupGuideDialog extends StatelessWidget {
  const NANDBackupGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 550,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.amber.withValues(alpha: 0.2),
                  Colors.transparent
                ]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.amber, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NAND Backup Guide',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Full system backup with BootMii',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'A NAND backup is your ultimate brick protection. Create one BEFORE modifying your system!',
                              style: TextStyle(
                                  color: Colors.red[300], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Requirements:',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...[
                      'BootMii installed (as boot2 preferred, or IOS)',
                      'SD card with at least 512MB free',
                      'GameCube controller or Wii remote power button',
                    ].map((r) => _buildCheckItem(r)),
                    const SizedBox(height: 20),
                    const Text('Steps:',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...[
                      'Launch BootMii (via HBC or boot)',
                      'Navigate with POWER (right) and RESET (select)',
                      'Select the gear icon (Options)',
                      'Select first icon (Backup NAND)',
                      'Wait for backup to complete (~15 mins)',
                      'Backup saved as /bootmii/nand.bin',
                    ]
                        .asMap()
                        .entries
                        .map((e) => _buildStepItem(e.key + 1, e.value)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Keep your nand.bin and keys.bin in a safe place! You\'ll need both to restore.',
                              style: TextStyle(
                                  color: Colors.green[300], fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 14),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildStepItem(int num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(11)),
            child: Text('$num',
                style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13))),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIIMMFI SETUP DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class WiimmfiSetupDialog extends StatelessWidget {
  const WiimmfiSetupDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 550,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.green.withValues(alpha: 0.2),
                  Colors.transparent
                ]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi, color: Colors.green, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Wiimmfi Setup',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Play online after Nintendo WFC shutdown',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Wiimmfi is a replacement for Nintendo Wi-Fi Connection, allowing you to play Wii and DS games online again!',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Supported Games:',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Mario Kart Wii',
                        'Smash Bros Brawl',
                        'Animal Crossing',
                        'Pokemon Battle Rev.',
                        'COD Series',
                        'Guitar Hero'
                      ]
                          .map((g) => Chip(
                                label: Text(g,
                                    style: const TextStyle(
                                        color: Colors.green, fontSize: 11)),
                                backgroundColor:
                                    Colors.green.withValues(alpha: 0.1),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('Setup Methods:',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildMethodCard(
                        'USB Loader',
                        'Patch games automatically via loader settings',
                        Icons.usb),
                    _buildMethodCard('Wiimmfi Patcher',
                        'Patch ISO/WBFS files directly', Icons.build),
                    _buildMethodCard('DNS Method',
                        'Set DNS to 95.217.77.181 (limited games)', Icons.dns),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('View Full Guide on wii.hacks.guide'),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(String title, String desc, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(desc,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIILINK SETUP DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class WiiLinkSetupDialog extends StatelessWidget {
  const WiiLinkSetupDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.blue.withValues(alpha: 0.2),
                  Colors.transparent
                ]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud, color: Colors.blue, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WiiLink Setup',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Restore WiiConnect24 services',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WiiLink restores Japanese-exclusive channels and WiiConnect24 features.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  const Text('Available Services:',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Wii Room',
                      'Digicam Print',
                      'Food Channel',
                      'Demae Channel',
                      'Kirby TV'
                    ]
                        .map((s) => Chip(
                              label: Text(s,
                                  style: const TextStyle(
                                      color: Colors.blue, fontSize: 11)),
                              backgroundColor:
                                  Colors.blue.withValues(alpha: 0.1),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Visit wiilink24.com'),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
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

// ═══════════════════════════════════════════════════════════════════════════
// RIICONNECT24 SETUP DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class RiiConnect24SetupDialog extends StatelessWidget {
  const RiiConnect24SetupDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.teal.withValues(alpha: 0.2),
                  Colors.transparent
                ]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.rss_feed, color: Colors.teal, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RiiConnect24',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('News, Weather, and more',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RiiConnect24 brings back discontinued WiiConnect24 services.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  const Text('Restored Channels:',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'News Channel',
                      'Forecast Channel',
                      'Everybody Votes',
                      'Nintendo Channel',
                      'Mii Contest'
                    ]
                        .map((s) => Chip(
                              label: Text(s,
                                  style: const TextStyle(
                                      color: Colors.teal, fontSize: 11)),
                              backgroundColor:
                                  Colors.teal.withValues(alpha: 0.1),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Visit rc24.xyz'),
                    style: TextButton.styleFrom(foregroundColor: Colors.teal),
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

// ═══════════════════════════════════════════════════════════════════════════
// FTP GUIDE DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class FTPGuideDialog extends StatelessWidget {
  const FTPGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 550),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.cyan.withValues(alpha: 0.2),
                  Colors.transparent
                ]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_shared, color: Colors.cyan, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FTP Server Guide',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Access Wii files from PC',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use ftpii or WiiXplorer to run an FTP server on your Wii, allowing wireless file transfer from your PC.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  const Text('Steps:',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...[
                    'Download ftpii from OSC',
                    'Launch from Homebrew Channel',
                    'Note the IP address shown',
                    'Connect with FileZilla or any FTP client',
                    'Use IP from Wii, port 21, no password',
                  ].asMap().entries.map((e) => _buildStep(e.key + 1, e.value)),
                  const SizedBox(height: 16),
                  const Text('Recommended FTP Clients:',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('FileZilla, WinSCP, Cyberduck',
                      style: TextStyle(color: Colors.cyan[300], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10)),
            child: Text('$num',
                style: const TextStyle(
                    color: Colors.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13))),
        ],
      ),
    );
  }
}
