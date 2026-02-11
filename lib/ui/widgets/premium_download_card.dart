import 'dart:ui';
import 'package:flutter/material.dart';

/// Premium Download Card - Apple Store Quality
/// Features: Layered shadows, sophisticated gradients, refined typography,
/// breathtaking animations, luxury spacing
class PremiumDownloadCard extends StatefulWidget {
  final Widget coverArt;
  final String title;
  final String platform;
  final String provider;
  final double progress;
  final String speed;
  final String eta;
  final String downloadedBytes;
  final String totalBytes;
  final String statusMessage;
  final bool isPaused;
  final VoidCallback? onPauseResume;
  final VoidCallback? onCancel;
  final Widget? progressBar;

  const PremiumDownloadCard({
    required this.coverArt,
    required this.title,
    required this.platform,
    required this.provider,
    required this.progress,
    required this.speed,
    required this.eta,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.statusMessage,
    super.key,
    this.isPaused = false,
    this.onPauseResume,
    this.onCancel,
    this.progressBar,
  });

  @override
  State<PremiumDownloadCard> createState() => _PremiumDownloadCardState();
}

class _PremiumDownloadCardState extends State<PremiumDownloadCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            // Outer ambient shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 60,
              offset: const Offset(0, 20),
              spreadRadius: -10,
            ),
            // Middle glow
            BoxShadow(
              color:
                  const Color(0xFF00D4FF).withOpacity(_isHovered ? 0.2 : 0.1),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
            // Inner highlight
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1A1A).withOpacity(0.9),
                    const Color(0xFF0A0A0A).withOpacity(0.95),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(_isHovered ? 0.15 : 0.08),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Stack(
                children: [
                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover art + metadata row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Premium cover with layered shadow
                            _buildPremiumCover(),
                            const SizedBox(width: 24),
                            // Metadata column
                            Expanded(child: _buildMetadataSection()),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Progress section
                        _buildProgressSection(),

                        const SizedBox(height: 24),

                        // Stats grid
                        _buildStatsGrid(),

                        const SizedBox(height: 28),

                        // Action buttons
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCover() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4FF).withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 140,
          height: 196,
          child: widget.coverArt,
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status badge - Apple-style pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isPaused
                  ? [const Color(0xFF6B7280), const Color(0xFF4B5563)]
                  : [const Color(0xFF00D4FF), const Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: (widget.isPaused
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF00D4FF))
                    .withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.isPaused)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              if (!widget.isPaused) const SizedBox(width: 8),
              Text(
                widget.statusMessage.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Title - Premium typography
        Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: -0.5,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 12),

        // Platform + provider chips
        Row(
          children: [
            _buildInfoChip(widget.platform, Icons.sports_esports_rounded),
            const SizedBox(width: 8),
            _buildInfoChip(widget.provider, Icons.cloud_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.6)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar or custom widget
        widget.progressBar ?? _buildDefaultProgressBar(),
      ],
    );
  }

  Widget _buildDefaultProgressBar() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: LinearProgressIndicator(
          value: widget.progress,
          backgroundColor: Colors.transparent,
          valueColor: const AlwaysStoppedAnimation(
            Color(0xFF00D4FF),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
            child: _buildStatBox(
                'PROGRESS',
                '${(widget.progress * 100).toStringAsFixed(1)}%',
                Icons.pie_chart_rounded)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatBox(
                'SPEED',
                widget.speed.isEmpty ? '--' : widget.speed,
                Icons.speed_rounded)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatBox(
                'ETA',
                widget.eta.isEmpty ? '--:--' : widget.eta,
                Icons.schedule_rounded)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatBox(
                'SIZE',
                '${widget.downloadedBytes} / ${widget.totalBytes}',
                Icons.storage_rounded)),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF00D4FF).withOpacity(0.7)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Pause/Resume button
        if (widget.onPauseResume != null)
          _PremiumButton(
            label: widget.isPaused ? 'Resume' : 'Pause',
            icon: widget.isPaused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            color: const Color(0xFF00D4FF),
            onPressed: widget.onPauseResume!,
          ),

        if (widget.onPauseResume != null && widget.onCancel != null)
          const SizedBox(width: 12),

        // Cancel button
        if (widget.onCancel != null)
          _PremiumButton(
            label: 'Cancel',
            icon: Icons.close_rounded,
            color: const Color(0xFFEF4444),
            onPressed: widget.onCancel!,
            isDestructive: true,
          ),
      ],
    );
  }
}

/// Premium button with Apple-style design
class _PremiumButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isDestructive;

  const _PremiumButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isDestructive = false,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(_isPressed ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.color.withOpacity(_isPressed ? 0.5 : 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 18, color: widget.color),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
