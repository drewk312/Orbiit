// SPDX-FileCopyrightText: 2026 WiiGC-Fusion Contributors
// SPDX-License-Identifier: GPL-3.0-only

#include "handshake_core.h"
#include <string.h>
#include <stdio.h>

bool handshake_resolve_url(const char* page_url, HandshakeProviderType provider, HandshakeResult* result) {
    if (!page_url || !result) return false;

    // URL resolution logic for different providers
    
    switch (provider) {
        case PROVIDER_ARCHIVE_ORG:
            // Strategy: Convert details page -> download URL
            // Archive.org follows: details/[ID] -> download/[ID]
            {
                const char* details_key = "/details/";
                const char* details_pos = strstr(page_url, details_key);
                if (details_pos) {
                    size_t prefix_len = details_pos - page_url;
                    strncpy(result->direct_url, page_url, prefix_len);
                    result->direct_url[prefix_len] = '\0';
                    strcat(result->direct_url, "/download/");
                    strcat(result->direct_url, details_pos + strlen(details_key));
                    
                    // Note: This often redirects to a zip/iso within the item, 
                    // but the forge_manager's WinHTTP handles redirects.
                    return true;
                }
                snprintf(result->direct_url, 2048, "%s", page_url);
                return true;
            }

        case PROVIDER_ROMSGAMES:
            // Strategy: This requires the headless browser to run JS
            // The C++ core just prepares the request for the automated agent
            result->requires_browser = true;
            return true;

        case PROVIDER_ROMSFUN:
             // Strategy: CloudFlare protection
             result->requires_browser = true;
             return true;

        default:
            return false;
    }
}
