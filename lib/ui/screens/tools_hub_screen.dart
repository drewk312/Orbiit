import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../../ui/screens/controller_wizard_screen.dart';
import '../../screens/cover_art_manager_screen.dart';
import '../../screens/controller_forge_screen.dart';
import '../../screens/storage_organizer_screen.dart';
import '../../screens/wiiload_screen.dart';
import '../../screens/codes.dart';
import '../../screens/homebrew.dart';
import '../../screens/hardware_wizard.dart';
import '../../screens/file_import_screen.dart';
import '../services/wiitdb_service.dart';
import '../services/checksum_service.dart';
import '../services/archive_service.dart' show ArchiveExtractionService;

import '../fusion_ui/fusion_ui.dart';

/// Tools Hub - sleek utilities with Wii/GameCube aesthetics
class ToolsHubScreen extends StatefulWidget {
  const ToolsHubScreen({super.key});

  @override
  State<ToolsHubScreen> createState() => _ToolsHubScreenState();
}

class _ToolsHubScreenState extends State<ToolsHubScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  bool _isProcessing = false;
  String _statusMessage = '';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: UiGradients.space),
      child: _isProcessing ? _buildProcessingOverlay() : _buildToolsView(),
    );
  }

  Widget _buildProcessingOverlay() {
    return Center(
      child: SizedBox(
        width: 420,
        child: GlassCard(
          borderRadius: UiRadius.xxl,
          glowColor: UiColors.wiiCyan,
          enableHover: false,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  strokeWidth: 4,
                  color: UiColors.wiiCyan,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _statusMessage,
                style: UiType.bodyMedium
                    .copyWith(color: UiColors.textPrimary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              if (_progress > 0) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: UiColors.glassWhite(0.08),
                    color: UiColors.wiiCyan,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_progress * 100).toStringAsFixed(0)}%',
                  style: UiType.bodySmall,
                ),
              ],
              const SizedBox(height: 18),
              ActionButton(
                label: 'Cancel',
                icon: Icons.close_rounded,
                outlined: true,
                outlineColor: UiColors.error,
                onPressed: () {
                  setState(() {
                    _isProcessing = false;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolsView() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        SliverToBoxAdapter(
          child: _buildFeaturedSection(),
        ),
        SliverToBoxAdapter(
          child: _buildQuickToolsSection(),
        ),
        SliverToBoxAdapter(
          child: _buildAdvancedToolsSection(),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 120),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF6B00)
                          .withValues(alpha: 0.3 + _glowController.value * 0.2),
                      const Color(0xFFFF8C00)
                          .withValues(alpha: 0.3 + _glowController.value * 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B00)
                          .withValues(alpha: 0.3 * _glowController.value),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.build_circle,
                  color: Colors.white,
                  size: 32,
                ),
              );
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOOLKIT',
                  style: UiType.headingLarge.copyWith(
                    fontSize: 28,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Advanced utilities for your Wii & GameCube library',
                  style: UiType.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('FEATURED TOOLS', Icons.star_rounded),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFeaturedCard(
                  title: 'Controller Customization',
                  description:
                      'Configure USB controllers for Nintendont. Map buttons, save profiles, and export configs.',
                  icon: Icons.sports_esports,
                  gradient: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                  onTap: _openControllerMapper,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFeaturedCard(
                  title: 'WiiLoad Transfer',
                  description:
                      'Send files wirelessly to your Wii. No USB required.',
                  icon: Icons.wifi,
                  gradient: [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
                  onTap: _openWiiLoad,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFeaturedCard(
                  title: 'Storage Organizer',
                  description:
                      'Auto-sort games by format (WBFS/ISO). Organize for USB Loader GX & Nintendont.',
                  icon: Icons.folder_special,
                  gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
                  onTap: _openStorageOrganizer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFeaturedCard(
                  title: 'Cover Art Manager',
                  description:
                      'Download high-quality covers, discs, and 3D boxes for your game library.',
                  icon: Icons.image,
                  gradient: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                  onTap: _openCoverArtManager,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Homebrew removed as it has a dedicated tab
          Row(
            children: [
              Expanded(
                child: _buildFeaturedCard(
                  title: 'Smart File Import',
                  description:
                      'Automatically detect and organize game files from any folder.',
                  icon: Icons.auto_fix_high,
                  gradient: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
                  onTap: _openSmartImport,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return SectionHeaderRow(
      icon: icon,
      title: title,
      accent: UiColors.amber,
    );
  }

  Widget _buildFeaturedCard({
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    final color = gradient.isNotEmpty ? gradient[0] : UiColors.cyan;

    return SizedBox(
      height: 160,
      child: GlassCard(
        onTap: onTap,
        glowColor: color,
        borderRadius: UiRadius.xl,
        padding: EdgeInsets.zero, // We handle padding inside for the stack
        child: Stack(
          children: [
            // Decorative glow
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(UiRadius.md),
                    ),
                    child: Icon(
                      icon,
                      color: UiColors.textPrimary,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: UiType.labelLarge.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: UiType.bodySmall.copyWith(color: UiColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: UiColors.glassWhite(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: UiColors.textSecondary,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickToolsSection() {
    return SelectionContainer.disabled(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('QUICK ACTIONS', Icons.flash_on),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickTool(
                   'New Controller',
                   Icons.add_circle_outline,
                   const Color(0xFF6B4EFF),
                   _openControllerWizard,
                ),
                _buildQuickTool(
                  'Download WiiTDB',
                  Icons.cloud_download,
                  const Color(0xFF3B82F6),
                  _downloadWiiTDB,
                ),
                _buildQuickTool(
                  'Calculate Checksum',
                  Icons.fingerprint,
                  const Color(0xFF22C55E),
                  _calculateChecksum,
                ),
                _buildQuickTool(
                  'Extract Archive',
                  Icons.unarchive,
                  const Color(0xFFF97316),
                  _extractArchive,
                ),
                _buildQuickTool(
                  'Find Duplicates',
                  Icons.content_copy,
                  const Color(0xFFEC4899),
                  _findDuplicates,
                ),
                _buildQuickTool(
                  'Split for FAT32',
                  Icons.call_split,
                  const Color(0xFF8B5CF6),
                  _splitFile,
                ),
                _buildQuickTool(
                  'Disk Space',
                  Icons.storage,
                  const Color(0xFF14B8A6),
                  _checkDiskSpace,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTool(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GlassCard(
        borderRadius: UiRadius.md,
        blurSigma: 10,
        glowColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: UiType.labelLarge.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedToolsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('ADVANCED', Icons.settings_suggest),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                _buildAdvancedTile(
                  'Hardware Wizard',
                  'Prepare USB drives and check system compatibility',
                  Icons.build_circle,
                  _openHardwareWizard,
                ),
                _buildDivider(),
                _buildAdvancedTile(
                  'Download GC Banners', // _downloadBanners
                  'Animated banners for GameCube games',
                  Icons.video_library,
                  _downloadBanners,
                ),
                _buildDivider(),
                _buildAdvancedTile(
                  'Download Cheat Codes',
                  'Gecko & Ocarina codes from WiiRD',
                  Icons.code,
                  _downloadCheats,
                ),
                _buildDivider(),
                _buildAdvancedTile(
                  'Database Info',
                  'View WiiTDB database status',
                  Icons.info_outline,
                  _showDatabaseInfo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTile(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.white.withValues(alpha: 0.1),
      indent: 56,
    );
  }

  // Tool implementations
  void _openControllerWizard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ControllerWizardScreen()),
    );
  }

  void _openControllerMapper() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const ControllerForgeScreen()),
    );
  }

  void _openWiiLoad() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WiiLoadScreen()),
    );
  }

  void _openStorageOrganizer() {
    // Navigate to StorageOrganizerScreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StorageOrganizerScreen(),
      ),
    );
  }

  void _openCoverArtManager() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CoverArtManagerScreen()),
    );
  }

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
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('WiiTDB database downloaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _calculateChecksum() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Calculating checksums...';
      _progress = 0.0;
    });

    try {
      final checksumService = ChecksumService();
      final checksums = await checksumService.calculateAllFile(filePath);

      if (mounted) {
        setState(() => _isProcessing = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Checksums'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _checksumRow('CRC32', checksums.crc32),
                _checksumRow('MD5', checksums.md5),
                _checksumRow('SHA-1', checksums.sha1),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _checksumRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          SelectableText(value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _extractArchive() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', '7z', 'rar', 'gz', 'bz2', 'tar'],
    );
    if (result == null) return;

    final archivePath = result.files.single.path;
    if (archivePath == null) return;

    final outputDir = await FilePicker.platform.getDirectoryPath();
    if (outputDir == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Extracting archive...';
      _progress = 0.0;
    });

    try {
      await ArchiveExtractionService.extractArchive(archivePath, outputDir);

      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archive extracted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Remaining tool methods are unchanged from the previous implementation.
  // (Keeping behavior stable; only removed naming/branding terms.)

  void _findDuplicates() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Game Library Folder',
    );

    if (result == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Scanning for duplicate games...';
      _progress = 0.0;
    });

    try {
      final dir = Directory(result);
      final gameFiles = <String, List<File>>{};
      final extensions = <String>[
        '.wbfs',
        '.iso',
        '.gcm',
        '.rvz',
        '.nkit.iso',
        '.ciso',
      ];

      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final ext = extensions.firstWhere(
            (e) => entity.path.toLowerCase().endsWith(e),
            orElse: () => '',
          );
          if (ext.isNotEmpty) {
            final fileName = p.basename(entity.path);
            final idMatch = RegExp(r'\[([A-Z0-9]{6})\]').firstMatch(fileName);
            final gameId = idMatch?.group(1) ?? fileName;

            gameFiles.putIfAbsent(gameId, () => []).add(entity);
          }
        }
      }

      final duplicates =
          gameFiles.entries.where((e) => e.value.length > 1).toList();

      setState(() => _isProcessing = false);

      if (!mounted) return;

      if (duplicates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ No duplicate games found!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1D24),
            title: Row(
              children: [
                const Icon(Icons.content_copy, color: Colors.orange),
                const SizedBox(width: 12),
                Text('${duplicates.length} Duplicates Found',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
            content: SizedBox(
              width: 500,
              height: 400,
              child: ListView.builder(
                itemCount: duplicates.length,
                itemBuilder: (context, index) {
                  final entry = duplicates[index];
                  return ExpansionTile(
                    title: Text(entry.key,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${entry.value.length} copies',
                        style: TextStyle(color: Colors.orange[300])),
                    children: entry.value.map((file) {
                      final size = file.lengthSync();
                      return ListTile(
                        leading: const Icon(Icons.videogame_asset,
                            color: Colors.grey),
                        title: Text(p.basename(file.path),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        subtitle: Text(_formatSize(size),
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                backgroundColor: const Color(0xFF1A1D24),
                                title: const Text('Delete File?',
                                    style: TextStyle(color: Colors.white)),
                                content: Text(
                                    'Delete ${p.basename(file.path)}?',
                                    style:
                                        const TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await file.delete();
                              Navigator.pop(ctx);
                              _findDuplicates();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _splitFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Large Game File to Split',
      type: FileType.custom,
      allowedExtensions: ['iso', 'wbfs', 'gcm'],
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.first.path!;
    final file = File(filePath);
    final fileSize = await file.length();

    const fat32Limit = 4 * 1024 * 1024 * 1024 - 1;

    if (fileSize <= fat32Limit) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File is already under 4GB - no split needed!'),
            backgroundColor: Colors.green,
          ),
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
      final baseName = p.basenameWithoutExtension(filePath);
      final dir = p.dirname(filePath);
      final ext = p.extension(filePath);

      final inputStream = file.openRead();
      int partNum = 0;
      int bytesWritten = 0;
      int totalBytesWritten = 0;

      IOSink? currentSink;

      await for (final chunk in inputStream) {
        if (currentSink == null || bytesWritten >= fat32Limit) {
          await currentSink?.close();

          final partExt = partNum == 0 ? ext : '.wbf$partNum';
          final partPath = '$dir/$baseName$partExt';
          currentSink = File(partPath).openWrite();
          bytesWritten = 0;
          partNum++;
        }

        currentSink!.add(chunk);
        bytesWritten += chunk.length;
        totalBytesWritten += chunk.length;

        setState(() {
          _progress = totalBytesWritten / fileSize;
          _statusMessage =
              'Splitting: Part $partNum (${(_progress * 100).toStringAsFixed(1)}%)';
        });
      }

      await currentSink?.close();

      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Split into $partNum parts successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _checkDiskSpace() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Drive or Folder to Check',
    );

    if (result == null) return;

    try {
      final dir = Directory(result);
      int totalSize = 0;
      int fileCount = 0;
      final Map<String, int> byExtension = {};

      setState(() {
        _isProcessing = true;
        _statusMessage = 'Analyzing disk space...';
        _progress = 0.0;
      });

      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          try {
            final size = await entity.length();
            totalSize += size;
            fileCount++;

            final ext = p.extension(entity.path).toLowerCase();
            if (ext.isNotEmpty) {
              byExtension[ext] = (byExtension[ext] ?? 0) + size;
            }
          } catch (_) {}
        }
      }

      setState(() => _isProcessing = false);

      if (!mounted) return;

      final sortedExts = byExtension.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1D24),
          title: Row(
            children: [
              const Icon(Icons.storage, color: Color(0xFF14B8A6)),
              const SizedBox(width: 12),
              const Text('Disk Space Analysis',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('Total Size', _formatSize(totalSize)),
                _buildStatRow('Total Files', '$fileCount files'),
                const Divider(color: Colors.white24),
                const Text('By File Type:',
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...sortedExts.take(8).map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key,
                              style: const TextStyle(color: Colors.white70)),
                          Text(_formatSize(e.value),
                              style: TextStyle(color: Colors.teal[300])),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _downloadBanners() async {
     final result = await FilePicker.platform.getDirectoryPath(dialogTitle: "Select Folder for Banners");
     if (result != null) {
       // Open the folder in explorer
       // Also offer to open GameTDB
       final uri = Uri.parse("https://www.gametdb.com/Wii/Downloads");
       if (await canLaunchUrl(uri)) {
         await launchUrl(uri);
       }
       // Open local folder
       if (Platform.isWindows) {
         Process.run('explorer', [result]);
       }
     }
  }

  void _downloadCheats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TxtCodesScreen()),
    );
  }

  void _openHomebrewBrowser() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomebrewScreen()),
    );
  }

  void _openHardwareWizard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HardwareWizardScreen()),
    );
  }

  void _openSmartImport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FileImportScreen()),
    );
  }

  Future<void> _showDatabaseInfo() async {
    final cached = await WiiTDBService.isDatabaseCached();
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        title: const Text('WiiTDB Database Info', style: TextStyle(color: Colors.white)),
        content: Text(
          cached 
            ? 'Database is cached and ready.\nLocation: Internal Storage\nStatus: Active'
            : 'Database not found.\nClick "Download WiiTDB" to fetch metadata.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotImplemented(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming in the next update!'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
