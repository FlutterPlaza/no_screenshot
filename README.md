# no_screenshot

<p align="center">
<a href="https://github.com/FlutterPlaza/no_screenshot/actions/workflows/main.yaml"><img src="https://github.com/FlutterPlaza/no_screenshot/actions/workflows/main.yaml/badge.svg?branch=development" alt="CI"></a>
<a href="https://codecov.io/gh/FlutterPlaza/no_screenshot"><img src="https://codecov.io/gh/FlutterPlaza/no_screenshot/branch/development/graph/badge.svg?token=C96E93VG2W" alt="Codecov"></a>
<a href="https://pub.dev/packages/no_screenshot"><img src="https://img.shields.io/pub/v/no_screenshot.svg" alt="Pub"></a>
<a href="https://github.com/FlutterPlaza/no_screenshot"><img src="https://img.shields.io/github/stars/FlutterPlaza/no_screenshot.svg?style=flat&logo=github&colorB=deeppink&label=stars" alt="Star on Github"></a>
<a href="https://flutter.dev/docs/development/data-and-backend/state-mgmt/options#bloc--rx"><img src="https://img.shields.io/badge/flutter-website-deepskyblue.svg" alt="Flutter Website"></a>
</p>

A Flutter plugin to **disable screenshots**, **block screen recording**, **detect screenshot events**, and **show a custom image overlay** in the app switcher on Android, iOS, and macOS.

## Features

| Feature | Android | iOS | macOS |
|---|:---:|:---:|:---:|
| Disable screenshot & screen recording | ✅ | ✅ | ✅ |
| Enable screenshot & screen recording | ✅ | ✅ | ✅ |
| Toggle screenshot protection | ✅ | ✅ | ✅ |
| Listen for screenshot events (stream) | ✅ | ✅ | ✅ |
| Screenshot file path | ❌ | ❌ | ✅ |
| Image overlay in app switcher / recents | ✅ | ✅ | ✅ |
| LTR & RTL language support | ✅ | ✅ | ✅ |

> **Note:** State is automatically persisted via native SharedPreferences / UserDefaults. You do **not** need to track `didChangeAppLifecycleState`.

> **Note:** `screenshotPath` is only available on **macOS** (via Spotlight / `NSMetadataQuery`). On Android and iOS the path is not accessible due to platform limitations — the field will contain a placeholder string. Use `wasScreenshotTaken` to detect screenshot events on all platforms.

## Installation

Add `no_screenshot` to your `pubspec.yaml`:

