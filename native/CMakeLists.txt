cmake_minimum_required(VERSION 3.15)
project(forge_core VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Define the library
add_library(forge_core SHARED
    forge_logic.cpp
)

target_include_directories(forge_core
    PUBLIC .
)

# Define FORGE_EXPORTS for Windows DLL export
target_compile_definitions(forge_core PRIVATE FORGE_EXPORTS)

# Set output directory
set_target_properties(forge_core PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
)

# Compiler specific settings
if(MSVC)
    target_compile_options(forge_core PRIVATE /W4)
else()
    target_compile_options(forge_core PRIVATE -Wall -Wextra)
endif()

# Install rules
install(TARGETS forge_core
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
)
