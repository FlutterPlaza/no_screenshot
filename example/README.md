# no_screenshot_example

Demonstrates how to use the no_screenshot plugin.

## Getting Started

```dart
import 'package:flutter/material.dart';
import 'package:no_screenshot/no_screenshot.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _noScreenshotPlugin = NoScreenshot();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              child: const Text('Press to toggle screenshot'),
              onPressed: () async {
                final result = await _noScreenshotPlugin.toggleScreenshot();
                print(result);
              },
            ),
            ElevatedButton(
              child: const Text('Press to turn off screenshot'),
              onPressed: () async {
                final result = await _noScreenshotPlugin.screenshotOff();
                print(result);
              },
            ),
            ElevatedButton(
              child: const Text('Press to turn on screenshot'),
              onPressed: () async {
                final result = await _noScreenshotPlugin.screenshotOn();
                print(result);
              },
            ),
          ],
        )),
      ),
    );
  }
}

```
