# no_screenshot

<p align="center">
<a href="https://github.com/FlutterPlaza/no_screenshot/actions/workflows/main.yaml"><img src="https://github.com/FlutterPlaza/no_screenshot/actions/workflows/main.yaml/badge.svg?branch=development" alt="CI"></a>
<a href="https://codecov.io/gh/FlutterPlaza/no_screenshot"><img src="https://codecov.io/gh/FlutterPlaza/no_screenshot/branch/development/graph/badge.svg?token=C96E93VG2W" alt="Codecov"></a>
<a href="https://pub.dev/packages/no_screenshot"><img src="https://img.shields.io/pub/v/no_screenshot.svg" alt="Pub"></a>
<a href="https://github.com/FlutterPlaza/no_screenshot"><img src="https://img.shields.io/github/stars/FlutterPlaza/no_screenshot.svg?style=flat&logo=github&colorB=deeppink&label=stars" alt="Star on Github"></a>
<a href="https://flutter.dev/docs/development/data-and-backend/state-mgmt/options#bloc--rx"><img src="https://img.shields.io/badge/flutter-website-deepskyblue.svg" alt="Flutter Website"></a>
</p>

A Flutter plugin to **disable screenshots**, **block screen recording**, **detect screenshot events**, **detect screen recording**, and **show a custom image, blur, or solid color overlay** in the app switcher on Android, iOS, macOS, and Linux.

## Features

| Feature | Android | iOS | macOS | Linux |
|---|:---:|:---:|:---:|:---:|
| Disable screenshot & screen recording | ✅ | ✅ | ✅ | ⚠️ |
| Enable screenshot & screen recording | ✅ | ✅ | ✅ | ⚠️ |
| Toggle screenshot protection | ✅ | ✅ | ✅ | ⚠️ |
| Listen for screenshot events (stream) | ✅ | ✅ | ✅ | ✅ |
| Detect screen recording start/stop | ✅\* | ✅ | ⚠️ | ⚠️ |
| Screenshot file path | ❌ | ❌ | ✅ | ✅ |
| Image overlay in app switcher / recents | ✅ | ✅ | ✅ | ⚠️ |
| Blur overlay in app switcher / recents | ✅ | ✅ | ✅ | ⚠️ |
| Color overlay in app switcher / recents | ✅ | ✅ | ✅ | ⚠️ |
| LTR & RTL language support | ✅ | ✅ | ✅ | ✅ |

> **\* Android recording detection:** Requires API 34+ (Android 14). Uses `Activity.ScreenCaptureCallback` which fires on recording start only — there is no "stop" callback. Graceful no-op on older devices.

> **⚠️ Linux limitations:** Linux compositors (Wayland / X11) do not expose a `FLAG_SECURE`-equivalent API, so screenshot prevention and image overlay are **best-effort** — the state is tracked and persisted, but the compositor cannot be instructed to hide the window content. Screenshot **detection** works reliably via `GFileMonitor` (inotify). Screen recording detection is best-effort via `/proc` process scanning.

> **⚠️ macOS recording detection:** Best-effort via `NSWorkspace` process monitoring for known recording apps (QuickTime Player, OBS, Loom, Kap, ffmpeg, etc.).

> **Note:** State is automatically persisted via native SharedPreferences / UserDefaults. You do **not** need to track `didChangeAppLifecycleState`.

> **Note:** `screenshotPath` is only available on **macOS** (via Spotlight / `NSMetadataQuery`) and **Linux** (via `GFileMonitor` / inotify). On Android and iOS the path is not accessible due to platform limitations — the field will contain a placeholder string. Use `wasScreenshotTaken` to detect screenshot events on all platforms.

## Installation

Add `no_screenshot` to your `pubspec.yaml`:

```yaml
dependencies:
  no_screenshot: ^0.6.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:no_screenshot/no_screenshot.dart';

final noScreenshot = NoScreenshot.instance;

// Disable screenshots & screen recording
await noScreenshot.screenshotOff();

// Re-enable screenshots & screen recording
await noScreenshot.screenshotOn();

// Toggle between enabled / disabled
await noScreenshot.toggleScreenshot();
```

