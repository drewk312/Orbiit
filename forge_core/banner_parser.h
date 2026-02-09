// SPDX-FileCopyrightText: 2026 WiiGC-Fusion Contributors
// SPDX-License-Identifier: GPL-3.0-only

#ifndef BANNER_PARSER_H
#define BANNER_PARSER_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Decoded banner information
typedef struct {
    char game_title[128];      // Increased buffer
    char game_subtitle[128];
    uint32_t texture_width;
    uint32_t texture_height;
    uint8_t* rgba_data;        // Buffer for decoded image (caller must free)
    size_t rgba_size;
    uint8_t* pcm_data;         // Buffer for decoded audio (caller must free)
    size_t pcm_size;
} BannerData;


/// Parse a Wii opening.bnr file to extract metadata and banner image
/// @param banner_path Path to opening.bnr
/// @param result Output struct for banner data
/// @return true if successful
bool parse_opening_banner(const char* banner_path, BannerData* result);

/// Free the buffer allocated by parse_opening_banner
void free_banner_data(BannerData* data);

#ifdef __cplusplus
}
#endif

#endif // BANNER_PARSER_H
