#include "no_screenshot_plugin.h"

#include "screenshot_prevention.h"

#include <chrono>
#include <sstream>

namespace no_screenshot {

NoScreenshotPlugin* NoScreenshotPlugin::instance_ = nullptr;

static const char kMethodChannelName[] =
    "com.flutterplaza.no_screenshot_methods";
static const char kEventChannelName[] =
    "com.flutterplaza.no_screenshot_streams";

// static
void NoScreenshotPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<NoScreenshotPlugin>(registrar);
  instance_ = plugin.get();
  registrar->AddPlugin(std::move(plugin));
}

NoScreenshotPlugin::NoScreenshotPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {
  // Method channel
  method_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), kMethodChannelName,
          &flutter::StandardMethodCodec::GetInstance());
  method_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleMethodCall(call, std::move(result));
      });

  // Event channel
  event_channel_ =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          registrar->messenger(), kEventChannelName,
          &flutter::StandardMethodCodec::GetInstance());

  auto handler =
      std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [this](const flutter::EncodableValue* arguments,
                 std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&&
                     events) {
            event_sink_ = std::move(events);
            StartEventStream();
            return std::unique_ptr<flutter::StreamHandlerError<
                flutter::EncodableValue>>();
          },
          [this](const flutter::EncodableValue* arguments) {
            StopEventStream();
            event_sink_ = nullptr;
            return std::unique_ptr<flutter::StreamHandlerError<
                flutter::EncodableValue>>();
          });
  event_channel_->SetStreamHandler(std::move(handler));

  // Screenshot detection subsystem
  detection_ = std::make_unique<ScreenshotDetection>(
      [this](const std::string& path, int64_t ts, const std::string& app) {
        last_timestamp_ms_ = ts;
        last_source_app_ = app;
        UpdateSharedState(path, ts, app);
      });

  // Recording detection subsystem
  recording_detection_ = std::make_unique<RecordingDetection>(
      [this](bool is_recording, const std::string& process_name) {
        is_screen_recording_ = is_recording;
        last_timestamp_ms_ =
            std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch())
                .count();
        last_source_app_ = process_name;
        UpdateSharedState("", last_timestamp_ms_, last_source_app_);
      });

  // Load persisted state
  PersistedState state = persistence_.Load();
  prevent_screenshot_ = state.prevent_screenshot;
  is_image_overlay_mode_ = state.is_image_overlay_mode;
  is_blur_overlay_mode_ = state.is_blur_overlay_mode;
  is_color_overlay_mode_ = state.is_color_overlay_mode;
  blur_radius_ = state.blur_radius;
  color_value_ = state.color_value;

  if (prevent_screenshot_) {
    HWND hwnd = GetFlutterWindowHandle();
    if (hwnd) PreventionActivate(hwnd);
  }

  // Initial state push
  UpdateSharedState("");
}

NoScreenshotPlugin::~NoScreenshotPlugin() {
  StopEventStream();
  if (detection_) detection_->Stop();
  if (recording_detection_) recording_detection_->Stop();
  if (instance_ == this) instance_ = nullptr;
}

HWND NoScreenshotPlugin::GetFlutterWindowHandle() {
  return registrar_->GetView()->GetNativeWindow();
}

// ---------------------------------------------------------------------------
// Method call handler
// ---------------------------------------------------------------------------

void NoScreenshotPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = method_call.method_name();

  if (method == "screenshotOff") {
    prevent_screenshot_ = true;
    PreventionActivate(GetFlutterWindowHandle());
    PersistState();
    result->Success(flutter::EncodableValue(true));

  } else if (method == "screenshotOn") {
    prevent_screenshot_ = false;
    PreventionDeactivate(GetFlutterWindowHandle());
    PersistState();
    result->Success(flutter::EncodableValue(true));

  } else if (method == "toggleScreenshot") {
    if (prevent_screenshot_) {
      prevent_screenshot_ = false;
      PreventionDeactivate(GetFlutterWindowHandle());
    } else {
      prevent_screenshot_ = true;
      PreventionActivate(GetFlutterWindowHandle());
    }
    PersistState();
    result->Success(flutter::EncodableValue(true));

  } else if (method == "toggleScreenshotWithImage") {
    is_image_overlay_mode_ = !is_image_overlay_mode_;
    if (is_image_overlay_mode_) {
      is_blur_overlay_mode_ = false;
      is_color_overlay_mode_ = false;
      prevent_screenshot_ = true;
      PreventionActivate(GetFlutterWindowHandle());
    } else {
      prevent_screenshot_ = false;
      PreventionDeactivate(GetFlutterWindowHandle());
    }
    PersistState();
    result->Success(flutter::EncodableValue(is_image_overlay_mode_));

  } else if (method == "toggleScreenshotWithBlur") {
    const auto* args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto it = args->find(flutter::EncodableValue("radius"));
      if (it != args->end()) {
        blur_radius_ = std::get<double>(it->second);
      }
    }
    is_blur_overlay_mode_ = !is_blur_overlay_mode_;
    if (is_blur_overlay_mode_) {
      is_image_overlay_mode_ = false;
      is_color_overlay_mode_ = false;
      prevent_screenshot_ = true;
      PreventionActivate(GetFlutterWindowHandle());
    } else {
      prevent_screenshot_ = false;
      PreventionDeactivate(GetFlutterWindowHandle());
    }
    PersistState();
    result->Success(flutter::EncodableValue(is_blur_overlay_mode_));

  } else if (method == "toggleScreenshotWithColor") {
    const auto* args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto it = args->find(flutter::EncodableValue("color"));
      if (it != args->end()) {
        color_value_ = std::get<int>(it->second);
      }
    }
    is_color_overlay_mode_ = !is_color_overlay_mode_;
    if (is_color_overlay_mode_) {
      is_image_overlay_mode_ = false;
      is_blur_overlay_mode_ = false;
      prevent_screenshot_ = true;
      PreventionActivate(GetFlutterWindowHandle());
    } else {
      prevent_screenshot_ = false;
      PreventionDeactivate(GetFlutterWindowHandle());
    }
    PersistState();
    result->Success(flutter::EncodableValue(is_color_overlay_mode_));

  } else if (method == "screenshotWithImage") {
    is_image_overlay_mode_ = true;
    is_blur_overlay_mode_ = false;
    is_color_overlay_mode_ = false;
    prevent_screenshot_ = true;
    PreventionActivate(GetFlutterWindowHandle());
    PersistState();
    result->Success(flutter::EncodableValue(true));

  } else if (method == "screenshotWithBlur") {
    const auto* args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto it = args->find(flutter::EncodableValue("radius"));
      if (it != args->end()) {
        blur_radius_ = std::get<double>(it->second);
      }
    }
    is_blur_overlay_mode_ = true;
    is_image_overlay_mode_ = false;
    is_color_overlay_mode_ = false;
    prevent_screenshot_ = true;
    PreventionActivate(GetFlutterWindowHandle());
    PersistState();
    result->Success(flutter::EncodableValue(true));

  } else if (method == "screenshotWithColor") {
    const auto* args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto it = args->find(flutter::EncodableValue("color"));
      if (it != args->end()) {
        color_value_ = std::get<int>(it->second);
      }
    }
    is_color_overlay_mode_ = true;
    is_image_overlay_mode_ = false;
    is_blur_overlay_mode_ = false;
    prevent_screenshot_ = true;
    PreventionActivate(GetFlutterWindowHandle());
    PersistState();
    result->Success(flutter::EncodableValue(true));

  } else if (method == "startScreenshotListening") {
    if (!is_listening_) {
      is_listening_ = true;
      detection_->Start();
      PersistState();
    }
    result->Success(flutter::EncodableValue("Listening started"));

  } else if (method == "stopScreenshotListening") {
    if (is_listening_) {
      is_listening_ = false;
      detection_->Stop();
      PersistState();
    }
    result->Success(flutter::EncodableValue("Listening stopped"));

  } else if (method == "startScreenRecordingListening") {
    if (!is_recording_listening_) {
      is_recording_listening_ = true;
      recording_detection_->Start();
      UpdateSharedState("");
    }
    result->Success(flutter::EncodableValue("Recording listening started"));

  } else if (method == "stopScreenRecordingListening") {
    if (is_recording_listening_) {
      is_recording_listening_ = false;
      recording_detection_->Stop();
      is_screen_recording_ = false;
      UpdateSharedState("");
    }
    result->Success(flutter::EncodableValue("Recording listening stopped"));

  } else {
    result->NotImplemented();
  }
}

// ---------------------------------------------------------------------------
// Event stream
// ---------------------------------------------------------------------------

void CALLBACK NoScreenshotPlugin::StreamTimerCallback(HWND hwnd, UINT msg,
                                                      UINT_PTR id,
                                                      DWORD time) {
  if (instance_ && instance_->has_pending_event_ && instance_->event_sink_) {
    instance_->event_sink_->Success(
        flutter::EncodableValue(instance_->last_event_json_));
    instance_->has_pending_event_ = false;
  }
}

void NoScreenshotPlugin::StartEventStream() {
  if (stream_timer_id_ == 0) {
    stream_timer_id_ = SetTimer(nullptr, 0, 1000, StreamTimerCallback);
  }
}

void NoScreenshotPlugin::StopEventStream() {
  if (stream_timer_id_ != 0) {
    KillTimer(nullptr, stream_timer_id_);
    stream_timer_id_ = 0;
  }
}

// ---------------------------------------------------------------------------
// State management
// ---------------------------------------------------------------------------

std::string NoScreenshotPlugin::BuildEventJson() {
  std::ostringstream oss;
  oss << "{\"is_screenshot_on\":" << (prevent_screenshot_ ? "true" : "false")
      << ",\"screenshot_path\":\"" << last_event_path_ << "\""
      << ",\"was_screenshot_taken\":"
      << (!last_event_path_.empty() ? "true" : "false")
      << ",\"is_screen_recording\":"
      << (is_screen_recording_ ? "true" : "false")
      << ",\"timestamp\":" << last_timestamp_ms_
      << ",\"source_app\":\"" << last_source_app_ << "\"}";
  return oss.str();
}

void NoScreenshotPlugin::UpdateSharedState(const std::string& screenshot_path,
                                           int64_t timestamp_ms,
                                           const std::string& source_app) {
  if (timestamp_ms > 0) last_timestamp_ms_ = timestamp_ms;
  if (!source_app.empty()) last_source_app_ = source_app;
  last_event_path_ = screenshot_path;

  std::string json = BuildEventJson();
  if (json != last_event_json_) {
    last_event_json_ = json;
    has_pending_event_ = true;
  }
}

void NoScreenshotPlugin::PersistState() {
  PersistedState state;
  state.prevent_screenshot = prevent_screenshot_;
  state.is_image_overlay_mode = is_image_overlay_mode_;
  state.is_blur_overlay_mode = is_blur_overlay_mode_;
  state.is_color_overlay_mode = is_color_overlay_mode_;
  state.blur_radius = blur_radius_;
  state.color_value = color_value_;
  persistence_.Save(state);
  UpdateSharedState("");
}

}  // namespace no_screenshot
