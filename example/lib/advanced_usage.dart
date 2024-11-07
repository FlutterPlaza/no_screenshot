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
