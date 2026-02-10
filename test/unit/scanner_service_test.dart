import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:wiigc_fusion/services/scanner_service.dart';
import 'package:wiigc_fusion/ffi/forge_bridge.dart';

// Fake ForgeBridge that forces Mock Mode
class FakeForgeBridge implements ForgeBridge {
  @override
  bool get isMockMode => true;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return dummy values or throw for unimplemented methods
    return null;
  }
}

void main() {
  group('ScannerService Constants', () {
    test('gameExtensions contains common Wii/GC formats', () {
      expect(ScannerService.gameExtensions, contains('.wbfs'));
      expect(ScannerService.gameExtensions, contains('.iso'));
      expect(ScannerService.gameExtensions, contains('.rvz'));
      expect(ScannerService.gameExtensions,
          contains('.nkit.iso')); // Double extension case
      expect(ScannerService.gameExtensions, contains('.gcm'));
    });

    test('minGameSize is reasonable', () {
      expect(ScannerService.minGameSize, 10 * 1024 * 1024); // 10 MB
    });
  });

  group('ScannerService Logic (Dart Fallback)', () {
    late Directory tempDir;
    late ScannerService scanner;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('orbiit_test_');
      scanner = ScannerService(forge: FakeForgeBridge());
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<void> createValidGameFile(String filename) async {
      final file = File(p.join(tempDir.path, filename));
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      final raf = await file.open(mode: FileMode.write);
      // Create a >10MB file by seeking and writing a byte
      await raf.setPosition(10 * 1024 * 1024 + 100);
      await raf.writeByte(0);
      await raf.close();
    }

    Future<void> createSmallGameFile(String filename) async {
      final file = File(p.join(tempDir.path, filename));
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await file.writeAsBytes([0, 1, 2, 3]);
    }

    test('Identifies valid game files in Dart mode', () async {
      await createValidGameFile('Mario Kart Wii [RMCE01].wbfs');

      final results = await scanner.scanDirectory(tempDir.path);

      expect(results.length, 1);
      expect(results.first.gameId, 'RMCE01');
      expect(results.first.fileName, 'Mario Kart Wii [RMCE01].wbfs');
      expect(results.first.extension, '.wbfs');
    });

    test('Skips small files', () async {
      await createSmallGameFile('Tiny Game [RMCE01].iso');

      final results = await scanner.scanDirectory(tempDir.path);

      expect(results.isEmpty, true);
    });

    test('Extracts ID from parent folder', () async {
      var subPath = p.join('Smash Bros Melee [GALE01]', 'game.iso');
      await createValidGameFile(subPath);

      final results = await scanner.scanDirectory(tempDir.path);

      expect(results.length, 1);
      expect(results.first.gameId, 'GALE01');
    });
  });
}
