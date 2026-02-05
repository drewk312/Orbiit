import 'package:flutter/material.dart';
import '../services/wiitdb_service.dart';

class MetadataSection extends StatelessWidget {
  final GameMetadata metadata;
  final Color primaryColor;

  const MetadataSection({
    super.key,
    required this.metadata,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Game Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        // Synopsis
        if (metadata.synopsis != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16162A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              metadata.synopsis!,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Metadata grid
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16162A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              MetadataRow(
                icon: Icons.category,
                label: 'Genre',
                value: metadata.displayGenre,
                color: primaryColor,
              ),
              if (metadata.developer != null) ...[
                const Divider(height: 24),
                MetadataRow(
                  icon: Icons.code,
                  label: 'Developer',
                  value: metadata.displayDeveloper,
                  color: primaryColor,
                ),
              ],
              if (metadata.publisher != null) ...[
                const Divider(height: 24),
                MetadataRow(
                  icon: Icons.business,
                  label: 'Publisher',
                  value: metadata.displayPublisher,
                  color: primaryColor,
                ),
              ],
              const Divider(height: 24),
              MetadataRow(
                icon: Icons.calendar_today,
                label: 'Release Date',
                value: metadata.releaseDate,
                color: primaryColor,
              ),
              const Divider(height: 24),
              MetadataRow(
                icon: Icons.people,
                label: 'Players',
                value: metadata.displayPlayers,
                color: primaryColor,
              ),
              if (metadata.hasOnline) ...[
                const Divider(height: 24),
                MetadataRow(
                  icon: Icons.wifi,
                  label: 'Online Players',
                  value: metadata.wifiPlayers ?? '0',
                  color: primaryColor,
                ),
              ],
              if (metadata.ratingValue != null) ...[
                const Divider(height: 24),
                MetadataRow(
                  icon: Icons.stars,
                  label: metadata.ratingType ?? 'Rating',
                  value: metadata.ratingValue!,
                  color: primaryColor,
                ),
              ],
            ],
          ),
        ),

        // Wi-Fi Features
        if (metadata.wifiFeatures.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16162A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wifi, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Online Features',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: metadata.wifiFeatures.map((feature) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class MetadataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const MetadataRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}
