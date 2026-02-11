import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/disc_metadata.dart';
import '../fusion/design_system.dart';

/// Game details panel (glass + tabs)
class GameInfoPanel extends StatefulWidget {
  final DiscMetadata disc;
  final VoidCallback? onClose;
  final VoidCallback? onOpenFolder;
  final VoidCallback? onVerify;
  final VoidCallback? onConvert;
  final VoidCallback? onDelete;
  final bool isVerifying;
  final double verifyProgress;

  const GameInfoPanel({
    required this.disc,
    super.key,
    this.onClose,
    this.onOpenFolder,
    this.onVerify,
    this.onConvert,
    this.onDelete,
    this.isVerifying = false,
    this.verifyProgress = 0.0,
  });

  @override
  State<GameInfoPanel> createState() => _GameInfoPanelState();
}

class _GameInfoPanelState extends State<GameInfoPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor =
        widget.disc.isWii ? FusionColors.wiiBlue : const Color(0xFF6441A5);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFF0D0D14).withValues(alpha: 0.85),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.10),
                  blurRadius: 80,
                  spreadRadius: -20,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(accentColor),
                _buildTabs(accentColor),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(accentColor),
                      _buildHashesTab(accentColor),
                      _buildActionsTab(accentColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accentColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.06),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withValues(alpha: 0.35),
                  accentColor.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(color: accentColor.withValues(alpha: 0.25)),
            ),
            child: Icon(
              widget.disc.isWii
                  ? Icons.sports_esports_rounded
                  : Icons.gamepad_rounded,
              color: accentColor.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.disc.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.disc.gameId} • ${widget.disc.console.shortName} • ${widget.disc.format}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              widget.onClose?.call();
              Navigator.of(context).maybePop();
            },
            icon: const Icon(Icons.close_rounded),
            color: Colors.white.withValues(alpha: 0.7),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(Color accentColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.55),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: accentColor.withValues(alpha: 0.22),
          border: Border.all(color: accentColor.withValues(alpha: 0.30)),
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Hashes'),
          Tab(text: 'Actions'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Color accentColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _row('Path', widget.disc.filePath),
        _row('Size', widget.disc.formattedFileSize),
        _row('Region', widget.disc.displayRegion),
        _row('Publisher', widget.disc.publisher ?? '—'),
        _row('Year', widget.disc.releaseYear?.toString() ?? '—'),
      ],
    );
  }

  Widget _buildHashesTab(Color accentColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _row('SHA-1', widget.disc.sha1 ?? '—', mono: true),
        _row('MD5', widget.disc.md5 ?? '—', mono: true),
        _row('CRC32', widget.disc.crc32 ?? '—', mono: true),
        if (widget.isVerifying) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: widget.verifyProgress > 0 ? widget.verifyProgress : null,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            color: accentColor,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ],
    );
  }

  Widget _buildActionsTab(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _action(
            accentColor,
            icon: Icons.folder_open_rounded,
            label: 'Open Folder',
            onTap: widget.onOpenFolder,
          ),
          const SizedBox(height: 12),
          _action(
            accentColor,
            icon: Icons.verified_rounded,
            label: 'Verify',
            onTap: widget.onVerify,
          ),
          const SizedBox(height: 12),
          _action(
            accentColor,
            icon: Icons.swap_horiz_rounded,
            label: 'Convert',
            onTap: widget.onConvert,
          ),
          const Spacer(),
          _danger(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            onTap: widget.onDelete,
          ),
        ],
      ),
    );
  }

  Widget _action(Color accentColor,
      {required IconData icon,
      required String label,
      required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Icon(icon, color: accentColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.35)),
          ],
        ),
      ),
    );
  }

  Widget _danger(
      {required IconData icon,
      required String label,
      required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.red.withValues(alpha: 0.10),
          border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.redAccent),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            value,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.90),
              fontSize: 13,
              height: 1.35,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }
}
