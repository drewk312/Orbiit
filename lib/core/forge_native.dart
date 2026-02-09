import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'native_library_loader.dart';

/// Singleton wrapper for the Native Forge Core library.
/// Ensures the DynamicLibrary is only loaded once per application session.
class ForgeNative {
  static ForgeNative? _instance;
  static DynamicLibrary? _lib;
  static String? _loadedPath;

  /// Get the singleton instance
  static ForgeNative get instance {
    _instance ??= ForgeNative._();
    return _instance!;
  }

  /// Private constructor
  ForgeNative._() {
    _init();
  }

  void _init() {
    if (_lib != null) return; // Already loaded

    final libName = _getLibraryName();
    final path = NativeLibraryLoader.findNativeLibrary(libName);

    if (path != null) {
      try {
        _lib = DynamicLibrary.open(path);
        _loadedPath = path;
        debugPrint('[ForgeNative] Loaded native library from: $path');
      } catch (e) {
        debugPrint('[ForgeNative] Failed to load native library: $e');
      }
    } else {
      debugPrint('[ForgeNative] Native library not found: $libName');
    }
  }

  /// The loaded dynamic library, or null if not found
  DynamicLibrary? get lib => _lib;

  /// Whether the library is currently loaded
  bool get isLoaded => _lib != null;

  /// Path to the loaded library
  String? get loadedPath => _loadedPath;

  String _getLibraryName() {
    if (Platform.isWindows) return 'forge_core.dll';
    if (Platform.isLinux) return 'libforge_core.so';
    if (Platform.isMacOS) return 'libforge_core.dylib';
    throw UnsupportedError('Platform not supported for native library');
  }
}
