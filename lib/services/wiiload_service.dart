import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

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
      debugPrint(
          '[Wiiload] Sending DOL: $dolPath → $wiiIp:$wiiloadPort');

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
      ByteData.view(lengthBytes.buffer).setUint32(0, dolBytes.length, Endian.big);

      socket.add(lengthBytes);
      socket.add(dolBytes);
      await socket.flush();

      debugPrint('[Wiiload] Sent ${dolBytes.length} bytes successfully');
      return true;
    } on SocketException catch (e) {
      debugPrint('[Wiiload] Socket error: $e');
      return false;
    } on TimeoutException catch (e) {
      debugPrint('[Wiiload] Timeout: $e');
      return false;
    } catch (e) {
      debugPrint('[Wiiload] Failed: $e');
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
      debugPrint('[Wiiload] Connection to $wiiIp:$wiiloadPort OK');
      return true;
    } on SocketException catch (e) {
      debugPrint('[Wiiload] Connection failed: $e');
      return false;
    } on TimeoutException {
      debugPrint('[Wiiload] Connection timeout');
      return false;
    } catch (e) {
      debugPrint('[Wiiload] Connection test failed: $e');
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
      debugPrint('[Wiiload] Found ${dolFiles.length} DOL files in $directoryPath');
      return dolFiles;
    } catch (e) {
      debugPrint('[Wiiload] Error finding DOL files: $e');
      return [];
    }
  }
}
