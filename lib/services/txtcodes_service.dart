import 'dart:io';
import 'dart:convert';

class TxtCodesResult {
  final String status;
  final String? codes;
  TxtCodesResult(this.status, this.codes);
}

class TxtCodesService {
  static Future<TxtCodesResult> fetchCodes(String gameId) async {
    final id = gameId.toUpperCase().trim();

    // Try codes.rc24.xyz first
    final rc24Url = Uri.parse('https://codes.rc24.xyz/txt.php?txt=$id');
    final rc24 = await _get(rc24Url);
    if (_isValidTxt(rc24)) {
      return TxtCodesResult('Loaded from codes.rc24.xyz', rc24);
    }

    // Try web archive of geckocodes.org (raw)
    final wbUrl = Uri.parse(
        'https://web.archive.org/web/20210501000000id_/http://geckocodes.org/txt.php?txt=$id');
    final wb = await _get(wbUrl);
    if (_isValidTxt(wb)) {
      return TxtCodesResult('Loaded from geckocodes.org (Archive)', wb);
    }

    // Try gamehacking.org
    // Format: https://gamehacking.org/export/gh/wii/$id
    // But direct TXT might be tricky. Let's try the direct Gecko export if possible.
    // Fallback to simple txt endpoint if known.
    final ghUrl = Uri.parse('https://gamehacking.org/$id.txt');
    final gh = await _get(ghUrl);
    if (_isValidTxt(gh)) {
      return TxtCodesResult('Loaded from gamehacking.org', gh);
    }

    return TxtCodesResult('No codes found for $id', null);
  }

  static bool _isValidTxt(String? s) {
    if (s == null || s.trim().isEmpty) return false;
    final lower = s.toLowerCase();
    if (lower.contains('<html') || lower.contains('<!doctype')) return false;
    return s.trim().isNotEmpty;
  }

  static Future<String?> _get(Uri url) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      client.userAgent =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
      final req = await client.getUrl(url);
      final resp = await req.close();
      if (resp.statusCode == 200) {
        return await resp.transform(utf8.decoder).join();
      }
    } catch (_) {}
    return null;
  }
}
