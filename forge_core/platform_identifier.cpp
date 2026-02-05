// SPDX-FileCopyrightText: 2026 WiiGC-Fusion Contributors
// SPDX-License-Identifier: GPL-3.0-only

#include "platform_identifier.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

// ============================================================================
// Magic Byte Definitions
// ============================================================================

// Wii/GC magic at offset 0x1C
static const uint8_t WII_MAGIC[] = { 0x5D, 0x1C, 0x9E, 0xA3 };
static const uint8_t GC_MAGIC[] = { 0xC2, 0x33, 0x9F, 0x3D };

// WBFS container signature
static const uint8_t WBFS_MAGIC[] = { 'W', 'B', 'F', 'S' };

// RVZ compressed format
static const uint8_t RVZ_MAGIC[] = { 'R', 'V', 'Z', '\0' };

// Wii U WUD format
static const uint8_t WUD_MAGIC[] = { 'W', 'U', 'P', '\0' };

// NES iNES format
static const uint8_t NES_MAGIC[] = { 'N', 'E', 'S', 0x1A };

// Game Boy Nintendo logo (first 8 bytes of 48-byte logo)
static const uint8_t GB_LOGO[] = { 0xCE, 0xED, 0x66, 0x66, 0xCC, 0x0D, 0x00, 0x0B };

// GBA Nintendo logo (first 8 bytes)
static const uint8_t GBA_LOGO[] = { 0x24, 0xFF, 0xAE, 0x51, 0x69, 0x9A, 0xA2, 0x21 };

// NDS header identifier
static const uint8_t NDS_LOGO[] = { 0x24, 0xFF, 0xAE, 0x51 };  // Same as GBA, at 0xC0

// N64 magic (big-endian)
static const uint8_t N64_MAGIC_Z64[] = { 0x80, 0x37, 0x12, 0x40 };  // .z64
static const uint8_t N64_MAGIC_N64[] = { 0x40, 0x12, 0x37, 0x80 };  // .n64 (byte-swapped)
static const uint8_t N64_MAGIC_V64[] = { 0x37, 0x80, 0x40, 0x12 };  // .v64 (word-swapped)

// PlayStation magic
static const uint8_t PS1_MAGIC[] = { 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00 };

// Sega Genesis magic
static const uint8_t GENESIS_MAGIC[] = { 'S', 'E', 'G', 'A' };  // At offset 0x100

// ============================================================================
// Helper Functions
// ============================================================================

static bool check_magic(const uint8_t* header, size_t offset, const uint8_t* magic, size_t magic_len, size_t header_size) {
    if (offset + magic_len > header_size) return false;
    return memcmp(header + offset, magic, magic_len) == 0;
}

static void extract_string(const uint8_t* src, char* dst, size_t len) {
    memcpy(dst, src, len);
    dst[len] = '\0';
    // Trim trailing spaces/nulls
    for (size_t i = len; i > 0; i--) {
        if (dst[i-1] == ' ' || dst[i-1] == '\0') {
            dst[i-1] = '\0';
        } else {
            break;
        }
    }
}

// ============================================================================
// Main Identification Logic
// ============================================================================

