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

// Scanning - real file system traversal (NO CALLBACK - uses polling)
FORGE_API int forge_scan_start(const char** root_paths, size_t path_count, int incremental);
FORGE_API int forge_scan_cancel();

// Event polling - retrieve queued events
FORGE_API const char* forge_poll_event();  // Returns JSON event or nullptr if queue empty

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

// Free returned strings
FORGE_API void forge_free_string(const char* str);

#ifdef __cplusplus
}
#endif

#endif // FORGE_CORE_H
