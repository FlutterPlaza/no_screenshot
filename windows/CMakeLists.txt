cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "no_screenshot")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "no_screenshot_plugin")

add_library(${PLUGIN_NAME} SHARED
  "no_screenshot_plugin.cpp"
  "no_screenshot_plugin_c_api.cpp"
  "screenshot_prevention.cpp"
  "screenshot_detection.cpp"
  "recording_detection.cpp"
  "state_persistence.cpp"
  "window_affinity.cpp"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)
target_link_libraries(${PLUGIN_NAME} PRIVATE shlwapi)

# === Tests ===
# Built when the example app sets include_no_screenshot_tests (see
# example/windows/CMakeLists.txt), following the flutter/packages pattern.

if (${include_${PROJECT_NAME}_tests})
set(TEST_RUNNER "${PROJECT_NAME}_test")
enable_testing()
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/v1.15.2.zip
)
# Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
# Disable install commands for gtest so it doesn't end up in the bundle.
set(INSTALL_GTEST OFF CACHE BOOL "Disable installation of googletest" FORCE)

FetchContent_MakeAvailable(googletest)

# The display-affinity logic under test (#119/#128) is pure Win32, so the
# sources are compiled directly into the test binary — no Flutter engine or
# wrapper dependency is needed.
add_executable(${TEST_RUNNER}
  test/no_screenshot_windows_test.cpp
  window_affinity.cpp
  screenshot_prevention.cpp
)
apply_standard_settings(${TEST_RUNNER})
target_include_directories(${TEST_RUNNER} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(${TEST_RUNNER} PRIVATE gtest_main)

include(GoogleTest)
gtest_discover_tests(${TEST_RUNNER})
endif()
