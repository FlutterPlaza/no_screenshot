#ifndef NO_SCREENSHOT_SCREENSHOT_DETECTION_H_
#define NO_SCREENSHOT_SCREENSHOT_DETECTION_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>
#include <thread>

namespace no_screenshot {

// Callback: file_path, timestamp_ms, source_app
using ScreenshotDetectedCallback =
    std::function<void(const std::string&, int64_t, const std::string&)>;

class ScreenshotDetection {
 public:
  explicit ScreenshotDetection(ScreenshotDetectedCallback callback);
  ~ScreenshotDetection();

  void Start();
  void Stop();

 private:
  void ClipboardThreadProc();
  void DirectoryThreadProc();

  static LRESULT CALLBACK ClipboardWndProc(HWND hwnd, UINT msg, WPARAM wparam,
                                           LPARAM lparam);

  ScreenshotDetectedCallback callback_;
  bool running_ = false;

  // Clipboard monitoring
  std::unique_ptr<std::thread> clipboard_thread_;
  HWND clipboard_hwnd_ = nullptr;

  // Directory monitoring
  std::unique_ptr<std::thread> directory_thread_;
  HANDLE dir_stop_event_ = nullptr;
};

}  // namespace no_screenshot

#endif  // NO_SCREENSHOT_SCREENSHOT_DETECTION_H_
