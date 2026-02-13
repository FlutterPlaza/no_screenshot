import 'package:flutter_test/flutter_test.dart';
import 'package:no_screenshot/no_screenshot_platform_interface.dart';
import 'package:no_screenshot/no_screenshot_method_channel.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';
import 'package:no_screenshot/no_screenshot.dart';
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
  Future<bool> toggleScreenshotWithImage() async {
    return Future.value(true);
  }

  @override
  Future<bool> toggleScreenshotWithBlur() async {
    return Future.value(true);
  }

  @override
  Future<bool> toggleScreenshot() async {
    // Mock implementation or return a fixed value
    return Future.value(true);
  }

  @override
  Stream<ScreenshotSnapshot> get screenshotStream => const Stream.empty();

  @override
  Future<void> startScreenshotListening() {
    return Future.value();
  }

  @override
  Future<void> stopScreenshotListening() {
    return Future.value();
  }

  @override
  Future<void> startScreenRecordingListening() {
    return Future.value();
  }

  @override
  Future<void> stopScreenRecordingListening() {
    return Future.value();
  }
}

void main() {
  final NoScreenshotPlatform initialPlatform = NoScreenshotPlatform.instance;
  MockNoScreenshotPlatform fakePlatform = MockNoScreenshotPlatform();

  setUp(() {
    NoScreenshotPlatform.instance = fakePlatform;
  });

  tearDown(() {
    NoScreenshotPlatform.instance = initialPlatform;
  });

  test('$MethodChannelNoScreenshot is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNoScreenshot>());
  });

  test('NoScreenshot instance is a singleton', () {
    final instance1 = NoScreenshot.instance;
    final instance2 = NoScreenshot.instance;
    expect(instance1, equals(instance2));
  });

  test('screenshotOn', () async {
    expect(await NoScreenshot.instance.screenshotOn(), true);
  });

  test('screenshotOff', () async {
    expect(await NoScreenshot.instance.screenshotOff(), true);
  });

  test('toggleScreenshot', () async {
    expect(await NoScreenshot.instance.toggleScreenshot(), true);
  });

  test('screenshotStream', () async {
    expect(NoScreenshot.instance.screenshotStream,
        isInstanceOf<Stream<ScreenshotSnapshot>>());
  });
  test('startScreenshotListening', () async {
    expect(NoScreenshot.instance.startScreenshotListening(), completes);
  });

  test('stopScreenshotListening', () async {
    expect(NoScreenshot.instance.stopScreenshotListening(), completes);
  });

  test('toggleScreenshotWithImage', () async {
    expect(await NoScreenshot.instance.toggleScreenshotWithImage(), true);
  });

  test('toggleScreenshotWithBlur', () async {
    expect(await NoScreenshot.instance.toggleScreenshotWithBlur(), true);
  });

  test('NoScreenshot equality operator', () {
    final instance1 = NoScreenshot.instance;
    final instance2 = NoScreenshot.instance;

    expect(instance1 == instance2, true, reason: 'Instances should be equal');
  });

  test('NoScreenshot hashCode consistency', () {
    final instance1 = NoScreenshot.instance;
    final instance2 = NoScreenshot.instance;

    expect(instance1.hashCode, instance2.hashCode);
  });

  test('deprecated constructor still works', () {
    // ignore: deprecated_member_use
    final instance = NoScreenshot();
    expect(instance, isA<NoScreenshot>());
  });
}
