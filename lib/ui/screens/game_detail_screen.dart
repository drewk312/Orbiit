import 'package:flutter/material.dart';
import '../../core/database/database.dart' hide Title;
import '../../core/database/database.dart' as db;
import '../widgets/cover_art_widget.dart';
import '../widgets/metadata_section.dart';
import '../services/wiitdb_service.dart';

class GameDetailScreen extends StatefulWidget {
  final db.Title title;
  final AppDatabase database;

  const GameDetailScreen({
    super.key,
    required this.title,
    required this.database,
  });

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  List<Issue> _issues = [];
  GameMetadata? _metadata;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final metadata = await WiiTDBService.getGameMetadata(widget.title.gameId);
      if (mounted) {
        setState(() => _metadata = metadata);
      }
    } catch (e) {
      // WiiTDB not downloaded yet - that's OK
    }
    _loadIssues();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadIssues() async {
    final issues = await widget.database.getUnresolvedIssues();
    setState(() {
      _issues = issues.where((i) => i.titleId == widget.title.id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWii = widget.title.platform == 'wii';
    final primaryColor =
        isWii ? const Color(0xFF00C2FF) : const Color(0xFFB000FF);
    final sizeGB =
        (widget.title.fileSizeBytes / 1024 / 1024 / 1024).toStringAsFixed(2);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A14) : const Color(0xFFF5F5F5),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              // App bar with cover art
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor:
                    isDark ? const Color(0xFF16162A) : Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Gradient background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              primaryColor.withValues(alpha: 0.3),
                              (isDark ? const Color(0xFF16162A) : Colors.white)
                                  .withValues(alpha: 0.9),
                            ],
                          ),
                        ),
                      ),
                      // Cover art (large)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Hero(
                            tag: 'cover_${widget.title.id}',
                            child: CoverArtWidget(
                              gameId: widget.title.gameId,
                              platform: widget.title.platform,
                              region: widget.title.region ?? 'Unknown',
                              width: 160,
                              height: 160,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Game info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.title.title,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Platform badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isWii
                                  ? Icons.sports_esports
                                  : Icons.videogame_asset,
                              size: 16,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isWii ? 'Wii' : 'GameCube',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // WiiTDB Metadata Section
                      if (_metadata != null) ...[
                        MetadataSection(
                            metadata: _metadata!, primaryColor: primaryColor),
                        const SizedBox(height: 24),
                      ],

                      // Technical Info Header
                      Text(
                        'Technical Info',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Info cards
                      _InfoCard(
                        icon: Icons.public,
                        label: 'Region',
                        value: widget.title.region ?? 'Unknown',
                        color: primaryColor,
                      ),
                      const SizedBox(height: 12),

                      _InfoCard(
                        icon: Icons.storage,
                        label: 'File Size',
                        value: '$sizeGB GB',
                        color: primaryColor,
                      ),
                      const SizedBox(height: 12),

                      _InfoCard(
                        icon: Icons.insert_drive_file,
                        label: 'Format',
                        value: widget.title.format.toUpperCase(),
                        color: primaryColor,
                      ),
                      const SizedBox(height: 12),

                      _InfoCard(
                        icon: Icons.qr_code,
                        label: 'Game ID',
                        value: widget.title.gameId,
                        color: primaryColor,
                      ),
                      const SizedBox(height: 12),

                      _InfoCard(
                        icon: Icons.folder_open,
                        label: 'File Path',
                        value: widget.title.filePath,
                        color: primaryColor,
                        copyable: true,
                      ),

                      if (_issues.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Issues',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._issues.map((issue) => _IssueCard(
                              issue: issue,
                              isDark: isDark,
                            )),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool copyable;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16162A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: copyable ? null : 1,
                  overflow: copyable ? null : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final Issue issue;
  final bool isDark;

  const _IssueCard({required this.issue, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final severityColor = issue.severity == 'critical'
        ? Colors.red
        : issue.severity == 'major'
            ? Colors.orange
            : Colors.yellow;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16162A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: severityColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: severityColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.issueType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  issue.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
