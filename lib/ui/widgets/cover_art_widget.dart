import 'dart:io';
import 'package:flutter/material.dart';
import '../../widgets/cascading_cover_image.dart';
import '../../widgets/premium_fallback_cover.dart';

/// Cover Art Widget - Display game cover search/cache
/// Now powered by CascadingCoverImage for multi-source hunting
class CoverArtWidget extends StatelessWidget {
  final String gameId;
  final String platform;
  final String region;
  final String title;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final String? cachedFilePath;
  final String? coverUrl;

  const CoverArtWidget({
    required this.gameId,
    required this.platform,
    required this.region,
    super.key,
    this.title = '',
    this.width = 140,
    this.height = 140,
    this.borderRadius,
    this.cachedFilePath,
    this.coverUrl,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(8);
    final isWii = platform.toLowerCase().contains('wii');

    // Determine base color for shadow/fallback
    final accentColor =
        isWii ? const Color(0xFF00C2FF) : const Color(0xFFB000FF);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: cachedFilePath != null
            ? Image.file(
                File(cachedFilePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallback(context),
              )
            : _buildCascading(context),
      ),
    );
  }

  Widget _buildCascading(BuildContext context) {
    return CascadingCoverImage(
      // We assume GameTDB is primary for this widget's context if no direct URL is passed
      primaryUrl: coverUrl ?? '',
      gameId: gameId,
      platform: platform,
      title: title,
      fallbackBuilder: (context) => _buildFallback(context),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return PremiumFallbackCover(
      title: title.isNotEmpty ? title : gameId,
      platform: platform,
    );
  }
}
