import 'package:flutter/material.dart';
import '../../models/disc_metadata.dart';

/// Minimal stub for PremiumGameInfoPanel to keep builds working if the
/// full implementation is missing. This mirrors the API used by
/// GameLibraryScreen but is intentionally small and safe.
class PremiumGameInfoPanel extends StatelessWidget {
  final DiscMetadata? disc;
  final VoidCallback? onClose;
  final VoidCallback? onOpenFolder;
  final VoidCallback? onVerify;
  final VoidCallback? onConvert;
  final VoidCallback? onDelete;

  const PremiumGameInfoPanel({
    super.key,
    this.disc,
    this.onClose,
    this.onOpenFolder,
    this.onVerify,
    this.onConvert,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      child: SizedBox(
        width: 560,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(disc?.title ?? 'Game Details',
                      style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('ID: ${disc?.gameId ?? "—"}'),
              const SizedBox(height: 6),
              Text('Platform: ${disc?.console.shortName ?? "—"}'),
              const SizedBox(height: 6),
              Text('Size: ${disc?.fileSize ?? "—"} bytes'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: onOpenFolder ?? () {},
                      child: const Text('Open Folder')),
                  const SizedBox(width: 8),
                  TextButton(
                      onPressed: onVerify ?? () {},
                      child: const Text('Verify')),
                  const SizedBox(width: 8),
                  TextButton(
                      onPressed: onConvert ?? () {},
                      child: const Text('Convert')),
                  const SizedBox(width: 8),
                  TextButton(
                      onPressed: onDelete ?? () {},
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete')),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
