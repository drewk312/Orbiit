import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wiigc_fusion/services/library_state_service.dart';
import 'package:wiigc_fusion/services/scanner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock path_provider to prevent "MissingPluginException" in logs
  const MethodChannel channel =
      MethodChannel('plugins.flutter.io/path_provider');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
  });

  group('LibraryStateService', () {
    test('Initial state is clear', () {
      final service = LibraryStateService();
      // Ensure specific initial state if singleton is already shared
      // In a real generic app we might need to reset it,
      // but here we can just check properties.
      // NOTE: Singleton persists across tests in same group?
      // Flutter test isolates should reset it usually,
      // but let's be safe and clear strictly in setUp if needed.
    });

    test('Deduplicates games by ID', () {
      final service = LibraryStateService();

      final game1 = ScannedGame(
          path: '/a',
          fileName: 'a',
          title: 'Game A',
          platform: 'Wii',
          sizeBytes: 100,
          extension: '.iso',
          gameId: 'RMCE01');

      final game2 = ScannedGame(
          path: '/b',
          fileName: 'b',
          title: 'Game A Duplicate',
          platform: 'Wii',
          sizeBytes: 100,
          extension: '.iso',
          gameId: 'RMCE01' // Same ID
          );

      final game3 = ScannedGame(
          path: '/c',
          fileName: 'c',
          title: 'Game B',
          platform: 'Wii',
          sizeBytes: 100,
          extension: '.iso',
          gameId: 'GALE01');

      service.updateLibrary([game1, game2, game3], '/test/path');

      expect(service.games.length, 2);
      expect(service.games.any((g) => g.gameId == 'RMCE01'), true);
      expect(service.games.any((g) => g.gameId == 'GALE01'), true);
    });

    test('Handles games without IDs', () {
      final service = LibraryStateService();

      final noId1 = ScannedGame(
          path: '/a',
          fileName: 'a',
          title: 'No ID 1',
          platform: 'Wii',
          sizeBytes: 100,
          extension: '.iso',
          gameId: null);

      final noId2 = ScannedGame(
          path: '/b',
          fileName: 'b',
          title: 'No ID 2',
          platform: 'Wii',
          sizeBytes: 100,
          extension: '.iso',
          gameId: '');

      service.updateLibrary([noId1, noId2], '/test/path');

      expect(service.games.length, 2);
    });

    test('Validates Health Calculation', () {
      final service = LibraryStateService();

      final g1 = ScannedGame(
          path: '',
          fileName: '',
          title: '',
          platform: '',
          sizeBytes: 0,
          extension: '',
          health: 100);
      final g2 = ScannedGame(
          path: '',
          fileName: '',
          title: '',
          platform: '',
          sizeBytes: 0,
          extension: '',
          health: 50);

      service.updateLibrary([g1, g2], '/');

      expect(service.averageHealth, 75.0);
    });

    test('Clear Library works', () {
      final service = LibraryStateService();
      final g1 = ScannedGame(
          path: '',
          fileName: '',
          title: '',
          platform: '',
          sizeBytes: 0,
          extension: '',
          health: 100);
      service.updateLibrary([g1], '/');
      expect(service.hasGames, true);

      service.clearLibrary();
      expect(service.hasGames, false);
      expect(service.games.isEmpty, true);
    });
  });
}
