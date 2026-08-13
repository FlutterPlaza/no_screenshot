#include <windows.h>

#include <gtest/gtest.h>

#include <vector>

#include "screenshot_prevention.h"
#include "window_affinity.h"

// Available on Windows 10 2004+ (build 19041+); mirror of the guard in
// screenshot_prevention.cpp for SDKs that predate it.
#ifndef WDA_EXCLUDEFROMCAPTURE
#define WDA_EXCLUDEFROMCAPTURE 0x00000011
#endif

namespace no_screenshot {
namespace {

constexpr wchar_t kTestClassName[] = L"NoScreenshotAffinityTestWindow";

void RegisterTestClass() {
  static bool registered = false;
  if (registered) return;
  WNDCLASSW wc = {};
  wc.lpfnWndProc = DefWindowProcW;
  wc.hInstance = GetModuleHandleW(nullptr);
  wc.lpszClassName = kTestClassName;
  RegisterClassW(&wc);
  registered = true;
}

DWORD AffinityOf(HWND hwnd) {
  DWORD affinity = WDA_NONE;
  GetWindowDisplayAffinity(hwnd, &affinity);
  return affinity;
}

// SetWindowDisplayAffinity requires DWM composition and an interactive
// session, which may be missing in exotic environments (Server Core,
// session 0). Probe once; assertions on the actual affinity value are gated
// on this so bookkeeping coverage still runs everywhere. GitHub-hosted
// Windows runners have a composited desktop, so the probe passes there and
// affinity values are asserted for real.
DWORD g_probe_error = ERROR_SUCCESS;

bool CanSetAffinity() {
  static int cached = -1;
  if (cached == -1) {
    RegisterTestClass();
    HWND probe = CreateWindowExW(0, kTestClassName, L"probe",
                                 WS_OVERLAPPEDWINDOW, CW_USEDEFAULT,
                                 CW_USEDEFAULT, 100, 100, nullptr, nullptr,
                                 GetModuleHandleW(nullptr), nullptr);
    if (probe != nullptr) {
      ShowWindow(probe, SW_SHOWNOACTIVATE);
    }
    if (probe != nullptr &&
        (SetWindowDisplayAffinity(probe, WDA_EXCLUDEFROMCAPTURE) ||
         SetWindowDisplayAffinity(probe, WDA_MONITOR))) {
      cached = 1;
    } else {
      cached = 0;
      g_probe_error = GetLastError();
    }
    if (probe != nullptr) {
      SetWindowDisplayAffinity(probe, WDA_NONE);
      DestroyWindow(probe);
    }
  }
  return cached == 1;
}

// Scope note: these tests pin the extracted #119 logic (ResolveRootWindow +
// AffinityTracker) against real Win32 windows. The plugin's thin glue —
// GetFlutterWindowHandle() feeding the tracker and the WindowProc delegate
// invoking MaybeMigrate — has no Flutter-free test seam (it needs a live
// PluginRegistrarWindows) and remains review-guarded; keep those call sites
// trivial.
//
// Creates real windows and destroys them on teardown. Top-level windows are
// shown without activation (DWM only composes shown windows, and affinity
// values are asserted for real when the environment supports it); child
// windows stay hidden.
class WindowAffinityTest : public ::testing::Test {
 protected:
  HWND MakeTopLevel() {
    RegisterTestClass();
    HWND hwnd = CreateWindowExW(0, kTestClassName, L"top",
                                WS_OVERLAPPEDWINDOW, CW_USEDEFAULT,
                                CW_USEDEFAULT, 200, 200, nullptr, nullptr,
                                GetModuleHandleW(nullptr), nullptr);
    EXPECT_NE(hwnd, nullptr);
    // Shown (without focus) because display affinity is only meaningfully
    // asserted against a window DWM actually composes.
    ShowWindow(hwnd, SW_SHOWNOACTIVATE);
    windows_.push_back(hwnd);
    return hwnd;
  }

  HWND MakeChild(HWND parent) {
    RegisterTestClass();
    HWND hwnd = CreateWindowExW(0, kTestClassName, L"child", WS_CHILD, 0, 0,
                                100, 100, parent, nullptr,
                                GetModuleHandleW(nullptr), nullptr);
    EXPECT_NE(hwnd, nullptr);
    windows_.push_back(hwnd);
    return hwnd;
  }

  void TearDown() override {
    // Reverse order so children go before their parents.
    for (auto it = windows_.rbegin(); it != windows_.rend(); ++it) {
      if (::IsWindow(*it)) {
        DestroyWindow(*it);
      }
    }
    windows_.clear();
  }

