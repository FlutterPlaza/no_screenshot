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
