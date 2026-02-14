@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:no_screenshot/no_screenshot_web.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';

void main() {
  late NoScreenshotWeb platform;

  setUp(() {
    platform = NoScreenshotWeb.createForTest();
  });

  group('NoScreenshotWeb', () {
    test('screenshotOff returns true and emits protection on', () async {
      final events = <ScreenshotSnapshot>[];
      platform.screenshotStream.listen(events.add);

      final result = await platform.screenshotOff();

      expect(result, true);
      await Future.delayed(Duration.zero);
      expect(events, isNotEmpty);
      expect(events.last.isScreenshotProtectionOn, true);
    });

    test('screenshotOn returns true and emits protection off', () async {
      await platform.screenshotOff(); // enable first

      final events = <ScreenshotSnapshot>[];
      platform.screenshotStream.listen(events.add);

      final result = await platform.screenshotOn();

      expect(result, true);
      await Future.delayed(Duration.zero);
      expect(events, isNotEmpty);
      expect(events.last.isScreenshotProtectionOn, false);
    });

    test('toggleScreenshot returns true', () async {
      final result = await platform.toggleScreenshot();
      expect(result, true);
    });

    test('toggleScreenshotWithImage returns toggle state', () async {
      // First toggle → on
      var result = await platform.toggleScreenshotWithImage();
      expect(result, true);

      // Second toggle → off
      result = await platform.toggleScreenshotWithImage();
      expect(result, false);
    });

    test('toggleScreenshotWithBlur returns toggle state', () async {
      var result = await platform.toggleScreenshotWithBlur();
      expect(result, true);

      result = await platform.toggleScreenshotWithBlur();
      expect(result, false);
    });

    test('toggleScreenshotWithColor returns toggle state', () async {
      var result = await platform.toggleScreenshotWithColor();
      expect(result, true);

      result = await platform.toggleScreenshotWithColor();
      expect(result, false);
    });

    test('screenshotWithImage returns true', () async {
      final result = await platform.screenshotWithImage();
      expect(result, true);
    });

    test('screenshotWithBlur returns true', () async {
      final result = await platform.screenshotWithBlur();
      expect(result, true);
    });

    test('screenshotWithColor returns true', () async {
      final result = await platform.screenshotWithColor();
      expect(result, true);
    });

    test('startScreenshotListening completes without error', () async {
      await expectLater(platform.startScreenshotListening(), completes);
    });

    test('stopScreenshotListening completes without error', () async {
      await platform.startScreenshotListening();
      await expectLater(platform.stopScreenshotListening(), completes);
    });

    test('startScreenRecordingListening completes (no-op)', () async {
      await expectLater(platform.startScreenRecordingListening(), completes);
    });

    test('stopScreenRecordingListening completes (no-op)', () async {
      await expectLater(platform.stopScreenRecordingListening(), completes);
    });

    test('screenshotStream emits on state changes', () async {
      final events = <ScreenshotSnapshot>[];
      platform.screenshotStream.listen(events.add);

      await platform.screenshotOff();
      await Future.delayed(Duration.zero);

      await platform.screenshotOn();
      await Future.delayed(Duration.zero);

      expect(events.length, 2);
      expect(events[0].isScreenshotProtectionOn, true);
      expect(events[1].isScreenshotProtectionOn, false);
    });

    test('enable is idempotent — does not double-emit', () async {
      final events = <ScreenshotSnapshot>[];
      platform.screenshotStream.listen(events.add);

      await platform.screenshotOff();
      await platform.screenshotOff(); // second call should be no-op
      await Future.delayed(Duration.zero);

      expect(events.length, 1);
    });
  });
}
