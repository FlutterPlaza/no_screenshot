#include "screenshot_detection.h"

#include <shlobj.h>
#include <shlwapi.h>

#include <algorithm>
#include <chrono>
#include <cstring>

namespace no_screenshot {

static int64_t now_ms() {
  return std::chrono::duration_cast<std::chrono::milliseconds>(
             std::chrono::system_clock::now().time_since_epoch())
      .count();
}

static bool is_screenshot_filename(const std::wstring& name) {
  // Convert to lowercase for matching.
  std::wstring lower = name;
  std::transform(lower.begin(), lower.end(), lower.begin(), ::towlower);

  // Common Windows screenshot patterns.
  if (lower.find(L"screenshot") != std::wstring::npos) return true;
  if (lower.find(L"capture") != std::wstring::npos) return true;
  if (lower.find(L"snip") != std::wstring::npos) return true;
  return false;
}

// ---------------------------------------------------------------------------
// Clipboard monitoring
// ---------------------------------------------------------------------------

static const wchar_t kClipboardClassName[] =
    L"NoScreenshotClipboardListener";

ScreenshotDetection::ScreenshotDetection(ScreenshotDetectedCallback callback)
    : callback_(std::move(callback)) {}

ScreenshotDetection::~ScreenshotDetection() { Stop(); }

LRESULT CALLBACK ScreenshotDetection::ClipboardWndProc(HWND hwnd, UINT msg,
                                                       WPARAM wparam,
                                                       LPARAM lparam) {
  if (msg == WM_CLIPBOARDUPDATE) {
    auto* self =
        reinterpret_cast<ScreenshotDetection*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));
    if (self && self->callback_) {
      // Check if clipboard contains a bitmap.
      if (IsClipboardFormatAvailable(CF_BITMAP) ||
          IsClipboardFormatAvailable(CF_DIB)) {
        self->callback_("clipboard_screenshot", now_ms(), "");
      }
    }
    return 0;
  }
  return DefWindowProc(hwnd, msg, wparam, lparam);
}

