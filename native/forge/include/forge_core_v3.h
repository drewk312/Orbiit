#ifndef FORGE_CORE_H
#define FORGE_CORE_H

#include <stdint.h>
#include <stddef.h>

#ifdef _WIN32
  #ifdef FORGE_EXPORTS
    #define FORGE_API __declspec(dllexport)
  #else
    #define FORGE_API __declspec(dllimport)
  #endif
#else
  #define FORGE_API
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Initialization
FORGE_API int forge_init(const char* db_path);
FORGE_API void forge_shutdown();
FORGE_API const char* forge_get_version();

// Event polling - call from Dart on timer
FORGE_API const char* forge_poll_event(char* event_type_out, size_t type_size, char* data_out, size_t data_size);

// Scanning - uses Dart native port instead of callback
FORGE_API int forge_scan_start(const char** root_paths, size_t path_count, int incremental, int64_t send_port);
FORGE_API int forge_scan_cancel();

// Library queries - returns JSON
FORGE_API const char* forge_get_library_summary();
FORGE_API const char* forge_get_title_list(const char* filter_json);
FORGE_API const char* forge_get_issues_list(const char* filter_json);

// Task queue - real background processing
FORGE_API int64_t forge_task_enqueue(const char* task_type, const char* payload_json);
FORGE_API int forge_task_pause(int64_t task_id);
FORGE_API int forge_task_resume(int64_t task_id);
FORGE_API int forge_task_cancel(int64_t task_id);
FORGE_API const char* forge_task_get_queue();

// Health engine - real duplicate detection, hashing
FORGE_API const char* forge_generate_fix_plan();
FORGE_API int forge_calculate_hash(const char* file_path, char* hash_output, size_t hash_size);

// Quarantine
FORGE_API int forge_quarantine_title(int title_id, const char* reason);

// Memory management
FORGE_API void forge_free_string(const char* str);

// ==============================================================================
// ISO/WBFS CONVERSION - For REAL jailbroken Wii hardware (USB Loader GX, WiiFlow)
// ==============================================================================

// Callback typedefs (also used by download missions)
typedef void (*ForgeProgressCallback)(int status, float progress, const char* message);
typedef void (*ForgeGameFoundCallback)(const char* filePath, void* identity);

// Mission-based download API (returns mission ID for progress polling)
FORGE_API int forge_start_mission(const char* url, const char* output_path, ForgeProgressCallback callback);
FORGE_API bool forge_cancel_mission(uint64_t mission_id);
FORGE_API bool forge_get_mission_progress(int mission_id, int* status, float* progress, char* message, size_t message_size);

// ISO to WBFS conversion - for real Wii USB loaders
// Returns mission ID for progress tracking via forge_get_mission_progress
FORGE_API int forge_convert_iso_to_wbfs(const char* iso_path, const char* wbfs_output, ForgeProgressCallback callback);

// Split WBFS files for FAT32 (4GB file limit on FAT32 drives)
// USB Loader GX supports: GAMEID.wbfs, GAMEID.wbf1, GAMEID.wbf2, etc.
FORGE_API int forge_split_wbfs_fat32(const char* wbfs_path, ForgeProgressCallback callback);

// File format detection - returns "wbfs", "iso", "gcm", "rvz", "wia", "ciso", or "unknown"
// RVZ/WIA are Dolphin-only formats and will NOT work on real Wii hardware!
FORGE_API const char* forge_get_file_format(const char* file_path);

// Drive formatting (for USB drives - requires admin/elevated privileges)
FORGE_API bool forge_format_drive_32kb(const char* drive_letter, const char* volume_label, ForgeProgressCallback callback);

// Redump database verification
FORGE_API bool forge_verify_redump_hash(const char* file_path, const char* expected_hash);

// Deploy folder structure to USB drive
FORGE_API bool forge_deploy_structure(const char* root_path);

// Folder scanning with callback
FORGE_API int forge_scan_folder(const char* folder_path, bool incremental, ForgeGameFoundCallback callback);

#ifdef __cplusplus
}
#endif

#endif // FORGE_CORE_H
