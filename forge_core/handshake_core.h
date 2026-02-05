// SPDX-FileCopyrightText: 2026 WiiGC-Fusion Contributors
// SPDX-License-Identifier: GPL-3.0-only

#ifndef HANDSHAKE_CORE_H
#define HANDSHAKE_CORE_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Handshake provider types
typedef enum {
    PROVIDER_UNKNOWN = 0,
    PROVIDER_ARCHIVE_ORG = 1,
    PROVIDER_ROMSGAMES = 2,
    PROVIDER_ROMSFUN = 3
} HandshakeProviderType;

/// Result of a handshake resolution
typedef struct {
    char direct_url[2048];
    char cookies[4096];
    char user_agent[256];
    bool requires_browser;
} HandshakeResult;

/// Direct Link Resolver (Phase 2 Core)
/// @param page_url The landing page URL (e.g. romsgames.net/.../?download)
/// @param provider The detected provider logic to use
/// @param result Output struct for the final streamable URL
/// @return true if resolution successful
bool handshake_resolve_url(const char* page_url, HandshakeProviderType provider, HandshakeResult* result);

#ifdef __cplusplus
}
#endif

#endif // HANDSHAKE_CORE_H
