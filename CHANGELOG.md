## 0.9.1

- chore: add pub.dev topics to pubspec.yaml.

## 0.9.0

- feat(ios, macos): added Swift Package Manager support — `Package.swift` for both iOS and macOS, with CocoaPods backward compatibility by @fonkamloic.
- feat(example): added color picker with 8 preset colors for the color overlay section by @fonkamloic.
- feat(example): added blur radius slider (1–100) that applies the blur overlay in real time by @fonkamloic.
- chore: updated podspec `source_files` paths to reference SPM directory structure by @fonkamloic.
- chore: added `.build/` and `.swiftpm/` to `.gitignore` and `.pubignore` by @fonkamloic.

## 0.8.0

- feat: added `timestamp` and `sourceApp` metadata fields to `ScreenshotSnapshot` — backward-compatible defaults (P8) by @fonkamloic.
- feat(android): screenshot metadata via `MediaStore.Images.Media.DATE_ADDED` and `DISPLAY_NAME` by @fonkamloic.
- feat(ios): screenshot metadata via wall clock at detection time by @fonkamloic.
- feat(macos): screenshot metadata via `kMDItemContentCreationDate` and `kMDItemCreator` / detected recording app name by @fonkamloic.
- feat(linux): screenshot metadata via `G_FILE_ATTRIBUTE_TIME_MODIFIED` and inferred source app from filename prefix by @fonkamloic.
- feat(windows): added Windows platform support — `SetWindowDisplayAffinity(WDA_EXCLUDEFROMCAPTURE)` for prevention, `AddClipboardFormatListener` + `ReadDirectoryChangesW` for screenshot detection, process scanning for recording detection (P11) by @fonkamloic.
- feat: added granular callbacks — `onScreenshotDetected`, `onScreenRecordingStarted`, `onScreenRecordingStopped` with `startCallbacks()` / `stopCallbacks()` / `removeAllCallbacks()` API (P15) by @fonkamloic.
- feat(web): added best-effort web platform support — right-click blocking, PrintScreen interception, `user-select: none` CSS, `visibilitychange` detection (P17) by @fonkamloic.
- fix: fixed `NoScreenshot.instance` creating a new instance on every access — now a proper cached singleton by @fonkamloic.
- fix: changed `_instancePlatform` from a captured field to a getter so platform is resolved at call time by @fonkamloic.
- feat(example): added Granular Callbacks section with real-time event display by @fonkamloic.
- feat(example): added web platform scaffolding by @fonkamloic.
- fix(linux): replaced `FlEventSink` with `fl_event_channel_send` for stream event delivery by @fonkamloic.
- fix(linux): fixed GObject typedefs, recording detection thread safety, stream caching, and platform-specific UI layout by @fonkamloic.
- test: added granular callback tests with mock platform class by @fonkamloic.
- test: added web platform test suite by @fonkamloic.
- test: added `screenshotStream` coverage for event channel decoding and stream caching by @fonkamloic.

## 0.7.0

- feat: added `SecureWidget` — a declarative Flutter widget that auto-enables screenshot protection on mount and disables on unmount (P6) by @fonkamloic.
- feat: added `SecureNavigatorObserver` — a `NavigatorObserver` that applies different protection levels per named route (P7) by @fonkamloic.
- feat: added `SecureRouteConfig` class for configuring per-route protection policies with `OverlayMode`, `blurRadius`, and `color` by @fonkamloic.
- feat: added `OverlayMode` enum (`none`, `secure`, `blur`, `color`, `image`) and `applyOverlayMode()` helper for declarative protection by @fonkamloic.
- feat: added idempotent `screenshotWithImage()`, `screenshotWithBlur()`, and `screenshotWithColor()` API methods — always enable the overlay (no toggle), safe to call repeatedly by @fonkamloic.
- feat: added idempotent native handlers on Android, iOS, macOS, and Linux for the new always-enable methods by @fonkamloic.
- feat(example): added SecureWidget demo page and per-route protection demo with payment, profile, and public pages by @fonkamloic.
- test: added widget tests for `SecureWidget` (initState, dispose, didUpdateWidget, all overlay modes) by @fonkamloic.
- test: added unit tests for `SecureNavigatorObserver` (didPush, didPop, didReplace, didRemove, defaultConfig, custom params) by @fonkamloic.
- test: added method channel, platform interface, and `NoScreenshot` tests for new idempotent methods by @fonkamloic.
- docs: updated README with SecureWidget and per-route protection sections, updated API reference table by @fonkamloic.

