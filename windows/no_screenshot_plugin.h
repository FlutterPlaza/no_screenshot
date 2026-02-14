#ifndef NO_SCREENSHOT_PLUGIN_H_
#define NO_SCREENSHOT_PLUGIN_H_

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <memory>
#include <string>

#include "recording_detection.h"
#include "screenshot_detection.h"
#include "state_persistence.h"

namespace no_screenshot {

class NoScreenshotPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  NoScreenshotPlugin(flutter::PluginRegistrarWindows* registrar);
  virtual ~NoScreenshotPlugin();

  // Disallow copy and assign.
  NoScreenshotPlugin(const NoScreenshotPlugin&) = delete;
  NoScreenshotPlugin& operator=(const NoScreenshotPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Event stream
  void StartEventStream();
  void StopEventStream();
  static void CALLBACK StreamTimerCallback(HWND hwnd, UINT msg, UINT_PTR id,
                                           DWORD time);

  // State management
  void UpdateSharedState(const std::string& screenshot_path,
                         int64_t timestamp_ms = 0,
                         const std::string& source_app = "");
  void PersistState();
  std::string BuildEventJson();

  // Helpers
  HWND GetFlutterWindowHandle();

  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>
      event_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;

  // State
  bool prevent_screenshot_ = false;
  bool is_image_overlay_mode_ = false;
  bool is_blur_overlay_mode_ = false;
  bool is_color_overlay_mode_ = false;
  double blur_radius_ = 30.0;
  int color_value_ = static_cast<int>(0xFF000000);
  bool is_listening_ = false;
  bool is_recording_listening_ = false;
  bool is_screen_recording_ = false;

  // Event stream
  std::string last_event_json_;
  std::string last_event_path_;
  bool has_pending_event_ = false;
  UINT_PTR stream_timer_id_ = 0;

  // P8 metadata
  int64_t last_timestamp_ms_ = 0;
  std::string last_source_app_;

  // Subsystems
  std::unique_ptr<ScreenshotDetection> detection_;
  std::unique_ptr<RecordingDetection> recording_detection_;
  StatePersistence persistence_;

  // Static instance pointer for timer callback.
  static NoScreenshotPlugin* instance_;
};

}  // namespace no_screenshot

#endif  // NO_SCREENSHOT_PLUGIN_H_
