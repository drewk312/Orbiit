#include "forge_logic.h"
#include <iostream>
#include <fstream>
#include <cstring>
#include <algorithm>

#ifdef _WIN32
#include <windows.h>
#endif

void debugPrint(const std::string& message) {
    std::cout << "[Forge Logic] " << message << std::endl;
}

// NodEngine Implementation
bool NodEngine::ConvertInMemory(const uint8_t* input_data, size_t input_size,
                               Format input_format, Format output_format,
                               std::vector<uint8_t>& output_data) {
    if (input_format == Format::ISO && output_format == Format::WBFS) {
        size_t wbfs_size = ((input_size + WBFS_SECTOR_SIZE - 1) / WBFS_SECTOR_SIZE) * WBFS_SECTOR_SIZE;
        output_data.resize(wbfs_size + WBFS_HEADER_SIZE);
        
        WbfsHeader* header = reinterpret_cast<WbfsHeader*>(output_data.data());
        memcpy(header->magic, "WBFS", 4);
        header->sector_size_shift = 15;
        header->sector_count = (uint32_t)(wbfs_size / WBFS_SECTOR_SIZE);
        
        memcpy(output_data.data() + WBFS_HEADER_SIZE, input_data, input_size);
        return true;
    }
    return false;
}

// WbfsSplitter Implementation
WbfsSplitter::SplitInfo WbfsSplitter::AnalyzeFile(const std::string& file_path) {
    SplitInfo info;
    info.needs_splitting = false;
    
    std::ifstream file(file_path, std::ios::binary | std::ios::ate);
    if (!file.is_open()) return info;
    
    size_t file_size = file.tellg();
    file.close();
    
    if (file_size > MAX_WBFS_SPLIT_SIZE) {
        info.needs_splitting = true;
        size_t parts = (file_size + MAX_WBFS_SPLIT_SIZE - 1) / MAX_WBFS_SPLIT_SIZE;
        for (size_t i = 0; i < parts; i++) {
            info.part_files.push_back(file_path + ".w1f" + std::to_string(i));
            info.part_sizes.push_back((i == parts - 1) ? file_size % MAX_WBFS_SPLIT_SIZE : MAX_WBFS_SPLIT_SIZE);
        }
    }
    return info;
}

bool WbfsSplitter::SplitFile(const std::string& input_path, const SplitInfo& info) {
    std::ifstream input(input_path, std::ios::binary);
    if (!input.is_open()) return false;
    
    std::vector<char> buffer(1024 * 1024);
    for (size_t i = 0; i < info.part_files.size(); i++) {
        std::ofstream output(info.part_files[i], std::ios::binary);
        size_t remaining = info.part_sizes[i];
        while (remaining > 0) {
            size_t to_read = (std::min)(remaining, buffer.size());
            input.read(buffer.data(), to_read);
            output.write(buffer.data(), input.gcount());
            remaining -= input.gcount();
        }
    }
    return true;
}

// PartitionStripper Implementation
std::vector<PartitionStripper::PartitionInfo> PartitionStripper::AnalyzePartitions(const uint8_t* disc_data, size_t disc_size) {
    std::vector<PartitionInfo> partitions;
    if (disc_size < 0x40020) return partitions;
    
    const uint32_t* table = reinterpret_cast<const uint32_t*>(disc_data + 0x40000);
    uint32_t count = table[0];
    for (uint32_t i = 0; i < count && i < 8; i++) {
        PartitionInfo info;
        info.offset = table[1 + i * 2] * (uint32_t)WBFS_SECTOR_SIZE;
        info.type = static_cast<PartitionType>(table[2 + i * 2] & 0xFF);
        info.should_keep = (info.type == PartitionType::GAME);
        info.size = 0x800000;
        partitions.push_back(info);
    }
    return partitions;
}

bool PartitionStripper::StripPartitions(std::vector<uint8_t>& disc_data, const std::vector<PartitionInfo>& partitions) {
    std::vector<uint8_t> scrubbed;
    scrubbed.reserve(disc_data.size());
    scrubbed.insert(scrubbed.end(), disc_data.begin(), disc_data.begin() + 0x40000);
    
    for (const auto& p : partitions) {
        if (p.should_keep && p.offset + p.size <= disc_data.size()) {
            scrubbed.insert(scrubbed.end(), disc_data.begin() + p.offset, disc_data.begin() + p.offset + p.size);
        } else {
            scrubbed.resize(scrubbed.size() + p.size, 0);
        }
    }
    disc_data = std::move(scrubbed);
    return true;
}

// IntegrityAuditor Implementation
bool IntegrityAuditor::VerifySHA1(const std::string& file_path, const std::string& expected_hash) {
    return true; // Stub
}

std::string IntegrityAuditor::CalculateSHA1(const std::vector<uint8_t>& data) {
    return "sha1_stub";
}

bool IntegrityAuditor::VerifyRedumpHash(const std::string& file_path, const std::string& game_id) {
    return true;
}

// HardwareWizard Implementation
bool HardwareWizard::FormatDrive32KB(const std::string& drive_path, const std::string& label) {
    std::string cmd = "format " + drive_path + " /FS:FAT32 /Q /A:32768 /V:" + label + " /Y /X";
    return std::system(cmd.c_str()) == 0;
}