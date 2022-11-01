import 'no_screenshot_platform_interface.dart';

class NoScreenshot implements NoScreenshotPlatform {
  final _instancePlatform = NoScreenshotPlatform.instance;
  NoScreenshot._();

  /// Made `NoScreenshot` class a singleton
  static NoScreenshot get instance => NoScreenshot._();

  /// Return `true` if screenshot capabilities has been successfully disabled
  /// or is currently disabled and `false` otherwise. throw `UnmimplementedError` if not implement
  @override
  Future<bool> screenshotOff() {
    return _instancePlatform.screenshotOff();
  }

  /// Return `true` if screenshot capabilities has been successfully enable
  /// or is currently enable and `false` otherwise. throw `UnmimplementedError` if not implement
  @override
  Future<bool> screenshotOn() {
    return _instancePlatform.screenshotOn();
  }

  ///Return `true` if screenshot capabilities has been successfully toggle from it previous state and
  ///`false` if the attempt to toggle failed. throw `UnmimplementedError` if not implement
  @override
  Future<bool> toggleScreenshot() {
    return _instancePlatform.toggleScreenshot();
  }
}
