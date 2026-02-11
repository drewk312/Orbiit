import 'dart:io';
import 'package:path/path.dart' as path;
import '../core/app_logger.dart';

/// Native library loader with fallback support
class NativeLibraryLoader {
  static final AppLogger _logger = AppLogger.instance;

  /// Try to load the native library from multiple possible locations
  static String? findNativeLibrary(String libraryName) {
    _logger.info('Searching for native library: $libraryName');

    // Possible locations to check
    final possiblePaths = <String>[];

    if (Platform.isWindows) {
      // Check current directory
      possiblePaths.add(libraryName);

      // Check build directories
      possiblePaths
          .add(path.join('forge_core', 'build', 'Release', libraryName));
      possiblePaths.add(path.join('forge_core', 'build', 'Debug', libraryName));
      possiblePaths.add(path.join('forge_core', 'build', libraryName));

      // Check common installation paths
      possiblePaths
          .add(path.join('C:\\Program Files\\WiiGCFusion', libraryName));
      possiblePaths
          .add(path.join('C:\\Program Files (x86)\\WiiGCFusion', libraryName));

      // Check relative to executable
      final executableDir = path.dirname(Platform.resolvedExecutable);
      possiblePaths.add(path.join(executableDir, libraryName));
      possiblePaths.add(path.join(executableDir, 'data', libraryName));
      possiblePaths.add(path.join(executableDir, 'forge_core', libraryName));
    } else if (Platform.isLinux) {
      possiblePaths.add(path.join('/usr/local/lib', libraryName));
      possiblePaths.add(path.join('/usr/lib', libraryName));
      possiblePaths.add(path.join(Directory.current.path, libraryName));
      possiblePaths.add(path.join(Directory.current.path, 'lib', libraryName));
    } else if (Platform.isMacOS) {
      possiblePaths.add(path.join('/usr/local/lib', libraryName));
      possiblePaths.add(path.join(Directory.current.path, libraryName));
      possiblePaths.add(path.join(Directory.current.path, 'lib', libraryName));
    }

    // Check each path
    for (final testPath in possiblePaths) {
      final file = File(testPath);
      if (file.existsSync()) {
        final absPath = file.absolute.path;
        _logger.info('Found native library at: $absPath');
        return absPath;
      }
    }

    _logger
        .warning('Native library not found in any of the expected locations');
    _logger.info('Searched locations: ${possiblePaths.join(', ')}');
    return null;
  }

  /// Check if native library is available
  static bool isNativeLibraryAvailable(String libraryName) {
    return findNativeLibrary(libraryName) != null;
  }

  /// Get instructions for installing the native library
  static String getInstallationInstructions() {
    if (Platform.isWindows) {
      return '''
Native library (forge_core.dll) not found!

To install:
1. Download the forge_core library from the releases page
2. Place forge_core.dll in one of these locations:
   - Same folder as this executable
   - forge_core/build/Release/
   - C:\\Program Files\\WiiGCFusion\\

The app will work in demo mode without the library, but some features will be limited.''';
    } else if (Platform.isLinux) {
      return '''
Native library (libforge_core.so) not found!

To install:
1. Build or download the forge_core library
2. Place libforge_core.so in one of these locations:
   - /usr/local/lib/
   - /usr/lib/
   - Same folder as this executable

The app will work in demo mode without the library, but some features will be limited.''';
    } else if (Platform.isMacOS) {
      return '''
Native library (libforge_core.dylib) not found!

To install:
1. Build or download the forge_core library
2. Place libforge_core.dylib in one of these locations:
   - /usr/local/lib/
   - Same folder as this executable

The app will work in demo mode without the library, but some features will be limited.''';
    }
    return 'Native library not found. Please install the forge_core library for your platform.';
  }
}
