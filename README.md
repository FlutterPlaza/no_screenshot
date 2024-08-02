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

- Basic Usage: Enable, disable, and toggle screenshot and screen recording functionalities.
- Advanced Features: Use stream to listen for screenshot activities and integrate these features into your application.

Screenshots and Recordings

Basic Usage | Advanced Usage
:-: | :-:
<video src='example/assets/basic_usage.mp4' width=180/> | <video src='example/assets/advanced_usage.mp4' width=180/>

### Basic Usage

Step 1: Disable Screenshot and Screen Recording

To disable screenshots and screen recording, you first have to import the package, then you can create an instance of the NoScreenshot object, which you can use to turn off screenshot, see code snippet:

```dart
import 'package:no_screenshot/no_screenshot.dart';

final _noScreenshot = NoScreenshot.instance;

void disableScreenshot() async {
  bool result = await _noScreenshot.screenshotOff();
  debugPrint('Screenshot Off: $result');
}
```

Step 2:  Enable Screenshot and Screen Recording

To re-enable screenshots and screen recording, use this code:

```dart
import 'package:no_screenshot/no_screenshot.dart';

final _noScreenshot = NoScreenshot.instance;

void enableScreenshot() async {
  bool result = await _noScreenshot.screenshotOn();
  debugPrint('Enable Screenshot: $result');
}
```

Step 3: Toggle Screenshot and Screen Recording

If you just want to toggle the screenshot or screen recording functionality, use this code:

```dart
import 'package:no_screenshot/no_screenshot.dart';

final _noScreenshot = NoScreenshot.instance;

void toggleScreenshot() async {
  bool result = await _noScreenshot.toggleScreenshot();
  debugPrint('Toggle Screenshot: $result');
}
```

Example UI Integration

Here’s an example of how you might integrate these functionalities into your app's UI:

```dart
import 'package:flutter/material.dart';
import 'package:no_screenshot/no_screenshot.dart';

void main() {
  runApp(const BasicUsage());
}

class BasicUsage extends StatefulWidget {
  const BasicUsage({super.key});

  @override
  State<BasicUsage> createState() => _BasicUsageState();
}

class _BasicUsageState extends State<BasicUsage> {
  final _noScreenshot = NoScreenshot.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('No Screenshot Basic Usage'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                onPressed: disableScreenshot,
                child: const Text('Disable Screenshot'),
              ),
              ElevatedButton(
                onPressed: enableScreenshot,
                child: const Text('Enable Screenshot'),
              ),
              ElevatedButton(
                onPressed: toggleScreenshot,
                child: const Text('Toggle Screenshot'),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  void toggleScreenshot() async {
    bool result = await _noScreenshot.toggleScreenshot();
    debugPrint('Toggle Screenshot: $result');
  }

  void enableScreenshot() async {
    bool result = await _noScreenshot.screenshotOn();
    debugPrint('Enable Screenshot: $result');
  }

  void disableScreenshot() async {
    bool result = await _noScreenshot.screenshotOff();
    debugPrint('Screenshot Off: $result');
  }
}
```

### Part 2: Advanced Features

Step 1: Listen for Screenshot Activities

To listen for screenshot activities, you can set up a stream listener like this:

NOTE: You first have to import the package, then you can create an instance of the NoScreenshot object, which you can use to listen for screenshot events, see code snippet:

```dart
import 'package:no_screenshot/no_screenshot.dart';

final _noScreenshot = NoScreenshot.instance;

void listenForScreenshot() {
  _noScreenshot.screenshotStream.listen((value) {
    print('Screenshot taken: ${value.wasScreenshotTaken}');
    print('Screenshot path: ${value.screenshotPath}');
  });
}
```

Step 2: Enable screenshot listening

By default, listening to screenshot events is turned off. To listen for screenshot activities, you will need to enable or start listening:

```dart
import 'package:no_screenshot/no_screenshot.dart';

final _noScreenshot = NoScreenshot.instance;

void startScreenshotListening() async {
  await _noScreenshot.startScreenshotListening();
}
```

Step 3: Disable/stop screenshot listening

To stop listen for screenshot activities, code below:

```dart
import 'package:no_screenshot/no_screenshot.dart';

final _noScreenshot = NoScreenshot.instance;

void stopScreenshotListening() async {
  await _noScreenshot.stopScreenshotListening();
}
```

Example Integration with Application

Incorporate the screenshot listener into your app's main logic:

```dart

import 'package:flutter/material.dart';
import 'package:no_screenshot/no_screenshot.dart';

void main() {
  runApp(const AdvancedUsage());
}

class AdvancedUsage extends StatefulWidget {
  const AdvancedUsage({super.key});

  @override
  State<AdvancedUsage> createState() => _AdvancedUsageState();
}

class _AdvancedUsageState extends State<AdvancedUsage> {
  final _noScreenshot = NoScreenshot.instance;
  bool _isListeningToScreenshotSnapshot = false;

  @override
  void initState() {
    super.initState();
    listenForScreenshot();
  }

  void listenForScreenshot() {
    _noScreenshot.screenshotStream.listen((value) {
      if (value.wasScreenshotTaken) showAlert(value.screenshotPath);
    });
  }


  void stopScreenshotListening() async {
    await _noScreenshot.stopScreenshotListening();
    setState(() {
      _isListeningToScreenshotSnapshot = false;
    });
  }

  void startScreenshotListening() async {
    await _noScreenshot.startScreenshotListening();
    setState(() {
      _isListeningToScreenshotSnapshot = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listen for Screenshot Activities'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: startScreenshotListening,
              child: const Text('Start Listening'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Screenshot Listening: $_isListeningToScreenshotSnapshot"),
                _isListeningToScreenshotSnapshot
                    ? Container(
                        height: 20,
                        width: 20,
                        margin: const EdgeInsets.only(left: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      )
                    : const SizedBox.shrink()
              ],
            ),
            ElevatedButton(
              onPressed: stopScreenshotListening,
              child: const Text('Stop Listening'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void showAlert(String path) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20.0),
            height: 280,
            width: MediaQuery.sizeOf(context).width - 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_outlined,
                  size: 80,
                  color: Colors.red,
                ),
                const Text(
                  "Alert: screenshot taken",
                  style: TextStyle(fontSize: 24),
                ),
                Text("Path: $path"),
                const SizedBox(height: 40),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("confirm"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

```

## Additional information

Check out our repo for Open-Source contributions. Contributions are welcome!
