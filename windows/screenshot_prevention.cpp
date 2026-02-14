#include "screenshot_prevention.h"

#include <iostream>

// WDA_EXCLUDEFROMCAPTURE = 0x00000011
// Available on Windows 10 2004+ (build 19041+).
#ifndef WDA_EXCLUDEFROMCAPTURE
#define WDA_EXCLUDEFROMCAPTURE 0x00000011
#endif

namespace no_screenshot {

void PreventionActivate(HWND hwnd) {
  if (hwnd == nullptr) return;
  if (!SetWindowDisplayAffinity(hwnd, WDA_EXCLUDEFROMCAPTURE)) {
    // Fall back to WDA_MONITOR on older Windows 10 builds.
    SetWindowDisplayAffinity(hwnd, WDA_MONITOR);
  }
}

void PreventionDeactivate(HWND hwnd) {
  if (hwnd == nullptr) return;
  SetWindowDisplayAffinity(hwnd, WDA_NONE);
}

}  // namespace no_screenshot