bool identify_from_header(const uint8_t* header, size_t header_size, GameIdentity* result) {
    if (!header || !result || header_size < 64) {
        return false;
    }
    
    memset(result, 0, sizeof(GameIdentity));
    
    // Try WBFS first (container format)
    if (check_magic(header, 0, WBFS_MAGIC, 4, header_size)) {
        result->platform = PLATFORM_WII;  // WBFS is always Wii
        result->format = FORMAT_WBFS;
        // WBFS header contains disc header at offset 0x200
        if (header_size >= 0x200 + 64) {
            extract_string(header + 0x200, result->title_id, 6);
            extract_string(header + 0x200 + 0x20, result->game_title, 64);
            result->region = header[0x200 + 3];
        }
        return true;
    }
    
    // Try RVZ compressed format
    if (check_magic(header, 0, RVZ_MAGIC, 3, header_size)) {
        result->format = FORMAT_RVZ;
        // RVZ contains Wii/GC disc - would need to decompress header to get title
        // For now, mark as Wii (most common)
        result->platform = PLATFORM_WII;
        return true;
    }
    
    // Try Wii U WUD/WUX
    if (check_magic(header, 0, WUD_MAGIC, 3, header_size)) {
        result->platform = PLATFORM_WII_U;
        result->format = FORMAT_WUD;
        return true;
    }
    
    // Try Wii/GC ISO (check magic at offset 0x1C)
    if (header_size >= 0x20) {
        if (check_magic(header, 0x1C, WII_MAGIC, 4, header_size)) {
            result->platform = PLATFORM_WII;
            result->format = FORMAT_ISO;
            extract_string(header, result->title_id, 6);
            extract_string(header + 0x20, result->game_title, 64);
            result->region = header[3];
            result->disc_number = header[6];
            return true;
        }
        if (check_magic(header, 0x1C, GC_MAGIC, 4, header_size)) {
            result->platform = PLATFORM_GAMECUBE;
            result->format = FORMAT_ISO;
            extract_string(header, result->title_id, 6);
            extract_string(header + 0x20, result->game_title, 64);
            result->region = header[3];
            result->disc_number = header[6];
            return true;
        }
    }
    
    // Try NES
    if (check_magic(header, 0, NES_MAGIC, 4, header_size)) {
        result->platform = PLATFORM_NES;
        result->format = FORMAT_UNKNOWN;
        strcpy(result->game_title, "NES ROM");
        return true;
    }
    
    // Try N64
    if (check_magic(header, 0, N64_MAGIC_Z64, 4, header_size) ||
        check_magic(header, 0, N64_MAGIC_N64, 4, header_size) ||
        check_magic(header, 0, N64_MAGIC_V64, 4, header_size)) {
        result->platform = PLATFORM_N64;
        result->format = FORMAT_UNKNOWN;
        extract_string(header + 0x20, result->game_title, 20);
        extract_string(header + 0x3B, result->title_id, 4);
        return true;
    }
    
    // Try Game Boy (check Nintendo logo at 0x104)
    if (header_size >= 0x150) {
        if (check_magic(header, 0x104, GB_LOGO, 8, header_size)) {
            // Check if GBC (0x143 flag)
            if (header[0x143] == 0x80 || header[0x143] == 0xC0) {
                result->platform = PLATFORM_GBC;
            } else {
                result->platform = PLATFORM_GAMEBOY;
            }
            result->format = FORMAT_UNKNOWN;
            extract_string(header + 0x134, result->game_title, 16);
            return true;
        }
    }
    
    // Try GBA (Nintendo logo at 0x04)
    if (header_size >= 0xC0) {
        if (check_magic(header, 0x04, GBA_LOGO, 8, header_size)) {
            result->platform = PLATFORM_GBA;
            result->format = FORMAT_UNKNOWN;
            extract_string(header + 0xA0, result->game_title, 12);
            extract_string(header + 0xAC, result->title_id, 4);
            return true;
        }
    }
    
    // Try NDS
    if (header_size >= 0x160) {
        // NDS has game title at 0x00 and game code at 0x0C
        // Check for valid NDS header by looking at ROM size field
        uint32_t rom_size = *(uint32_t*)(header + 0x80);
        if (rom_size > 0 && rom_size < 0x20000000) {  // Max 512MB
            // Additional validation: check for Nintendo logo at 0xC0
            if (check_magic(header, 0xC0, NDS_LOGO, 4, header_size)) {
                result->platform = PLATFORM_NDS;
                result->format = FORMAT_UNKNOWN;
                extract_string(header, result->game_title, 12);
                extract_string(header + 0x0C, result->title_id, 4);
                return true;
            }
        }
    }
    
    // Try Sega Genesis (SEGA at 0x100)
    if (header_size >= 0x110) {
        if (check_magic(header, 0x100, GENESIS_MAGIC, 4, header_size)) {
            result->platform = PLATFORM_GENESIS;
            result->format = FORMAT_UNKNOWN;
            extract_string(header + 0x120, result->game_title, 48);
            return true;
        }
    }
    
    return false;
}

bool identify_from_file(const char* file_path, GameIdentity* result) {
    FILE* f = fopen(file_path, "rb");
    if (!f) return false;
    
    uint8_t header[512];
    size_t bytes_read = fread(header, 1, sizeof(header), f);
    
    // Get file size
    fseek(f, 0, SEEK_END);
    result->file_size = ftell(f);
    fclose(f);
    
    return identify_from_header(header, bytes_read, result);
}

