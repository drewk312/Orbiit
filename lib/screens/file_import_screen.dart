import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../services/platform_detector.dart';
import '../services/file_organizer.dart';

/// Smart file import and organization screen
class FileImportScreen extends StatefulWidget {
  const FileImportScreen({super.key});

  @override
  State<FileImportScreen> createState() => _FileImportScreenState();
}

class _FileImportScreenState extends State<FileImportScreen> {
  final PlatformDetector _detector = PlatformDetector();
  final FileOrganizer _organizer = FileOrganizer();

  List<ImportFileEntry> _files = [];
  String? _targetDirectory;
  bool _isProcessing = false;
  bool _moveFiles = false;
  bool _fetchCoversAfter = true;
  ConflictAction _conflictAction = ConflictAction.skip;

  int _processedCount = 0;
  int _totalCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('Smart File Import & Organization'),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSettings(),
          const SizedBox(height: 24),
          _buildDropZone(),
          const SizedBox(height: 24),
          if (_files.isNotEmpty) ...[
            _buildFileList(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: const Color(0xFF1A1A2E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.blue, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Smart Import',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Automatically detects platform and organizes your games into the proper folder structure.',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return Card(
      color: const Color(0xFF1A1A2E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Target directory
            InkWell(
              onTap: _selectTargetDirectory,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Target Directory',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _targetDirectory ?? 'Click to select',
                            style: TextStyle(
                              color: _targetDirectory != null
                                  ? Colors.white
                                  : Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.white30, size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Options
            CheckboxListTile(
              title: const Text('Move files (instead of copy)',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text('Faster but removes from original location',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              value: _moveFiles,
              onChanged: (value) => setState(() => _moveFiles = value ?? false),
              activeColor: Colors.blue,
              visualDensity: VisualDensity.compact,
            ),

            CheckboxListTile(
              title: const Text('Fetch cover art after import',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text('Download covers for organized games',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              value: _fetchCoversAfter,
              onChanged: (value) =>
                  setState(() => _fetchCoversAfter = value ?? true),
              activeColor: Colors.blue,
              visualDensity: VisualDensity.compact,
            ),

            const SizedBox(height: 12),

            // Conflict resolution
            DropdownButtonFormField<ConflictAction>(
              value: _conflictAction,
              decoration: const InputDecoration(
                labelText: 'If file exists',
                border: OutlineInputBorder(),
              ),
              dropdownColor: const Color(0xFF2A2A3E),
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(
                  value: ConflictAction.skip,
                  child: Text('Skip (keep existing)'),
                ),
                DropdownMenuItem(
                  value: ConflictAction.replace,
                  child: Text('Replace existing'),
                ),
                DropdownMenuItem(
                  value: ConflictAction.keepBoth,
                  child: Text('Keep both (rename new)'),
                ),
              ],
              onChanged: (value) => setState(
                  () => _conflictAction = value ?? ConflictAction.skip),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropZone() {
    return Card(
      color: const Color(0xFF1A1A2E),
      child: InkWell(
        onTap: _selectFiles,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.blue.withOpacity(0.5),
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload, size: 64, color: Colors.blue[300]),
                const SizedBox(height: 16),
                const Text(
                  'Drop files here or click to browse',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Supports: ISO, WBFS, RVZ, GBA, N64, SNES, NES, Genesis',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileList() {
    return Card(
      color: const Color(0xFF1A1A2E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Files to Import (${_files.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (_files.isNotEmpty && !_isProcessing)
                  TextButton.icon(
                    onPressed: () => setState(() => _files.clear()),
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3E),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Expanded(
                      flex: 3,
                      child: Text('File',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12))),
                  const Expanded(
                      flex: 2,
                      child: Text('Platform',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12))),
                  const Expanded(
                      flex: 1,
                      child: Text('Conf.',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12))),
                  const Expanded(
                      flex: 3,
                      child: Text('Target',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12))),
                  Container(
                      width: 80,
                      alignment: Alignment.center,
                      child: const Text('Status',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12))),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // File rows
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _files.length,
              itemBuilder: (context, index) => _buildFileRow(_files[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileRow(ImportFileEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: entry.status == ImportStatus.success
              ? Colors.green.withOpacity(0.3)
              : entry.status == ImportStatus.error
                  ? Colors.red.withOpacity(0.3)
                  : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              p.basename(entry.sourcePath),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.detection?.platform.displayName ?? 'Detecting...',
              style: TextStyle(
                color: entry.detection != null ? Colors.blue[300] : Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              entry.detection != null
                  ? '${(entry.detection!.confidence * 100).toInt()}%'
                  : '-',
              style: TextStyle(
                color: entry.detection != null && entry.detection!.isConfident
                    ? Colors.green[300]
                    : Colors.orange[300],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              entry.targetPreview ?? 'Calculating...',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 80,
            child: _buildStatusIndicator(entry.status),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(ImportStatus status) {
    switch (status) {
      case ImportStatus.pending:
        return const Icon(Icons.pending, color: Colors.grey, size: 20);
      case ImportStatus.processing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
        );
      case ImportStatus.success:
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case ImportStatus.error:
        return const Icon(Icons.error, color: Colors.red, size: 20);
    }
  }

  Widget _buildActionButtons() {
    if (_isProcessing) {
      return Card(
        color: const Color(0xFF1A1A2E),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: _totalCount > 0 ? _processedCount / _totalCount : 0,
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 12),
              Text(
                'Processing: $_processedCount / $_totalCount files',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => setState(() => _files.clear()),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _targetDirectory != null && _files.isNotEmpty
              ? _startImport
              : null,
          icon: const Icon(Icons.start),
          label: const Text('Import All Files'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }

  // === ACTIONS ===

  Future<void> _selectTargetDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Target Directory',
    );

    if (result != null) {
      setState(() {
        _targetDirectory = result;
      });
    }
  }

  Future<void> _selectFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'iso',
        'wbfs',
        'rvz',
        'gba',
        'gbc',
        'gb',
        'z64',
        'n64',
        'v64',
        'sfc',
        'smc',
        'nes',
        'gen',
        'md',
        'smd',
        'zip',
        '7z',
      ],
    );

    if (result != null && result.files.isNotEmpty) {
      for (final file in result.files) {
        if (file.path != null) {
          await _addFile(file.path!);
        }
      }
    }
  }

  Future<void> _addFile(String filePath) async {
    final entry = ImportFileEntry(
      sourcePath: filePath,
      status: ImportStatus.pending,
    );

    setState(() {
      _files.add(entry);
    });

    // Detect platform in background
    final detection = await _detector.detectPlatform(filePath);
    final index = _files.indexWhere((e) => e.sourcePath == filePath);

    if (index != -1) {
      setState(() {
        _files[index] = entry.copyWith(
          detection: detection,
          targetPreview: _generatePreview(detection, filePath),
        );
      });
    }
  }

  String _generatePreview(DetectionResult detection, String filePath) {
    final platform = detection.platform.folderName;

    if (detection.platform == GamePlatform.wii ||
        detection.platform == GamePlatform.gamecube) {
      final gameId = detection.gameId ?? 'UNKNOWN';
      return '$platform/$gameId/';
    } else {
      return '$platform/${p.basename(filePath)}';
    }
  }

  Future<void> _startImport() async {
    if (_targetDirectory == null) return;

    setState(() {
      _isProcessing = true;
      _processedCount = 0;
      _totalCount = _files.length;
    });

    final filesToOrganize = _files.map((entry) {
      return FileToOrganize(
        sourcePath: entry.sourcePath,
        platform: entry.detection?.platform ?? GamePlatform.other,
        gameId: entry.detection?.gameId,
        title: entry.detection?.detectedTitle,
      );
    }).toList();

    final result = await _organizer.organizeBatch(
      filesToOrganize,
      _targetDirectory!,
      moveInsteadOfCopy: _moveFiles,
      conflictAction: _conflictAction,
      onProgress: (current, total) {
        setState(() {
          _processedCount = current;
        });
      },
    );

    // Update status for each file
    for (int i = 0; i < result.results.length; i++) {
      final organizeResult = result.results[i];
      setState(() {
        _files[i] = _files[i].copyWith(
          status: organizeResult.success
              ? ImportStatus.success
              : ImportStatus.error,
        );
      });
    }

    setState(() {
      _isProcessing = false;
    });

    // Show summary
    _showSummaryDialog(result);
  }

  void _showSummaryDialog(BatchOrganizeResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Import Complete',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✓ ${result.successCount} files imported successfully',
              style: const TextStyle(color: Colors.green),
            ),
            if (result.failCount > 0)
              Text(
                '✗ ${result.failCount} files failed',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// === SUPPORTING CLASSES ===

class ImportFileEntry {
  final String sourcePath;
  final DetectionResult? detection;
  final String? targetPreview;
  final ImportStatus status;

  ImportFileEntry({
    required this.sourcePath,
    this.detection,
    this.targetPreview,
    required this.status,
  });

  ImportFileEntry copyWith({
    DetectionResult? detection,
    String? targetPreview,
    ImportStatus? status,
  }) {
    return ImportFileEntry(
      sourcePath: sourcePath,
      detection: detection ?? this.detection,
      targetPreview: targetPreview ?? this.targetPreview,
      status: status ?? this.status,
    );
  }
}

enum ImportStatus {
  pending,
  processing,
  success,
  error,
}
