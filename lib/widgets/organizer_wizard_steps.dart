import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/storage/storage_organizer_service.dart';

// ============================================================================
// STEP 1: DRIVE SELECTION
// ============================================================================

class OrganizerStep1Selection extends StatefulWidget {
  final Function(String path) onPathSelected;
  final bool isScanning;

  const OrganizerStep1Selection({
    required this.onPathSelected,
    super.key,
    this.isScanning = false,
  });

  @override
  State<OrganizerStep1Selection> createState() =>
      _OrganizerStep1SelectionState();
}

class _OrganizerStep1SelectionState extends State<OrganizerStep1Selection> {
  String? _selectedPath;

  Future<void> _pickFolder() async {
    final String? selectedDirectory =
        await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _selectedPath = selectedDirectory;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Hero Icon
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF00C2FF).withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF00C2FF).withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.drive_file_move_rounded,
            size: 64,
            color: Color(0xFF00C2FF),
          ),
        ),
        const SizedBox(height: 32),

        // Title & Description
        const Text(
          'Select Storage Drive',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Choose the USB drive or SD card containing your ROMs.\nWe will scan for Wii and GameCube games automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 48),

        // Path Display
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.folder_open, color: Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _selectedPath ?? 'No drive selected',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedPath != null ? null : Colors.grey,
                    fontWeight: _selectedPath != null
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (_selectedPath != null)
                IconButton(
                  onPressed: () => setState(() => _selectedPath = null),
                  icon: const Icon(Icons.close),
                  tooltip: 'Clear selection',
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: widget.isScanning ? null : _pickFolder,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('BROWSE...'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                side: BorderSide(
                    color: const Color(0xFF00C2FF).withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _selectedPath != null && !widget.isScanning
                  ? () => widget.onPathSelected(_selectedPath!)
                  : null,
              icon: widget.isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(widget.isScanning ? 'SCANNING...' : 'SCAN DRIVE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C2FF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// STEP 2: PREVIEW & ANALYSIS
// ============================================================================

class OrganizerStep2Preview extends StatelessWidget {
  final StorageAnalysis analysis;
  final VoidCallback onStartOrganization;
  final VoidCallback onCancel;

  const OrganizerStep2Preview({
    required this.analysis,
    required this.onStartOrganization,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analysis Complete',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Found ${analysis.totalGamesCount} games on ${analysis.drivePath}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Ready to Organize',
                    style: TextStyle(
                      color: Colors.green[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Stats Cards
        Row(
          children: [
            Expanded(
                child: _buildStatCard('Wii Games', '${analysis.wiiGamesCount}',
                    Icons.sports_esports, const Color(0xFF00C2FF))),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard('GameCube', '${analysis.gcGamesCount}',
                    Icons.videogame_asset, const Color(0xFFB000FF))),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard('Issues', '${analysis.issues.length}',
                    Icons.warning_amber_rounded, Colors.orange)),
          ],
        ),
        const SizedBox(height: 32),

        // Action Plan
        const Text(
          'PROPOSED ACTIONS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildActionItem(
                  icon: Icons.folder_shared,
                  title: 'Organize Folder Structure',
                  description: 'Create standardized /wbfs and /games folders',
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildActionItem(
                  icon: Icons.drive_file_move,
                  title: 'Move & Rename Games',
                  description:
                      'Rename ${analysis.games.length} files to ID_Title [ID] format',
                  color: Colors.indigo,
                ),
                if (analysis.issues.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildActionItem(
                    icon: Icons.auto_fix_high,
                    title: 'Fix ${analysis.issues.length} Issues',
                    description:
                        'Resolve naming duplicates and folder locations',
                    color: Colors.orange,
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Bottom Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: onCancel,
              child: const Text('CANCEL'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: onStartOrganization,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('START ORGANIZATION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C2FF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
        Icon(Icons.check, color: Colors.green.withValues(alpha: 0.5)),
      ],
    );
  }
}

// ============================================================================
// STEP 3: EXECUTION & PROGRESS
// ============================================================================

class OrganizerStep3Execution extends StatelessWidget {
  final List<String> logs;
  final bool isComplete;
  final VoidCallback onFinish;

  const OrganizerStep3Execution({
    required this.logs,
    required this.onFinish,
    super.key,
    this.isComplete = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animation / Icon
        if (isComplete)
          _buildCompleteIcon()
        else
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation(Color(0xFF00C2FF)),
              backgroundColor: Colors.white10,
            ),
          ),

        const SizedBox(height: 32),

        Text(
          isComplete ? 'All Done!' : 'Organizing Library...',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          isComplete
              ? 'Your library has been successfully organized.'
              : 'Please do not unplug your drive.',
          style: const TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 40),

        // Logs console
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: logs.isEmpty
                ? const Center(
                    child: Text('Waiting to start...',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: logs.length,
                    reverse: true, // Auto-scroll to bottom
                    itemBuilder: (context, index) {
                      final log = logs[logs.length - 1 - index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '> $log',
                          style: const TextStyle(
                            fontFamily: 'Consolas',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),

        const SizedBox(height: 24),

        if (isComplete)
          ElevatedButton(
            onPressed: onFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
            child: const Text('BACK TO DASHBOARD'),
          ),
      ],
    );
  }

  Widget _buildCompleteIcon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: const Icon(
        Icons.check_rounded,
        size: 64,
        color: Colors.green,
      ),
    );
  }
}