## 0.6.0

- feat: added configurable `blurRadius` parameter to `toggleScreenshotWithBlur({double blurRadius})` — defaults to 30.0, customizable per platform by @fonkamloic.
- feat: added `toggleScreenshotWithColor({int color})` API — solid color overlay for app switcher / recents screen across all platforms by @fonkamloic.
- feat(android): color overlay via a solid `View` with the specified ARGB color by @fonkamloic.
- feat(ios): color overlay via `UIView` with the specified background color by @fonkamloic.
- feat(macos): color overlay via `NSView` with the specified background color by @fonkamloic.
- feat(linux): color overlay state tracked and persisted (best-effort — compositors control task switcher thumbnails) by @fonkamloic.
- feat: color, blur, and image overlays are mutually exclusive — activating one deactivates the others, enforced at native level on all platforms by @fonkamloic.
- feat(example): added Color Overlay section with color picker and toggle button by @fonkamloic.
- feat(example): added localization strings for color overlay UI by @fonkamloic.
- test: added method channel, platform interface, and `NoScreenshot` tests for `toggleScreenshotWithBlur` with custom radius and `toggleScreenshotWithColor` by @fonkamloic.
- docs: updated README, CHANGELOG, roadmap, and example app to reflect configurable blur radius and color overlay support by @fonkamloic.

## 0.5.0

- feat: added `toggleScreenshotWithBlur()` API — Gaussian blur overlay for app switcher / recents screen (P2) by @fonkamloic.
- feat(android): blur overlay via `RenderEffect.createBlurEffect()` on API 31+ (zero-copy GPU blur) and `RenderScript.ScriptIntrinsicBlur` on API 17–30 by @fonkamloic.
- feat(ios): blur overlay via `UIVisualEffectView` with `UIBlurEffect(style: .regular)` by @fonkamloic.
- feat(macos): blur overlay via `NSVisualEffectView` with `.hudWindow` material by @fonkamloic.
- feat(linux): blur overlay state tracked and persisted (best-effort — compositors control task switcher thumbnails) by @fonkamloic.
- feat: blur and image overlay are mutually exclusive — activating one deactivates the other, enforced at native level on all platforms by @fonkamloic.
- feat: blur overlay state persists across app restarts via SharedPreferences / UserDefaults / JSON on all platforms by @fonkamloic.
- feat(example): added Overlay Blur section with toggle button and status indicator by @fonkamloic.
- fix(example): fixed stream subscription leak causing `setState` on unmounted widget — added proper `dispose()` and `mounted` check by @fonkamloic.
- test: added method channel, platform interface, and `NoScreenshot` tests for `toggleScreenshotWithBlur` by @fonkamloic.
- docs: updated README, CHANGELOG, roadmap, and example app to reflect blur overlay support by @fonkamloic.

## 0.4.0

- feat: detect screen recording start/stop events across all platforms (P1) by @fonkamloic.
- feat(ios): event-driven screen recording detection via `UIScreen.capturedDidChangeNotification` (iOS 11+) — detects both start and stop by @fonkamloic.
- feat(android): screen recording detection via `Activity.ScreenCaptureCallback` (API 34+) — detects recording start; graceful no-op on pre-34 devices by @fonkamloic.
- feat(macos): best-effort screen recording detection via `NSWorkspace` process monitoring — polls for known recording apps (QuickTime Player, OBS, Loom, Kap, ffmpeg, screencapture, simplescreenrecorder) by @fonkamloic.
- feat(linux): best-effort screen recording detection via `/proc` process scanning — polls for known recording tools (ffmpeg, obs, simplescreenrecorder, kazam, peek, recordmydesktop, vokoscreen) by @fonkamloic.
- feat: added `isScreenRecording` field to `ScreenshotSnapshot` — backward-compatible, defaults to `false` when omitted by native code by @fonkamloic.
- feat: added `startScreenRecordingListening()` and `stopScreenRecordingListening()` API methods — recording detection is independent of screenshot detection by @fonkamloic.
- feat(example): added Recording Monitoring section with enable/disable buttons and real-time `isScreenRecording` status display by @fonkamloic.
- test: added method channel, platform interface, and `ScreenshotSnapshot` tests for screen recording detection by @fonkamloic.
- docs: updated README, CHANGELOG, roadmap, and example app to reflect screen recording detection support by @fonkamloic.

