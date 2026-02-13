import 'package:no_screenshot/screenshot_snapshot.dart';

import 'no_screenshot_platform_interface.dart';

/// A class that provides a platform-agnostic way to disable screenshots.
///
class NoScreenshot implements NoScreenshotPlatform {
  final _instancePlatform = NoScreenshotPlatform.instance;
  NoScreenshot._();

  @Deprecated(
      "Using this may cause issue\nUse instance directly\ne.g: 'NoScreenshot.instance.screenshotOff()'")
  NoScreenshot();

  static NoScreenshot get instance => NoScreenshot._();

  /// Return `true` if screenshot capabilities has been
  /// successfully disabled or is currently disabled and `false` otherwise.
  /// throw `UnmimplementedError` if not implement
  ///
  @override
  Future<bool> screenshotOff() {
    return _instancePlatform.screenshotOff();
  }

  /// Return `true` if screenshot capabilities has been
  /// successfully enabled or is currently enabled and `false` otherwise.
  /// throw `UnmimplementedError` if not implement
  ///
  @override
  Future<bool> screenshotOn() {
    return _instancePlatform.screenshotOn();
  }

  @override
  Future<bool> toggleScreenshotWithImage() {
    return _instancePlatform.toggleScreenshotWithImage();
  }

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
