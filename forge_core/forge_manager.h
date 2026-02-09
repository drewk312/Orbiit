// SPDX-FileCopyrightText: 2026 Manuel Quarneti <mq1@ik.me>
// SPDX-License-Identifier: GPL-3.0-only

#ifndef FORGE_MANAGER_H
#define FORGE_MANAGER_H

#include <stdint.h>
#include <stdbool.h>
#include "platform_identifier.h"

#ifdef __cplusplus
extern "C" {
#endif

// Export macro for shared library
#ifndef FORGE_EXPORT
    #ifdef _WIN32
        #define FORGE_EXPORT __declspec(dllexport)
    #else
        #define FORGE_EXPORT 
    #endif
#endif

/// Status codes for Forge operations
typedef enum {
    FORGE_STATUS_HANDSHAKING = 0,
    FORGE_STATUS_DOWNLOADING = 1,
    FORGE_STATUS_EXTRACTING = 2,
    FORGE_STATUS_FORGING = 3,
    FORGE_STATUS_READY = 4,
    FORGE_STATUS_ERROR = 5
} ForgeStatus;

/// Progress callback for UI updates
typedef void (*ForgeProgressCallback)(ForgeStatus status, float progress, const char* message);

/// Initialize the Forge Manager
/// @return true if successful, false otherwise
FORGE_EXPORT bool forge_init(void);
FORGE_EXPORT void forge_shutdown(void);

/// Callback for when a game is found during folder scan
typedef void (*ForgeGameFoundCallback)(const char* file_path, const GameIdentity* identity);

/// Scan a folder for games and invoke callback for each found
/// @param folder_path Path to scan
/// @param recursive Whether to scan subdirectories
/// @param callback Callback for each game found
/// @return Number of games found
FORGE_EXPORT int forge_scan_folder(const char* folder_path, bool recursive, ForgeGameFoundCallback callback);

/// Format a drive to FAT32 with 32KB clusters (Wii Compatible)
/// @param drive_letter Drive letter (e.g. "E:")
/// @param label Volume label
/// @param callback Progress callback (optional, can be null)
/// @return true if successful
FORGE_EXPORT bool forge_format_drive(const char* drive_letter, const char* label, ForgeProgressCallback callback);

/// Verify file hash against expected value (SHA-1)
/// @param file_path Path to file
/// @param expected_hash Expected hash string
/// @return true if match
FORGE_EXPORT bool forge_verify_hash(const char* file_path, const char* expected_hash);
FORGE_EXPORT uint64_t forge_start_mission(const char* url, const char* dest_path, ForgeProgressCallback callback);
FORGE_EXPORT bool forge_cancel_mission(uint64_t mission_id);
FORGE_EXPORT bool forge_format_drive_32kb(const char* drive_path, const char* label, ForgeProgressCallback callback);
FORGE_EXPORT bool forge_verify_redump_hash(const char* file_path, const char* expected_hash);
FORGE_EXPORT bool forge_deploy_structure(const char* drive_path);
FORGE_EXPORT char* forge_handshake_resolve(const char* url, int provider_id);

/// Get current mission progress (Polling API)
/// @param mission_id Mission ID to query
/// @param status_out Pointer to write status code
/// @param progress_out Pointer to write progress (0.0-1.0)
/// @param message_out Buffer to write Status Message
/// @param message_size Size of message buffer
/// @return true if mission exists
FORGE_EXPORT bool forge_get_mission_progress(int32_t mission_id, int32_t* status_out, float* progress_out, char* message_out, size_t message_size);

/// Convert an ISO file to WBFS format
/// @param input_path Path to source ISO
/// @param output_path Path to destination WBFS
/// @param callback Progress callback
/// @return true if successful
FORGE_EXPORT bool forge_convert_iso_to_wbfs(const char* input_path, const char* output_path, ForgeProgressCallback callback);

/// Split a WBFS file for FAT32 (4GB limit)
/// @param file_path Path to WBFS file
/// @param callback Progress callback
/// @return true if successful (or splitting not needed)
FORGE_EXPORT bool forge_split_wbfs_fat32(const char* file_path, ForgeProgressCallback callback);

/// Get file format identity
/// @param file_path Path to file
/// @return "ISO", "WBFS", "RVZ", etc. or "Unknown" (Caller must free)
FORGE_EXPORT char* forge_get_file_format(const char* file_path);

#ifdef __cplusplus
}
#endif

#endif // FORGE_MANAGER_H
