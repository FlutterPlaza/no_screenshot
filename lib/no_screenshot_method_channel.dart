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

  Stream<ScreenshotSnapshot>? _cachedStream;

  @override
  Stream<ScreenshotSnapshot> get screenshotStream {
    _cachedStream ??= eventChannel.receiveBroadcastStream().map(
      (event) =>
          ScreenshotSnapshot.fromMap(jsonDecode(event) as Map<String, dynamic>),
    );
    return _cachedStream!;
  }

  @override
  Future<bool> toggleScreenshot() async {
    final result = await methodChannel.invokeMethod<bool>(
      toggleScreenShotConst,
    );
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
  Future<bool> toggleScreenshotWithImage() async {
    final result = await methodChannel.invokeMethod<bool>(screenSetImage);
    return result ?? false;
  }

  @override
  Future<bool> toggleScreenshotWithBlur({double blurRadius = 30.0}) async {
    final result = await methodChannel.invokeMethod<bool>(screenSetBlur, {
      'radius': blurRadius,
    });
    return result ?? false;
  }

  @override
  Future<bool> toggleScreenshotWithColor({int color = 0xFF000000}) async {
    final result = await methodChannel.invokeMethod<bool>(screenSetColor, {
      'color': color,
    });
    return result ?? false;
  }

  @override
  Future<bool> screenshotWithImage() async {
    final result = await methodChannel.invokeMethod<bool>(screenEnableImage);
    return result ?? false;
  }

  @override
  Future<bool> screenshotWithBlur({double blurRadius = 30.0}) async {
    final result = await methodChannel.invokeMethod<bool>(screenEnableBlur, {
      'radius': blurRadius,
    });
    return result ?? false;
  }

  @override
  Future<bool> screenshotWithColor({int color = 0xFF000000}) async {
    final result = await methodChannel.invokeMethod<bool>(screenEnableColor, {
      'color': color,
    });
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

  @override
  Future<void> startScreenRecordingListening() {
    return methodChannel.invokeMethod<void>(startScreenRecordingListeningConst);
  }

  @override
  Future<void> stopScreenRecordingListening() {
    return methodChannel.invokeMethod<void>(stopScreenRecordingListeningConst);
  }
}
