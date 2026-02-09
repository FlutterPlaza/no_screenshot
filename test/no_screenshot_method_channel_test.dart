import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_screenshot/constants.dart';
import 'package:no_screenshot/no_screenshot_method_channel.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelNoScreenshot platform;

  setUp(() {
    platform = MethodChannelNoScreenshot();
  });

  group('MethodChannelNoScreenshot', () {
    const MethodChannel channel = MethodChannel(screenshotMethodChannel);

    test('screenshotOn', () async {
      const bool expected = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == screenShotOnConst) {
          return expected;
        }
        return null;
      });

      final result = await platform.screenshotOn();
      expect(result, expected);
    });

    test('screenshotOff', () async {
      const bool expected = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == screenShotOffConst) {
          return expected;
        }
        return null;
      });

      final result = await platform.screenshotOff();
      expect(result, expected);
    });

    test('toggleScreenshot', () async {
      const bool expected = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == toggleScreenShotConst) {
          return expected;
        }
        return null;
      });

      final result = await platform.toggleScreenshot();
      expect(result, expected);
    });

    test('startScreenshotListening', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == startScreenshotListeningConst) {
          return null;
        }
        return null;
      });

      await platform.startScreenshotListening();
      expect(true, true); // Add more specific expectations if needed
    });

    test('stopScreenshotListening', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == stopScreenshotListeningConst) {
          return null;
        }
        return null;
      });

      await platform.stopScreenshotListening();
      expect(true, true); // Add more specific expectations if needed
    });

    test('toggleScreenshotWithImage', () async {
      const bool expected = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == screenSetImage) {
          return expected;
        }
        return null;
      });

      final result = await platform.toggleScreenshotWithImage();
      expect(result, expected);
    });

    test('toggleScreenshotWithImage returns false when channel returns null',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return null;
      });

      final result = await platform.toggleScreenshotWithImage();
      expect(result, false);
    });

    test('screenshotOn returns false when channel returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return null;
      });

      final result = await platform.screenshotOn();
      expect(result, false);
    });

    test('screenshotOff returns false when channel returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return null;
      });

      final result = await platform.screenshotOff();
      expect(result, false);
    });

    test('toggleScreenshot returns false when channel returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return null;
      });

      final result = await platform.toggleScreenshot();
      expect(result, false);
    });
  });

  group('ScreenshotSnapshot', () {
    test('fromMap', () {
      final map = {
        'screenshot_path': '/example/path',
        'is_screenshot_on': true,
        'was_screenshot_taken': true,
      };
      final snapshot = ScreenshotSnapshot.fromMap(map);
      expect(snapshot.screenshotPath, '/example/path');
      expect(snapshot.isScreenshotProtectionOn, true);
      expect(snapshot.wasScreenshotTaken, true);
    });

    test('toMap', () {
      final snapshot = ScreenshotSnapshot(
        screenshotPath: '/example/path',
        isScreenshotProtectionOn: true,
        wasScreenshotTaken: true,
      );
      final map = snapshot.toMap();
      expect(map['screenshot_path'], '/example/path');
      expect(map['is_screenshot_on'], true);
      expect(map['was_screenshot_taken'], true);
    });

    test('equality operator', () {
      final snapshot1 = ScreenshotSnapshot(
        screenshotPath: '/example/path',
        isScreenshotProtectionOn: true,
        wasScreenshotTaken: true,
      );
      final snapshot2 = ScreenshotSnapshot(
        screenshotPath: '/example/path',
        isScreenshotProtectionOn: true,
        wasScreenshotTaken: true,
      );
      final snapshot3 = ScreenshotSnapshot(
        screenshotPath: '/different/path',
        isScreenshotProtectionOn: false,
        wasScreenshotTaken: false,
      );

      expect(snapshot1 == snapshot2, true);
      expect(snapshot1 == snapshot3, false);
    });

    test('hashCode', () {
      final snapshot1 = ScreenshotSnapshot(
        screenshotPath: '/example/path',
        isScreenshotProtectionOn: true,
        wasScreenshotTaken: true,
      );
      final snapshot2 = ScreenshotSnapshot(
        screenshotPath: '/example/path',
        isScreenshotProtectionOn: true,
        wasScreenshotTaken: true,
      );
      final snapshot3 = ScreenshotSnapshot(
        screenshotPath: '/different/path',
        isScreenshotProtectionOn: false,
        wasScreenshotTaken: false,
      );

      expect(snapshot1.hashCode, snapshot2.hashCode);
      expect(snapshot1.hashCode, isNot(snapshot3.hashCode));
    });

    test('fromMap with empty map uses defaults', () {
      final snapshot = ScreenshotSnapshot.fromMap({});
      expect(snapshot.screenshotPath, '');
      expect(snapshot.isScreenshotProtectionOn, false);
      expect(snapshot.wasScreenshotTaken, false);
    });

    test('fromMap with null values uses defaults', () {
      final map = <String, dynamic>{
        'screenshot_path': null,
        'is_screenshot_on': null,
        'was_screenshot_taken': null,
      };
      final snapshot = ScreenshotSnapshot.fromMap(map);
      expect(snapshot.screenshotPath, '');
      expect(snapshot.isScreenshotProtectionOn, false);
      expect(snapshot.wasScreenshotTaken, false);
    });

    test('toString', () {
      final snapshot = ScreenshotSnapshot(
        screenshotPath: '/example/path',
        isScreenshotProtectionOn: true,
        wasScreenshotTaken: true,
      );
      final string = snapshot.toString();
      expect(string,
          'ScreenshotSnapshot(\nscreenshotPath: /example/path, \nisScreenshotProtectionOn: true, \nwasScreenshotTaken: true\n)');
    });
  });
}
