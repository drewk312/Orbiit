// SPDX-FileCopyrightText: 2026 WiiGC-Fusion Contributors
// SPDX-License-Identifier: GPL-3.0-only

#include "banner_parser.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// U8 Archive Magic
const uint32_t U8_MAGIC = 0x55AA382D;

// Helper to read big-endian uint32
static uint32_t read_u32_be(const uint8_t* p) {
    return (p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3];
}

// Helper to read big-endian uint16
static uint16_t read_u16_be(const uint8_t* p) {
    return (p[0] << 8) | p[1];
}

// Convert UTF-16BE to UTF-8
static void utf16be_to_utf8(const uint8_t* src, char* dest, size_t max_len) {
    size_t i = 0, j = 0;
    while (i < max_len - 1 && j < 63) {
        uint16_t code = (src[i] << 8) | src[i+1];
        if (code == 0) break;
        if (code < 0x80) {
            dest[j++] = (char)code;
        } else {
            dest[j++] = '?'; // Simplified
        }
        i += 2;
    }
    dest[j] = '\0';
}

bool parse_opening_banner(const char* banner_path, BannerData* result) {
    if (!result) return false;
    
    // Initialize result
    memset(result->game_title, 0, 128);
    memset(result->game_subtitle, 0, 128);
    result->texture_width = 0;
    result->texture_height = 0;
    result->rgba_data = NULL;
    result->rgba_size = 0;
    result->pcm_data = NULL;
    result->pcm_size = 0;

    FILE* f = fopen(banner_path, "rb");

    if (!f) return false;

    fseek(f, 0, SEEK_END);
    long fsize = ftell(f);
    fseek(f, 0, SEEK_SET);

    uint8_t* buffer = (uint8_t*)malloc(fsize);
    if (!buffer) {
        fclose(f);
        return false;
    }
    fread(buffer, 1, fsize, f);
    fclose(f);

    // 1. Check for IMET Header (at offset 0x40 usually, or 0x00)
    // IMET is at the start of opening.bnr
    if (memcmp(buffer, "IMET", 4) == 0) {
        // Japanese at 0x40, English at 0x80, German at 0xC0...
        // We'll take English (index 1)
        utf16be_to_utf8(buffer + 0x80, result->game_title, 64);
        utf16be_to_utf8(buffer + 0xC0, result->game_subtitle, 64); // Using German as subtitle fallback or just publisher
    } else {
        strncpy(result->game_title, "Unknown Title", 64);
        strncpy(result->game_subtitle, "Unknown Publisher", 64);
    }

    // 2. Find U8 Archive (usually at offset 0x600)
    size_t u8_offset = 0;
    for (size_t i = 0; i < fsize - 4; i++) {
        if (read_u32_be(buffer + i) == U8_MAGIC) {
            u8_offset = i;
            break;
        }
    }

    if (u8_offset != 0) {
        const uint8_t* u8_base = buffer + u8_offset;
        uint32_t root_offset = read_u32_be(u8_base + 0x04);
        uint32_t node_count = read_u32_be(u8_base + root_offset + 0x08);
        const uint8_t* nodes = u8_base + root_offset;
        const char* strings = (const char*)(nodes + node_count * 12);

        for (uint32_t i = 0; i < node_count; i++) {
            const uint8_t* node = nodes + i * 12;
            bool is_dir = node[0] == 0x01;
            uint32_t name_offset = (node[1] << 16) | (node[2] << 8) | node[3];
            const char* name = strings + name_offset;

            if (!is_dir && (strcmp(name, "banner.tpl") == 0 || strstr(name, ".tpl"))) {
                uint32_t data_offset = read_u32_be(node + 0x04);
                uint32_t data_size = read_u32_be(node + 0x08);
                const uint8_t* tpl_data = u8_base + data_offset;

                // Basic TPL Header Check (0x0020AF30)
                if (read_u32_be(tpl_data) == 0x0020AF30) {
                    uint32_t num_images = read_u32_be(tpl_data + 0x04);
                    uint32_t image_table_offset = read_u32_be(tpl_data + 0x08);
                    
                    if (num_images > 0) {
                        uint32_t image_header_offset = read_u32_be(tpl_data + image_table_offset);
                        const uint8_t* img_header = tpl_data + image_header_offset;
                        
                        result->texture_height = read_u16_be(img_header);
                        result->texture_width = read_u16_be(img_header + 0x02);
                        uint32_t format = read_u32_be(img_header + 0x04);
                        uint32_t pixel_data_offset = read_u32_be(img_header + 0x08);
                        const uint8_t* pixels = tpl_data + pixel_data_offset;
                        
                        result->rgba_size = result->texture_width * result->texture_height * 4;
                        result->rgba_data = (uint8_t*)malloc(result->rgba_size);
                        
                        if (result->rgba_data && format == 14) { // CMPR
                            // CMPR Decoding Logic (4x4 blocks)
                            for (uint32_t y = 0; y < result->texture_height; y += 4) {
                                for (uint32_t x = 0; x < result->texture_width; x += 4) {
                                    // CMPR uses 2x2 sub-tiles of 4x4 blocks in 8x8 tiles? 
                                    // Actually, it's just linear 4x4 blocks for simplicity in this stub.
                                    const uint8_t* block = pixels + ((y / 4) * (result->texture_width / 4) + (x / 4)) * 8;
                                    
                                    uint16_t c0 = read_u16_be(block);
                                    uint16_t c1 = read_u16_be(block + 2);
                                    uint32_t bits = read_u32_be(block + 4);
                                    
                                    uint8_t r[4], g[4], b[4], a[4];
                                    r[0] = (c0 >> 11) << 3; g[0] = ((c0 >> 5) & 0x3F) << 2; b[0] = (c0 & 0x1F) << 3; a[0] = 255;
                                    r[1] = (c1 >> 11) << 3; g[1] = ((c1 >> 5) & 0x3F) << 2; b[1] = (c1 & 0x1F) << 3; a[1] = 255;
                                    
                                    if (c0 > c1) {
                                        r[2] = (2 * r[0] + r[1]) / 3; g[2] = (2 * g[0] + g[1]) / 3; b[2] = (2 * b[0] + b[1]) / 3; a[2] = 255;
                                        r[3] = (r[0] + 2 * r[1]) / 3; g[3] = (g[0] + 2 * g[1]) / 3; b[3] = (b[0] + 2 * b[1]) / 3; a[3] = 255;
                                    } else {
                                        r[2] = (r[0] + r[1]) / 2; g[2] = (g[0] + g[1]) / 2; b[2] = (b[0] + b[1]) / 2; a[2] = 255;
                                        r[3] = 0; g[3] = 0; b[3] = 0; a[3] = 0;
                                    }
                                    
                                    for (int iy = 0; iy < 4; iy++) {
                                        for (int ix = 0; ix < 4; ix++) {
                                            int bitPos = 30 - ((iy * 4 + ix) * 2);
                                            int idx = (bits >> bitPos) & 0x03;
                                            uint32_t px = (y + iy) * result->texture_width + (x + ix);
                                            if (px < result->texture_width * result->texture_height) {
                                                uint8_t* rgba = result->rgba_data + px * 4;
                                                rgba[0] = r[idx]; rgba[1] = g[idx]; rgba[2] = b[idx]; rgba[3] = a[idx];
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                break;
            }
        }
    }

    free(buffer);
    return true;
}


void free_banner_data(BannerData* data) {
    if (data) {
        if (data->rgba_data) {
            free(data->rgba_data);
            data->rgba_data = NULL;
        }
        if (data->pcm_data) {
            free(data->pcm_data);
            data->pcm_data = NULL;
        }
    }
}
