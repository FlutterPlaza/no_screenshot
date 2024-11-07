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
