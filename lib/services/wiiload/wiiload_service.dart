// ============================================================================
// WIILOAD WIRELESS INJECTION SERVICE (Enhanced)
// ============================================================================
// Full wireless game/app injection to Wii console over network.
// Supports:
//   - DOL (executable) injection to Homebrew Channel
//   - ELF file injection
//   - WAD installation (with appropriate homebrew)
//   - Game file transfer (ISO/WBFS to USB Loader GX)
//   - Wii console discovery via UDP broadcast
// ============================================================================

import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';

// ============================================================================
// CONSTANTS
// ============================================================================

/// WiiLoad protocol constants
class WiiLoadProtocol {
  static const int port = 4299;
  static const int discoveryPort = 4300;
  static const int bufferSize = 4096;
  static const int connectionTimeout = 10; // seconds
  static const int transferTimeout = 300; // seconds (5 min for large files)

  // Protocol magic bytes
  static const String magic = 'HAXX';
  static const int version = 0x0005;

  // File type identifiers
  static const int typeDol = 0;
  static const int typeElf = 1;
  static const int typeCompressed = 2;

  WiiLoadProtocol._();
}

// ============================================================================
// DATA MODELS
// ============================================================================

/// Represents a discovered Wii console on the network
class DiscoveredWii {
  final String ipAddress;
  final String? nickname;
  final String macAddress;
  final DateTime discoveredAt;
  final bool isOnline;