  std::vector<HWND> windows_;
};

// --- Environment -----------------------------------------------------------

// Witnesses in the CI log whether affinity values are asserted for real or
// the suite fell back to bookkeeping-only coverage (#128).
TEST_F(WindowAffinityTest, EnvironmentSupportsSettingDisplayAffinity) {
  if (!CanSetAffinity()) {
    GTEST_SKIP() << "SetWindowDisplayAffinity unavailable (GetLastError="
                 << g_probe_error
                 << "); affinity-value assertions are skipped in this "
                    "environment, bookkeeping assertions still run.";
  }
  SUCCEED();
}

// --- ResolveRootWindow -----------------------------------------------------

TEST_F(WindowAffinityTest, ResolveRootNullYieldsNull) {
  EXPECT_EQ(ResolveRootWindow(nullptr), nullptr);
}

TEST_F(WindowAffinityTest, ResolveRootTopLevelResolvesToItself) {
  HWND top = MakeTopLevel();
  EXPECT_EQ(ResolveRootWindow(top), top);
}

TEST_F(WindowAffinityTest, ResolveRootChildResolvesToTopLevelParent) {
  HWND top = MakeTopLevel();
  HWND child = MakeChild(top);
  EXPECT_EQ(ResolveRootWindow(child), top);
}

TEST_F(WindowAffinityTest, ResolveRootGrandchildResolvesToRoot) {
  HWND top = MakeTopLevel();
  HWND child = MakeChild(top);
  HWND grandchild = MakeChild(child);
  EXPECT_EQ(ResolveRootWindow(grandchild), top);
}

// The #119 startup sequence: the runner calls SetParent on the view AFTER
// plugin registration, so root resolution must track the live parent chain
// instead of caching the first answer.
TEST_F(WindowAffinityTest, ResolveRootTracksReparenting) {
  HWND top_a = MakeTopLevel();
  HWND top_b = MakeTopLevel();
  HWND child = MakeChild(top_a);
  ASSERT_EQ(ResolveRootWindow(child), top_a);
  SetParent(child, top_b);
  EXPECT_EQ(ResolveRootWindow(child), top_b);
}

// --- PreventionActivate / PreventionDeactivate -----------------------------

TEST_F(WindowAffinityTest, PreventionActivateSetsCaptureExclusion) {
  if (!CanSetAffinity()) {
    GTEST_SKIP() << "SetWindowDisplayAffinity unavailable (no DWM?)";
  }
  HWND top = MakeTopLevel();
  PreventionActivate(top);
  EXPECT_NE(AffinityOf(top), static_cast<DWORD>(WDA_NONE));
  PreventionDeactivate(top);
  EXPECT_EQ(AffinityOf(top), static_cast<DWORD>(WDA_NONE));
}

// --- AffinityTracker::ApplyEffective ---------------------------------------

TEST_F(WindowAffinityTest, ApplyEffectiveActivateTracksAppliedWindow) {
  HWND top = MakeTopLevel();
  AffinityTracker tracker;
  tracker.ApplyEffective(true, top);
  EXPECT_EQ(tracker.applied_window(), top);
  if (CanSetAffinity()) {
    EXPECT_NE(AffinityOf(top), static_cast<DWORD>(WDA_NONE));
  }
}

TEST_F(WindowAffinityTest, ApplyEffectiveDeactivateClearsAppliedWindow) {
  HWND top = MakeTopLevel();
  AffinityTracker tracker;
  tracker.ApplyEffective(true, top);
  tracker.ApplyEffective(false, top);
  EXPECT_EQ(tracker.applied_window(), nullptr);
  if (CanSetAffinity()) {
    EXPECT_EQ(AffinityOf(top), static_cast<DWORD>(WDA_NONE));
  }
}

// When the resolved root changes (the runner reparented the view), the old
// window must not be left holding a stale affinity.
TEST_F(WindowAffinityTest, ApplyEffectiveMigratesOffPreviousWindow) {
  HWND top_a = MakeTopLevel();
  HWND top_b = MakeTopLevel();
  AffinityTracker tracker;
  tracker.ApplyEffective(true, top_a);
  tracker.ApplyEffective(true, top_b);
  EXPECT_EQ(tracker.applied_window(), top_b);
  if (CanSetAffinity()) {
    EXPECT_EQ(AffinityOf(top_a), static_cast<DWORD>(WDA_NONE));
    EXPECT_NE(AffinityOf(top_b), static_cast<DWORD>(WDA_NONE));
  }
}

// Fail-secure: an unresolvable view (headless, teardown) must not drop
// protection a still-active claim demands.
TEST_F(WindowAffinityTest, ApplyEffectiveNullRootKeepsProtectionWhileClaimed) {
  HWND top = MakeTopLevel();
  AffinityTracker tracker;
  tracker.ApplyEffective(true, top);
  tracker.ApplyEffective(true, nullptr);
  EXPECT_EQ(tracker.applied_window(), top);
  if (CanSetAffinity()) {
    EXPECT_NE(AffinityOf(top), static_cast<DWORD>(WDA_NONE));
  }
}

// ...but releasing with an unresolvable view must still clear the window
// that was protected.
TEST_F(WindowAffinityTest, ApplyEffectiveNullRootReleaseClearsPrevious) {
  HWND top = MakeTopLevel();
  AffinityTracker tracker;
  tracker.ApplyEffective(true, top);
  tracker.ApplyEffective(false, nullptr);
  EXPECT_EQ(tracker.applied_window(), nullptr);
  if (CanSetAffinity()) {
    EXPECT_EQ(AffinityOf(top), static_cast<DWORD>(WDA_NONE));
  }
}

TEST_F(WindowAffinityTest, ApplyEffectiveReleaseWithoutPriorApplyIsNoOp) {
  AffinityTracker tracker;
  tracker.ApplyEffective(false, nullptr);
  EXPECT_EQ(tracker.applied_window(), nullptr);
}

TEST_F(WindowAffinityTest, ApplyEffectiveSkipsDestroyedPreviousWindow) {
  HWND top_a = MakeTopLevel();
  HWND top_b = MakeTopLevel();
  AffinityTracker tracker;
  tracker.ApplyEffective(true, top_a);
  DestroyWindow(top_a);
  tracker.ApplyEffective(true, top_b);
  EXPECT_EQ(tracker.applied_window(), top_b);
}

// --- AffinityTracker::MaybeMigrate (top-level WindowProc delegate, #119) ---

// Persisted prevention restored before the runner attached the view: nothing
// applied yet, then the delegate reports the real top-level window.
TEST_F(WindowAffinityTest, MaybeMigrateAdoptsRootWhenNothingApplied) {
  HWND top = MakeTopLevel();
  AffinityTracker tracker;
  EXPECT_TRUE(tracker.MaybeMigrate(top, top));
  EXPECT_EQ(tracker.applied_window(), top);
  if (CanSetAffinity()) {
    EXPECT_NE(AffinityOf(top), static_cast<DWORD>(WDA_NONE));
  }
}

// Prevention was applied to the wrong window (the pre-reparent root); the
// delegate migrates it to the window that actually hosts the view.
TEST_F(WindowAffinityTest, MaybeMigrateMovesAffinityToCurrentRoot) {
  HWND old_root = MakeTopLevel();
  HWND new_root = MakeTopLevel();
  AffinityTracker tracker;
  tracker.ApplyEffective(true, old_root);
  EXPECT_TRUE(tracker.MaybeMigrate(new_root, new_root));
  EXPECT_EQ(tracker.applied_window(), new_root);
  if (CanSetAffinity()) {
    EXPECT_EQ(AffinityOf(old_root), static_cast<DWORD>(WDA_NONE));
    EXPECT_NE(AffinityOf(new_root), static_cast<DWORD>(WDA_NONE));
  }
}

// An embedder may forward several top-level windows' messages into one
// engine; a delegate window that is not the view's root must not be adopted.
TEST_F(WindowAffinityTest, MaybeMigrateRejectsForeignWindow) {
  HWND root = MakeTopLevel();
  HWND foreign = MakeTopLevel();
  AffinityTracker tracker;
  tracker.ApplyEffective(true, root);
  EXPECT_FALSE(tracker.MaybeMigrate(foreign, root));
  EXPECT_EQ(tracker.applied_window(), root);
  if (CanSetAffinity()) {
    EXPECT_EQ(AffinityOf(foreign), static_cast<DWORD>(WDA_NONE));
  }
}

TEST_F(WindowAffinityTest, MaybeMigrateAlreadyAppliedIsNoOp) {
  HWND root = MakeTopLevel();
  AffinityTracker tracker;
  tracker.ApplyEffective(true, root);
  EXPECT_FALSE(tracker.MaybeMigrate(root, root));
  EXPECT_EQ(tracker.applied_window(), root);
}

TEST_F(WindowAffinityTest, MaybeMigrateIgnoresNullDelegate) {
  AffinityTracker tracker;
  EXPECT_FALSE(tracker.MaybeMigrate(nullptr, nullptr));
  EXPECT_EQ(tracker.applied_window(), nullptr);
}

// End-to-end shape of the #119 fix: apply lands on the pre-reparent root,
// the runner reparents the view, and the delegate migrates the affinity to
// the real top-level window.
TEST_F(WindowAffinityTest, ReparentThenDelegateMigrationEndToEnd) {
  HWND real_top = MakeTopLevel();
  HWND view = MakeTopLevel();  // The view starts unparented (top-level).
  AffinityTracker tracker;
  tracker.ApplyEffective(true, ResolveRootWindow(view));
  EXPECT_EQ(tracker.applied_window(), view);

  // Runner attaches the view (SetChildContent -> SetParent).
  SetWindowLongPtrW(view, GWL_STYLE,
                    (GetWindowLongPtrW(view, GWL_STYLE) & ~WS_POPUP) |
                        WS_CHILD);
  SetParent(view, real_top);

  // First delegate callback for the hosting top-level window.
  HWND current_root = ResolveRootWindow(view);
  ASSERT_EQ(current_root, real_top);
  EXPECT_TRUE(tracker.MaybeMigrate(real_top, current_root));
  EXPECT_EQ(tracker.applied_window(), real_top);
  if (CanSetAffinity()) {
    EXPECT_EQ(AffinityOf(view), static_cast<DWORD>(WDA_NONE));
    EXPECT_NE(AffinityOf(real_top), static_cast<DWORD>(WDA_NONE));
  }
}

}  // namespace
}  // namespace no_screenshot
