cmake_minimum_required(VERSION 3.20)
project(forge_core VERSION 0.1.0 LANGUAGES CXX)

# MSVC: Disable warnings for standard C functions
if(MSVC)
    add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
endif()

# Force export definition for Windows DLL generation
if(WIN32)
    add_compile_definitions("FORGE_EXPORT=__declspec(dllexport)")
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Source files
set(FORGE_SOURCES
    forge_manager.cpp
    platform_identifier.cpp
    banner_parser.cpp
    handshake_core.cpp
    ../native/forge_logic.cpp
)

# Build shared library for FFI
add_library(forge_core SHARED ${FORGE_SOURCES})
target_link_libraries(forge_core PRIVATE winhttp kernel32 user32 shell32)

# Platform-specific settings
# The header forge_manager.h handles FORGE_EXPORT via #ifndef check
# so we don't need to define it here

# Dependencies
# Standard Win32 API and WinHTTP dependencies handled via forge_manager.cpp

# Install
install(TARGETS forge_core
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)

install(FILES forge_manager.h
    DESTINATION include
)
