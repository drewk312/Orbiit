// ============================================================================
// WIILOAD TRANSFER SCREEN
// ============================================================================
// Wireless file transfer to Wii console.
// Features:
//   - Automatic Wii discovery on local network
//   - DOL/ELF file transfer with progress tracking
//   - Connection status and history
//   - Quick-send for recently used files
// ============================================================================

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:io';

/// Represents a discovered Wii console on the network
class DiscoveredWii {
  final String ipAddress;
  final String? name;
  final bool isOnline;

  DiscoveredWii({
    required this.ipAddress,
    this.name,
    this.isOnline = true,
  });

  @override
  bool operator ==(Object other) =>
      other is DiscoveredWii && other.ipAddress == ipAddress;

  @override
  int get hashCode => ipAddress.hashCode;
}

/// Transfer progress information
class TransferProgress {
  final String fileName;
  final int totalBytes;
  final int transferredBytes;
  final DateTime startTime;

  TransferProgress({
    required this.fileName,
    required this.totalBytes,
    required this.transferredBytes,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();

  double get progress => totalBytes > 0 ? transferredBytes / totalBytes : 0;
  int get percent => (progress * 100).round();

  Duration get elapsed => DateTime.now().difference(startTime);

  double get speedBytesPerSec {
    final elapsedSec = elapsed.inMilliseconds / 1000;
    return elapsedSec > 0 ? transferredBytes / elapsedSec : 0;
  }

  String get formattedSpeed {
    final speed = speedBytesPerSec;
    if (speed > 1024 * 1024) {
      return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    } else if (speed > 1024) {
      return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${speed.toStringAsFixed(0)} B/s';
  }

  String get formattedEta {
    if (speedBytesPerSec <= 0) return '--:--';
    final remaining = totalBytes - transferredBytes;
    final seconds = remaining / speedBytesPerSec;
    final duration = Duration(seconds: seconds.round());
    final mins = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} remaining';
  }
}

// ============================================================================
// WIILOAD SERVICE (Screen-local implementation)
// ============================================================================

class WiiLoadService {
  static const int wiiLoadPort = 4299;

  /// Discover Wiis on the local network
  Future<List<DiscoveredWii>> discoverWiis() async {
    final discovered = <DiscoveredWii>[];

    try {
      // Get local IP to determine subnet
      final interfaces = await NetworkInterface.list();

      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 && !address.isLoopback) {
            final parts = address.address.split('.');
            if (parts.length == 4) {
              final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

              // Scan common IPs (batch to avoid overwhelming)
              final futures = <Future<DiscoveredWii?>>[];
              for (int i = 1; i <= 254; i++) {
                futures.add(_probeWii('$subnet.$i'));
              }

              final results = await Future.wait(futures);
              discovered.addAll(results.whereType<DiscoveredWii>());
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[WiiLoad] Discovery error: $e');
    }

    return discovered;
  }

  Future<DiscoveredWii?> _probeWii(String ip) async {
    try {
      final socket = await Socket.connect(
        ip,
        wiiLoadPort,
        timeout: const Duration(milliseconds: 300),
      );
      await socket.close();
      return DiscoveredWii(ipAddress: ip, name: 'Wii ($ip)');
    } catch (e) {
      return null;
    }
  }

  /// Send a file to a Wii
  Future<void> sendFile(
    String wiiIp,
    String filePath, {
    void Function(TransferProgress)? onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final fileName = file.path.split(Platform.pathSeparator).last;
    final fileBytes = await file.readAsBytes();

    Socket? socket;
    try {
      socket = await Socket.connect(
        wiiIp,
        wiiLoadPort,
        timeout: const Duration(seconds: 10),
      );

      // Build WiiLoad header
      final header = _buildHeader(fileBytes.length);
      socket.add(header);
      await socket.flush();

      // Send file data
      const chunkSize = 4096;
      int sent = 0;
      final startTime = DateTime.now();

      while (sent < fileBytes.length) {
        final end = (sent + chunkSize).clamp(0, fileBytes.length);
        socket.add(fileBytes.sublist(sent, end));
        await socket.flush();
        sent = end;

        onProgress?.call(TransferProgress(
          fileName: fileName,
          totalBytes: fileBytes.length,
          transferredBytes: sent,
          startTime: startTime,
        ));

        await Future.delayed(const Duration(milliseconds: 1));
      }
    } finally {
      await socket?.close();
    }
  }

  List<int> _buildHeader(int fileSize) {
    final header = <int>[];

    // Magic "HAXX"
    header.addAll([0x48, 0x41, 0x58, 0x58]);

    // Version (0x0005)
    header.addAll([0x00, 0x05]);

    // Arguments length (0)
    header.addAll([0x00, 0x00]);

    // File size uncompressed (big endian)
    header.add((fileSize >> 24) & 0xFF);
    header.add((fileSize >> 16) & 0xFF);
    header.add((fileSize >> 8) & 0xFF);
    header.add(fileSize & 0xFF);

    // File size compressed (same as uncompressed)
    header.add((fileSize >> 24) & 0xFF);
    header.add((fileSize >> 16) & 0xFF);
    header.add((fileSize >> 8) & 0xFF);
    header.add(fileSize & 0xFF);

    return header;
  }
}

// ============================================================================
// MAIN SCREEN
// ============================================================================

class WiiLoadScreen extends StatefulWidget {
  const WiiLoadScreen({super.key});

  @override
  State<WiiLoadScreen> createState() => _WiiLoadScreenState();
}

class _WiiLoadScreenState extends State<WiiLoadScreen>
    with SingleTickerProviderStateMixin {
  // Services
  final _wiiLoadService = WiiLoadService();

  // State
  List<DiscoveredWii> _discoveredWiis = [];
  DiscoveredWii? _selectedWii;
  bool _isScanning = false;
  bool _isTransferring = false;
  String? _selectedFilePath;
  TransferProgress? _currentProgress;

  // History
  final List<String> _recentFiles = [];
  final List<_TransferHistoryItem> _transferHistory = [];

  // Animations
  late AnimationController _scanAnimController;

  @override
  void initState() {
    super.initState();

    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _startDiscovery();
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    super.dispose();
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isScanning = true;
    });
    _scanAnimController.repeat();

    try {
      final wiis = await _wiiLoadService.discoverWiis();
      setState(() {
        _discoveredWiis = wiis;
        if (wiis.isNotEmpty && _selectedWii == null) {
          _selectedWii = wiis.first;
        }
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
      _scanAnimController.stop();
    }
  }

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dol', 'elf'],
      dialogTitle: 'Select DOL or ELF file',
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFilePath = result.files.first.path;
      });
    }
  }

