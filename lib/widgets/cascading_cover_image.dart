import 'dart:io';
import 'package:flutter/material.dart';

/// A widget that tries a sequence of URLs for cover art.
/// Typically: 3D Cover -> 2D Cover -> Disc Image -> Libretro Hunter -> Fallback Widget
class CascadingCoverImage extends StatefulWidget {
  final String primaryUrl;
  final String? gameId;
  final String platform; // 'wii', 'gc', 'n64', 'snes' etc
  final String? title; // Added for name-based lookups
  final BoxFit fit;
  final WidgetBuilder fallbackBuilder;
  final Color? color;
  final BlendMode? colorBlendMode;

  const CascadingCoverImage({
    required this.primaryUrl,
    required this.platform,
    required this.fallbackBuilder,
    super.key,
    this.gameId,
    this.title,
    this.fit = BoxFit.cover,
    this.color,
    this.colorBlendMode,
  });

  @override
  State<CascadingCoverImage> createState() => _CascadingCoverImageState();
}

class _CascadingCoverImageState extends State<CascadingCoverImage> {
  late String _currentUrl;
  int _retryStage = 0; // 0=Primary, 1=2D, 2=Disc, 3=Libretro(Hunt), 4=Fallback
  bool _isHunting = false;
  bool _isChecking = false; // true while we HEAD-check a URL to avoid 404 spam

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.primaryUrl;
    // Verify primary URL first to avoid 404 console spam
    if (_currentUrl.startsWith('http')) {
      _isChecking = true;
      _verifyPrimary();
    }
  }

  Future<void> _verifyPrimary() async {
    final exists = await _checkUrl(_currentUrl);
    if (!mounted) return;

    if (exists) {
      setState(() => _isChecking = false);
    } else {
      // Primary failed, move to next stage immediately
      _advanceStage();
    }
  }

  @override
  void didUpdateWidget(CascadingCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryUrl != widget.primaryUrl) {
      _currentUrl = widget.primaryUrl;
      _retryStage = 0;
      _isHunting = false;
      if (_currentUrl.startsWith('http')) {
        _isChecking = true;
        _verifyPrimary();
      } else {
        _isChecking = false;
      }
    }
  }

  Future<void> _advanceStage() async {
    if (!mounted) return;

    // Move to next stage
    setState(() {
      _retryStage++;
      _isHunting = false;
      _isChecking = false;
    });

    final gameTDBPlatform = _getGameTDBPlatform();
    final hasGameTDBSupport = gameTDBPlatform.isNotEmpty;

    // Stage 1: GameTDB 2D (ID-based) — do a HEAD check first to avoid 404 noise
    if (_retryStage == 1) {
      // Skip GameTDB for platforms that don't support it (GBA, N64, SNES, etc.)
      if (!hasGameTDBSupport ||
          widget.gameId == null ||
          !_isValidGameId(widget.gameId!)) {
        return _advanceStage();
      }
      final url =
          'https://art.gametdb.com/$gameTDBPlatform/cover/US/${widget.gameId}.png';
      setState(() => _isChecking = true);
      final exists = await _checkUrl(url);
      if (!mounted) return;
      if (exists) {
        setState(() {
          _currentUrl = url;
          _isChecking = false;
        });
        return;
      }
      setState(() => _isChecking = false);
      // Not found — advance immediately
      return _advanceStage();
    }

    // Stage 2: GameTDB Disc (ID-based)
    if (_retryStage == 2) {
      // Skip GameTDB for platforms that don't support it
      if (!hasGameTDBSupport ||
          widget.gameId == null ||
          !_isValidGameId(widget.gameId!)) {
        return _advanceStage();
      }
      final url =
          'https://art.gametdb.com/$gameTDBPlatform/disc/US/${widget.gameId}.png';
      setState(() => _isChecking = true);
      final exists = await _checkUrl(url);
      if (!mounted) return;
      if (exists) {
        setState(() {
          _currentUrl = url;
          _isChecking = false;
        });
        return;
      }
      setState(() => _isChecking = false);
      return _advanceStage();
    }

    // Stage 3: Libretro Thumbnails (Name-based Hunter)
    if (_retryStage == 3 && widget.title != null) {
      _isHunting = true;
      _performLibretroHunt();
      return;
    }
  }

  /// Silently hunts for a valid Libretro URL to avoid 404 console spam
  Future<void> _performLibretroHunt() async {
    final system = _getLibretroSystem();
    final rawTitle = widget.title!;

    // 1. Clean Title (Strip Region/Disc info)
    // "Super Mario 64 (USA)" -> "Super Mario 64"
    String baseTitle = rawTitle;
    if (baseTitle.contains('(')) {
      baseTitle = baseTitle.split('(')[0];
    }
    baseTitle = baseTitle.trim();

    // 2. Sanitize for Filename (Relaxed)
    // Keep letters, numbers, spaces, dots, commas, apostrophes, ampersand, exclamation
    // Use a raw double-quoted string so single quotes may appear unescaped
    final safeTitle =
        baseTitle.replaceAll(RegExp(r"[^\w\s\-\.\',&!]"), '').trim();

    // 3. Generate Candidates
    final candidates = <String>{}; // Set to avoid duplicates

    // Helper to add variations
    void addVariations(String t) {
      candidates.add(t);
      candidates.add('$t (USA)');
      candidates.add('$t (USA, Europe)');
      candidates.add('$t (Europe)');
      candidates.add('$t (Japan)');
      candidates.add('$t (World)');
    }

    addVariations(safeTitle);

    // Swap "The" (Common mismatch source)
    // "The Legend of Zelda" <-> "Legend of Zelda, The"
    if (safeTitle.startsWith('The ')) {
      addVariations('${safeTitle.substring(4)}, The');
    } else if (safeTitle.endsWith(', The')) {
      addVariations('The ${safeTitle.substring(0, safeTitle.length - 5)}');
    }

    // Special handling for Pokemon games (common naming issue)
    // "Pokemon Emerald" -> "Pokemon - Emerald Version"
    if (safeTitle.toLowerCase().startsWith('pokemon ')) {
      final pokeName = safeTitle.substring(8); // Remove "Pokemon "
      addVariations('Pokemon - $pokeName Version');
      addVariations('Pokemon - ${pokeName}Version'); // No space
    }

    // Handle "FireRed" / "LeafGreen" / etc.
    if (safeTitle.toLowerCase().contains('firered')) {
      addVariations('Pokemon - Fire Red Version');
      addVariations('Pokemon - FireRed Version');
    }
    if (safeTitle.toLowerCase().contains('leafgreen')) {
      addVariations('Pokemon - Leaf Green Version');
      addVariations('Pokemon - LeafGreen Version');
    }

    // Handle Zelda games
    if (safeTitle.toLowerCase().contains('zelda')) {
      // Try with "Legend of Zelda, The" prefix
      if (!safeTitle.startsWith('The ')) {
        addVariations('The $safeTitle');
      }
      // Minish Cap variations
      if (safeTitle.toLowerCase().contains('minish')) {
        addVariations('Legend of Zelda, The - The Minish Cap');
        addVariations('Legend of Zelda, The - The Minish Cap (USA)');
      }
    }

    // Handle Metroid games
    if (safeTitle.toLowerCase().contains('metroid')) {
      addVariations('Metroid - $safeTitle');
    }

    // 4. Check Existence (Silent HEAD request)
    for (final filename in candidates) {
      if (!mounted) return;

      // Encode for URL (GitHub requires %20 for space)
      final urlName = Uri.encodeComponent(filename).replaceAll('%2B', '+');
      final url =
          'https://raw.githubusercontent.com/libretro-thumbnails/$system/master/Named_Boxarts/$urlName.png';

      if (await _checkUrl(url)) {
        if (!mounted) return;
        setState(() {
          _currentUrl = url;
          _isHunting = false;
        });
        return; // Success!
      }
    }

    // 5. If all fail, move to Fallback
    if (mounted) {
      setState(() {
        _retryStage = 4; // Force fallback
        _isHunting = false;
      });
    }
  }

  // Shared client to prevent socket exhaustion (Semaphore Timeout)
  static final HttpClient _sharedClient = HttpClient()
    ..userAgent = 'Fusion/1.0'
    ..connectionTimeout = const Duration(seconds: 4)
    ..idleTimeout = const Duration(seconds: 15);

  Future<bool> _checkUrl(String url) async {
    // Platform check: On Web this falls back to simple true (can't HEAD cross-origin easily without CORS)
    // But since this is a Desktop app, we use dart:io
    try {
      final req = await _sharedClient.headUrl(Uri.parse(url));
      final res = await req.close();
      // We accept 200 OK.
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Define max stage clearly (0, 1, 2, 3 used. 4 is fallback)
  bool get _isExhausted => _retryStage > 3;

  @override
  Widget build(BuildContext context) {
    // If Hunting, show placeholder (prevents 404 spam)
    if (_isHunting) {
      return Container(color: widget.color ?? const Color(0xFF202020));
    }

    // If we're actively checking a URL, show placeholder to avoid firing a NetworkImage immediately
    if (_isChecking) {
      return Container(color: widget.color ?? const Color(0xFF151515));
    }

    // If exhausted, show fallback
    if (_isExhausted) {
      return widget.fallbackBuilder(context);
    }

    // Skip empty GameTDB stages immediately
    if ((_retryStage == 1 || _retryStage == 2) && widget.gameId == null) {
      _advanceStage();
      return Container();
    }

    // Skip Libretro stage if title logic invalid (shouldn't happen with _advanceStage logic but safe guard)
    if (_retryStage == 3 && widget.title == null) {
      _advanceStage();
      return Container();
    }

    // Check for local file
    final isLocal = !_currentUrl.startsWith('http');
    if (isLocal) {
      final file = File(_currentUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: widget.fit,
          color: widget.color,
          colorBlendMode: widget.colorBlendMode,
          errorBuilder: (context, error, stackTrace) {
            // If file corrupt, advance
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _advanceStage());
            return Container(color: widget.color ?? const Color(0xFF151515));
          },
        );
      } else {
        // File doesn't exist, advance immediately
        WidgetsBinding.instance.addPostFrameCallback((_) => _advanceStage());
        return Container(color: widget.color ?? const Color(0xFF151515));
      }
    }

    return Image.network(
      _currentUrl,
      fit: widget.fit,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      errorBuilder: (context, error, stackTrace) {
        // Schedule state update to avoid build collisions
        WidgetsBinding.instance.addPostFrameCallback((_) => _advanceStage());
        // Return placeholder while retrying
        return Container(color: widget.color ?? const Color(0xFF151515));
      },
    );
  }

  String _getGameTDBPlatform() {
    final p = widget.platform.toLowerCase();
    // Wii U must come before Wii check
    if (p.contains('wii u') || p == 'wiiu') return 'wiiu';
    if (p.contains('wii')) return 'wii';
    if (p.contains('gamecube') || p == 'gc') {
      return 'wii'; // GameTDB stores GC under Wii
    }
    if (p.contains('3ds')) return '3ds';
    if (p.contains('ds')) return 'ds';
    // GBA/SNES/N64 etc don't have GameTDB support - skip to Libretro
    if (p.contains('gba') || p.contains('game boy advance')) return '';
    if (p.contains('n64') || p.contains('nintendo 64')) return '';
    if (p.contains('snes') || p.contains('super nintendo')) return '';
    if (p.contains('nes')) return '';
    if (p.contains('genesis') || p.contains('mega drive')) return '';
    return 'wii'; // Default fallback
  }

  bool _isValidGameId(String id) {
    // GameTDB uses alphanumeric IDs (4-6 chars), e.g., RMGE01, GALE01
    // GBA uses 4-char IDs like BPEE, BPRE
    return RegExp(r'^[A-Z0-9]{4,6}$').hasMatch(id.trim());
  }

  String _getLibretroSystem() {
    final p = widget.platform.toLowerCase();
    // Wii U must come before Wii check
    if (p.contains('wii u') || p == 'wiiu') return 'Nintendo_-_Wii_U';
    if (p.contains('n64') || p.contains('nintendo 64')) {
      return 'Nintendo_-_Nintendo_64';
    }
    if (p.contains('gamecube') || p == 'gc') return 'Nintendo_-_GameCube';
    if (p.contains('wii')) return 'Nintendo_-_Wii';
    if (p.contains('snes') || p.contains('super nintendo')) {
      return 'Nintendo_-_Super_Nintendo_Entertainment_System';
    }
    if (p.contains('gba') || p.contains('advance')) {
      return 'Nintendo_-_Game_Boy_Advance';
    }
    if (p.contains('ds')) return 'Nintendo_-_Nintendo_DS';
    if (p.contains('genesis') || p.contains('mega drive')) {
      return 'Sega_-_Mega_Drive_-_Genesis';
    }
    if (p.contains('nes') || p.contains('entertainment system')) {
      return 'Nintendo_-_Nintendo_Entertainment_System';
    }

    // Default fallback to Wii if unknown (likely won't match but better than crash)
    return 'Nintendo_-_Wii';
  }
}
