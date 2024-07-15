import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_screenshot/no_screenshot_platform_interface.dart';
import 'package:no_screenshot/no_screenshot_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNoScreenshotPlatform
    with MockPlatformInterfaceMixin
    implements NoScreenshotPlatform {
  @override
  Future<bool> screenshotOff() async {
    // Mock implementation or return a fixed value
    return Future.value(true);
  }

  @override
  Future<bool> screenshotOn() async {
    // Mock implementation or return a fixed value
    return Future.value(true);
  }

  @override
  Future<bool> toggleScreenshot() async {
    // Mock implementation or return a fixed value
    return Future.value(true);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final NoScreenshotPlatform initialPlatform = NoScreenshotPlatform.instance;
  MockNoScreenshotPlatform fakePlatform = MockNoScreenshotPlatform();

  test('$MethodChannelNoScreenshot is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNoScreenshot>());
  });

  test('screenshotOn', () async {
    expect(await fakePlatform.screenshotOn(), true);
  });
  // screenshotOff
  test('screenshotOff', () async {
    expect(await fakePlatform.screenshotOff(), true);
  });

  // toggleScreenshot
  test('toggleScreenshot', () async {
    expect(await fakePlatform.toggleScreenshot(), true);
  });
}
