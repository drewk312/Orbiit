import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../core/app_logger.dart';

/// WiiloadService - Network client for pushing .dol files to Wii via Wiiload protocol.
/// Uses TCP port 4299: sends 4-byte big-endian file length then raw file bytes.
class WiiloadService {
  static const int wiiloadPort = 4299;
  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration sendTimeout = Duration(seconds: 60);

  /// Send a .dol file to Wii via Wiiload protocol (real TCP).
  Future<bool> sendDolFile(String wiiIp, String dolPath,
      {String? arguments}) async {
    Socket? socket;
    try {
      AppLogger.instance
          .info('[Wiiload] Sending DOL: $dolPath → $wiiIp:$wiiloadPort');

      final file = File(dolPath);
      if (!await file.exists()) {
        throw Exception('DOL file not found: $dolPath');
      }

      final dolBytes = await file.readAsBytes();
      if (dolBytes.isEmpty) {
        throw Exception('DOL file is empty');
      }

      socket = await Socket.connect(
        wiiIp,
        wiiloadPort,
        timeout: connectTimeout,
      );

      // Wiiload / TCP Loader: 4-byte big-endian length, then file data
      final lengthBytes = Uint8List(4);
      ByteData.view(lengthBytes.buffer).setUint32(0, dolBytes.length);

      socket.add(lengthBytes);
      socket.add(dolBytes);
      await socket.flush();

      AppLogger.instance
          .info('[Wiiload] Sent ${dolBytes.length} bytes successfully');
      return true;
    } on SocketException catch (e) {
      AppLogger.instance.error('[Wiiload] Socket error', error: e);
      return false;
    } on TimeoutException catch (e) {
      AppLogger.instance.error('[Wiiload] Timeout', error: e);
      return false;
    } catch (e) {
      AppLogger.instance.error('[Wiiload] Failed', error: e);
      return false;
    } finally {
      await socket?.close();
    }
  }

  /// Test connection to Wii (real TCP connect to port 4299).
  Future<bool> testConnection(String wiiIp) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        wiiIp,
        wiiloadPort,
        timeout: connectTimeout,
      );
      AppLogger.instance.info('[Wiiload] Connection to $wiiIp:$wiiloadPort OK');
      return true;
    } on SocketException catch (e) {
      AppLogger.instance.warning('[Wiiload] Connection failed: ${e.message}');
      return false;
    } on TimeoutException {
      AppLogger.instance.warning('[Wiiload] Connection timeout');
      return false;
    } catch (e) {
      AppLogger.instance.error('[Wiiload] Connection test failed', error: e);
      return false;
    } finally {
      await socket?.close();
    }
  }

  /// Get list of .dol files in a directory
  Future<List<String>> findDolFiles(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) return [];

      final dolFiles = <String>[];
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.dol')) {
          dolFiles.add(entity.path);
        }
      }
      AppLogger.instance.info(
          '[Wiiload] Found ${dolFiles.length} DOL files in $directoryPath');
      return dolFiles;
    } catch (e) {
      AppLogger.instance.error('[Wiiload] Error finding DOL files', error: e);
      return [];
    }
  }
}
