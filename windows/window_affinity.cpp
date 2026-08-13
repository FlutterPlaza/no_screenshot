#include "window_affinity.h"

#include "screenshot_prevention.h"

namespace no_screenshot {

HWND ResolveRootWindow(HWND view_hwnd) {
  if (view_hwnd == nullptr) return nullptr;
  HWND root = ::GetAncestor(view_hwnd, GA_ROOT);
  return root ? root : view_hwnd;
}

void AffinityTracker::ApplyEffective(bool effective, HWND root) {
  if (root == nullptr) {
    // View not resolvable (headless engine or teardown). Releasing
    // prevention must still clear a previously protected window; an active
    // claim keeps that window protected (fail-secure).
    if (!effective && applied_hwnd_ != nullptr && ::IsWindow(applied_hwnd_)) {
      PreventionDeactivate(applied_hwnd_);
      applied_hwnd_ = nullptr;
    }
    return;
  }
  // If a previous apply targeted a different window (the view resolved
  // before the runner reparented it), clear that one first so no window is
  // left holding a stale affinity.
  if (applied_hwnd_ != nullptr && applied_hwnd_ != root &&
      ::IsWindow(applied_hwnd_)) {
    PreventionDeactivate(applied_hwnd_);
  }
  if (effective) {
    PreventionActivate(root);
    applied_hwnd_ = root;
  } else {
    PreventionDeactivate(root);
    applied_hwnd_ = nullptr;
  }
}

bool AffinityTracker::MaybeMigrate(HWND delegate_hwnd, HWND current_root) {
  if (delegate_hwnd == nullptr || delegate_hwnd == applied_hwnd_ ||
      delegate_hwnd != current_root) {
    return false;
  }
  if (applied_hwnd_ != nullptr && ::IsWindow(applied_hwnd_)) {
    PreventionDeactivate(applied_hwnd_);
  }
  PreventionActivate(delegate_hwnd);
  applied_hwnd_ = delegate_hwnd;
  return true;
}

}  // namespace no_screenshot