## Usage

### 1. Screenshot & Screen Recording Protection

Block or allow screenshots and screen recording with a single method call.

```dart
final _noScreenshot = NoScreenshot.instance;

// Disable screenshots (returns true on success)
Future<void> disableScreenshot() async {
  final result = await _noScreenshot.screenshotOff();
  debugPrint('screenshotOff: $result');
}

// Enable screenshots (returns true on success)
Future<void> enableScreenshot() async {
  final result = await _noScreenshot.screenshotOn();
  debugPrint('screenshotOn: $result');
}

// Toggle the current state
Future<void> toggleScreenshot() async {
  final result = await _noScreenshot.toggleScreenshot();
  debugPrint('toggleScreenshot: $result');
}
```

#### Enable / Disable Screenshot

| Android | iOS |
|:---:|:---:|
| <img src="https://raw.githubusercontent.com/FlutterPlaza/no_screenshot/development/doc/gifs/screenshot_on_off_android.gif" width="350" alt="Screenshot on/off on Android"> | <img src="https://raw.githubusercontent.com/FlutterPlaza/no_screenshot/development/doc/gifs/screenshot_on_off_ios.gif" width="333" alt="Screenshot on/off on iOS"> |

### 2. Screenshot Monitoring (Stream)

Listen for screenshot events in real time. Monitoring is **off by default** -- you must explicitly start it.

```dart
final _noScreenshot = NoScreenshot.instance;

// 1. Subscribe to the stream
_noScreenshot.screenshotStream.listen((snapshot) {
  debugPrint('Protection active: ${snapshot.isScreenshotProtectionOn}');
  debugPrint('Screenshot taken: ${snapshot.wasScreenshotTaken}');
  debugPrint('Path: ${snapshot.screenshotPath}');
});

// 2. Start monitoring
await _noScreenshot.startScreenshotListening();

// 3. Stop monitoring when no longer needed
await _noScreenshot.stopScreenshotListening();
```

The stream emits a `ScreenshotSnapshot` object:

| Property | Type | Description |
|---|---|---|
| `isScreenshotProtectionOn` | `bool` | Whether screenshot protection is currently active |
| `wasScreenshotTaken` | `bool` | Whether a screenshot was just captured |
| `screenshotPath` | `String` | File path of the screenshot (**macOS & Linux only** — see note below) |
| `isScreenRecording` | `bool` | Whether screen recording is currently active (requires recording monitoring) |

> **Screenshot path availability:** The actual file path of a captured screenshot is only available on **macOS** (via Spotlight / `NSMetadataQuery`) and **Linux** (via `GFileMonitor` / inotify). On **Android** and **iOS**, the operating system does not expose the screenshot file path to apps — the field will contain a placeholder string. Always use `wasScreenshotTaken` to detect screenshot events reliably across all platforms.

| Android | iOS |
|:---:|:---:|
| <img src="https://raw.githubusercontent.com/FlutterPlaza/no_screenshot/development/doc/gifs/screenshot_monitoring_android.gif" width="350" alt="Screenshot monitoring on Android"> | <img src="https://raw.githubusercontent.com/FlutterPlaza/no_screenshot/development/doc/gifs/screenshot_monitoring_ios.gif" width="333" alt="Screenshot monitoring on iOS"> |

### macOS Screenshot Monitoring

On macOS, screenshot monitoring uses three complementary detection methods — **no special permissions required**:

| Method | What it detects |
|---|---|
| `NSMetadataQuery` (Spotlight) | Screenshots saved to disk — provides the actual file path |
| `NSWorkspace` process monitor | `screencaptureui` process launch & termination — tracks the screenshot lifecycle |
| Pasteboard polling | Clipboard-only screenshots (Cmd+Ctrl+Shift+3/4) — detected when image data appears on the pasteboard while `screencaptureui` is active or recently exited |

