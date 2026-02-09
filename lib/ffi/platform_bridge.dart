import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import '../core/forge_native.dart';
import 'dart:convert'; // Added for utf8.decode

/// Platform enum matching C++ Platform
enum GamePlatform {
  unknown(0),
  wii(1),
  gamecube(2),
  wiiU(3),
  nes(4),
  snes(5),
  n64(6),
  gameboy(7),
  gbc(8),
  gba(9),
  nds(10),
  threeDS(11),
  psp(12),
  ps1(13),
  ps2(14),
  genesis(15),
  dreamcast(16);

  const GamePlatform(this.value);
  final int value;

  static GamePlatform fromValue(int value) {
    return GamePlatform.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GamePlatform.unknown,
    );
  }

  String get displayName {
    switch (this) {
      case GamePlatform.wii:
        return 'Nintendo Wii';
      case GamePlatform.gamecube:
        return 'Nintendo GameCube';
      case GamePlatform.wiiU:
        return 'Nintendo Wii U';
      case GamePlatform.nes:
        return 'NES';
      case GamePlatform.snes:
        return 'SNES';
      case GamePlatform.n64:
        return 'Nintendo 64';
      case GamePlatform.gameboy:
        return 'Game Boy';
      case GamePlatform.gbc:
        return 'Game Boy Color';
      case GamePlatform.gba:
        return 'Game Boy Advance';
      case GamePlatform.nds:
        return 'Nintendo DS';
      case GamePlatform.threeDS:
        return 'Nintendo 3DS';
      case GamePlatform.psp:
        return 'PSP';
      case GamePlatform.ps1:
        return 'PlayStation';
      case GamePlatform.ps2:
        return 'PlayStation 2';
      case GamePlatform.genesis:
        return 'Sega Genesis';
      case GamePlatform.dreamcast:
        return 'Dreamcast';
      default:
        return 'Unknown';
    }
  }

  String get folderPath {
    switch (this) {
      case GamePlatform.wii:
        return 'wbfs';
      case GamePlatform.gamecube:
        return 'games';
      case GamePlatform.wiiU:
        return 'wiiu/games';
      case GamePlatform.nes:
        return 'roms/NES';
      case GamePlatform.snes:
        return 'roms/SNES';
      case GamePlatform.n64:
        return 'roms/N64';
      case GamePlatform.gameboy:
        return 'roms/GB';
      case GamePlatform.gbc:
        return 'roms/GBC';
      case GamePlatform.gba:
        return 'roms/GBA';
      case GamePlatform.nds:
        return 'roms/NDS';
      case GamePlatform.threeDS:
        return 'roms/3DS';
      case GamePlatform.psp:
        return 'roms/PSP';
      case GamePlatform.ps1:
        return 'roms/PS1';
      case GamePlatform.ps2:
        return 'roms/PS2';
      case GamePlatform.genesis:
        return 'roms/Genesis';
      case GamePlatform.dreamcast:
        return 'roms/Dreamcast';
      default:
        return 'roms/Unknown';
    }
  }
}

/// Dart representation of C++ GameIdentity
class GameIdentity {
  final GamePlatform platform;
  final String titleId;
  final String gameTitle;
  final String region;
  final int discNumber;
  final int fileSize;
  final bool isScrubbed;
  final bool requiresCios;

  GameIdentity({
    required this.platform,
    required this.titleId,
    required this.gameTitle,
    required this.region,
    required this.discNumber,
    required this.fileSize,
    required this.isScrubbed,
    required this.requiresCios,
  });

  String get organizedPath {
    if (platform == GamePlatform.wii) {
      return '${platform.folderPath}/$gameTitle [$titleId]/$titleId.wbfs';
    } else if (platform == GamePlatform.gamecube) {
      return '${platform.folderPath}/$gameTitle [$titleId]/game.iso';
    } else if (platform == GamePlatform.wiiU) {
      return '${platform.folderPath}/$titleId/';
    } else {
      return '${platform.folderPath}/$gameTitle';
    }
  }
}

/// FFI Bindings for Platform Identifier
class PlatformIdentifierBridge {
  late final ffi.DynamicLibrary _lib;
  late final IdentifyFromFile _identifyFromFile;
  late final PlatformToString _platformToString;

  PlatformIdentifierBridge() {
    // Use the singleton native library
    final lib = ForgeNative.instance.lib;
    if (lib == null) throw Exception('Native library not loaded');
    _lib = lib;

    _identifyFromFile = _lib.lookupFunction<
        ffi.Bool Function(ffi.Pointer<Utf8>, ffi.Pointer<GameIdentityNative>),
        bool Function(ffi.Pointer<Utf8>,
            ffi.Pointer<GameIdentityNative>)>('identify_from_file');

    _platformToString = _lib.lookupFunction<
        ffi.Pointer<Utf8> Function(ffi.Int32),
        ffi.Pointer<Utf8> Function(int)>('platform_to_string');
  }

  /// Helper to convert fixed-size char array to Dart String
  String _arrayToString(ffi.Array<ffi.Uint8> array, int length) {
    final list = <int>[];
    for (int i = 0; i < length; i++) {
      if (array[i] == 0) break;
      list.add(array[i]);
    }
    return utf8.decode(list, allowMalformed: true);
  }

  /// Identify a game file by its magic bytes
  GameIdentity? identifyFile(String filePath) {
    final pathPtr = filePath.toNativeUtf8();
    final resultPtr = calloc<GameIdentityNative>();

    try {
      final success = _identifyFromFile(pathPtr, resultPtr);
      if (!success) return null;

      final native = resultPtr.ref;
      return GameIdentity(
        platform: GamePlatform.fromValue(native.platform),
        titleId: _arrayToString(native.titleId, 8),
        gameTitle: _arrayToString(native.gameTitle, 256),
        region: String.fromCharCode(native.region),
        discNumber: native.discNumber,
        fileSize: native.fileSize,
        isScrubbed: native.isScrubbed,
        requiresCios: native.requiresCios,
      );
    } finally {
      malloc.free(pathPtr);
      calloc.free(resultPtr);
    }
  }

  String getPlatformName(GamePlatform platform) {
    final ptr = _platformToString(platform.value);
    return ptr.toDartString();
  }
}

// Native struct definition for FFI
final class GameIdentityNative extends ffi.Struct {
  @ffi.Int32()
  external int platform;

  @ffi.Int32()
  external int format;

  @ffi.Array(8)
  external ffi.Array<ffi.Uint8> titleId;

  @ffi.Array(256)
  external ffi.Array<ffi.Uint8> gameTitle;

  @ffi.Uint8()
  external int region;

  @ffi.Uint8()
  external int discNumber;

  @ffi.Uint64()
  external int fileSize;

  @ffi.Bool()
  external bool isScrubbed;

  @ffi.Bool()
  external bool requiresCios;
}

// Native function typedefs
typedef IdentifyFromFile = bool Function(
    ffi.Pointer<Utf8>, ffi.Pointer<GameIdentityNative>);
typedef PlatformToString = ffi.Pointer<Utf8> Function(int);
