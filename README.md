# no_screenshot

<p align="center">
<a href="https://pub.dev/packages/no_screenshot"><img src="https://img.shields.io/pub/v/no_screenshot.svg" alt="Pub"></a>
<a href="https://github.com/FlutterPlaza/no_screenshot/actions"><img src="https://github.com/FlutterPlaza/no_screenshot/workflows/build/badge.svg" alt="build"></a>
<a href="https://github.com/FlutterPlaza/no_screenshot"><img src="https://codecov.io/gh/FlutterPlaza/no_screenshot/branch/development/graph/badge.svg" alt="codecov"></a>
<a href="https://github.com/FlutterPlaza/no_screenshot"><img src="https://img.shields.io/github/stars/FlutterPlaza/no_screenshot.svg?style=flat&logo=github&colorB=deeppink&label=stars" alt="Star on Github"></a>
<a href="https://flutter.dev/docs/development/data-and-backend/state-mgmt/options#bloc--rx"><img src="https://img.shields.io/badge/flutter-website-deepskyblue.svg" alt="Flutter Website"></a>
</p>

The Flutter plugin will enable, disable, or toggle screenshot support in your application.

## Features

- Disables screenshot and screen recording on Android and iOS.
- Enables screenshot and screen recording on Android and iOS.
- Toggles screenshot and screen recording on Android and iOS.
- Provides a stream to listen for screenshot activities.

## Update

Tracking `didChangeAppLifecycleState` is no longer required. The state will be persisted automatically in the native platform SharedPreferences.

## Getting started

Add `no_screenshot` to your `pubspec.yaml` dependencies.

## Usage

Call the singleton `NoScreenshot.instance` anywhere you want to use it. For instance:

```dart
import 'package:flutter/material.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _noScreenshot = NoScreenshot.instance;
  bool _isListeningToScreenshotSnapshot = false;
  ScreenshotSnapshot _latestValue = ScreenshotSnapshot(
    isScreenshotProtectionOn: false,
    wasScreenshotTaken: false,
    screenshotPath: '',
  );

  @override
  void initState() {
    super.initState();
    _noScreenshot.screenshotStream.listen((value) {
      setState(() {
        _latestValue = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('No Screenshot Plugin Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              ElevatedButton(
                onPressed: () async {
                  await _noScreenshot.startScreenshotListening();
                  setState(() {
                    _isListeningToScreenshotSnapshot = true;
                  });
                },
                child: const Text('Start Listening'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _noScreenshot.stopScreenshotListening();
                  setState(() {
                    _isListeningToScreenshotSnapshot = false;
                  });
                },
                child: const Text('Stop Listening'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                    "Screenshot Streaming is ${_isListeningToScreenshotSnapshot ? 'ON' : 'OFF'}\n\nIsScreenshotProtectionOn: ${_latestValue.isScreenshotProtectionOn}\nwasScreenshotTaken: ${_latestValue.wasScreenshotTaken}\nScreenshot Path: ${_latestValue.screenshotPath}"),
              ),
              ElevatedButton(
                onPressed: () async {
                  bool result = await _noScreenshot.screenshotOff();
                  debugPrint('Screenshot Off: $result');
                },
                child: const Text('Disable Screenshot'),
              ),
              ElevatedButton(
                onPressed: () async {
                  bool result = await _noScreenshot.screenshotOn();
                  debugPrint('Enable Screenshot: $result');
                },
                child: const Text('Enable Screenshot'),
              ),
              ElevatedButton(
                onPressed: () async {
                  bool result = await _noScreenshot.toggleScreenshot();
                  debugPrint('Toggle Screenshot: $result');
                },
                child: const Text('Toggle Screenshot'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Additional information

Check out our repo for Open-Source contributions. Contributions are welcome!
