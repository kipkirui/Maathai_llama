cmake_minimum_required(VERSION 3.22)

project(maathai_llamma LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

add_compile_options(
    $<$<COMPILE_LANGUAGE:CXX>:-fexceptions>
)

set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TOOLS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(LLAMA_ALL_WARNINGS OFF CACHE BOOL "" FORCE)
set(GGML_ALL_WARNINGS OFF CACHE BOOL "" FORCE)
set(GGML_CPU ON CACHE BOOL "" FORCE)
set(GGML_BLAS OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP ON CACHE BOOL "" FORCE)
set(GGML_VULKAN OFF CACHE BOOL "" FORCE)

set(LLAMA_DISABLE_LOGS ON CACHE BOOL "" FORCE)

add_subdirectory(
    ${CMAKE_CURRENT_SOURCE_DIR}/../../../../extern/llama.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/llama-build
)

add_library(maathai_llamma SHARED
    maathai_llamma_bridge.cpp
)

target_include_directories(maathai_llamma PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../../../../extern/llama.cpp/include
)

target_compile_definitions(maathai_llamma PRIVATE
    GGML_USE_K_QUANTS
    _POSIX_C_SOURCE=200809L
    _GNU_SOURCE
)

find_library(log-lib log)

find_package(OpenMP)
if (OpenMP_CXX_FOUND)
    target_link_libraries(maathai_llamma PRIVATE OpenMP::OpenMP_CXX)
else()
    target_compile_options(maathai_llamma PRIVATE -fopenmp)
    target_link_options(maathai_llamma PRIVATE -fopenmp)
endif()

target_link_libraries(maathai_llamma PRIVATE
    llama
    ${log-lib}
)