> **Note:** Pasteboard-based detection is scoped to the `screencaptureui` process window (running or terminated < 3 s ago) to avoid false positives from normal copy/paste. When "Show Floating Thumbnail" is disabled in macOS screenshot settings, the `screencaptureui` process does not launch; in that case only file-saved screenshots are detected via `NSMetadataQuery`.

### Linux Screenshot Monitoring

On Linux, screenshot monitoring uses `GFileMonitor` (inotify) to watch common screenshot directories for new files:

| Directory | Why |
|---|---|
| `~/Pictures/Screenshots/` | Default location for GNOME Screenshot and many other tools |
| `~/Pictures/` | Fallback — some tools save directly here |
| XDG pictures directory | Respects `$XDG_PICTURES_DIR` if it differs from `~/Pictures` |

Detected screenshot tool naming patterns include: **GNOME Screenshot**, **Spectacle** (KDE), **Flameshot**, **scrot**, **Shutter**, **maim**, and any file containing "screenshot" in its name.

### 3. Screen Recording Monitoring

Detect when the screen is being recorded. Recording monitoring is **off by default** and independent of screenshot monitoring — you must explicitly start it.

```dart
final _noScreenshot = NoScreenshot.instance;

// 1. Subscribe to the stream (same stream as screenshot events)
_noScreenshot.screenshotStream.listen((snapshot) {
  if (snapshot.isScreenRecording) {
    debugPrint('Screen is being recorded!');
  }
});

// 2. Start recording monitoring
await _noScreenshot.startScreenRecordingListening();

// 3. Stop recording monitoring when no longer needed
await _noScreenshot.stopScreenRecordingListening();
```

#### Platform-specific behavior

| Platform | Mechanism | Start | Stop |
|---|---|:---:|:---:|
| **iOS 11+** | `UIScreen.capturedDidChangeNotification` | ✅ | ✅ |
| **Android 14+** (API 34) | `Activity.ScreenCaptureCallback` | ✅ | ❌\* |
| **Android < 14** | No reliable API (no-op) | — | — |
| **macOS** | `NSWorkspace` process polling (2s) | ✅ | ✅ |
| **Linux** | `/proc` process scanning (2s) | ✅ | ✅ |

> **\* Android limitation:** `ScreenCaptureCallback.onScreenCaptured()` fires when recording starts but there is no "stop" callback. `isScreenRecording` becomes `true` and stays `true` until `stopScreenRecordingListening()` + `startScreenRecordingListening()` is called to reset.

> **macOS & Linux:** Recording detection is best-effort — it polls for known recording application processes. Detected apps include QuickTime Player, OBS, Loom, Kap, ffmpeg, screencapture, simplescreenrecorder, kazam, peek, recordmydesktop, and vokoscreen.

### 4. Image Overlay (App Switcher / Recents)

Show a custom image when the app appears in the app switcher or recents screen. This prevents sensitive content from being visible in thumbnails.

```dart
final _noScreenshot = NoScreenshot.instance;

// Toggle the image overlay on/off (returns the new state)
Future<void> toggleOverlay() async {
  final isActive = await _noScreenshot.toggleScreenshotWithImage();
  debugPrint('Image overlay active: $isActive');
}
```

**Setup:** Place your overlay image in the platform-specific asset locations:

- **Android:** `android/app/src/main/res/drawable/image.png`
- **iOS:** Add an image named `image` to your asset catalog (`Runner/Assets.xcassets/image.imageset/`)
- **macOS:** Add an image named `image` to your asset catalog (`Runner/Assets.xcassets/image.imageset/`)
- **Linux:** Best-effort — the state is tracked but compositors control task switcher thumbnails

When enabled, the overlay image is shown whenever the app goes to the background or appears in the app switcher. Screenshot protection is also automatically activated.

