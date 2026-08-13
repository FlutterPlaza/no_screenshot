#ifndef NO_SCREENSHOT_WINDOW_AFFINITY_H_
#define NO_SCREENSHOT_WINDOW_AFFINITY_H_

#include <windows.h>

namespace no_screenshot {

// Resolves the top-level ancestor that display affinity must target for a
// (possibly reparented) Flutter view window. SetWindowDisplayAffinity only
// takes effect on top-level windows, and the standard runner reparents the
// Flutter view via SetParent after plugin registration (#119), so the root
// must be resolved per call, never cached. For a window that is itself
// top-level, returns the window unchanged; returns nullptr for nullptr.
HWND ResolveRootWindow(HWND view_hwnd);

// Tracks which top-level window currently holds the display affinity and
// keeps it consistent as the effective prevention claim and the view's
// parent chain change. Pure Win32 — no Flutter dependencies — so the #119
// regression surface is unit-testable against synthetic windows.
class AffinityTracker {
 public:
  // Applies (or clears) prevention on `root` — the current top-level window,
  // or nullptr when the view is not resolvable (headless engine, teardown).
  // Migrates the affinity off a previously protected window so no window is
  // left holding a stale affinity. With a null root this is fail-secure: an
  // active claim keeps the previously protected window protected, while
  // releasing still clears it.
  void ApplyEffective(bool effective, HWND root);

  // Delegate-driven migration (#119): adopt `delegate_hwnd` iff prevention
  // is currently applied elsewhere (or nowhere) and `delegate_hwnd` is the
  // window that actually hosts the view (`current_root`) — an embedder may
  // forward several top-level windows' messages into one engine, and
  // migrating to a foreign window would thrash the affinity. Returns true
  // if the affinity moved.
  bool MaybeMigrate(HWND delegate_hwnd, HWND current_root);

  // Window the display affinity is currently applied to, if any. Tracked so
  // deactivation always targets the window that was actually protected,
  // even if the view has been reparented since (#119).
  HWND applied_window() const { return applied_hwnd_; }

 private:
  HWND applied_hwnd_ = nullptr;
};

}  // namespace no_screenshot

#endif  // NO_SCREENSHOT_WINDOW_AFFINITY_H_
