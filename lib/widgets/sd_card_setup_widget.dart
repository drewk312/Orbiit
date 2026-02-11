import 'package:flutter/material.dart';
import '../services/sd_card_service.dart';

/// SD Card Setup Widget for Tools Screen
class SDCardSetupWidget extends StatefulWidget {
  const SDCardSetupWidget({super.key});

  @override
  State<SDCardSetupWidget> createState() => _SDCardSetupWidgetState();
}

class _SDCardSetupWidgetState extends State<SDCardSetupWidget> {
  final SDCardService _sdService = SDCardService();
  List<SDCardInfo> _detectedCards = [];
  bool _isScanning = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _scanForSDCards();
  }

  Future<void> _scanForSDCards() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning for drives...';
    });

    try {
      final cards = await _sdService.detectSDCards();
      setState(() {
        _detectedCards = cards;
        _isScanning = false;
        _statusMessage = cards.isEmpty
            ? 'No drives detected'
            : '${cards.length} drive(s) found';
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Error scanning: $e';
      });
    }
  }

  Future<void> _setupSDCard(SDCardInfo card) async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Setting up ${card.displayName}...';
    });

    try {
      final result = await _sdService.setupSDCard(
        card.path,
      );

      setState(() {
        _isScanning = false;
        if (result.success) {
          _statusMessage = 'Created ${result.created.length} folders!';
        } else {
          _statusMessage = 'Setup failed: ${result.errors.join(', ')}';
        }
      });

      // Rescan to update UI
      await Future.delayed(const Duration(seconds: 1));
      await _scanForSDCards();
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Setup error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1A2E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.storage, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Drive Setup (SD/USB/SSD)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                  onPressed: _isScanning ? null : _scanForSDCards,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Auto-detect and set up Wii/GameCube drive structure',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[400],
              ),
            ),
            const Divider(height: 24, color: Colors.white24),

            // Status message
            if (_statusMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isScanning ? Icons.hourglass_empty : Icons.info_outline,
                      color: Colors.blue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),

            // SD cards list
            if (_detectedCards.isEmpty && !_isScanning)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.sd_card_alert,
                          size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text(
                        'No suitable drives detected',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect a drive (SD/USB/SSD) and click refresh',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

            // Display detected SD cards
            ..._detectedCards.map((card) => _buildSDCardTile(card)),
          ],
        ),
      ),
    );
  }

  Widget _buildSDCardTile(SDCardInfo card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: card.isWiiReady
              ? Colors.green.withOpacity(0.5)
              : Colors.orange.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drive info
          Row(
            children: [
              Icon(
                card.isWiiReady ? Icons.check_circle : Icons.warning,
                color: card.isWiiReady ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                card.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Save location (like Wii Save Manager)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Text(
                  'Save Location:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Text(
                  _sdService.getSaveLocation(card.path),
                  style:
                      const TextStyle(color: Colors.greenAccent, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Folder status
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...SDCardService.requiredFolders.map((folder) {
                final exists = card.existingFolders.contains(folder);
                return Chip(
                  label: Text(
                    folder,
                    style: TextStyle(
                      color: exists ? Colors.white : Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  backgroundColor: exists
                      ? Colors.green.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                  avatar: Icon(
                    exists ? Icons.check : Icons.folder_outlined,
                    size: 14,
                    color: exists ? Colors.green : Colors.grey,
                  ),
                );
              }),
              // Boot.elf status
              Chip(
                label: Text(
                  'boot.elf',
                  style: TextStyle(
                    color: card.hasBootElf ? Colors.white : Colors.white70,
                    fontSize: 11,
                  ),
                ),
                backgroundColor: card.hasBootElf
                    ? Colors.green.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
                avatar: Icon(
                  card.hasBootElf ? Icons.check : Icons.file_present_outlined,
                  size: 14,
                  color: card.hasBootElf ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),

          // Setup button if not complete
          if (!card.isComplete) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : () => _setupSDCard(card),
                icon: const Icon(Icons.build, size: 18),
                label: Text(
                  'Setup ${card.missingFolders.length} Missing Folder(s)',
                  style: const TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],

          // File structure preview
          if (card.isWiiReady) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text(
                'File Structure',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              iconColor: Colors.blue,
              collapsedIconColor: Colors.grey,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFileStructureItem(Icons.folder, card.path,
                          isRoot: true),
                      ...card.existingFolders.map((folder) =>
                          _buildFileStructureItem(
                              Icons.folder_open, '  └─ $folder/')),
                      if (card.hasBootElf)
                        _buildFileStructureItem(
                            Icons.insert_drive_file, '  └─ boot.elf'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileStructureItem(IconData icon, String text,
      {bool isRoot = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: isRoot ? Colors.orange : Colors.green),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: isRoot ? Colors.white : Colors.greenAccent,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