void ScreenshotDetection::ClipboardThreadProc() {
  WNDCLASSEXW wc = {};
  wc.cbSize = sizeof(wc);
  wc.lpfnWndProc = ClipboardWndProc;
  wc.hInstance = GetModuleHandle(nullptr);
  wc.lpszClassName = kClipboardClassName;
  RegisterClassExW(&wc);

  clipboard_hwnd_ = CreateWindowExW(0, kClipboardClassName, L"", 0, 0, 0, 0, 0,
                                     HWND_MESSAGE, nullptr,
                                     GetModuleHandle(nullptr), nullptr);
  if (clipboard_hwnd_) {
    SetWindowLongPtr(clipboard_hwnd_, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(this));
    AddClipboardFormatListener(clipboard_hwnd_);
  }

  MSG msg;
  while (running_ && GetMessage(&msg, nullptr, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }

  if (clipboard_hwnd_) {
    RemoveClipboardFormatListener(clipboard_hwnd_);
    DestroyWindow(clipboard_hwnd_);
    clipboard_hwnd_ = nullptr;
  }
  UnregisterClassW(kClipboardClassName, GetModuleHandle(nullptr));
}

// ---------------------------------------------------------------------------
// Directory monitoring
// ---------------------------------------------------------------------------

void ScreenshotDetection::DirectoryThreadProc() {
  // Monitor %USERPROFILE%\Pictures\Screenshots
  wchar_t pictures_path[MAX_PATH] = {};
  if (FAILED(SHGetFolderPathW(nullptr, CSIDL_MYPICTURES, nullptr, 0,
                               pictures_path))) {
    return;
  }

  std::wstring screenshots_dir = std::wstring(pictures_path) + L"\\Screenshots";

  // Create the directory if it doesn't exist (so monitoring doesn't fail).
  CreateDirectoryW(screenshots_dir.c_str(), nullptr);

  HANDLE dir_handle = CreateFileW(
      screenshots_dir.c_str(), FILE_LIST_DIRECTORY,
      FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
      OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OVERLAPPED,
      nullptr);

  if (dir_handle == INVALID_HANDLE_VALUE) return;

  OVERLAPPED overlapped = {};
  overlapped.hEvent = CreateEvent(nullptr, TRUE, FALSE, nullptr);
  BYTE buffer[4096];
  HANDLE events[2] = {overlapped.hEvent, dir_stop_event_};

  while (running_) {
    DWORD bytes_returned = 0;
    if (!ReadDirectoryChangesW(dir_handle, buffer, sizeof(buffer), FALSE,
                                FILE_NOTIFY_CHANGE_FILE_NAME, &bytes_returned,
                                &overlapped, nullptr)) {
      break;
    }

    DWORD wait_result = WaitForMultipleObjects(2, events, FALSE, INFINITE);
    if (wait_result == WAIT_OBJECT_0 + 1) {
      // Stop event signaled.
      CancelIo(dir_handle);
      break;
    }

    if (wait_result == WAIT_OBJECT_0) {
      if (!GetOverlappedResult(dir_handle, &overlapped, &bytes_returned,
                                FALSE)) {
        continue;
      }

      FILE_NOTIFY_INFORMATION* info =
          reinterpret_cast<FILE_NOTIFY_INFORMATION*>(buffer);
      while (info) {
        if (info->Action == FILE_ACTION_ADDED) {
          std::wstring wname(info->FileName,
                             info->FileNameLength / sizeof(wchar_t));
          if (is_screenshot_filename(wname)) {
            // Convert wide string path to UTF-8.
            std::wstring full_path = screenshots_dir + L"\\" + wname;
            int size_needed = WideCharToMultiByte(CP_UTF8, 0, full_path.c_str(),
                                                  -1, nullptr, 0, nullptr,
                                                  nullptr);
            std::string utf8_path(size_needed - 1, 0);
            WideCharToMultiByte(CP_UTF8, 0, full_path.c_str(), -1,
                                &utf8_path[0], size_needed, nullptr, nullptr);

            if (callback_) {
              callback_(utf8_path, now_ms(), "");
            }
          }
        }

        if (info->NextEntryOffset == 0) break;
        info = reinterpret_cast<FILE_NOTIFY_INFORMATION*>(
            reinterpret_cast<BYTE*>(info) + info->NextEntryOffset);
      }
      ResetEvent(overlapped.hEvent);
    }
  }

  CloseHandle(overlapped.hEvent);
  CloseHandle(dir_handle);
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

void ScreenshotDetection::Start() {
  if (running_) return;
  running_ = true;

  dir_stop_event_ = CreateEvent(nullptr, TRUE, FALSE, nullptr);

  clipboard_thread_ =
      std::make_unique<std::thread>(&ScreenshotDetection::ClipboardThreadProc, this);
  directory_thread_ =
      std::make_unique<std::thread>(&ScreenshotDetection::DirectoryThreadProc, this);
}

void ScreenshotDetection::Stop() {
  if (!running_) return;
  running_ = false;

  // Signal the directory thread to stop.
  if (dir_stop_event_) {
    SetEvent(dir_stop_event_);
  }

  // Post quit to clipboard message loop.
  if (clipboard_hwnd_) {
    PostMessage(clipboard_hwnd_, WM_QUIT, 0, 0);
  }

  if (clipboard_thread_ && clipboard_thread_->joinable()) {
    clipboard_thread_->join();
  }
  clipboard_thread_.reset();

  if (directory_thread_ && directory_thread_->joinable()) {
    directory_thread_->join();
  }
  directory_thread_.reset();

  if (dir_stop_event_) {
    CloseHandle(dir_stop_event_);
    dir_stop_event_ = nullptr;
  }
}

}  // namespace no_screenshot