| Android | iOS |
|:---:|:---:|
| <img src="https://raw.githubusercontent.com/FlutterPlaza/no_screenshot/development/doc/gifs/image_overlay_android.gif" width="350" alt="Image overlay on Android"> | <img src="https://raw.githubusercontent.com/FlutterPlaza/no_screenshot/development/doc/gifs/image_overlay_ios.gif" width="333" alt="Image overlay on iOS"> |

### 5. Blur Overlay (App Switcher / Recents)

Show a Gaussian blur of the current screen content when the app appears in the app switcher. Provides a more natural UX than a static image while still protecting sensitive content. **No asset required.**

```dart
final _noScreenshot = NoScreenshot.instance;

// Toggle the blur overlay on/off with default radius (30.0)
Future<void> toggleBlur() async {
  final isActive = await _noScreenshot.toggleScreenshotWithBlur();
  debugPrint('Blur overlay active: $isActive');
}

// Toggle with a custom blur radius
Future<void> toggleBlurCustom() async {
  final isActive = await _noScreenshot.toggleScreenshotWithBlur(blurRadius: 50.0);
  debugPrint('Blur overlay active: $isActive');
}
```

> **Mutual exclusivity:** Blur, image, and color overlay modes are mutually exclusive — activating one automatically deactivates the others. This is enforced at the native level on all platforms.

#### Platform-specific blur implementation

| Platform | Mechanism |
|---|---|
| **Android API 31+** | `RenderEffect.createBlurEffect()` — zero-copy GPU blur on `decorView` (configurable radius) |
| **Android API 17–30** | `RenderScript.ScriptIntrinsicBlur` — bitmap capture + blur + `ImageView` overlay (configurable radius, max 25f) |
| **Android API <17** | `FLAG_SECURE` alone (no blur, but app switcher preview is hidden) |
| **iOS** | `UIVisualEffectView` with `UIBlurEffect(style: .regular)` |
| **macOS** | `NSVisualEffectView` with `.hudWindow` material, `.behindWindow` blending |
| **Linux** | Best-effort — state tracked and persisted, compositors control task switcher thumbnails |

### 6. Color Overlay (App Switcher / Recents)

Show a solid color when the app appears in the app switcher or recents screen. Useful when you want a branded or themed overlay instead of a blurred or image-based one. **No asset required.**

```dart
final _noScreenshot = NoScreenshot.instance;

// Toggle with default color (opaque black)
Future<void> toggleColor() async {
  final isActive = await _noScreenshot.toggleScreenshotWithColor();
  debugPrint('Color overlay active: $isActive');
}

// Toggle with a custom ARGB color (e.g. opaque blue)
Future<void> toggleColorCustom() async {
  final isActive = await _noScreenshot.toggleScreenshotWithColor(color: 0xFF2196F3);
  debugPrint('Color overlay active: $isActive');
}
```

> **Mutual exclusivity:** Color, blur, and image overlay modes are mutually exclusive — activating one automatically deactivates the others. This is enforced at the native level on all platforms.

#### Platform-specific color overlay implementation

| Platform | Mechanism |
|---|---|
| **Android** | Solid `View` overlay with the specified ARGB color |
| **iOS** | `UIView` with the specified background color |
| **macOS** | `NSView` with the specified background color |
| **Linux** | Best-effort — state tracked and persisted, compositors control task switcher thumbnails |

### macOS Demo

All features (screenshot protection, monitoring, and image overlay) on macOS:

| macOS |
|:---:|
| <img src="https://raw.githubusercontent.com/FlutterPlaza/no_screenshot/development/doc/gifs/all_features_macos.gif" width="1098" alt="All features on macOS"> |

## RTL Language Support

