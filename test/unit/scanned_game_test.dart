import 'package:flutter_test/flutter_test.dart';
import 'package:wiigc_fusion/models/disc_metadata.dart';
import 'package:wiigc_fusion/services/scanner_service.dart';

void main() {
  group('ScannedGame Model', () {
    test('Region Getter', () {
      final usa = ScannedGame(
          path: '',
          fileName: '',
          title: '',
          sizeBytes: 0,
          extension: '',
          platform: '',
          gameId: 'RMCE01');
      expect(usa.region, 'US');

      final pal = ScannedGame(
          path: '',
          fileName: '',
          title: '',
          sizeBytes: 0,
          extension: '',
          platform: '',
          gameId: 'RMCP01');
      expect(pal.region, 'EN');

      final unknown = ScannedGame(
          path: '',
          fileName: '',
          title: '',
          sizeBytes: 0,
          extension: '',
          platform: '',
          gameId: 'ABC' // Too short
          );
      expect(unknown.region, null);
    });

    test('toDiscMetadata conversion', () {
      final game = ScannedGame(
        path: '/path/game.wbfs',
        fileName: 'game.wbfs',
        title: 'Title',
        gameId: 'RMCE01',
        platform: 'Wii',
        sizeBytes: 1000,
        extension: '.wbfs',
        format: DiscFormat.wbfs,
        discNumber: 1,
        discVersion: 1,
      );

      final meta = game.toDiscMetadata();

      expect(meta.filePath, '/path/game.wbfs');
      expect(meta.gameId, 'RMCE01');
      expect(meta.region, RegionCode.usa);
      expect(meta.format, DiscFormat.wbfs);
      expect(meta.discNumber, 1);
    });

    test('isValid check', () {
      // Too small
      final small = ScannedGame(
          path: '',
          fileName: '',
          title: 'Title',
          sizeBytes: 100,
          extension: '',
          platform: '',
          gameId: 'ID');
      expect(small.isValid,
          false); // Assuming ScannedGame.isValid checks min size (it does)

      // Invalid title
      final junk = ScannedGame(
          path: '',
          fileName: '',
          title: '<html>',
          sizeBytes: 100000000,
          extension: '',
          platform: '',
          gameId: 'ID');
      expect(junk.isValid, false);

      // Valid
      final valid = ScannedGame(
          path: '',
          fileName: '',
          title: 'Valid Title',
          sizeBytes: 10 * 1024 * 1024 + 1,
          extension: '',
          platform: '',
          gameId: 'ID');
      expect(valid.isValid, true);
    });
  });
}
