#include "state_persistence.h"

#include <shlobj.h>
#include <windows.h>

#include <cstdio>
#include <cstring>
#include <fstream>
#include <sstream>

namespace no_screenshot {

static std::string get_state_file_path() {
  wchar_t* appdata = nullptr;
  if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_RoamingAppData, 0, nullptr,
                                      &appdata))) {
    char narrow[MAX_PATH * 2] = {};
    WideCharToMultiByte(CP_UTF8, 0, appdata, -1, narrow, sizeof(narrow),
                        nullptr, nullptr);
    CoTaskMemFree(appdata);
    std::string path(narrow);
    path += "\\no_screenshot";
    CreateDirectoryA(path.c_str(), nullptr);
    path += "\\state.json";
    return path;
  }
  return "";
}

StatePersistence::StatePersistence() : file_path_(get_state_file_path()) {}

void StatePersistence::Save(const PersistedState& state) {
  if (file_path_.empty()) return;

  char buf[512];
  std::snprintf(buf, sizeof(buf),
                "{\n"
                "  \"prevent_screenshot\": %s,\n"
                "  \"is_image_overlay_mode\": %s,\n"
                "  \"is_blur_overlay_mode\": %s,\n"
                "  \"is_color_overlay_mode\": %s,\n"
                "  \"blur_radius\": %.1f,\n"
                "  \"color_value\": %d\n"
                "}\n",
                state.prevent_screenshot ? "true" : "false",
                state.is_image_overlay_mode ? "true" : "false",
                state.is_blur_overlay_mode ? "true" : "false",
                state.is_color_overlay_mode ? "true" : "false",
                state.blur_radius, state.color_value);

  std::ofstream ofs(file_path_);
  if (ofs.is_open()) {
    ofs << buf;
  }
}

PersistedState StatePersistence::Load() {
  PersistedState state;
  if (file_path_.empty()) return state;

  std::ifstream ifs(file_path_);
  if (!ifs.is_open()) return state;

  std::stringstream ss;
  ss << ifs.rdbuf();
  std::string contents = ss.str();

  if (contents.find("\"prevent_screenshot\": true") != std::string::npos) {
    state.prevent_screenshot = true;
  }
  if (contents.find("\"is_image_overlay_mode\": true") != std::string::npos) {
    state.is_image_overlay_mode = true;
  }
  if (contents.find("\"is_blur_overlay_mode\": true") != std::string::npos) {
    state.is_blur_overlay_mode = true;
  }
  if (contents.find("\"is_color_overlay_mode\": true") != std::string::npos) {
    state.is_color_overlay_mode = true;
  }

  auto extract_double = [&](const char* key) -> double {
    auto pos = contents.find(key);
    if (pos != std::string::npos) {
      return std::atof(contents.c_str() + pos + std::strlen(key));
    }
    return 0.0;
  };

  double radius = extract_double("\"blur_radius\": ");
  if (radius > 0) state.blur_radius = radius;

  auto extract_int = [&](const char* key) -> int {
    auto pos = contents.find(key);
    if (pos != std::string::npos) {
      return std::atoi(contents.c_str() + pos + std::strlen(key));
    }
    return 0;
  };

  int color = extract_int("\"color_value\": ");
  if (color != 0) state.color_value = color;

  return state;
}

}  // namespace no_screenshot
