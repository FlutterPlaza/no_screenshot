import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_screenshot/constants.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:no_screenshot/no_screenshot_method_channel.dart';
import 'package:no_screenshot/no_screenshot_platform_interface.dart';
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

    test('toggleScreenshotWithBlur', () async {
      const bool expected = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == screenSetBlur) {
              expect(methodCall.arguments, {'radius': 30.0});
              return expected;
            }
            return null;
          });

      final result = await platform.toggleScreenshotWithBlur();
      expect(result, expected);
    });

    test('toggleScreenshotWithBlur with custom radius', () async {
      const bool expected = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == screenSetBlur) {
              expect(methodCall.arguments, {'radius': 50.0});
              return expected;
            }
            return null;
          });

      final result = await platform.toggleScreenshotWithBlur(blurRadius: 50.0);
      expect(result, expected);
    });

    test(
      'toggleScreenshotWithBlur returns false when channel returns null',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              return null;
            });

        final result = await platform.toggleScreenshotWithBlur();
        expect(result, false);
      },
    );

    test('toggleScreenshotWithColor', () async {
      const bool expected = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == screenSetColor) {
              expect(methodCall.arguments, {'color': 0xFF000000});
              return expected;
            }
            return null;
          });

      final result = await platform.toggleScreenshotWithColor();
      expect(result, expected);
    });

    test('toggleScreenshotWithColor with custom color', () async {
      const bool expected = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == screenSetColor) {
              expect(methodCall.arguments, {'color': 0xFFFF0000});
              return expected;
            }
            return null;
          });

      final result = await platform.toggleScreenshotWithColor(
        color: 0xFFFF0000,
      );
      expect(result, expected);
    });

    test(
      'toggleScreenshotWithColor returns false when channel returns null',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              return null;
            });

        final result = await platform.toggleScreenshotWithColor();
        expect(result, false);
      },
    );

    test(
      'toggleScreenshotWithImage returns false when channel returns null',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              return null;
            });

        final result = await platform.toggleScreenshotWithImage();
        expect(result, false);
      },
    );

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

    test('screenshotWithImage', () async {
      const bool expected = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == screenEnableImage) {
              return expected;
            }
            return null;
          });

      final result = await platform.screenshotWithImage();
      expect(result, expected);
    });

    test(
      'screenshotWithImage returns false when channel returns null',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              return null;
            });

        final result = await platform.screenshotWithImage();
        expect(result, false);
      },
    );

    test('screenshotWithBlur', () async {
      const bool expected = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == screenEnableBlur) {
              expect(methodCall.arguments, {'radius': 30.0});
              return expected;
            }
            return null;
          });

      final result = await platform.screenshotWithBlur();
      expect(result, expected);
    });

    test('screenshotWithBlur with custom radius', () async {
      const bool expected = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == screenEnableBlur) {
              expect(methodCall.arguments, {'radius': 50.0});
              return expected;
            }
            return null;
          });

      final result = await platform.screenshotWithBlur(blurRadius: 50.0);
      expect(result, expected);
    });

    test(
      'screenshotWithBlur returns false when channel returns null',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              return null;
            });

        final result = await platform.screenshotWithBlur();
        expect(result, false);
      },
    );

    test('screenshotWithColor', () async {
      const bool expected = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == screenEnableColor) {
              expect(methodCall.arguments, {'color': 0xFF000000});
              return expected;
            }
            return null;
          });

      final result = await platform.screenshotWithColor();
      expect(result, expected);
    });

    test('screenshotWithColor with custom color', () async {
      const bool expected = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == screenEnableColor) {
              expect(methodCall.arguments, {'color': 0xFFFF0000});
              return expected;
            }
            return null;
          });

      final result = await platform.screenshotWithColor(color: 0xFFFF0000);
      expect(result, expected);
    });

    test(
      'screenshotWithColor returns false when channel returns null',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              return null;
            });

        final result = await platform.screenshotWithColor();
        expect(result, false);
      },
    );

    test('startScreenRecordingListening', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == startScreenRecordingListeningConst) {
              return null;
            }
            return null;
          });

      await platform.startScreenRecordingListening();
      expect(true, true);
    });

    test('stopScreenRecordingListening', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == stopScreenRecordingListeningConst) {
              return null;
            }
            return null;
          });

      await platform.stopScreenRecordingListening();
      expect(true, true);
    });

    test(
      'screenshotStream returns a stream that emits ScreenshotSnapshot',
      () async {
        final snapshotMap = {
          'screenshot_path': '/test/path',
          'is_screenshot_on': true,
          'was_screenshot_taken': true,
          'is_screen_recording': false,
          'timestamp': 0,
          'source_app': '',
        };
        final encoded = jsonEncode(snapshotMap);

        // Mock the event channel by handling the underlying method channel
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              platform.eventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  events.success(encoded);
                },
              ),
            );

        final stream = platform.screenshotStream;
        final snapshot = await stream.first;

        expect(snapshot.screenshotPath, '/test/path');
        expect(snapshot.isScreenshotProtectionOn, true);
        expect(snapshot.wasScreenshotTaken, true);
      },
    );

    test('screenshotStream caches and returns the same stream instance', () {
      final stream1 = platform.screenshotStream;
      final stream2 = platform.screenshotStream;
      expect(identical(stream1, stream2), true);
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
      expect(snapshot.isScreenRecording, false);
    });

    test('fromMap with is_screen_recording', () {
      final map = {
        'screenshot_path': '/example/path',
        'is_screenshot_on': true,
        'was_screenshot_taken': false,
        'is_screen_recording': true,
      };
      final snapshot = ScreenshotSnapshot.fromMap(map);
      expect(snapshot.screenshotPath, '/example/path');
      expect(snapshot.isScreenshotProtectionOn, true);
      expect(snapshot.wasScreenshotTaken, false);
      expect(snapshot.isScreenRecording, true);
    });

    test('fromMap without is_screen_recording defaults to false', () {
      final map = {
        'screenshot_path': '/example/path',
        'is_screenshot_on': true,
        'was_screenshot_taken': true,
      };
      final snapshot = ScreenshotSnapshot.fromMap(map);
      expect(snapshot.isScreenRecording, false);
    });

    test('toMap', () {
      final snapshot = ScreenshotSnapshot(
        screenshotPath: '/example/path',
        isScreenshotProtectionOn: true,
        wasScreenshotTaken: true,
        isScreenRecording: true,
      );
      final map = snapshot.toMap();
      expect(map['screenshot_path'], '/example/path');
      expect(map['is_screenshot_on'], true);
      expect(map['was_screenshot_taken'], true);
      expect(map['is_screen_recording'], true);
    });

    test('toMap with default isScreenRecording', () {
      final snapshot = ScreenshotSnapshot(
        screenshotPath: '/example/path',
        isScreenshotProtectionOn: true,
        wasScreenshotTaken: true,
      );
      final map = snapshot.toMap();
      expect(map['is_screen_recording'], false);
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
      final snapshot4 = ScreenshotSnapshot(
        screenshotPath: '/example/path',
        isScreenshotProtectionOn: true,
        wasScreenshotTaken: true,
        isScreenRecording: true,
      );

      expect(snapshot1 == snapshot2, true);
      expect(snapshot1 == snapshot3, false);
      expect(snapshot1 == snapshot4, false);
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
      expect(snapshot.isScreenRecording, false);
      expect(snapshot.timestamp, 0);
      expect(snapshot.sourceApp, '');
    });

    test('fromMap with null values uses defaults', () {
      final map = <String, dynamic>{
        'screenshot_path': null,
        'is_screenshot_on': null,
        'was_screenshot_taken': null,
        'is_screen_recording': null,
        'timestamp': null,
        'source_app': null,
      };
      final snapshot = ScreenshotSnapshot.fromMap(map);
      expect(snapshot.screenshotPath, '');
      expect(snapshot.isScreenshotProtectionOn, false);
      expect(snapshot.wasScreenshotTaken, false);
      expect(snapshot.isScreenRecording, false);
      expect(snapshot.timestamp, 0);
      expect(snapshot.sourceApp, '');
    });

    test('fromMap with metadata', () {
      final map = {
        'screenshot_path': '/example/path',
        'is_screenshot_on': true,
        'was_screenshot_taken': true,
        'is_screen_recording': false,
        'timestamp': 1700000000000,
        'source_app': 'screencaptureui',
      };
      final snapshot = ScreenshotSnapshot.fromMap(map);
      expect(snapshot.screenshotPath, '/example/path');
      expect(snapshot.isScreenshotProtectionOn, true);
      expect(snapshot.wasScreenshotTaken, true);
      expect(snapshot.timestamp, 1700000000000);
      expect(snapshot.sourceApp, 'screencaptureui');
    });

    test('fromMap without metadata defaults timestamp and sourceApp', () {
      final map = {
        'screenshot_path': '/example/path',
        'is_screenshot_on': true,
        'was_screenshot_taken': true,
      };
      final snapshot = ScreenshotSnapshot.fromMap(map);
      expect(snapshot.timestamp, 0);
      expect(snapshot.sourceApp, '');
    });

    test('toMap includes metadata', () {
      final snapshot = ScreenshotSnapshot(
        screenshotPath: '/example/path',
        isScreenshotProtectionOn: true,
        wasScreenshotTaken: true,
        timestamp: 1700000000000,
        sourceApp: 'GNOME Screenshot',
      );
      final map = snapshot.toMap();
      expect(map['timestamp'], 1700000000000);
      expect(map['source_app'], 'GNOME Screenshot');
    });

    test('equality with metadata', () {
      final snapshot1 = ScreenshotSnapshot(
        screenshotPath: '/example/path',
        isScreenshotProtectionOn: true,
        wasScreenshotTaken: true,
        timestamp: 1700000000000,
        sourceApp: 'screencaptureui',
      );
      final snapshot2 = ScreenshotSnapshot(
        screenshotPath: '/example/path',
        isScreenshotProtectionOn: true,
        wasScreenshotTaken: true,
        timestamp: 1700000000000,
        sourceApp: 'screencaptureui',
      );
      final snapshot3 = ScreenshotSnapshot(
        screenshotPath: '/example/path',
        isScreenshotProtectionOn: true,
        wasScreenshotTaken: true,
        timestamp: 1700000000001,
        sourceApp: 'screencaptureui',
      );
      final snapshot4 = ScreenshotSnapshot(
        screenshotPath: '/example/path',
        isScreenshotProtectionOn: true,
        wasScreenshotTaken: true,
        timestamp: 1700000000000,
        sourceApp: 'different_app',
      );

      expect(snapshot1 == snapshot2, true);
      expect(snapshot1 == snapshot3, false);
      expect(snapshot1 == snapshot4, false);
    });

    test('toString', () {
      final snapshot = ScreenshotSnapshot(
        screenshotPath: '/example/path',
        isScreenshotProtectionOn: true,
        wasScreenshotTaken: true,
      );
      final string = snapshot.toString();
      expect(
        string,
        'ScreenshotSnapshot(\nscreenshotPath: /example/path, \nisScreenshotProtectionOn: true, \nwasScreenshotTaken: true, \nisScreenRecording: false, \ntimestamp: 0, \nsourceApp: \n)',
      );
    });

    test('toString with isScreenRecording true', () {
      final snapshot = ScreenshotSnapshot(
        screenshotPath: '/example/path',
        isScreenshotProtectionOn: true,
        wasScreenshotTaken: true,
        isScreenRecording: true,
      );
      final string = snapshot.toString();
      expect(
        string,
        'ScreenshotSnapshot(\nscreenshotPath: /example/path, \nisScreenshotProtectionOn: true, \nwasScreenshotTaken: true, \nisScreenRecording: true, \ntimestamp: 0, \nsourceApp: \n)',
      );
    });

    test('toString with metadata', () {
      final snapshot = ScreenshotSnapshot(
        screenshotPath: '/example/path',
        isScreenshotProtectionOn: true,
        wasScreenshotTaken: true,
        timestamp: 1700000000000,
        sourceApp: 'screencaptureui',
      );
      final string = snapshot.toString();
      expect(string, contains('timestamp: 1700000000000'));
      expect(string, contains('sourceApp: screencaptureui'));
    });
  });

  group('Granular Callbacks (P15)', () {
    late StreamController<ScreenshotSnapshot> controller;
    late _MockNoScreenshotPlatform mockPlatform;
    late NoScreenshot noScreenshot;

    setUp(() {
      controller = StreamController<ScreenshotSnapshot>.broadcast();
      mockPlatform = _MockNoScreenshotPlatform(controller.stream);
      NoScreenshotPlatform.instance = mockPlatform;
      // Create a fresh instance for each test to avoid shared state.
      noScreenshot = NoScreenshot.instance;
      noScreenshot.removeAllCallbacks();
    });

    tearDown(() {
      noScreenshot.removeAllCallbacks();
      controller.close();
    });

    test(
      'onScreenshotDetected fires when wasScreenshotTaken is true',
      () async {
        final detected = <ScreenshotSnapshot>[];
        noScreenshot.onScreenshotDetected = detected.add;
        noScreenshot.startCallbacks();

        controller.add(
          ScreenshotSnapshot(
            screenshotPath: '/path',
            isScreenshotProtectionOn: true,
            wasScreenshotTaken: true,
          ),
        );
        await Future.delayed(Duration.zero);

        expect(detected, hasLength(1));
        expect(detected.first.wasScreenshotTaken, true);
      },
    );

    test(
      'onScreenshotDetected does NOT fire when wasScreenshotTaken is false',
      () async {
        final detected = <ScreenshotSnapshot>[];
        noScreenshot.onScreenshotDetected = detected.add;
        noScreenshot.startCallbacks();

        controller.add(
          ScreenshotSnapshot(
            screenshotPath: '',
            isScreenshotProtectionOn: true,
            wasScreenshotTaken: false,
          ),
        );
        await Future.delayed(Duration.zero);

        expect(detected, isEmpty);
      },
    );

    test('onScreenRecordingStarted fires on false→true transition', () async {
      final started = <ScreenshotSnapshot>[];
      noScreenshot.onScreenRecordingStarted = started.add;
      noScreenshot.startCallbacks();

      // Initial state: not recording → recording starts
      controller.add(
        ScreenshotSnapshot(
          screenshotPath: '',
          isScreenshotProtectionOn: true,
          wasScreenshotTaken: false,
          isScreenRecording: true,
        ),
      );
      await Future.delayed(Duration.zero);

      expect(started, hasLength(1));
      expect(started.first.isScreenRecording, true);
    });

    test('onScreenRecordingStopped fires on true→false transition', () async {
      final stopped = <ScreenshotSnapshot>[];
      noScreenshot.onScreenRecordingStopped = stopped.add;
      noScreenshot.startCallbacks();

      // First: recording starts
      controller.add(
        ScreenshotSnapshot(
          screenshotPath: '',
          isScreenshotProtectionOn: true,
          wasScreenshotTaken: false,
          isScreenRecording: true,
        ),
      );
      await Future.delayed(Duration.zero);

      // Then: recording stops
      controller.add(
        ScreenshotSnapshot(
          screenshotPath: '',
          isScreenshotProtectionOn: true,
          wasScreenshotTaken: false,
          isScreenRecording: false,
        ),
      );
      await Future.delayed(Duration.zero);

      expect(stopped, hasLength(1));
      expect(stopped.first.isScreenRecording, false);
    });

    test(
      'removeAllCallbacks clears all callbacks and stops subscription',
      () async {
        final detected = <ScreenshotSnapshot>[];
        noScreenshot.onScreenshotDetected = detected.add;
        noScreenshot.startCallbacks();
        expect(noScreenshot.hasActiveCallbacks, true);

        noScreenshot.removeAllCallbacks();
        expect(noScreenshot.hasActiveCallbacks, false);
        expect(noScreenshot.onScreenshotDetected, isNull);
        expect(noScreenshot.onScreenRecordingStarted, isNull);
        expect(noScreenshot.onScreenRecordingStopped, isNull);

        // Events after removal should not fire
        controller.add(
          ScreenshotSnapshot(
            screenshotPath: '/path',
            isScreenshotProtectionOn: true,
            wasScreenshotTaken: true,
          ),
        );
        await Future.delayed(Duration.zero);

        expect(detected, isEmpty);
      },
    );

    test('hasActiveCallbacks reflects subscription state', () {
      expect(noScreenshot.hasActiveCallbacks, false);

      noScreenshot.onScreenshotDetected = (_) {};
      noScreenshot.startCallbacks();
      expect(noScreenshot.hasActiveCallbacks, true);

      noScreenshot.stopCallbacks();
      expect(noScreenshot.hasActiveCallbacks, false);
    });

    test('startCallbacks is idempotent', () {
      noScreenshot.onScreenshotDetected = (_) {};
      noScreenshot.startCallbacks();
      noScreenshot.startCallbacks(); // second call should be no-op
      expect(noScreenshot.hasActiveCallbacks, true);
    });
  });
}

class _MockNoScreenshotPlatform extends NoScreenshotPlatform {
  final Stream<ScreenshotSnapshot> _stream;

  _MockNoScreenshotPlatform(this._stream);

  @override
  Stream<ScreenshotSnapshot> get screenshotStream => _stream;

  @override
  Future<bool> screenshotOff() async => true;

  @override
  Future<bool> screenshotOn() async => true;

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
  Future<bool> screenshotWithImage() async => true;

  @override
  Future<bool> screenshotWithBlur({double blurRadius = 30.0}) async => true;

  @override
  Future<bool> screenshotWithColor({int color = 0xFF000000}) async => true;

  @override
  Future<void> startScreenshotListening() async {}

  @override
  Future<void> stopScreenshotListening() async {}

  @override
  Future<void> startScreenRecordingListening() async {}

  @override
  Future<void> stopScreenRecordingListening() async {}
}