This plugin works correctly with both **LTR** (left-to-right) and **RTL** (right-to-left) languages such as Arabic and Hebrew. On iOS 26+, the internal screenshot prevention mechanism uses `forceLeftToRight` semantics to avoid a layout shift to the right when the device language is set to Arabic or another RTL language (see [flutter/flutter#175523](https://github.com/flutter/flutter/issues/175523)).

The example app includes an RTL toggle to verify correct behavior:

| RTL Support (iOS) |
|:---:|
| <img src="https://raw.githubusercontent.com/FlutterPlaza/no_screenshot/development/doc/gifs/rtl_support_ios.gif" width="333" alt="RTL support on iOS"> |

## API Reference

| Method | Return Type | Description |
|---|---|---|
| `NoScreenshot.instance` | `NoScreenshot` | Singleton instance of the plugin |
| `screenshotOff()` | `Future<bool>` | Disable screenshots & screen recording |
| `screenshotOn()` | `Future<bool>` | Enable screenshots & screen recording |
| `toggleScreenshot()` | `Future<bool>` | Toggle screenshot protection on/off |
| `toggleScreenshotWithImage()` | `Future<bool>` | Toggle image overlay mode (returns new state) |
| `toggleScreenshotWithBlur({double blurRadius = 30.0})` | `Future<bool>` | Toggle blur overlay mode with optional radius (returns new state) |
| `toggleScreenshotWithColor({int color = 0xFF000000})` | `Future<bool>` | Toggle solid color overlay mode with optional ARGB color (returns new state) |
| `startScreenshotListening()` | `Future<void>` | Start monitoring for screenshot events |
| `stopScreenshotListening()` | `Future<void>` | Stop monitoring for screenshot events |
| `startScreenRecordingListening()` | `Future<void>` | Start monitoring for screen recording events |
| `stopScreenRecordingListening()` | `Future<void>` | Stop monitoring for screen recording events |
| `screenshotStream` | `Stream<ScreenshotSnapshot>` | Stream of screenshot and recording activity events |

## Contributors

Thanks to everyone who has contributed to this project!

<table>
<tr>
<td align="center"><a href="https://github.com/fonkamloic"><img src="https://github.com/fonkamloic.png" width="60" height="60" style="border-radius:50%" alt="@fonkamloic"><br><sub>@fonkamloic</sub></a></td>
<td align="center"><a href="https://github.com/zhangyuanyuan-bear"><img src="https://github.com/zhangyuanyuan-bear.png" width="60" height="60" style="border-radius:50%" alt="@zhangyuanyuan-bear"><br><sub>@zhangyuanyuan-bear</sub></a></td>
<td align="center"><a href="https://github.com/BranislavKljaic96"><img src="https://github.com/BranislavKljaic96.png" width="60" height="60" style="border-radius:50%" alt="@BranislavKljaic96"><br><sub>@BranislavKljaic96</sub></a></td>
<td align="center"><a href="https://github.com/qk7b"><img src="https://github.com/qk7b.png" width="60" height="60" style="border-radius:50%" alt="@qk7b"><br><sub>@qk7b</sub></a></td>
<td align="center"><a href="https://github.com/T-moz"><img src="https://github.com/T-moz.png" width="60" height="60" style="border-radius:50%" alt="@T-moz"><br><sub>@T-moz</sub></a></td>
</tr>
<tr>
<td align="center"><a href="https://github.com/ggiordan"><img src="https://github.com/ggiordan.png" width="60" height="60" style="border-radius:50%" alt="@ggiordan"><br><sub>@ggiordan</sub></a></td>
<td align="center"><a href="https://github.com/Musaddiq625"><img src="https://github.com/Musaddiq625.png" width="60" height="60" style="border-radius:50%" alt="@Musaddiq625"><br><sub>@Musaddiq625</sub></a></td>
<td align="center"><a href="https://github.com/albertocappellina-intesys"><img src="https://github.com/albertocappellina-intesys.png" width="60" height="60" style="border-radius:50%" alt="@albertocappellina-intesys"><br><sub>@albertocappellina-intesys</sub></a></td>
<td align="center"><a href="https://github.com/kefeh"><img src="https://github.com/kefeh.png" width="60" height="60" style="border-radius:50%" alt="@kefeh"><br><sub>@kefeh</sub></a></td>
<td></td>
</tr>
</table>

## License

BSD 3-Clause License. See [LICENSE](LICENSE) for details.