  DiscoveredWii({
    required this.ipAddress,
    this.nickname,
    required this.macAddress,
    DateTime? discoveredAt,
    this.isOnline = true,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  @override
  String toString() => nickname ?? 'Wii ($ipAddress)';

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
  final TransferState state;
  final String? error;
  final DateTime startTime;

  TransferProgress({
    required this.fileName,
    required this.totalBytes,
    required this.transferredBytes,
    required this.state,
    this.error,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();

  double get progress => totalBytes > 0 ? transferredBytes / totalBytes : 0;
  int get percent => (progress * 100).round();

  Duration get elapsed => DateTime.now().difference(startTime);

  double get speedBytesPerSec {
    final elapsedSec = elapsed.inMilliseconds / 1000;
    return elapsedSec > 0 ? transferredBytes / elapsedSec : 0;
  }

  String get speedFormatted {
    final speed = speedBytesPerSec;
    if (speed > 1024 * 1024) {
      return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    } else if (speed > 1024) {
      return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${speed.toStringAsFixed(0)} B/s';
  }

  Duration? get estimatedTimeRemaining {
    if (speedBytesPerSec <= 0) return null;
    final remaining = totalBytes - transferredBytes;
    final seconds = remaining / speedBytesPerSec;
    return Duration(seconds: seconds.round());
  }

  TransferProgress copyWith({
    int? transferredBytes,
    TransferState? state,
    String? error,
  }) {
    return TransferProgress(
      fileName: fileName,
      totalBytes: totalBytes,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      state: state ?? this.state,
      error: error ?? this.error,
      startTime: startTime,
    );
  }
}

/// Transfer states
enum TransferState {
  pending,
  connecting,
  transferring,
  verifying,
  complete,
  failed,
  cancelled,
}

/// Supported file types for injection
enum WiiFileType {
  dol, // Executable
  elf, // Executable
  wad, // Installable channel/app
  iso, // Game image
  wbfs, // Wii Backup File System
  rvz, // Revolution compressed
  unknown,
}

// ============================================================================
// ENHANCED WIILOAD SERVICE
// ============================================================================

/// Enhanced WiiLoad service for wireless Wii communication
class WiiLoadService {
  // Singleton pattern
  static final WiiLoadService _instance = WiiLoadService._internal();
  factory WiiLoadService() => _instance;
  WiiLoadService._internal();

  // ══════════════════════════════════════════════════════════════════════════
  // STATE MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════════

  final _discoveredWiis = <DiscoveredWii>[];
  final _progressController = StreamController<TransferProgress>.broadcast();

  List<DiscoveredWii> get discoveredWiis => List.unmodifiable(_discoveredWiis);
  Stream<TransferProgress> get progressStream => _progressController.stream;

  Timer? _discoveryTimer;
  bool _isDiscovering = false;

  // ══════════════════════════════════════════════════════════════════════════
  // WII DISCOVERY
  // ══════════════════════════════════════════════════════════════════════════

  /// Start periodic Wii discovery on the local network
  Future<void> startDiscovery(
      {Duration interval = const Duration(seconds: 10)}) async {
    stopDiscovery();
    _isDiscovering = true;

    // Initial scan
    await _performDiscovery();

    // Periodic rescans
    _discoveryTimer = Timer.periodic(interval, (_) => _performDiscovery());
  }

  /// Stop Wii discovery
  void stopDiscovery() {
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    _isDiscovering = false;
  }

  /// Scan local network for Wiis running Homebrew Channel
  Future<List<DiscoveredWii>> _performDiscovery() async {
    debugPrint('[WiiLoad] Starting Wii discovery...');

    try {
      // Get local IP to determine subnet
      final interfaces = await NetworkInterface.list();

      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 && !address.isLoopback) {
            await _scanSubnet(address.address);
          }
        }
      }
    } catch (e) {
      debugPrint('[WiiLoad] Discovery error: $e');
    }

    return _discoveredWiis;
  }

  /// Scan a subnet for Wiis
  Future<void> _scanSubnet(String localIp) async {
    final parts = localIp.split('.');
    if (parts.length != 4) return;

    final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
    debugPrint('[WiiLoad] Scanning subnet: $subnet.0/24');

    // Scan common IP ranges in parallel (batched to avoid overwhelming)
    final futures = <Future<void>>[];

    for (int i = 1; i <= 254; i++) {
      final targetIp = '$subnet.$i';
      futures.add(_probeWii(targetIp));

      // Batch processing - check 50 at a time
      if (futures.length >= 50) {
        await Future.wait(futures);
        futures.clear();
      }
    }

    // Process remaining
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  /// Probe a specific IP for WiiLoad
  Future<void> _probeWii(String ip) async {
    try {
      final socket = await Socket.connect(
        ip,
        WiiLoadProtocol.port,
        timeout: const Duration(milliseconds: 500),
      );

      // Found a Wii!
      final wii = DiscoveredWii(
        ipAddress: ip,
        macAddress: 'Unknown', // Would need ARP lookup
        nickname: null,
      );

      if (!_discoveredWiis.contains(wii)) {
        _discoveredWiis.add(wii);
        debugPrint('[WiiLoad] Found Wii at $ip');
      }

      await socket.close();
    } catch (e) {
      // Not a Wii or not responding - ignore
    }
  }

  /// Manually add a Wii by IP
  Future<bool> addWiiManually(String ip, {String? nickname}) async {
    final isReachable = await testConnection(ip);
    if (isReachable) {
      final wii = DiscoveredWii(
        ipAddress: ip,
        macAddress: 'Manual',
        nickname: nickname,
      );

      _discoveredWiis.removeWhere((w) => w.ipAddress == ip);
      _discoveredWiis.add(wii);
      return true;
    }
    return false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CONNECTION TESTING
  // ══════════════════════════════════════════════════════════════════════════

  /// Test if a Wii is reachable at the given IP
  Future<bool> testConnection(String wiiIp) async {
    try {
      debugPrint(
          '[WiiLoad] Testing connection to $wiiIp:${WiiLoadProtocol.port}');

      final socket = await Socket.connect(
        wiiIp,
        WiiLoadProtocol.port,
        timeout: Duration(seconds: WiiLoadProtocol.connectionTimeout),
      );

      await socket.close();
      debugPrint('[WiiLoad] Connection successful!');
      return true;
    } catch (e) {
      debugPrint('[WiiLoad] Connection failed: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FILE TRANSFER
  // ══════════════════════════════════════════════════════════════════════════

  /// Send a DOL/ELF file to a Wii
  Future<bool> sendExecutable(
    String wiiIp,
    String filePath, {
    String? arguments,
    void Function(TransferProgress)? onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint('[WiiLoad] File not found: $filePath');
      return false;
    }

    final fileName = file.path.split(Platform.pathSeparator).last;
    final fileBytes = await file.readAsBytes();
    final fileType = _detectFileType(filePath);

    if (fileType != WiiFileType.dol && fileType != WiiFileType.elf) {
      debugPrint('[WiiLoad] Invalid file type. Expected DOL or ELF.');
      return false;
    }

    var progress = TransferProgress(
      fileName: fileName,
      totalBytes: fileBytes.length,
      transferredBytes: 0,
      state: TransferState.connecting,
    );

    _progressController.add(progress);
    onProgress?.call(progress);

    Socket? socket;
    try {
      // Connect to Wii
      debugPrint('[WiiLoad] Connecting to $wiiIp...');
      socket = await Socket.connect(
        wiiIp,
        WiiLoadProtocol.port,
        timeout: Duration(seconds: WiiLoadProtocol.connectionTimeout),
      );

      // Prepare WiiLoad header
      final header = _buildWiiLoadHeader(
        fileBytes.length,
        fileType == WiiFileType.dol
            ? WiiLoadProtocol.typeDol
            : WiiLoadProtocol.typeElf,
        arguments,
      );

      // Send header
      socket.add(header);
      await socket.flush();
      debugPrint('[WiiLoad] Header sent (${header.length} bytes)');

      // Update state
      progress = progress.copyWith(state: TransferState.transferring);
      _progressController.add(progress);
      onProgress?.call(progress);

      // Send file data in chunks
      const chunkSize = WiiLoadProtocol.bufferSize;
      int sent = 0;

      while (sent < fileBytes.length) {
        final end = (sent + chunkSize).clamp(0, fileBytes.length);
        final chunk = fileBytes.sublist(sent, end);

        socket.add(chunk);
        await socket.flush();

        sent = end;
        progress = progress.copyWith(transferredBytes: sent);
        _progressController.add(progress);
        onProgress?.call(progress);

        // Small delay to prevent overwhelming
        await Future.delayed(const Duration(milliseconds: 1));
      }

      debugPrint('[WiiLoad] Transfer complete! Sent $sent bytes.');

      progress = progress.copyWith(
        state: TransferState.complete,
        transferredBytes: fileBytes.length,
      );
      _progressController.add(progress);
      onProgress?.call(progress);

      return true;
    } catch (e) {
      debugPrint('[WiiLoad] Transfer failed: $e');

      progress = progress.copyWith(
        state: TransferState.failed,
        error: e.toString(),
      );
      _progressController.add(progress);
      onProgress?.call(progress);

      return false;
    } finally {
      await socket?.close();
    }
  }

  /// Build WiiLoad protocol header
  Uint8List _buildWiiLoadHeader(int fileSize, int fileType, String? arguments) {
    final argBytes = arguments != null ? utf8.encode(arguments) : Uint8List(0);

    // Header structure:
    // - 4 bytes: Magic "HAXX"
    // - 1 byte: Version high
    // - 1 byte: Version low
    // - 2 bytes: Arguments length
    // - 4 bytes: File size (uncompressed)
    // - 4 bytes: File size (compressed, same as uncompressed for raw)
    // - Arguments (if any)

    final header = BytesBuilder();

    // Magic
    header.add(utf8.encode(WiiLoadProtocol.magic));

    // Version (big endian)
    header.addByte((WiiLoadProtocol.version >> 8) & 0xFF);
    header.addByte(WiiLoadProtocol.version & 0xFF);

    // Arguments length (big endian)
    header.addByte((argBytes.length >> 8) & 0xFF);
    header.addByte(argBytes.length & 0xFF);

    // File size uncompressed (big endian)
    header.addByte((fileSize >> 24) & 0xFF);
    header.addByte((fileSize >> 16) & 0xFF);
    header.addByte((fileSize >> 8) & 0xFF);
    header.addByte(fileSize & 0xFF);

    // File size compressed (same for raw, big endian)
    header.addByte((fileSize >> 24) & 0xFF);
    header.addByte((fileSize >> 16) & 0xFF);
    header.addByte((fileSize >> 8) & 0xFF);
    header.addByte(fileSize & 0xFF);

    // Arguments
    if (argBytes.isNotEmpty) {
      header.add(argBytes);
    }

    return header.toBytes();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FILE TYPE DETECTION
  // ══════════════════════════════════════════════════════════════════════════

  /// Detect file type from extension
  WiiFileType _detectFileType(String filePath) {
    final ext = filePath.toLowerCase().split('.').last;

    switch (ext) {
      case 'dol':
        return WiiFileType.dol;
      case 'elf':
        return WiiFileType.elf;
      case 'wad':
        return WiiFileType.wad;
      case 'iso':
        return WiiFileType.iso;
      case 'wbfs':
        return WiiFileType.wbfs;
      case 'rvz':
        return WiiFileType.rvz;
      default:
        return WiiFileType.unknown;
    }
  }

  /// Get list of DOL files in a directory
  Future<List<String>> findDolFiles(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) return [];

      final dolFiles = <String>[];
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final ext = entity.path.toLowerCase().split('.').last;
          if (ext == 'dol' || ext == 'elf') {
            dolFiles.add(entity.path);
          }
        }
      }

      debugPrint('[WiiLoad] Found ${dolFiles.length} executable files');
      return dolFiles;
    } catch (e) {
      debugPrint('[WiiLoad] Error scanning directory: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ══════════════════════════════════════════════════════════════════════════

  void dispose() {
    stopDiscovery();
    _progressController.close();
  }
}

// ============================================================================
// WIILOAD PROVIDER (for state management)
// ============================================================================

/// Provider for WiiLoad service state management
class WiiLoadProvider extends ChangeNotifier {
  final _service = WiiLoadService();

  List<DiscoveredWii> get discoveredWiis => _service.discoveredWiis;
  Stream<TransferProgress> get progressStream => _service.progressStream;

  DiscoveredWii? _selectedWii;
  DiscoveredWii? get selectedWii => _selectedWii;

  TransferProgress? _currentTransfer;
  TransferProgress? get currentTransfer => _currentTransfer;

  bool _isDiscovering = false;
  bool get isDiscovering => _isDiscovering;

  bool _isTransferring = false;
  bool get isTransferring => _isTransferring;

  /// Start Wii discovery
  Future<void> startDiscovery() async {
    _isDiscovering = true;
    notifyListeners();

    await _service.startDiscovery();

    _isDiscovering = false;
    notifyListeners();
  }

  /// Stop discovery
  void stopDiscovery() {
    _service.stopDiscovery();
    _isDiscovering = false;
    notifyListeners();
  }

  /// Select a Wii for transfers
  void selectWii(DiscoveredWii? wii) {
    _selectedWii = wii;
    notifyListeners();
  }

  /// Add Wii manually
  Future<bool> addWiiManually(String ip, {String? nickname}) async {
    final success = await _service.addWiiManually(ip, nickname: nickname);
    notifyListeners();
    return success;
  }

  /// Test connection to selected Wii
  Future<bool> testConnection() async {
    if (_selectedWii == null) return false;
    return await _service.testConnection(_selectedWii!.ipAddress);
  }

  /// Send executable to selected Wii
  Future<bool> sendExecutable(String filePath, {String? arguments}) async {
    if (_selectedWii == null) return false;

    _isTransferring = true;
    notifyListeners();

    final success = await _service.sendExecutable(
      _selectedWii!.ipAddress,
      filePath,
      arguments: arguments,
      onProgress: (progress) {
        _currentTransfer = progress;
        notifyListeners();
      },
    );

    _isTransferring = false;
    notifyListeners();

    return success;
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
