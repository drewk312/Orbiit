#ifndef FORGE_CORE_H
#define FORGE_CORE_H

#include <stdint.h>

#ifdef _WIN32
#define FUSION_API __declspec(dllexport)
#else
#define FUSION_API __attribute__((visibility("default")))
#endif

extern "C" {
    // 1. DISCOVERY & CLASSIFICATION
    // MAGIC_OFFSET: 0x1C
    // MAGIC_WII_GC: 0x5D1C9EA3
    typedef struct {
        int platform; // 0: Unknown, 1: Wii, 2: GC, 3: WiiU
        char title_id[7];
        char name[128];
    } GameInfo;

    FUSION_API GameInfo identify_game(const char* path);

    // 2. STEALTH ACQUISITION (THE FORGE)
    // Streams: URL -> RAM -> WBFS Conversion -> Hardware
    typedef void (*ForgeCallback)(float progress, const char* status);
    FUSION_API void start_forge_task(const char* url, const char* dest, ForgeCallback callback);

    // 3. THE HARDWARE WIZARD
    // MANDATORY: Cluster size 32KB (0x8000) for Nintendont compatibility
    FUSION_API bool format_wii_drive(const char* drive_letter);
}

#endif