```yaml
dependencies:
  no_screenshot: ^0.3.5
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
| `screenshotPath` | `String` | File path of the screenshot (**macOS only** — see note below) |

> **Screenshot path availability:** The actual file path of a captured screenshot is only available on **macOS**, where it is retrieved via Spotlight (`NSMetadataQuery`). On **Android** and **iOS**, the operating system does not expose the screenshot file path to apps — the field will contain a placeholder string. Always use `wasScreenshotTaken` to detect screenshot events reliably across all platforms.

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

### 3. Image Overlay (App Switcher / Recents)

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

When enabled, the overlay image is shown whenever the app goes to the background or appears in the app switcher. Screenshot protection is also automatically activated.

| Android | iOS |
|:---:|:---:|
| <img src="https://raw.githubusercontent.com/FlutterPlaza/no_screenshot/development/doc/gifs/image_overlay_android.gif" width="350" alt="Image overlay on Android"> | <img src="https://raw.githubusercontent.com/FlutterPlaza/no_screenshot/development/doc/gifs/image_overlay_ios.gif" width="333" alt="Image overlay on iOS"> |

### macOS Demo

All features (screenshot protection, monitoring, and image overlay) on macOS:

| macOS |
|:---:|
| <img src="https://raw.githubusercontent.com/FlutterPlaza/no_screenshot/development/doc/gifs/all_features_macos.gif" width="732" alt="All features on macOS"> |

## RTL Language Support

This plugin works correctly with both **LTR** (left-to-right) and **RTL** (right-to-left) languages such as Arabic and Hebrew. On iOS, the internal screenshot prevention mechanism uses `forceLeftToRight` semantics to avoid layout shifts caused by the underlying `UITextField` layer trick.

The example app includes an RTL toggle to verify correct behavior:

| RTL Support (iOS) |
|:---:|
| <img src="https://raw.githubusercontent.com/FlutterPlaza/no_screenshot/development/doc/gifs/rtl_support_ios.gif" width="333" alt="RTL support on iOS"> |

## Full Example

Below is a complete example showing all features together. See the full source in [`example/lib/main.dart`](example/lib/main.dart).

```dart
import 'package:flutter/material.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'No Screenshot Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _noScreenshot = NoScreenshot.instance;
  bool _isMonitoring = false;
  bool _isOverlayImageOn = false;
  ScreenshotSnapshot _latestSnapshot = ScreenshotSnapshot(
    isScreenshotProtectionOn: false,
    wasScreenshotTaken: false,
    screenshotPath: '',
  );

  @override
  void initState() {
    super.initState();
    _noScreenshot.screenshotStream.listen((value) {
      setState(() => _latestSnapshot = value);
      if (value.wasScreenshotTaken) {
        debugPrint('Screenshot taken at path: ${value.screenshotPath}');
      }
    });
  }

  // ── Screenshot Protection ──────────────────────────────────────────

  Future<void> _disableScreenshot() async {
    final result = await _noScreenshot.screenshotOff();
    debugPrint('screenshotOff: $result');
  }

  Future<void> _enableScreenshot() async {
    final result = await _noScreenshot.screenshotOn();
    debugPrint('screenshotOn: $result');
  }

  Future<void> _toggleScreenshot() async {
    final result = await _noScreenshot.toggleScreenshot();
    debugPrint('toggleScreenshot: $result');
  }

  // ── Screenshot Monitoring ──────────────────────────────────────────

  Future<void> _startMonitoring() async {
    await _noScreenshot.startScreenshotListening();
    setState(() => _isMonitoring = true);
  }

  Future<void> _stopMonitoring() async {
    await _noScreenshot.stopScreenshotListening();
    setState(() => _isMonitoring = false);
  }

  // ── Image Overlay ─────────────────────────────────────────────────

  Future<void> _toggleScreenshotWithImage() async {
    final result = await _noScreenshot.toggleScreenshotWithImage();
    debugPrint('toggleScreenshotWithImage: $result');
    setState(() => _isOverlayImageOn = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('No Screenshot Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Screenshot protection buttons
          ElevatedButton(
            onPressed: _disableScreenshot,
            child: const Text('Disable Screenshot'),
          ),
          ElevatedButton(
            onPressed: _enableScreenshot,
            child: const Text('Enable Screenshot'),
          ),
          ElevatedButton(
            onPressed: _toggleScreenshot,
            child: const Text('Toggle Screenshot'),
          ),

          const Divider(),

          // Monitoring buttons
          ElevatedButton(
            onPressed: _startMonitoring,
            child: const Text('Start Monitoring'),
          ),
          ElevatedButton(
            onPressed: _stopMonitoring,
            child: const Text('Stop Monitoring'),
          ),
          Text('Monitoring: $_isMonitoring'),
          Text('Last snapshot: $_latestSnapshot'),

          const Divider(),

          // Image overlay toggle
          ElevatedButton(
            onPressed: _toggleScreenshotWithImage,
            child: const Text('Toggle Image Overlay'),
          ),
          Text('Overlay active: $_isOverlayImageOn'),
        ],
      ),
    );
  }
}
```

## API Reference

| Method | Return Type | Description |
|---|---|---|
| `NoScreenshot.instance` | `NoScreenshot` | Singleton instance of the plugin |
| `screenshotOff()` | `Future<bool>` | Disable screenshots & screen recording |
| `screenshotOn()` | `Future<bool>` | Enable screenshots & screen recording |
| `toggleScreenshot()` | `Future<bool>` | Toggle screenshot protection on/off |
| `toggleScreenshotWithImage()` | `Future<bool>` | Toggle image overlay mode (returns new state) |
| `startScreenshotListening()` | `Future<void>` | Start monitoring for screenshot events |
| `stopScreenshotListening()` | `Future<void>` | Stop monitoring for screenshot events |
| `screenshotStream` | `Stream<ScreenshotSnapshot>` | Stream of screenshot activity events |

## Contributors

Thanks to everyone who has contributed to this project!

<a href="https://github.com/fonkamloic"><img src="https://github.com/fonkamloic.png" width="60" height="60" style="border-radius:50%" alt="@fonkamloic"></a>
<a href="https://github.com/zhangyuanyuan-bear"><img src="https://github.com/zhangyuanyuan-bear.png" width="60" height="60" style="border-radius:50%" alt="@zhangyuanyuan-bear"></a>
<a href="https://github.com/BranislavKljaic96"><img src="https://github.com/BranislavKljaic96.png" width="60" height="60" style="border-radius:50%" alt="@BranislavKljaic96"></a>
<a href="https://github.com/qk7b"><img src="https://github.com/qk7b.png" width="60" height="60" style="border-radius:50%" alt="@qk7b"></a>
<a href="https://github.com/T-moz"><img src="https://github.com/T-moz.png" width="60" height="60" style="border-radius:50%" alt="@T-moz"></a>
<a href="https://github.com/ggiordan"><img src="https://github.com/ggiordan.png" width="60" height="60" style="border-radius:50%" alt="@ggiordan"></a>
<a href="https://github.com/Musaddiq625"><img src="https://github.com/Musaddiq625.png" width="60" height="60" style="border-radius:50%" alt="@Musaddiq625"></a>
<a href="https://github.com/albertocappellina-intesys"><img src="https://github.com/albertocappellina-intesys.png" width="60" height="60" style="border-radius:50%" alt="@albertocappellina-intesys"></a>
<a href="https://github.com/kefeh"><img src="https://github.com/kefeh.png" width="60" height="60" style="border-radius:50%" alt="@kefeh"></a>

## License

BSD 3-Clause License. See [LICENSE](LICENSE) for details.
