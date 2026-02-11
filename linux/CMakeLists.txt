cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "no_screenshot")
project(${PROJECT_NAME} LANGUAGES CXX C)

set(PLUGIN_NAME "no_screenshot_plugin")

add_library(${PLUGIN_NAME} SHARED
  "no_screenshot_plugin.cc"
  "screenshot_prevention.cc"
  "screenshot_detection.cc"
  "state_persistence.cc"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)