  Future<void> _sendFile() async {
    if (_selectedWii == null || _selectedFilePath == null) return;

    setState(() {
      _isTransferring = true;
      _currentProgress = null;
    });

    try {
      await _wiiLoadService.sendFile(
        _selectedWii!.ipAddress,
        _selectedFilePath!,
        onProgress: (progress) {
          setState(() {
            _currentProgress = progress;
          });
        },
      );

      // Add to history
      setState(() {
        _transferHistory.insert(
            0,
            _TransferHistoryItem(
              fileName: _selectedFilePath!.split(Platform.pathSeparator).last,
              wiiName: _selectedWii!.name ?? _selectedWii!.ipAddress,
              timestamp: DateTime.now(),
              success: true,
            ));

        // Keep recent files
        if (!_recentFiles.contains(_selectedFilePath)) {
          _recentFiles.insert(0, _selectedFilePath!);
          if (_recentFiles.length > 5) _recentFiles.removeLast();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _transferHistory.insert(
            0,
            _TransferHistoryItem(
              fileName: _selectedFilePath!.split(Platform.pathSeparator).last,
              wiiName: _selectedWii!.name ?? _selectedWii!.ipAddress,
              timestamp: DateTime.now(),
              success: false,
              error: e.toString(),
            ));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transfer failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isTransferring = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'WiiLoad Transfer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Row(
        children: [
          // ════════════════════════════════════════════════════════════════
          // LEFT PANEL - Wii Discovery
          // ════════════════════════════════════════════════════════════════
          Container(
            width: 340,
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              border: Border(
                right: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              children: [
                // Header
                _buildPanelHeader(),

                // Discovered Wiis list
                Expanded(
                  child: _buildWiiList(),
                ),

                // Scan button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildScanButton(),
                ),
              ],
            ),
          ),

          // ════════════════════════════════════════════════════════════════
          // MAIN CONTENT
          // ════════════════════════════════════════════════════════════════
          Expanded(
            child: Column(
              children: [
                // Transfer Panel
                Expanded(
                  flex: 5,
                  child: _buildTransferPanel(),
                ),

                // History Panel
                Expanded(
                  flex: 3,
                  child: _buildHistoryPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PANEL HEADER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPanelHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyan.withValues(alpha: 0.2),
            Colors.blue.withValues(alpha: 0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.cyan, Colors.blue],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.wifi, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WiiLoad Transfer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_discoveredWiis.length} Wii${_discoveredWiis.length == 1 ? '' : 's'} found',
                  style: TextStyle(
                    color: Colors.cyan.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_isScanning)
            AnimatedBuilder(
              animation: _scanAnimController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _scanAnimController.value * 2 * 3.14159,
                  child: child,
                );
              },
              child: Icon(
                Icons.radar,
                color: Colors.cyan.withValues(alpha: 0.7),
                size: 28,
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WII LIST
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildWiiList() {
    if (_discoveredWiis.isEmpty && !_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 48,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Wii consoles found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure your Wii is running\nHomebrew Channel on the same network',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _discoveredWiis.length,
      itemBuilder: (context, index) {
        final wii = _discoveredWiis[index];
        final isSelected = wii == _selectedWii;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildWiiCard(wii, isSelected),
        );
      },
    );
  }

  Widget _buildWiiCard(DiscoveredWii wii, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedWii = wii),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.cyan.withValues(alpha: 0.15)
              : const Color(0xFF21262D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? Colors.cyan : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Wii icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.videogame_asset,
                color: isSelected ? Colors.cyan : Colors.white54,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wii.name ?? 'Wii Console',
                    style: TextStyle(
                      color: isSelected ? Colors.cyan : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    wii.ipAddress,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.cyan,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SCAN BUTTON
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isScanning ? null : _startDiscovery,
        icon: _isScanning
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              )
            : const Icon(Icons.refresh, size: 20),
        label: Text(_isScanning ? 'Scanning...' : 'Scan Network'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF21262D),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TRANSFER PANEL
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTransferPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.upload_file,
                          color: Colors.cyan,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Send File',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Target Wii info
                  if (_selectedWii != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_forward,
                              color: Colors.cyan, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'Sending to: ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _selectedWii!.name ?? _selectedWii!.ipAddress,
                            style: const TextStyle(
                              color: Colors.cyan,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: Colors.orange, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No Wii selected. Scan and select a console.',
                              style:
                                  TextStyle(color: Colors.orange, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // File selection - more compact
                  GestureDetector(
                    onTap: _selectFile,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedFilePath != null
                              ? Colors.cyan.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: _selectedFilePath != null
                          ? Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.cyan.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.description,
                                    color: Colors.cyan,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedFilePath!
                                            .split(Platform.pathSeparator)
                                            .last,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _selectedFilePath!,
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.4),
                                          fontSize: 10,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white54, size: 18),
                                  onPressed: () =>
                                      setState(() => _selectedFilePath = null),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Icon(
                                  Icons.file_upload,
                                  size: 32,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Click to select a DOL or ELF file',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.5),
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        'Supports .dol and .elf homebrew files',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.3),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // Progress (if transferring)
                  if (_isTransferring && _currentProgress != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Transferring...',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${(_currentProgress!.progress * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Colors.cyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _currentProgress!.progress,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.1),
                              valueColor:
                                  const AlwaysStoppedAnimation(Colors.cyan),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _currentProgress!.formattedSpeed,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                _currentProgress!.formattedEta,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Fixed send button at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _selectedWii != null &&
                        _selectedFilePath != null &&
                        !_isTransferring
                    ? _sendFile
                    : null,
                icon: _isTransferring
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      )
                    : const Icon(Icons.send, size: 20),
                label: Text(
                  _isTransferring ? 'Sending...' : 'Send to Wii',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.cyan.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HISTORY PANEL
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHistoryPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.white.withValues(alpha: 0.5),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Transfer History',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // History list
          Expanded(
            child: _transferHistory.isEmpty
                ? Center(
                    child: Text(
                      'No transfers yet',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _transferHistory.length,
                    itemBuilder: (context, index) {
                      final item = _transferHistory[index];
                      return _buildHistoryItem(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(_TransferHistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            item.success ? Icons.check_circle : Icons.error,
            color: item.success ? Colors.green : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '→ ${item.wiiName}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(item.timestamp),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ============================================================================
// TRANSFER HISTORY ITEM
// ============================================================================

class _TransferHistoryItem {
  final String fileName;
  final String wiiName;
  final DateTime timestamp;
  final bool success;
  final String? error;

  _TransferHistoryItem({
    required this.fileName,
    required this.wiiName,
    required this.timestamp,
    required this.success,
    this.error,
  });
}
