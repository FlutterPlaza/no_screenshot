#ifndef NO_SCREENSHOT_RECORDING_DETECTION_H_
#define NO_SCREENSHOT_RECORDING_DETECTION_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>
#include <thread>

namespace no_screenshot {

// Callback: is_recording, process_name
using RecordingStateChangedCallback =
    std::function<void(bool, const std::string&)>;

class RecordingDetection {
 public:
  explicit RecordingDetection(RecordingStateChangedCallback callback);
  ~RecordingDetection();

  void Start();
  void Stop();
  bool is_recording() const { return is_recording_; }

 private:
  void PollThreadProc();

  RecordingStateChangedCallback callback_;
  bool running_ = false;
  bool is_recording_ = false;
  std::string detected_process_;
  std::unique_ptr<std::thread> poll_thread_;
  HANDLE stop_event_ = nullptr;
};

}  // namespace no_screenshot

#endif  // NO_SCREENSHOT_RECORDING_DETECTION_H_
