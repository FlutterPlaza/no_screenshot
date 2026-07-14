import 'dart:async';

import 'package:no_screenshot/screenshot_snapshot.dart';

import 'no_screenshot_platform_interface.dart';

/// Callback type for screenshot and recording events.
typedef ScreenshotEventCallback = void Function(ScreenshotSnapshot snapshot);

/// A class that provides a platform-agnostic way to disable screenshots.
///
class NoScreenshot implements NoScreenshotPlatform {
  NoScreenshotPlatform get _instancePlatform => NoScreenshotPlatform.instance;
  NoScreenshot._();

  @Deprecated(
    "Using this may cause issue\nUse instance directly\ne.g: 'NoScreenshot.instance.screenshotOff()'",
  )
  NoScreenshot();

  static final NoScreenshot instance = NoScreenshot._();

  // ── Granular Callbacks (P15) ────────────────────────────────────────

  /// Called when a screenshot is detected.
  ScreenshotEventCallback? onScreenshotDetected;

  /// Called when screen recording starts.
  ScreenshotEventCallback? onScreenRecordingStarted;

  /// Called when screen recording stops.
  ScreenshotEventCallback? onScreenRecordingStopped;

  StreamSubscription<ScreenshotSnapshot>? _callbackSubscription;
  bool _wasRecording = false;

  /// Starts dispatching events to [onScreenshotDetected],
  /// [onScreenRecordingStarted], and [onScreenRecordingStopped].
  ///
  /// Listens to [screenshotStream] internally. Call [stopCallbacks] or
  /// [removeAllCallbacks] to cancel.
  void startCallbacks() {
    if (_callbackSubscription != null) return;
    _callbackSubscription = screenshotStream.listen(_dispatchCallbacks);
  }

  /// Stops dispatching events but keeps callback assignments.
  void stopCallbacks() {
    _callbackSubscription?.cancel();
    _callbackSubscription = null;
  }

  /// Stops dispatching and clears all callback assignments.
  void removeAllCallbacks() {
    stopCallbacks();
    onScreenshotDetected = null;
    onScreenRecordingStarted = null;
    onScreenRecordingStopped = null;
    _wasRecording = false;
  }

  /// Whether callbacks are currently being dispatched.
  bool get hasActiveCallbacks => _callbackSubscription != null;

  void _dispatchCallbacks(ScreenshotSnapshot snapshot) {
    if (snapshot.wasScreenshotTaken) {
      onScreenshotDetected?.call(snapshot);
    }
    if (!_wasRecording && snapshot.isScreenRecording) {
      onScreenRecordingStarted?.call(snapshot);
    }
    if (_wasRecording && !snapshot.isScreenRecording) {
      onScreenRecordingStopped?.call(snapshot);
    }
    _wasRecording = snapshot.isScreenRecording;
  }

  // ── Platform delegation ─────────────────────────────────────────────

  /// Return `true` if screenshot capabilities has been
  /// successfully disabled or is currently disabled and `false` otherwise.
  /// throw `UnmimplementedError` if not implement
  ///
  /// Always returns `false` when an iOS build runs on a Mac
  /// ("Designed for iPhone/iPad" on Apple silicon) — screenshot
  /// prevention is not supported there, though overlays and
  /// screenshot/recording detection still work.
  ///
  /// On iOS, also returns `false` if no window is available yet (e.g.
  /// called before the first frame is rendered). The request is
  /// remembered and protection engages on the next app activation.
  @override
  Future<bool> screenshotOff() {
    return _instancePlatform.screenshotOff();
  }

  /// Return `true` if screenshot capabilities has been
  /// successfully enabled or is currently enabled and `false` otherwise.
  /// throw `UnmimplementedError` if not implement
  ///
  /// Always returns `true` when an iOS build runs on a Mac —
  /// screenshots are permitted there by default.
  @override
  Future<bool> screenshotOn() {
    return _instancePlatform.screenshotOn();
  }

  @override
  Future<bool> toggleScreenshotWithImage() {
    return _instancePlatform.toggleScreenshotWithImage();
  }

  /// Toggles the blur overlay shown in the app switcher.
  ///
  /// On macOS, Flutter draws into a `CAMetalLayer` whose GPU content
  /// AppKit's snapshot API cannot capture, so the system blur material
  /// is used instead and [blurRadius] has no effect there. (Granting
  /// Screen Recording permission would not change this.)
  @override
  Future<bool> toggleScreenshotWithBlur({double blurRadius = 30.0}) {
    return _instancePlatform.toggleScreenshotWithBlur(blurRadius: blurRadius);
  }

  @override
  Future<bool> toggleScreenshotWithColor({int color = 0xFF000000}) {
    return _instancePlatform.toggleScreenshotWithColor(color: color);
  }

  /// Always enables image overlay mode (idempotent — safe to call repeatedly).
  @override
  Future<bool> screenshotWithImage() {
    return _instancePlatform.screenshotWithImage();
  }

  /// Always enables blur overlay mode (idempotent — safe to call repeatedly).
  ///
  /// On macOS the system blur material is used and [blurRadius] has no
  /// effect — see [toggleScreenshotWithBlur].
  @override
  Future<bool> screenshotWithBlur({double blurRadius = 30.0}) {
    return _instancePlatform.screenshotWithBlur(blurRadius: blurRadius);
  }

  /// Always enables color overlay mode (idempotent — safe to call repeatedly).
  @override
  Future<bool> screenshotWithColor({int color = 0xFF000000}) {
    return _instancePlatform.screenshotWithColor(color: color);
  }

  /// Return `true` if screenshot capabilities has been
  /// successfully toggle from it previous state and `false` if the attempt
  /// to toggle failed.
  /// throw `UnmimplementedError` if not implement
  ///
  /// Always returns `false` when an iOS build runs on a Mac
  /// ("Designed for iPhone/iPad" on Apple silicon) — screenshot
  /// prevention is not supported there; see [screenshotOff].
  @override
  Future<bool> toggleScreenshot() {
    return _instancePlatform.toggleScreenshot();
  }

  /// Stream to screenshot activities [ScreenshotSnapshot]
  ///
  @override
  Stream<ScreenshotSnapshot> get screenshotStream {
    return _instancePlatform.screenshotStream;
  }

  /// Start listening to screenshot activities
  @override
  Future<void> startScreenshotListening() {
    return _instancePlatform.startScreenshotListening();
  }

  /// Stop listening to screenshot activities
  @override
  Future<void> stopScreenshotListening() {
    return _instancePlatform.stopScreenshotListening();
  }

  /// Start listening to screen recording activities
  @override
  Future<void> startScreenRecordingListening() {
    return _instancePlatform.startScreenRecordingListening();
  }

  /// Stop listening to screen recording activities
  @override
  Future<void> stopScreenRecordingListening() {
    return _instancePlatform.stopScreenRecordingListening();
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NoScreenshot &&
            runtimeType == other.runtimeType &&
            _instancePlatform == other._instancePlatform;
  }

  @override
  int get hashCode => _instancePlatform.hashCode;
}
