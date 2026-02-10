import 'package:flutter_test/flutter_test.dart';
import 'package:wiigc_fusion/models/disc_metadata.dart';

void main() {
  group('DiscMetadata Tests', () {
    test('Region Detection Logic via Factory', () {
      final usaGame = DiscMetadata.fromScannedGame(
        path: '/games/mario.wbfs',
        fileName: 'mario.wbfs',
        title: 'Mario Kart Wii',
        gameId: 'RMCE01',
        platform: 'Wii',
        sizeBytes: 1000,
        extension: '.wbfs',
      );
      expect(usaGame.region, RegionCode.usa);
      expect(usaGame.displayRegion, 'USA (NTSC-U)');

      final palGame = DiscMetadata.fromScannedGame(
        path: '/games/mario_pal.wbfs',
        fileName: 'mario_pal.wbfs',
        title: 'Mario Kart Wii',
        gameId: 'RMCP01',
        platform: 'Wii',
        sizeBytes: 1000,
        extension: '.wbfs',
      );
      expect(palGame.region, RegionCode.europe);
      expect(palGame.displayRegion, 'Europe (PAL)');

      final japGame = DiscMetadata.fromScannedGame(
        path: '/games/mario_jap.wbfs',
        fileName: 'mario_jap.wbfs',
        title: 'Mario Kart Wii',
        gameId: 'RMCJ01',
        platform: 'Wii',
        sizeBytes: 1000,
        extension: '.wbfs',
      );
      expect(japGame.region, RegionCode.japan);

      final korGame = DiscMetadata.fromScannedGame(
        path: '/games/mario_kor.wbfs',
        fileName: 'mario_kor.wbfs',
        title: 'Mario Kart Wii',
        gameId: 'RMCK01',
        platform: 'Wii',
        sizeBytes: 1000,
        extension: '.wbfs',
      );
      expect(korGame.region, RegionCode.korea);
    });

    test('Console Detection Logic via Factory', () {
      // GameCube via Platform String
      final gcGame = DiscMetadata.fromScannedGame(
        path: '/games/melee.iso',
        fileName: 'melee.iso',
        title: 'Super Smash Bros. Melee',
        gameId: 'GALE01',
        platform: 'GameCube',
        sizeBytes: 1000,
        extension: '.iso',
      );
      expect(gcGame.console, ConsoleType.gamecube);
      expect(gcGame.isGameCube, true);
      expect(gcGame.isWii, false);

      // Wii via Platform String
      final wiiGame = DiscMetadata.fromScannedGame(
        path: '/games/brawl.iso',
        fileName: 'brawl.iso',
        title: 'Super Smash Bros. Brawl',
        gameId: 'RSBE01',
        platform: 'Wii',
        sizeBytes: 1000,
        extension: '.iso',
      );
      expect(wiiGame.console, ConsoleType.wii);
      expect(wiiGame.isWii, true);
    });

    test('Format Detection Logic via Factory', () {
      final wbfs = DiscMetadata.fromScannedGame(
          path: 'test.wbfs',
          fileName: 'test.wbfs',
          title: 'T',
          sizeBytes: 0,
          platform: 'Wii',
          extension: '.wbfs');
      expect(wbfs.format, DiscFormat.wbfs);

      final iso = DiscMetadata.fromScannedGame(
          path: 'test.iso',
          fileName: 'test.iso',
          title: 'T',
          sizeBytes: 0,
          platform: 'Wii',
          extension: '.iso');
      expect(iso.format, DiscFormat.iso);

      final rvz = DiscMetadata.fromScannedGame(
          path: 'test.rvz',
          fileName: 'test.rvz',
          title: 'T',
          sizeBytes: 0,
          platform: 'Wii',
          extension: '.rvz');
      expect(rvz.format, DiscFormat.rvz);
    });

    test('Cover URL Generation', () {
      final game = DiscMetadata(
        filePath: 'path',
        fileName: 'name',
        fileSize: 0,
        gameId: 'RMCE01',
        embeddedTitle: 'Mario',
        console: ConsoleType.wii,
        region: RegionCode.usa,
        format: DiscFormat.wbfs,
      );

      expect(
          game.coverUrl, 'https://art.gametdb.com/wii/cover3D/US/RMCE01.png');
      expect(game.fullCoverUrl,
          'https://art.gametdb.com/wii/coverfull/US/RMCE01.png');
      expect(game.discUrl, 'https://art.gametdb.com/wii/disc/US/RMCE01.png');
    });

    test('Size Formatting', () {
      final gameParams = {
        'filePath': 'path',
        'fileName': 'name',
        'gameId': 'ID',
        'embeddedTitle': 'T',
        'console': ConsoleType.wii,
        'region': RegionCode.usa,
        'format': DiscFormat.iso
      };

      final small = DiscMetadata(
          fileSize: 500,
          filePath: 'path',
          fileName: 'name',
          gameId: 'ID',
          embeddedTitle: 'T',
          console: ConsoleType.wii,
          region: RegionCode.usa,
          format: DiscFormat.iso);
      expect(small.formattedFileSize, '500 B');

      final kb = DiscMetadata(
          fileSize: 1024 * 5,
          filePath: 'path',
          fileName: 'name',
          gameId: 'ID',
          embeddedTitle: 'T',
          console: ConsoleType.wii,
          region: RegionCode.usa,
          format: DiscFormat.iso);
      expect(kb.formattedFileSize, '5.0 KB');

      final mb = DiscMetadata(
          fileSize: 1024 * 1024 * 5,
          filePath: 'path',
          fileName: 'name',
          gameId: 'ID',
          embeddedTitle: 'T',
          console: ConsoleType.wii,
          region: RegionCode.usa,
          format: DiscFormat.iso);
      expect(mb.formattedFileSize, '5.0 MB');

      final gb = DiscMetadata(
          fileSize: 1024 * 1024 * 1024 * 2,
          filePath: 'path',
          fileName: 'name',
          gameId: 'ID',
          embeddedTitle: 'T',
          console: ConsoleType.wii,
          region: RegionCode.usa,
          format: DiscFormat.iso);
      expect(gb.formattedFileSize, '2.00 GB');
    });
  });
}
