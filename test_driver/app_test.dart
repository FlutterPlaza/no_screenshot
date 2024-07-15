import 'package:flutter/services.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_screenshot/constants.dart';
import 'package:no_screenshot/no_screenshot_method_channel.dart';

void main() {
  MethodChannelNoScreenshot platform = MethodChannelNoScreenshot();
  const MethodChannel channel = MethodChannel('no_screenshot');

  TestWidgetsFlutterBinding.ensureInitialized();
  late FlutterDriver driver;

  setUp(() async {
    driver = await FlutterDriver.connect();
    // Updated deprecated method usage
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case screenShotOffConst:
          break;
        case screenShotOnConst:
          break;
        case toggleScreenShotConst:
          break;
        default:
      }
    });
  });

  group("Testing screenshot off", () {
    test(screenShotOffConst, () async {
      final firstScreenshot = await driver.screenshot();
      final result = await platform.screenshotOff();
      if (result) {
        final secondScreenshot = await driver.screenshot();
        expect(firstScreenshot != secondScreenshot, true);
      }
    });
  });
  group("Testing screenshot on", () {
    test(screenShotOnConst, () async {
      await platform.screenshotOn();
      final firstScreenshot = await driver.screenshot();
      final result = await platform.screenshotOn();
      if (result) {
        final secondScreenshot = await driver.screenshot();
        expect(firstScreenshot == secondScreenshot, true);
      }
    });
  });

  group("Testing screenshot toggle on and off", () {
    test(toggleScreenShotConst, () async {
      // resetting screenshot support
      await platform.screenshotOn();

      final firstScreenshot = await driver.screenshot();
      final result = await platform.toggleScreenshot();
      if (result) {
        final secondScreenshot = await driver.screenshot();
        expect(firstScreenshot != secondScreenshot, true);
      }
      final secondResult = await platform.toggleScreenshot();
      final thirdScreenshot = await driver.screenshot();
      late List<int> forthScreenshot;
      if (secondResult) {
        forthScreenshot = await driver.screenshot();
        expect(thirdScreenshot != forthScreenshot, true);
      }
      final fithScreenshot = await driver.screenshot();
      expect(forthScreenshot == fithScreenshot, true);
    });
  });
  tearDown(() {
    // Updated deprecated method usage
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    driver.close();
  });
}
