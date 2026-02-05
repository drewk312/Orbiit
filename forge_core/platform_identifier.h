// SPDX-FileCopyrightText: 2026 WiiGC-Fusion Contributors
// SPDX-License-Identifier: GPL-3.0-only

#ifndef PLATFORM_IDENTIFIER_H
#define PLATFORM_IDENTIFIER_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Detected platform types
typedef enum {
    PLATFORM_UNKNOWN = 0,
    PLATFORM_WII = 1,
    PLATFORM_GAMECUBE = 2,
    PLATFORM_WII_U = 3,
    PLATFORM_NES = 4,
    PLATFORM_SNES = 5,
    PLATFORM_N64 = 6,
    PLATFORM_GAMEBOY = 7,
    PLATFORM_GBC = 8,
    PLATFORM_GBA = 9,
    PLATFORM_NDS = 10,
    PLATFORM_3DS = 11,
    PLATFORM_PSP = 12,
    PLATFORM_PS1 = 13,
    PLATFORM_PS2 = 14,
    PLATFORM_GENESIS = 15,
    PLATFORM_DREAMCAST = 16,
} Platform;

/// Disc/ROM format detection
typedef enum {
    FORMAT_UNKNOWN = 0,
    FORMAT_ISO = 1,
    FORMAT_WBFS = 2,
    FORMAT_RVZ = 3,
    FORMAT_WUD = 4,
    FORMAT_WUX = 5,
    FORMAT_NKIt = 6,
    FORMAT_CIA = 7,
    FORMAT_3DSX = 8,
    FORMAT_CSO = 9,
    FORMAT_CHD = 10,
    FORMAT_FOLDER = 11,  // Wii U extracted folder structure
} DiscFormat;

/// Game identification result
typedef struct {
    Platform platform;
    DiscFormat format;
    char title_id[8];          // e.g., "RSPE01" for Wii Sports
    char game_title[256];      // Internal game title
    char region;               // 'E'=USA, 'P'=PAL, 'J'=JPN
    uint8_t disc_number;       // For multi-disc games
    uint64_t file_size;
    bool is_scrubbed;          // Partition data removed
    bool requires_cios;        // Wii games that need cIOS
} GameIdentity;

/// Magic byte signatures for platform detection
typedef struct {
    const uint8_t* signature;
    size_t signature_length;
    size_t offset;
    Platform platform;
    DiscFormat format;
} MagicSignature;

// ============================================================================
// Platform Identification API
// ============================================================================

/// Identify a game from raw header bytes
/// @param header First 512 bytes of the file
/// @param header_size Size of header buffer
/// @param result Output: filled GameIdentity struct
/// @return true if platform was identified
bool identify_from_header(const uint8_t* header, size_t header_size, GameIdentity* result);

/// Identify a game from file path (reads header automatically)
/// @param file_path Path to game file
/// @param result Output: filled GameIdentity struct
/// @return true if platform was identified
bool identify_from_file(const char* file_path, GameIdentity* result);

/// Identify Wii U from folder structure (code/content/meta)
/// @param folder_path Path to potential Wii U folder
/// @param result Output: filled GameIdentity struct
/// @return true if valid Wii U structure detected
bool identify_wiiu_folder(const char* folder_path, GameIdentity* result);

/// Get human-readable platform name
/// @param platform Platform enum value
/// @return Static string like "Nintendo Wii"
const char* platform_to_string(Platform platform);

/// Get recommended output path for game organization
/// @param identity Identified game
/// @param drive_root Root of target drive (e.g., "E:\\")
/// @param output_path Buffer for output path (at least 512 bytes)
/// @return Formatted path like "E:\\wbfs\\Wii Sports [RSPE01]\\RSPE01.wbfs"
bool get_organized_path(const GameIdentity* identity, const char* drive_root, char* output_path);

// ============================================================================
// Magic Byte Constants (Defined in platform_identifier.cpp)
// ============================================================================

// Wii/GC: Disc header at offset 0x00
// - Bytes 0x00-0x03: Game ID (e.g., "RSPE")
// - Byte 0x18: Magic word 0x5D1C9EA3 (Wii) or 0xC2339F3D (GC)

// WBFS: Header at offset 0x00
// - Bytes 0x00-0x03: "WBFS" (0x57424653)

// RVZ: Header at offset 0x00
// - Bytes 0x00-0x03: "RVZ" followed by version

// Wii U WUD: First 0x8000 bytes contain header
// - Magic at 0x00: 0x57555000 ("WUP\0")

// NES: iNES header
// - Bytes 0x00-0x03: "NES\x1A"

// SNES: No universal header, use ROM makeup byte at 0x7FD5 or 0xFFD5

// Game Boy/GBC: Nintendo logo at 0x104-0x133
// - Bytes 0x104-0x133: Fixed Nintendo logo bitmap

// GBA: Nintendo logo at 0x04-0x9F
// - Bytes 0x04-0x9F: Compressed Nintendo logo

// NDS: "Nitro" header at 0x00
// - Bytes 0x00-0x0B: Game title
// - Bytes 0x0C-0x0F: Game code

#ifdef __cplusplus
}
#endif

#endif // PLATFORM_IDENTIFIER_H
