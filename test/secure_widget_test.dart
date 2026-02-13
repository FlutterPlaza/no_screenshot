import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_screenshot/no_screenshot_platform_interface.dart';
import 'package:no_screenshot/overlay_mode.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';
import 'package:no_screenshot/secure_widget.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _RecordingPlatform extends NoScreenshotPlatform
    with MockPlatformInterfaceMixin {
  final List<String> calls = [];

  @override
  Future<bool> screenshotOff() async {
    calls.add('screenshotOff');
    return true;
  }

  @override
  Future<bool> screenshotOn() async {
    calls.add('screenshotOn');
    return true;
  }

  @override
  Future<bool> screenshotWithImage() async {
    calls.add('screenshotWithImage');
    return true;
  }

  @override
  Future<bool> screenshotWithBlur({double blurRadius = 30.0}) async {
    calls.add('screenshotWithBlur($blurRadius)');
    return true;
  }

  @override
  Future<bool> screenshotWithColor({int color = 0xFF000000}) async {
    calls.add('screenshotWithColor($color)');
    return true;
  }

  @override
  Future<bool> toggleScreenshot() async => true;

  @override
  Future<bool> toggleScreenshotWithImage() async => true;

  @override
  Future<bool> toggleScreenshotWithBlur({double blurRadius = 30.0}) async =>
      true;

  @override
  Future<bool> toggleScreenshotWithColor({int color = 0xFF000000}) async =>
      true;

  @override
  Stream<ScreenshotSnapshot> get screenshotStream => const Stream.empty();

  @override
  Future<void> startScreenshotListening() async {}

  @override
  Future<void> stopScreenshotListening() async {}

  @override
  Future<void> startScreenRecordingListening() async {}

  @override
  Future<void> stopScreenRecordingListening() async {}
}

void main() {
  late _RecordingPlatform fakePlatform;
  late NoScreenshotPlatform originalPlatform;

  setUp(() {
    originalPlatform = NoScreenshotPlatform.instance;
    fakePlatform = _RecordingPlatform();
    NoScreenshotPlatform.instance = fakePlatform;
  });

  tearDown(() {
    NoScreenshotPlatform.instance = originalPlatform;
  });

  testWidgets('default mode is OverlayMode.secure', (tester) async {
    await tester.pumpWidget(
      const SecureWidget(child: SizedBox()),
    );
    await tester.pump();
    expect(fakePlatform.calls, contains('screenshotOff'));
  });

  testWidgets('initState calls screenshotOff for OverlayMode.secure',
      (tester) async {
    await tester.pumpWidget(
      const SecureWidget(mode: OverlayMode.secure, child: SizedBox()),
    );
    await tester.pump();
    expect(fakePlatform.calls, contains('screenshotOff'));
  });

  testWidgets('initState calls screenshotWithBlur for OverlayMode.blur',
      (tester) async {
    await tester.pumpWidget(
      const SecureWidget(mode: OverlayMode.blur, child: SizedBox()),
    );
    await tester.pump();
    expect(fakePlatform.calls, contains('screenshotWithBlur(30.0)'));
  });

  testWidgets('initState calls screenshotWithColor for OverlayMode.color',
      (tester) async {
    await tester.pumpWidget(
      const SecureWidget(mode: OverlayMode.color, child: SizedBox()),
    );
    await tester.pump();
    expect(fakePlatform.calls, contains('screenshotWithColor(4278190080)'));
  });

  testWidgets('initState calls screenshotWithImage for OverlayMode.image',
      (tester) async {
    await tester.pumpWidget(
      const SecureWidget(mode: OverlayMode.image, child: SizedBox()),
    );
    await tester.pump();
    expect(fakePlatform.calls, contains('screenshotWithImage'));
  });

  testWidgets('initState calls screenshotOn for OverlayMode.none',
      (tester) async {
    await tester.pumpWidget(
      const SecureWidget(mode: OverlayMode.none, child: SizedBox()),
    );
    await tester.pump();
    expect(fakePlatform.calls, contains('screenshotOn'));
  });

  testWidgets('dispose calls screenshotOn', (tester) async {
    await tester.pumpWidget(
      const SecureWidget(child: SizedBox()),
    );
    await tester.pump();
    fakePlatform.calls.clear();

    // Remove the widget to trigger dispose
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(fakePlatform.calls, contains('screenshotOn'));
  });

  testWidgets('didUpdateWidget re-applies when mode changes',
      (tester) async {
    await tester.pumpWidget(
      const SecureWidget(mode: OverlayMode.secure, child: SizedBox()),
    );
    await tester.pump();
    fakePlatform.calls.clear();

    await tester.pumpWidget(
      const SecureWidget(mode: OverlayMode.blur, child: SizedBox()),
    );
    await tester.pump();
    expect(fakePlatform.calls, contains('screenshotWithBlur(30.0)'));
  });

  testWidgets('didUpdateWidget re-applies when blurRadius changes',
      (tester) async {
    await tester.pumpWidget(
      const SecureWidget(
          mode: OverlayMode.blur, blurRadius: 30.0, child: SizedBox()),
    );
    await tester.pump();
    fakePlatform.calls.clear();

    await tester.pumpWidget(
      const SecureWidget(
          mode: OverlayMode.blur, blurRadius: 50.0, child: SizedBox()),
    );
    await tester.pump();
    expect(fakePlatform.calls, contains('screenshotWithBlur(50.0)'));
  });

  testWidgets('didUpdateWidget re-applies when color changes',
      (tester) async {
    await tester.pumpWidget(
      const SecureWidget(mode: OverlayMode.color, child: SizedBox()),
    );
    await tester.pump();
    fakePlatform.calls.clear();

    await tester.pumpWidget(
      const SecureWidget(
          mode: OverlayMode.color, color: 0xFFFF0000, child: SizedBox()),
    );
    await tester.pump();
    expect(fakePlatform.calls, contains('screenshotWithColor(4294901760)'));
  });

  testWidgets('didUpdateWidget does not re-apply when nothing changes',
      (tester) async {
    await tester.pumpWidget(
      const SecureWidget(mode: OverlayMode.secure, child: SizedBox()),
    );
    await tester.pump();
    fakePlatform.calls.clear();

    // Rebuild with same params
    await tester.pumpWidget(
      const SecureWidget(mode: OverlayMode.secure, child: SizedBox()),
    );
    await tester.pump();
    expect(fakePlatform.calls, isEmpty);
  });

  testWidgets('child is rendered correctly', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SecureWidget(child: Text('Hello')),
      ),
    );
    expect(find.text('Hello'), findsOneWidget);
  });
}
