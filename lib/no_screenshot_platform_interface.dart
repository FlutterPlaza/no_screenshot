import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'no_screenshot_method_channel.dart';

abstract class NoScreenshotPlatform extends PlatformInterface {
  /// Constructs a NoScreenshotPlatform.
  NoScreenshotPlatform() : super(token: _token);

  static final Object _token = Object();

  static NoScreenshotPlatform _instance = MethodChannelNoScreenshot();

  /// The default instance of [NoScreenshotPlatform] to use.
  ///
  /// Defaults to [MethodChannelNoScreenshot].
  static NoScreenshotPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NoScreenshotPlatform] when
  /// they register themselves.
  static set instance(NoScreenshotPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Return `true` if screenshot capabilities has been
  /// successfully disabled or is currently disabled and `false` otherwise.
  /// throw `UnmimplementedError` if not implement
  Future<bool> screenshotOff() {
    throw UnimplementedError('screenshotOff() has not been implemented.');
  }

  /// Return `true` if screenshot capabilities has been
  /// successfully enabled or is currently enabled and `false` otherwise.
  /// throw `UnmimplementedError` if not implement
  Future<bool> screenshotOn() {
    throw UnimplementedError('screenshotOn() has not been implemented.');
  }

  /// Return `true` if screenshot capabilities has been
  /// successfully toggle from it previous state and `false` if the attempt
  /// to toggle failed.
  /// throw `UnmimplementedError` if not implement
  Future<bool> toggleScreenshot() {
    throw UnimplementedError('toggleScreenshot() has not been implemented.');
  }
}
