#include "recording_detection.h"

#include <tlhelp32.h>

#include <algorithm>
#include <vector>

namespace no_screenshot {

static const std::vector<std::string> kKnownRecordingProcesses = {
    "obs64.exe",
    "obs32.exe",
    "ffmpeg.exe",
    "Bandicam.exe",
    "bdcam.exe",
    "CamtasiaStudio.exe",
    "CamtasiaRecorder.exe",
    "ScreenToGif.exe",
    "ShareX.exe",
    "XSplit.Core.exe",
    "Streamlabs OBS.exe",
};

static bool is_known_recording_process(const std::string& name) {
  for (const auto& known : kKnownRecordingProcesses) {
    // Case-insensitive compare.
    if (name.size() == known.size() &&
        _stricmp(name.c_str(), known.c_str()) == 0) {
      return true;
    }
  }
  return false;
}

RecordingDetection::RecordingDetection(RecordingStateChangedCallback callback)
    : callback_(std::move(callback)) {}

RecordingDetection::~RecordingDetection() { Stop(); }

void RecordingDetection::PollThreadProc() {
  while (running_) {
    bool found = false;
    std::string matched_name;

    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snapshot != INVALID_HANDLE_VALUE) {
      PROCESSENTRY32 entry = {};
      entry.dwSize = sizeof(entry);

      if (Process32First(snapshot, &entry)) {
        do {
          // Convert wide char to narrow string.
          char narrow[MAX_PATH] = {};
          WideCharToMultiByte(CP_UTF8, 0, entry.szExeFile, -1, narrow,
                              MAX_PATH, nullptr, nullptr);
          std::string exe_name(narrow);

          if (is_known_recording_process(exe_name)) {
            found = true;
            matched_name = exe_name;
            break;
          }
        } while (Process32Next(snapshot, &entry));
      }
      CloseHandle(snapshot);
    }

    if (found != is_recording_) {
      is_recording_ = found;
      detected_process_ = found ? matched_name : "";
      if (callback_) {
        callback_(is_recording_, detected_process_);
      }
    }

    // Wait 2 seconds or until stop event.
    if (stop_event_ &&
        WaitForSingleObject(stop_event_, 2000) == WAIT_OBJECT_0) {
      break;
    }
  }
}

void RecordingDetection::Start() {
  if (running_) return;
  running_ = true;
  stop_event_ = CreateEvent(nullptr, TRUE, FALSE, nullptr);
  poll_thread_ =
      std::make_unique<std::thread>(&RecordingDetection::PollThreadProc, this);
}

void RecordingDetection::Stop() {
  if (!running_) return;
  running_ = false;

  if (stop_event_) {
    SetEvent(stop_event_);
  }

  if (poll_thread_ && poll_thread_->joinable()) {
    poll_thread_->join();
  }
  poll_thread_.reset();

  if (stop_event_) {
    CloseHandle(stop_event_);
    stop_event_ = nullptr;
  }

  is_recording_ = false;
  detected_process_.clear();
}

}  // namespace no_screenshot
