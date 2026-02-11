import 'package:flutter/foundation.dart';

import '../core/app_logger.dart';
import '../services/wiiload_service.dart';

/// WiiloadProvider - Manages state for Wiiload network operations
class WiiloadProvider extends ChangeNotifier {
  final WiiloadService _wiiloadService = WiiloadService();

  bool _isLoading = false;
  String _error = '';
  String _wiiIp = '';
  bool _isConnected = false;

  // Getters
  bool get isLoading => _isLoading;
  String get error => _error;
  String get wiiIp => _wiiIp;
  bool get isConnected => _isConnected;

  /// Set Wii IP address
  void setWiiIp(String ip) {
    _wiiIp = ip.trim();
    _error = '';
    notifyListeners();
  }

  /// Test connection to Wii
  Future<bool> testConnection() async {
    if (_wiiIp.isEmpty) {
      _error = 'Please enter Wii IP address';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final success = await _wiiloadService.testConnection(_wiiIp);
      _isConnected = success;
      if (!success) {
        _error = 'Failed to connect to Wii at $_wiiIp';
      }
      return success;
    } catch (e) {
      _error = 'Connection error: $e';
      _isConnected = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send DOL file to Wii
  Future<bool> sendDolFile(String dolPath, {String? arguments}) async {
    if (_wiiIp.isEmpty) {
      _error = 'Please enter Wii IP address';
      notifyListeners();
      return false;
    }

    if (!_isConnected) {
      final connected = await testConnection();
      if (!connected) return false;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final success = await _wiiloadService.sendDolFile(_wiiIp, dolPath,
          arguments: arguments);
      if (!success) {
        _error = 'Failed to send DOL file to Wii';
      }
      return success;
    } catch (e) {
      _error = 'Send error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Find DOL files in a directory
  Future<List<String>> findDolFiles(String directoryPath) async {
    try {
      return await _wiiloadService.findDolFiles(directoryPath);
    } catch (e) {
      AppLogger.instance
          .error('[WiiloadProvider] Error finding DOL files', error: e);
      return [];
    }
  }

  /// Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  /// Reset connection state
  void resetConnection() {
    _isConnected = false;
    _error = '';
    notifyListeners();
  }
}
