﻿set(Qt5_DIR "D:/GreenTools/Qt/6.5.3_installed/lib/cmake/Qt6")
list(APPEND CMAKE_LIBRARY_PATH "D:/GreenTools/Qt/6.5.3_installed/lib")
list(APPEND CMAKE_PREFIX_PATH "D:/GreenTools/Qt/6.5.3_installed/lib")
set(Qt_version Qt6)

set(CMAKE_TOOLCHAIN_FILE "D:/GreenTools/vcpkg/scripts/buildsystems/vcpkg.cmake" CACHE STRING "Vcpkg toolchain file")

set(CMAKE_SYSTEM_VERSION 10.0.22621.0)
set(CMAKE_CXX_STANDARD 20)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG ${CMAKE_BINARY_DIR}/output/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR}/output/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG ${CMAKE_BINARY_DIR}/output/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR}/output/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_BINARY_DIR}/output/bin)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR}/output/bin)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/output)

if(CMAKE_BUILD_TYPE AND (CMAKE_BUILD_TYPE STREQUAL "Release"))
    set(CMAKE_CONFIGURATION_TYPES "Release" CACHE STRING "Configuration types" FORCE)
else()
    set(CMAKE_CONFIGURATION_TYPES "Debug" CACHE STRING "Configuration types" FORCE)
endif()
