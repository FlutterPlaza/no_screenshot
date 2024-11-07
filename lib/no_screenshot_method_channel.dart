import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:no_screenshot/constants.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';

import 'no_screenshot_platform_interface.dart';

/// An implementation of [NoScreenshotPlatform] that uses method channels.
class MethodChannelNoScreenshot extends NoScreenshotPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(screenshotMethodChannel);
  @visibleForTesting
  final eventChannel = const EventChannel(screenshotEventChannel);

  @override
  Stream<ScreenshotSnapshot> get screenshotStream {
    return eventChannel.receiveBroadcastStream().map((event) =>
        ScreenshotSnapshot.fromMap(jsonDecode(event) as Map<String, dynamic>));
  }

  @override
  Future<bool> toggleScreenshot() async {
    final result =
        await methodChannel.invokeMethod<bool>(toggleScreenShotConst);
    return result ?? false;
  }

  @override
  Future<bool> screenshotOff() async {
    final result = await methodChannel.invokeMethod<bool>(screenShotOffConst);
    return result ?? false;
  }

  @override
  Future<bool> screenshotOn() async {
    final result = await methodChannel.invokeMethod<bool>(screenShotOnConst);
    return result ?? false;
  }

  @override
  Future<void> startScreenshotListening() {
    return methodChannel.invokeMethod<void>(startScreenshotListeningConst);
  }

  @override
  Future<void> stopScreenshotListening() {
    return methodChannel.invokeMethod<void>(stopScreenshotListeningConst);
  }
}
