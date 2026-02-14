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
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)
target_link_libraries(${PLUGIN_NAME} PRIVATE shlwapi)
