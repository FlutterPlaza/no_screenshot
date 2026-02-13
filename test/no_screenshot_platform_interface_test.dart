import 'package:flutter_test/flutter_test.dart';
import 'package:no_screenshot/no_screenshot_method_channel.dart';
import 'package:no_screenshot/no_screenshot_platform_interface.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';

/// A minimal subclass that does NOT override toggleScreenshotWithImage,
/// so we can verify the base class throws UnimplementedError.
class BaseNoScreenshotPlatform extends NoScreenshotPlatform {}

class MockNoScreenshotPlatform extends NoScreenshotPlatform {
  @override
  Future<bool> screenshotOff() async {
    return true;
  }

  @override
  Future<bool> screenshotOn() async {
    return true;
  }

  @override
  Future<bool> toggleScreenshot() async {
    return true;
  }

  @override
  Stream<ScreenshotSnapshot> get screenshotStream {
    return const Stream.empty();
  }

  @override
  Future<void> startScreenshotListening() async {
    return;
  }

  @override
  Future<bool> toggleScreenshotWithImage() async {
    return true;
  }

  @override
  Future<bool> toggleScreenshotWithBlur() async {
    return true;
  }

  @override
  Future<void> stopScreenshotListening() async {
    return;
  }

  @override
  Future<void> startScreenRecordingListening() async {
    return;
  }

  @override
  Future<void> stopScreenRecordingListening() async {
    return;
  }
}

void main() {
  final platform = MockNoScreenshotPlatform();

  group('NoScreenshotPlatform', () {
    test('default instance should be MethodChannelNoScreenshot', () {
      expect(NoScreenshotPlatform.instance,
          isInstanceOf<MethodChannelNoScreenshot>());
    });

    test('screenshotOff should return true when called', () async {
      expect(await platform.screenshotOff(), isTrue);
    });

    test('screenshotOn should return true when called', () async {
      expect(await platform.screenshotOn(), isTrue);
    });

    test('toggleScreenshot should return true when called', () async {
      expect(await platform.toggleScreenshot(), isTrue);
    });

    test('screenshotStream should not throw UnimplementedError when accessed',
        () {
      expect(() => platform.screenshotStream, isNot(throwsUnimplementedError));
    });
    test(
        'startScreenshotListening should not throw UnimplementedError when called',
        () async {
      expect(platform.startScreenshotListening(), completes);
    });

    test(
        'stopScreenshotListening should not throw UnimplementedError when called',
        () async {
      expect(platform.stopScreenshotListening(), completes);
    });

    test('toggleScreenshotWithImage should return true when called', () async {
      expect(await platform.toggleScreenshotWithImage(), isTrue);
    });

    test(
        'base NoScreenshotPlatform.toggleScreenshotWithImage() throws UnimplementedError',
        () {
      final basePlatform = BaseNoScreenshotPlatform();
      expect(() => basePlatform.toggleScreenshotWithImage(),
          throwsUnimplementedError);
    });

    test('toggleScreenshotWithBlur should return true when called', () async {
      expect(await platform.toggleScreenshotWithBlur(), isTrue);
    });

    test(
        'base NoScreenshotPlatform.toggleScreenshotWithBlur() throws UnimplementedError',
        () {
      final basePlatform = BaseNoScreenshotPlatform();
      expect(() => basePlatform.toggleScreenshotWithBlur(),
          throwsUnimplementedError);
    });

    test('base NoScreenshotPlatform.screenshotOff() throws UnimplementedError',
        () {
      final basePlatform = BaseNoScreenshotPlatform();
      expect(() => basePlatform.screenshotOff(), throwsUnimplementedError);
    });

    test('base NoScreenshotPlatform.screenshotOn() throws UnimplementedError',
        () {
      final basePlatform = BaseNoScreenshotPlatform();
      expect(() => basePlatform.screenshotOn(), throwsUnimplementedError);
    });

    test(
        'base NoScreenshotPlatform.toggleScreenshot() throws UnimplementedError',
        () {
      final basePlatform = BaseNoScreenshotPlatform();
      expect(() => basePlatform.toggleScreenshot(), throwsUnimplementedError);
    });

    test('base NoScreenshotPlatform.screenshotStream throws UnimplementedError',
        () {
      final basePlatform = BaseNoScreenshotPlatform();
      expect(() => basePlatform.screenshotStream, throwsUnimplementedError);
    });

    test(
        'base NoScreenshotPlatform.startScreenshotListening() throws UnimplementedError',
        () {
      final basePlatform = BaseNoScreenshotPlatform();
      expect(() => basePlatform.startScreenshotListening(),
          throwsUnimplementedError);
    });

    test(
        'base NoScreenshotPlatform.stopScreenshotListening() throws UnimplementedError',
        () {
      final basePlatform = BaseNoScreenshotPlatform();
      expect(() => basePlatform.stopScreenshotListening(),
          throwsUnimplementedError);
    });

    test(
        'startScreenRecordingListening should not throw UnimplementedError when called',
        () async {
      expect(platform.startScreenRecordingListening(), completes);
    });

    test(
        'stopScreenRecordingListening should not throw UnimplementedError when called',
        () async {
      expect(platform.stopScreenRecordingListening(), completes);
    });

    test(
        'base NoScreenshotPlatform.startScreenRecordingListening() throws UnimplementedError',
        () {
      final basePlatform = BaseNoScreenshotPlatform();
      expect(() => basePlatform.startScreenRecordingListening(),
          throwsUnimplementedError);
    });

    test(
        'base NoScreenshotPlatform.stopScreenRecordingListening() throws UnimplementedError',
        () {
      final basePlatform = BaseNoScreenshotPlatform();
      expect(() => basePlatform.stopScreenRecordingListening(),
          throwsUnimplementedError);
    });
  });
}
