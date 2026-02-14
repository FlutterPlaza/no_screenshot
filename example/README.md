# no_screenshot example

Demonstrates how to use the `no_screenshot` plugin.

## Supported Platforms

Android, iOS, macOS, Linux, Windows, and Web.

## Features Demonstrated

- **Screenshot Protection** — enable, disable, and toggle screenshot/screen recording blocking.
- **Screenshot Monitoring** — real-time stream of screenshot events with `ScreenshotSnapshot`.
- **Screen Recording Monitoring** — detect recording start/stop events.
- **Image Overlay** — show a custom image in the app switcher / recents screen.
- **Blur Overlay** — Gaussian blur with configurable radius in the app switcher.
- **Color Overlay** — solid color overlay with color picker in the app switcher.
- **Granular Callbacks** — `onScreenshotDetected`, `onScreenRecordingStarted`, `onScreenRecordingStopped` with real-time event display.
- **SecureWidget** — declarative protection that auto-enables on mount and disables on unmount.
- **Per-Route Protection** — different protection levels for different named routes.
- **RTL Support** — EN/AR localization toggle for verifying RTL layout.

## Quick Start

```dart
import 'package:no_screenshot/no_screenshot.dart';

final noScreenshot = NoScreenshot.instance;

// Disable screenshots & screen recording
await noScreenshot.screenshotOff();

// Re-enable screenshots & screen recording
await noScreenshot.screenshotOn();

// Listen for screenshot events
noScreenshot.screenshotStream.listen((snapshot) {
  print('Protection: ${snapshot.isScreenshotProtectionOn}');
  print('Screenshot taken: ${snapshot.wasScreenshotTaken}');
  print('Recording: ${snapshot.isScreenRecording}');
  print('Timestamp: ${snapshot.timestamp}');
  print('Source app: ${snapshot.sourceApp}');
});
await noScreenshot.startScreenshotListening();

// Granular callbacks
noScreenshot.onScreenshotDetected = (snapshot) {
  print('Screenshot detected!');
};
noScreenshot.startCallbacks();
```

## Running the Example

```bash
flutter run
```

For Linux with Wayland issues, use:

```bash
GDK_BACKEND=x11 flutter run -d linux
```

## Additional Information

See the [main README](../README.md) for full documentation and API reference.