## 0.3.6

- feat(linux): added Linux support with screenshot detection via `GFileMonitor` (inotify), monitoring `~/Pictures/Screenshots/`, `~/Pictures/`, and XDG pictures directory by @fonkamloic.
- feat(linux): screenshot file path is available on Linux (via `GFileMonitor`) — same as macOS by @fonkamloic.
- feat(linux): screenshot prevention and image overlay are best-effort on Linux — state is tracked and persisted, but Linux compositors (Wayland / X11) do not expose a `FLAG_SECURE`-equivalent API by @fonkamloic.
- feat(linux): state persistence via JSON file in `$XDG_DATA_HOME/no_screenshot/state.json` by @fonkamloic.
- docs: updated README, CHANGELOG, and example app to reflect Linux support by @fonkamloic.

## 0.3.5

- fix(ios): fix iOS 26 RTL layout shift by dropping `ScreenProtectorKit` and inlining screenshot prevention with `forceLeftToRight` semantics by @fonkamloic.
- fix(ios): fix `EXC_BAD_ACCESS` crash in `_collectExistingTraitCollectionsForTraitTracking` on iOS 26+ caused by circular view hierarchy by @fonkamloic.
- fix(ios): fix bottom-right content alignment caused by Auto Layout constraint offset during layer reparenting by @fonkamloic.
- feat(ios): removed `ScreenProtectorKit` dependency — all iOS screenshot prevention is now inlined by @fonkamloic.
- feat(example): add EN/AR localization and RTL toggle to example app for testing RTL layout by @fonkamloic.
- docs: document `screenshotPath` availability — file path is only available on macOS; Android and iOS return a placeholder by @fonkamloic.
- docs: add LTR/RTL language support note to README by @fonkamloic.
- docs: add GIF demo placeholders for every feature on every platform by @fonkamloic.

## 0.3.4

- fix(macos): detect clipboard-only screenshots (Cmd+Ctrl+Shift+3/4) via pasteboard polling by @fonkamloic.
- fix(macos): detect repeated screenshots while `screencaptureui` is still running by @fonkamloic.
- fix(macos): track `screencaptureui` process lifecycle (launch + termination) for reliable detection by @fonkamloic.
- fix(macos): add 2s debounce to suppress duplicate detection events while allowing file-path upgrades from `NSMetadataQuery` by @fonkamloic.
- docs: updated macOS screenshot monitoring documentation to reflect three detection methods by @fonkamloic.

## 0.3.3

- feat(macos): added macOS support for `toggleScreenshotWithImage()` by @fonkamloic.
- feat: added `toggleScreenshotWithImage()` API to display a custom image overlay when the app goes to the background or app switcher, preventing screenshot content exposure on both Android and iOS by @zhangyuanyuan-bear and @fonkamloic.
- feat: image overlay mode persists across app restarts via platform SharedPreferences/UserDefaults by @zhangyuanyuan-bear and @fonkamloic.
- fix(ios): prevent stale image overlay by consolidating lifecycle handling by @BranislavKljaic96 and @fonkamloic.
- fix(ios): native code now works with both SceneDelegate and AppDelegate by @BranislavKljaic96 in https://github.com/FlutterPlaza/no_screenshot/pull/86.
- fix: use `Executors` for SharedPreferences access on Android to avoid strict mode violations on startup by @qk7b in https://github.com/FlutterPlaza/no_screenshot/pull/74.
- fix: properly clean up image overlay and activity references on detach/config changes (Android) by @fonkamloic.
- chore: updated Kotlin and Gradle versions in Android build configuration by @T-moz in https://github.com/FlutterPlaza/no_screenshot/pull/76.
- chore: updated example app to demonstrate the new image overlay feature by @fonkamloic.
- test: added `toggleScreenshotWithImage` tests and fixed CI codecov upload by @fonkamloic.
- ci: added automated pub.dev publish workflow by @fonkamloic.

## 0.3.3-beta.1

- feat: added `toggleScreenshotWithImage()` API to display a custom image overlay when the app goes to the background or app switcher, preventing screenshot content exposure on both Android and iOS by @zhangyuanyuan-bear and @fonkamloic.
- feat: image overlay mode persists across app restarts via platform SharedPreferences/UserDefaults by @zhangyuanyuan-bear and @fonkamloic.
- fix: use `Executors` for SharedPreferences access on Android to avoid strict mode violations on startup by @qk7b.
- fix: properly clean up image overlay and activity references on detach/config changes (Android) by @fonkamloic.
- chore: updated Kotlin and Gradle versions in Android build configuration by @T-moz.
- chore: updated example app to demonstrate the new image overlay feature by @fonkamloic.
- ci: added automated pub.dev publish workflow by @fonkamloic.

