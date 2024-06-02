set(Qt5_DIR "D:/GreenTools/Qt/5.15.12_installed/lib/cmake/Qt5")
list(APPEND CMAKE_LIBRARY_PATH "D:/GreenTools/Qt/5.15.12_installed/lib")
list(APPEND CMAKE_PREFIX_PATH "D:/GreenTools/Qt/5.15.12_installed/lib")

# 提供 OpenSSL 路径
set(OPENSSL_ROOT_DIR "D:/GreenTools/openssl/openssl-3.3.0-installed")
set(OPENSSL_INCLUDE_DIR "D:/GreenTools/openssl/openssl-3.3.0-installed/include")
set(OPENSSL_LIBRARIES "D:/GreenTools/openssl/openssl-3.3.0-installed/lib")

set(CMAKE_SYSTEM_VERSION 10.0.18362.0)
set(CMAKE_CXX_STANDARD 14)

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
