#ifndef NO_SCREENSHOT_STATE_PERSISTENCE_H_
#define NO_SCREENSHOT_STATE_PERSISTENCE_H_

#include <string>

namespace no_screenshot {

struct PersistedState {
  bool prevent_screenshot = false;
  bool is_image_overlay_mode = false;
  bool is_blur_overlay_mode = false;
  bool is_color_overlay_mode = false;
  double blur_radius = 30.0;
  int color_value = static_cast<int>(0xFF000000);
};

class StatePersistence {
 public:
  StatePersistence();

  void Save(const PersistedState& state);
  PersistedState Load();

 private:
  std::string file_path_;
};

}  // namespace no_screenshot

#endif  // NO_SCREENSHOT_STATE_PERSISTENCE_H_
