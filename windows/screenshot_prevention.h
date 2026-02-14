#ifndef NO_SCREENSHOT_SCREENSHOT_PREVENTION_H_
#define NO_SCREENSHOT_SCREENSHOT_PREVENTION_H_

#include <windows.h>

namespace no_screenshot {

// Activate screenshot/recording prevention using SetWindowDisplayAffinity.
// Requires Windows 10 version 2004+ for WDA_EXCLUDEFROMCAPTURE.
void PreventionActivate(HWND hwnd);

// Deactivate screenshot prevention (restore normal display affinity).
void PreventionDeactivate(HWND hwnd);

}  // namespace no_screenshot

#endif  // NO_SCREENSHOT_SCREENSHOT_PREVENTION_H_
