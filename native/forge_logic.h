#ifndef FORGE_LOGIC_H
#define FORGE_LOGIC_H

#define NOMINMAX
#include <vector>
#include <string>
#include <stdint.h>
#include <filesystem>

namespace fs = std::filesystem;

void debugPrint(const std::string& message);

// Constants
constexpr size_t WBFS_SECTOR_SIZE = 0x8000;
constexpr size_t WBFS_HEADER_SIZE = 0x300;
constexpr size_t MAX_WBFS_SPLIT_SIZE = 0xFB040000;

// WBFS Header Structure
struct WbfsHeader {
    uint8_t magic[4];           // "WBFS"
    uint32_t sector_size_shift; // Sector size = 2^shift
    uint32_t sector_count;      // Total sectors on device
    uint8_t disc_table[500];    // Disc table (1 bit per slot)
    uint8_t reserved[16];
};

// Disc Info Structure
struct DiscInfo {
    char title_id[8];           // 6-byte ID + 2-byte maker code
    char title[64];             // Game title
    uint32_t sector_count;      // Number of sectors used
    uint32_t disc_header_offset; // Offset to disc header
};

class NodEngine {
public:
    enum class Format { ISO, WBFS, RVZ };
    static bool ConvertInMemory(const uint8_t* input_data, size_t input_size,
                               Format input_format, Format output_format,
                               std::vector<uint8_t>& output_data);
};

class WbfsSplitter {
public:
    struct SplitInfo {
        std::vector<std::string> part_files;
        std::vector<size_t> part_sizes;
        bool needs_splitting;
    };
    static SplitInfo AnalyzeFile(const std::string& file_path);
    static bool SplitFile(const std::string& input_path, const SplitInfo& info);
};

class PartitionStripper {
public:
    enum class PartitionType : uint32_t { UPDATE = 0x01, CHANNEL = 0x02, GAME = 0x03 };
    struct PartitionInfo {
        uint32_t offset;
        uint32_t size;
        PartitionType type;
        bool should_keep;
    };
    static std::vector<PartitionInfo> AnalyzePartitions(const uint8_t* disc_data, size_t disc_size);
    static bool StripPartitions(std::vector<uint8_t>& disc_data, const std::vector<PartitionInfo>& partitions);
};

class IntegrityAuditor {
public:
    static bool VerifySHA1(const std::string& file_path, const std::string& expected_hash);
    static std::string CalculateSHA1(const std::vector<uint8_t>& data);
    static bool VerifyRedumpHash(const std::string& file_path, const std::string& game_id);
};

class HardwareWizard {
public:
    static bool FormatDrive32KB(const std::string& drive_path, const std::string& label);
};

#endif // FORGE_LOGIC_H
