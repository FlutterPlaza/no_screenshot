import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_screenshot/no_screenshot_platform_interface.dart';
import 'package:no_screenshot/overlay_mode.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';
import 'package:no_screenshot/secure_navigator_observer.dart';
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

// Helper to create a fake route with a given name
Route<dynamic> _fakeRoute(String? name) {
  return PageRouteBuilder<void>(
    settings: RouteSettings(name: name),
    pageBuilder: (_, __, ___) => const SizedBox(),
  );
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

  group('SecureRouteConfig', () {
    test('equality', () {
      const a = SecureRouteConfig(mode: OverlayMode.blur, blurRadius: 50.0);
      const b = SecureRouteConfig(mode: OverlayMode.blur, blurRadius: 50.0);
      const c = SecureRouteConfig(mode: OverlayMode.secure);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode', () {
      const a = SecureRouteConfig(mode: OverlayMode.blur, blurRadius: 50.0);
      const b = SecureRouteConfig(mode: OverlayMode.blur, blurRadius: 50.0);

      expect(a.hashCode, equals(b.hashCode));
    });

    test('default values', () {
      const config = SecureRouteConfig();
      expect(config.mode, OverlayMode.secure);
      expect(config.blurRadius, 30.0);
      expect(config.color, 0xFF000000);
    });
  });

  group('SecureNavigatorObserver', () {
    test('didPush applies policy for pushed route', () async {
      final observer = SecureNavigatorObserver(
        policies: {
          '/payment': const SecureRouteConfig(mode: OverlayMode.secure),
        },
      );

      observer.didPush(_fakeRoute('/payment'), null);
      await Future<void>.delayed(Duration.zero);
      expect(fakePlatform.calls, contains('screenshotOff'));
    });

    test('didPop applies policy for previous route', () async {
      final observer = SecureNavigatorObserver(
        policies: {
          '/home': const SecureRouteConfig(mode: OverlayMode.none),
        },
      );

      observer.didPop(_fakeRoute('/payment'), _fakeRoute('/home'));
      await Future<void>.delayed(Duration.zero);
      expect(fakePlatform.calls, contains('screenshotOn'));
    });

    test('didReplace applies policy for new route', () async {
      final observer = SecureNavigatorObserver(
        policies: {
          '/profile':
              const SecureRouteConfig(mode: OverlayMode.blur, blurRadius: 50.0),
        },
      );

      observer.didReplace(
          newRoute: _fakeRoute('/profile'), oldRoute: _fakeRoute('/home'));
      await Future<void>.delayed(Duration.zero);
      expect(fakePlatform.calls, contains('screenshotWithBlur(50.0)'));
    });

    test('didRemove applies policy for previous route', () async {
      final observer = SecureNavigatorObserver(
        policies: {
          '/home': const SecureRouteConfig(mode: OverlayMode.none),
        },
      );

      observer.didRemove(_fakeRoute('/payment'), _fakeRoute('/home'));
      await Future<void>.delayed(Duration.zero);
      expect(fakePlatform.calls, contains('screenshotOn'));
    });

    test('unmapped routes use defaultConfig', () async {
      final observer = SecureNavigatorObserver(
        policies: {
          '/payment': const SecureRouteConfig(mode: OverlayMode.secure),
        },
        defaultConfig: const SecureRouteConfig(mode: OverlayMode.none),
      );

      observer.didPush(_fakeRoute('/unknown'), null);
      await Future<void>.delayed(Duration.zero);
      expect(fakePlatform.calls, contains('screenshotOn'));
    });

    test('custom defaultConfig works', () async {
      final observer = SecureNavigatorObserver(
        defaultConfig: const SecureRouteConfig(mode: OverlayMode.blur),
      );

      observer.didPush(_fakeRoute('/anything'), null);
      await Future<void>.delayed(Duration.zero);
      expect(fakePlatform.calls, contains('screenshotWithBlur(30.0)'));
    });

    test('null route name uses defaultConfig', () async {
      final observer = SecureNavigatorObserver(
        policies: {
          '/payment': const SecureRouteConfig(mode: OverlayMode.secure),
        },
        defaultConfig: const SecureRouteConfig(mode: OverlayMode.none),
      );

      observer.didPush(_fakeRoute(null), null);
      await Future<void>.delayed(Duration.zero);
      expect(fakePlatform.calls, contains('screenshotOn'));
    });

    test('blur params passed correctly', () async {
      final observer = SecureNavigatorObserver(
        policies: {
          '/settings': const SecureRouteConfig(
            mode: OverlayMode.blur,
            blurRadius: 75.0,
          ),
        },
      );

      observer.didPush(_fakeRoute('/settings'), null);
      await Future<void>.delayed(Duration.zero);
      expect(fakePlatform.calls, contains('screenshotWithBlur(75.0)'));
    });

    test('color params passed correctly', () async {
      final observer = SecureNavigatorObserver(
        policies: {
          '/branded': const SecureRouteConfig(
            mode: OverlayMode.color,
            color: 0xFF2196F3,
          ),
        },
      );

      observer.didPush(_fakeRoute('/branded'), null);
      await Future<void>.delayed(Duration.zero);
      expect(
          fakePlatform.calls, contains('screenshotWithColor(${0xFF2196F3})'));
    });
  });
}
