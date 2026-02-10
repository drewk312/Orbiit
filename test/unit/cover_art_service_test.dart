import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wiigc_fusion/services/cover_art/cover_art_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Register basic mock for path_provider since CoverArtService (via config) usually needs paths.
  // Although the test below mainly tests the static method which doesn't need it.
  const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
  
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
  });

  group('CoverArtService Logic', () {
    test('getRegionFromGameId parses regions correctly', () {
      // US Cases
      expect(CoverArtService.getRegionFromGameId('RMCE01'), 'US');
      expect(CoverArtService.getRegionFromGameId('RMCN01'), 'US');
      
      // Japan Cases
      expect(CoverArtService.getRegionFromGameId('RMCJ01'), 'JA');
      
      // Korea Cases
      expect(CoverArtService.getRegionFromGameId('RMCK01'), 'KO');
      expect(CoverArtService.getRegionFromGameId('RMCQ01'), 'KO');
      expect(CoverArtService.getRegionFromGameId('RMCT01'), 'KO');
      
      // Russia (Custom mapping in logic)
      expect(CoverArtService.getRegionFromGameId('RMCR01'), 'RU');
      
      // Taiwan (Custom mapping in logic)
      expect(CoverArtService.getRegionFromGameId('RMCW01'), 'ZH');
      
      // Europe/Defaults
      expect(CoverArtService.getRegionFromGameId('RMCP01'), 'EN');
      expect(CoverArtService.getRegionFromGameId('RMCX01'), 'EN');
      
      // Short IDs
      expect(CoverArtService.getRegionFromGameId('ABC'), 'EN');
    });
  });
}