## 0.3.2

- feat: macos support by @fonkamloic in https://github.com/FlutterPlaza/no_screenshot/pull/51
- fix: fix screenshot state not persisting on iOS by @fonkamloic in https://github.com/FlutterPlaza/no_screenshot/pull/45
- fix: duplicate interface definition for class 'NoScreenshotPlugin' by @fonkamloic in https://github.com/FlutterPlaza/no_screenshot/pull/62
- chore(deps): bump actions/checkout from 2 to 4 by @dependabot in https://github.com/FlutterPlaza/no_screenshot/pull/43
- chore(deps): bump codecov/codecov-action from 4.0.1 to 4.5.0 by @dependabot in https://github.com/FlutterPlaza/no_screenshot/pull/42

## 0.3.2-beta.3

- chore: updated pkg version by @fonkamloic in https://github.com/FlutterPlaza/no_screenshot/pull/63
- fix: duplicate interface definition for class 'NoScreenshotPlugin' by @fonkamloic in https://github.com/FlutterPlaza/no_screenshot/pull/62

## 0.3.2-beta.1

- fix: fix screenshot state not persisting on iOS by @fonkamloic in https://github.com/FlutterPlaza/no_screenshot/pull/45
- chore(deps): bump actions/checkout from 2 to 4 by @dependabot in https://github.com/FlutterPlaza/no_screenshot/pull/43
- chore(deps): bump codecov/codecov-action from 4.0.1 to 4.5.0 by @dependabot in https://github.com/FlutterPlaza/no_screenshot/pull/42
- feat: macos support by @fonkamloic in https://github.com/FlutterPlaza/no_screenshot/pull/51

## 0.3.1

- feat: added MacOS support
- fix: fix screenshot state not persisting on iOS
- chore: added more examples.

## 1.0.0-beta.2

- fix: Pub Point analysis failure.

## 1.0.0-beta.1

### Summary of Changes

- **Automatic State Persistence**: Removed the need to track `didChangeAppLifecycleState`. The state will now be automatically persisted using native platform SharedPreferences.
- **Enhanced Example**: Updated the example app to demonstrate the new automatic state persistence and usage of the `NoScreenshot` plugin.
- **Stream Support**: Provided a stream to listen for screenshot activities, making it easier to react to screenshots in real-time.
- **Bug Fixes**: Fixed various bugs related to screenshot detection and state management on both Android and iOS platforms.
- **Documentation Updates**: Improved documentation to reflect the new features and provide clearer usage examples.
- **Deprecation Notice**: Deprecated the use of the constructor `NoScreenshot()` in favor of the singleton `NoScreenshot.instance`.

## 0.2.0

- Upgrade android to support AGP 8.X
- merged fix by @alberto-cappellina PR[https://github.com/FlutterPlaza/no_screenshot/pull/27]
- gradle:7.1.2 -> 7.4.2
- kotlin_version = '1.6.10' -> '1.6.21'

## 0.0.1+7


- Set the namespace for android
- Specify a more current version of ScreenProtectorKit.  This resolves iOS17 issues.
- fix: screenshot prevention on iOS
- updated readme by @Musaddiq635 PR[https://github.com/FlutterPlaza/no_screenshot/pull/26]
- merged fix by @ggiordan PR[https://github.com/FlutterPlaza/no_screenshot/pull/29]

## 0.0.1+6

- Removed the non implemented override functions in android life-cycle

## 0.0.1+5

- Fixed broken link from pub dev analyses

## 0.0.1+4

- Fixed issue #1[Crashes app when backgrounded on iOS](https://github.com/FlutterPlaza/no_screenshot/issues/1)

## 0.0.1+3

- Reverted to BSD 3 license
- Added documentation
- Made `NoScreenshot` class a singleton

## 0.0.1+2

- Adopted MIT license

## 0.0.1+1

Updated readme and added sample usage.

## 0.0.1

Package has 3 basic functionalities on android and IOS via method channel.
    - Disable screenshot support in app
    - Enable screenshot support in app
    - Toggle between enable and disable state