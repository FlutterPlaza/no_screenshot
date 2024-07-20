import 'package:flutter_test/flutter_test.dart';
import 'package:no_screenshot/no_screenshot_method_channel.dart';
import 'package:no_screenshot/no_screenshot_platform_interface.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';

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
  Future<void> stopScreenshotListening() async {
    return;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
  });
}