bool identify_wiiu_folder(const char* folder_path, GameIdentity* result) {
    // Check for Wii U folder structure: code/, content/, meta/
    char path_buf[512];
    
    snprintf(path_buf, sizeof(path_buf), "%s/code", folder_path);
    FILE* f = fopen(path_buf, "rb");
    if (!f) {
        // Try backslash for Windows
        snprintf(path_buf, sizeof(path_buf), "%s\\code", folder_path);
        f = fopen(path_buf, "rb");
    }
    
    // For folder check, we just verify the directory exists
    // This is a simplified check - real implementation would use stat()
    if (f) {
        fclose(f);
        result->platform = PLATFORM_WII_U;
        result->format = FORMAT_FOLDER;
        strcpy(result->game_title, "Wii U Game");
        return true;
    }
    
    return false;
}

const char* platform_to_string(Platform platform) {
    switch (platform) {
        case PLATFORM_WII: return "Nintendo Wii";
        case PLATFORM_GAMECUBE: return "Nintendo GameCube";
        case PLATFORM_WII_U: return "Nintendo Wii U";
        case PLATFORM_NES: return "Nintendo Entertainment System";
        case PLATFORM_SNES: return "Super Nintendo";
        case PLATFORM_N64: return "Nintendo 64";
        case PLATFORM_GAMEBOY: return "Game Boy";
        case PLATFORM_GBC: return "Game Boy Color";
        case PLATFORM_GBA: return "Game Boy Advance";
        case PLATFORM_NDS: return "Nintendo DS";
        case PLATFORM_3DS: return "Nintendo 3DS";
        case PLATFORM_PSP: return "PlayStation Portable";
        case PLATFORM_PS1: return "PlayStation";
        case PLATFORM_PS2: return "PlayStation 2";
        case PLATFORM_GENESIS: return "Sega Genesis";
        case PLATFORM_DREAMCAST: return "Sega Dreamcast";
        default: return "Unknown Platform";
    }
}

bool get_organized_path(const GameIdentity* identity, const char* drive_root, char* output_path) {
    if (!identity || !drive_root || !output_path) return false;
    
    switch (identity->platform) {
        case PLATFORM_WII:
            // /wbfs/[Game Name] [[ID]]/[ID].wbfs
            snprintf(output_path, 512, "%s/wbfs/%s [%s]/%s.wbfs",
                drive_root, identity->game_title, identity->title_id, identity->title_id);
            break;
            
        case PLATFORM_GAMECUBE:
            // /games/[Game Name] [[ID]]/game.iso
            snprintf(output_path, 512, "%s/games/%s [%s]/game.iso",
                drive_root, identity->game_title, identity->title_id);
            break;
            
        case PLATFORM_WII_U:
            // /wiiu/games/[Title ID]/
            snprintf(output_path, 512, "%s/wiiu/games/%s/",
                drive_root, identity->title_id);
            break;
            
        case PLATFORM_NES:
            snprintf(output_path, 512, "%s/roms/NES/%s.nes", drive_root, identity->game_title);
            break;
            
        case PLATFORM_SNES:
            snprintf(output_path, 512, "%s/roms/SNES/%s.sfc", drive_root, identity->game_title);
            break;
            
        case PLATFORM_N64:
            snprintf(output_path, 512, "%s/roms/N64/%s.z64", drive_root, identity->game_title);
            break;
            
        case PLATFORM_GAMEBOY:
            snprintf(output_path, 512, "%s/roms/GB/%s.gb", drive_root, identity->game_title);
            break;
            
        case PLATFORM_GBC:
            snprintf(output_path, 512, "%s/roms/GBC/%s.gbc", drive_root, identity->game_title);
            break;
            
        case PLATFORM_GBA:
            snprintf(output_path, 512, "%s/roms/GBA/%s.gba", drive_root, identity->game_title);
            break;
            
        case PLATFORM_NDS:
            snprintf(output_path, 512, "%s/roms/NDS/%s.nds", drive_root, identity->game_title);
            break;
            
        case PLATFORM_GENESIS:
            snprintf(output_path, 512, "%s/roms/Genesis/%s.md", drive_root, identity->game_title);
            break;
            
        default:
            snprintf(output_path, 512, "%s/roms/Unknown/%s", drive_root, identity->game_title);
            break;
    }
    
    return true;
}
