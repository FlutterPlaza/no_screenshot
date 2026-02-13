# no_screenshot — Feature Roadmap

## Implemented (v0.5.0)

| # | Feature | Platforms | Key APIs |
|---|---|---|---|
| 1 | Disable/enable screenshots & screen recording | Android, iOS, macOS, Linux ⚠️ | `screenshotOff()`, `screenshotOn()` |
| 2 | Toggle protection state | Android, iOS, macOS, Linux ⚠️ | `toggleScreenshot()` |
| 3 | Persist state across app restarts | Android, iOS, macOS, Linux | SharedPreferences / UserDefaults / JSON |
| 4 | Real-time screenshot event stream | Android, iOS, macOS, Linux | `screenshotStream` |
| 5 | Screenshot file path retrieval | macOS, Linux | `screenshotPath` (placeholder on Android/iOS) |
| 6 | Clipboard-only screenshot detection | macOS only | Pasteboard polling scoped to screencaptureui |
| 7 | Custom image overlay in app switcher | Android, iOS, macOS, Linux ⚠️ | `toggleScreenshotWithImage()` |
| 8 | LTR & RTL language support | All platforms | `forceLeftToRight` semantics on iOS 26+ (flutter/flutter#175523) |
| 9 | Linux platform support | Linux | `GFileMonitor` (inotify) for detection; best-effort prevention |
| 10 | Screen recording start/stop detection | iOS, Android 14+, macOS ⚠️, Linux ⚠️ | `startScreenRecordingListening()`, `stopScreenRecordingListening()`, `isScreenRecording` |
| 11 | Blur overlay in app switcher | Android, iOS, macOS, Linux ⚠️ | `toggleScreenshotWithBlur()` |

> **⚠️ Linux:** Compositors (Wayland / X11) have no `FLAG_SECURE` equivalent — prevention and overlay are best-effort (state is tracked and persisted). Detection works reliably via `GFileMonitor`.

---

## Package Strategy — FlutterPlaza Security Suite

Features are split across focused packages. All `no_*` names confirmed **available** on pub.dev (checked 2026-02-10).

### `no_screenshot` (this package) — Screenshot & Recording Prevention

Core package. Handles screenshot/recording prevention, detection, overlays, and DX widgets.

| Priority | Feature | Impact |
|---|---|---|
| ~~P1~~ | ~~Detect screen recording start/stop events~~ | ~~High~~ — **SHIPPED v0.4.0** |
| ~~P2~~ | ~~Blur overlay option for app switcher~~ | ~~High~~ — **SHIPPED v0.5.0** |
| P2.1 | Configurable blur radius | Medium |
| P2.2 | Enhanced macOS screen recording detection (Cmd+Shift+5) | Medium |
| P3 | Solid color overlay option for app switcher | Medium |
| P6 | Declarative SecureWidget wrapper | High |
| P7 | Per-route / per-screen protection policies | High |
| P8 | Screenshot metadata (timestamp, source app) | Medium |
| P11 | Windows platform support | Medium |
| P15 | Granular callbacks (onScreenshotAttempt, etc.) | Low |
| P17 | Web platform support (limited) | Low |

### `no_screen_mirror` (new package) — Display Mirroring & Casting Detection

Detects screen mirroring, external displays, and screen sharing in video calls.

| Priority | Feature | Impact |
|---|---|---|
| P4 | Detect AirPlay / Miracast / screen mirroring | High |
| P5 | Detect external display connections (HDMI/USB-C) | Medium |
| P14 | Detect screen sharing in video calls (Zoom, Teams, Meet) | Medium |

### `no_tapjack` (new package) — Overlay & Tapjacking Attack Detection

Android-focused input security. Detects when other apps draw overlays on top of the app.

| Priority | Feature | Impact |
|---|---|---|
| P10 | Detect tapjacking / overlay attacks | Medium |

### `secure_watermark` (new package) — Visible & Forensic Watermarking

DLP watermarking for tracing leaked content back to users.

| Priority | Feature | Impact |
|---|---|---|
| P9 | Visible watermark overlay (user ID, timestamp) | Medium |
| P16 | Invisible forensic watermarking | Low |

### `no_shoulder_surf` (new package) — Physical Presence Detection

Camera and sensor-based physical security.

| Priority | Feature | Impact |
|---|---|---|
| P18 | Front camera shoulder surfing detection (ML) | Low |
| P19 | Proximity sensor content hiding | Low |

### Cross-cutting (package TBD — could live in `no_screenshot` or standalone)

| Priority | Feature | Impact | Notes |
|---|---|---|---|
| P13 | Audit log of protection events | Medium | Could serve all packages in the suite. Standalone `secure_audit_log` or built into `no_screenshot`. |

---

## Competitors / Landscape

| Package | Status | Overlap |
|---|---|---|
| [pkb_screen_guard](https://pub.dev/packages/pkb_screen_guard) | Active | Screenshot, recording, mirroring, root/jailbreak detection |
| [secure_display](https://pub.dev/packages/secure_display) | Active (47 days old) | Screenshot/recording prevention, SecureWidget |
| [privacy_screen](https://pub.dev/packages/privacy_screen) | Deprecated | Background privacy screen |
| [screen_protector](https://pub.dev/packages/screen_protector) | Active | Screenshot prevention |
| [invisible_watermark](https://pub.dev/documentation/invisible_watermark/latest/) | Active | Invisible watermark embedding/extraction |

---

## Detailed Feature Specs

### ~~P1: Detect screen recording start/stop events~~ — SHIPPED in v0.4.0
- `isScreenRecording` field added to `ScreenshotSnapshot` (default `false`, backward-compatible)
- `startScreenRecordingListening()` / `stopScreenRecordingListening()` API methods
- Recording state changes emit through the same `screenshotStream` — no new EventChannel
- iOS 11+: `UIScreen.capturedDidChangeNotification` (event-driven, detects start + stop)
- Android 14+ (API 34): `Activity.ScreenCaptureCallback` (start only; no "stop" callback)
- Android < 14: Graceful no-op
- macOS: `NSWorkspace` process polling (2s) for QuickTime Player, OBS, Loom, Kap, ffmpeg, screencapture, simplescreenrecorder
- Linux: `/proc` process scanning (2s) for ffmpeg, obs, simplescreenrecorder, kazam, peek, recordmydesktop, vokoscreen, gtk-recordmydesktop

### ~~P2: Blur overlay option for app switcher~~ — SHIPPED in v0.5.0
- `toggleScreenshotWithBlur()` API — mirrors `toggleScreenshotWithImage()` exactly
- Returns `true` when blur mode is activated, `false` when deactivated
- Blur and image overlay are **mutually exclusive** — activating one deactivates the other (enforced at native level)
- Android API 31+: `RenderEffect.createBlurEffect(30f, 30f, CLAMP)` — zero-copy GPU blur on `decorView`
- Android API 17–30: `RenderScript.ScriptIntrinsicBlur(radius=25f)` — bitmap capture + blur + `ImageView` overlay
- Android API <17: `FLAG_SECURE` alone (no blur, but app switcher content is hidden)
- iOS: `UIVisualEffectView(effect: UIBlurEffect(style: .regular))`
- macOS: `NSVisualEffectView` with `.hudWindow` material, `.behindWindow` blending, `.active` state
- Linux: Best-effort — state tracked and persisted, compositors control task switcher thumbnails
- State persisted across app restarts on all platforms

### P2.1: Configurable blur radius
- **Package:** `no_screenshot`
- **Impact:** Medium
- **Description:** Allow developers to pass a custom blur radius to `toggleScreenshotWithBlur()`. Currently hardcoded to sensible defaults (30f Android RenderEffect, 25f RenderScript, `.regular` iOS, `.hudWindow` macOS).
- **Approach:** Add optional `double radius` parameter to `toggleScreenshotWithBlur()`. Pass through method channel. Map to platform-specific ranges.
- **Why deferred from v1:** Sensible defaults cover most use cases. Configurable radius adds API surface + cross-platform mapping complexity.

### P2.2: Enhanced macOS screen recording detection (Cmd+Shift+5)
- **Package:** `no_screenshot`
- **Impact:** Medium
- **Description:** Improve macOS screen recording detection to specifically track the native `Cmd+Shift+5` recording flow via `screencaptureui` and `screencapture` process lifecycle, in addition to the existing third-party app polling.
- **Approach:**
  - Track `screencaptureui` launch/termination via `NSWorkspace.didLaunchApplicationNotification` / `NSWorkspace.didTerminateApplicationNotification` (already used for screenshot detection)
  - Detect `screencapture` CLI process (used by macOS for the actual recording) via process polling or `NSWorkspace`
  - Distinguish between screenshot and recording modes by monitoring process arguments or duration
  - Emit `isScreenRecording = true` when a `screencapture` recording process is detected, `false` when it terminates
- **Why:** macOS `Cmd+Shift+5` starts a recording via the native `screencapture` tool, which is not currently in the known recording process list. This is the most common way users record on macOS.

### P3: Solid color overlay option for app switcher
- **Package:** `no_screenshot`
- **Impact:** Medium
- **Description:** Simple configurable solid color overlay. Lightweight, no asset required.
- **Approach:** New method like `screenshotOffWithColor(Color)`.

### P4: Detect AirPlay / Miracast / screen mirroring
- **Package:** `no_screen_mirror`
- **Impact:** High
- **Description:** Detect screen mirroring to external displays or AirPlay.
- **Approach:**
  - iOS: `UIScreen.screens.count > 1` or `UIScreen.mirrored`
  - Android: `DisplayManager` + `MediaRouter`
  - macOS: `NSScreen.screens`
- **Why:** Major security gap — content visible on external screens bypasses screenshot protection.

### P5: Detect external display connections (HDMI/USB-C)
- **Package:** `no_screen_mirror`
- **Impact:** Medium
- **Description:** Detect physical external display connections.
- **Approach:**
  - Android: `DisplayManager.DisplayListener`
  - iOS: `UIScreen.didConnectNotification`
  - macOS: NSScreen notifications

### P6: Declarative SecureWidget wrapper
- **Package:** `no_screenshot`
- **Impact:** High
- **Description:** Flutter widget that wraps content and auto-enables/disables protection on mount/unmount.
- **API sketch:** `SecureWidget(child: MyScreen(), overlay: OverlayType.blur)`
- **Why:** Major DX improvement — no imperative calls needed.

### P7: Per-route / per-screen protection policies
- **Package:** `no_screenshot`
- **Impact:** High
- **Description:** Different screens get different protection levels (e.g. payment = full block, home = none, profile = blur).
- **Approach:** Navigator observer or RouteAware integration.
- **Why:** Enterprise must-have.

### P8: Screenshot metadata (timestamp, source app)
- **Package:** `no_screenshot`
- **Impact:** Medium
- **Description:** Enrich `ScreenshotSnapshot` with timestamp and (where possible) source app.
- **Approach:**
  - macOS: Extract from file metadata via NSMetadataQuery
  - Android: ContentObserver provides some metadata
  - iOS: Limited

### P9: Watermark overlay with user ID / timestamp
- **Package:** `secure_watermark`
- **Impact:** Medium
- **Description:** Render visible watermark over protected content (user ID, email, timestamp). Deters screenshots by making leaks traceable.
- **Approach:** Flutter overlay widget with customizable text, opacity, angle, color.

### P10: Detect tapjacking / overlay attacks (Android)
- **Package:** `no_tapjack`
- **Impact:** Medium
- **Description:** Detect when another app draws an overlay (tapjacking).
- **Approach:** `filterTouchesWhenObscured` flag, `TYPE_APPLICATION_OVERLAY` detection.
- **Platforms:** Android only.

### P11: Windows platform support
- **Package:** `no_screenshot`
- **Impact:** Medium
- **Description:** Desktop expansion to Windows.
- **Approach:**
  - Prevention: `SetWindowDisplayAffinity(WDA_EXCLUDEFROMCAPTURE)`
  - Detection: Clipboard monitoring / `WM_CLIPBOARDUPDATE`
  - App switcher: `DwmSetWindowAttribute` for thumbnail exclusion

### ~~P12: Linux platform support~~ — SHIPPED in v0.3.6
- Detection via `GFileMonitor` (inotify) monitoring `~/Pictures/Screenshots/`, `~/Pictures/`, XDG pictures dir
- File path available via `GFileMonitor` (same as macOS)
- Prevention/overlay best-effort — state tracked and persisted, compositors lack `FLAG_SECURE`
- State persistence via JSON in `$XDG_DATA_HOME/no_screenshot/state.json`
- Detected tools: GNOME Screenshot, Spectacle (KDE), Flameshot, scrot, Shutter, maim

### P13: Audit log of protection events
- **Package:** `no_screenshot` or standalone `secure_audit_log`
- **Impact:** Medium
- **Description:** Log all state changes, screenshot attempts, recording detections, mirroring events with timestamps. Provide query/export API.
- **Why:** Enterprise compliance and incident investigation.

### P14: Detect screen sharing in video calls
- **Package:** `no_screen_mirror`
- **Impact:** Medium
- **Description:** Detect content shared via Zoom, Teams, Meet, etc.
- **Approach:**
  - Android: MediaProjection
  - iOS: `RPScreenRecorder.shared().isRecording`
- **Why:** Niche but high-value for enterprise.

### P15: Granular callbacks (onScreenshotAttempt, onRecordingStart, etc.)
- **Package:** `no_screenshot`
- **Impact:** Low
- **Description:** Named callbacks for specific events in addition to the stream.
- **API sketch:** `NoScreenshot.instance.onScreenshotAttempt = (snapshot) => showWarning()`
- **Why low:** Stream already covers this; callbacks are syntactic sugar.

### P16: Invisible forensic watermarking
- **Package:** `secure_watermark`
- **Impact:** Low
- **Description:** Embed invisible markers in rendered content that survive screenshots. Allows tracing leaked screenshots to source user.
- **Approach:** LSB encoding, yellow dot patterns, sub-pixel shifts.
- **Why low:** High complexity, requires image processing.

### P17: Web platform support (limited)
- **Package:** `no_screenshot`
- **Impact:** Low
- **Description:** Best-effort web support. Cannot truly prevent screenshots.
- **Approach:** Block right-click, disable print screen via JS, CSS `user-select: none`, `visibilitychange` listener.

### P18: Front camera shoulder surfing detection
- **Package:** `no_shoulder_surf`
- **Impact:** Low
- **Description:** Use front camera + ML to detect multiple faces. Apply privacy filter or dim screen.
- **Why low:** Requires camera permission, ML model, very high complexity.

### P19: Proximity sensor content hiding
- **Package:** `no_shoulder_surf`
- **Impact:** Low
- **Description:** Use proximity sensor to hide content when device is near a surface/person.
- **Why low:** Proximity sensor is binary (near/far), limited practical value. Could detect "phone placed face-down".