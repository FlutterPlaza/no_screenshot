import 'package:flutter/material.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'No Screenshot Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _noScreenshot = NoScreenshot.instance;
  bool _isMonitoring = false;
  bool _isOverlayImageOn = false;
  ScreenshotSnapshot _latestSnapshot = ScreenshotSnapshot(
    isScreenshotProtectionOn: false,
    wasScreenshotTaken: false,
    screenshotPath: '',
  );

  @override
  void initState() {
    super.initState();
    _noScreenshot.screenshotStream.listen((value) {
      setState(() => _latestSnapshot = value);
      if (value.wasScreenshotTaken) {
        print('Screenshot taken at path: ${value.screenshotPath}');
        _showScreenshotAlert(value.screenshotPath);
      }
    });
  }

  // ── Screenshot Protection ──────────────────────────────────────────

  Future<void> _disableScreenshot() async {
    final result = await _noScreenshot.screenshotOff();
    debugPrint('screenshotOff: $result');
  }

  Future<void> _enableScreenshot() async {
    final result = await _noScreenshot.screenshotOn();
    debugPrint('screenshotOn: $result');
  }

  Future<void> _toggleScreenshot() async {
    final result = await _noScreenshot.toggleScreenshot();
    debugPrint('toggleScreenshot: $result');
  }

  // ── Screenshot Monitoring ──────────────────────────────────────────

  Future<void> _startMonitoring() async {
    await _noScreenshot.startScreenshotListening();
    setState(() => _isMonitoring = true);
  }

  Future<void> _stopMonitoring() async {
    await _noScreenshot.stopScreenshotListening();
    setState(() => _isMonitoring = false);
  }

  // ── Set Overlay Image ──────────────────────────────────────────────

  Future<void> _toggleScreenshotWithImage() async {
    final result = await _noScreenshot.toggleScreenshotWithImage();
    debugPrint('toggleScreenshotWithImage: $result');
    setState(() => _isOverlayImageOn = result);
  }

  // ── UI ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('No Screenshot Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Screenshot & Recording Protection',
            subtitle: 'Android, iOS & macOS',
            children: [
              _StatusRow(
                label: 'Protection',
                isOn: _latestSnapshot.isScreenshotProtectionOn,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _FeatureButton(
                      label: 'Disable Screenshot',
                      subtitle: 'Blocks capture & recording',
                      onPressed: _disableScreenshot,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FeatureButton(
                      label: 'Enable Screenshot',
                      subtitle: 'Allows capture & recording',
                      onPressed: _enableScreenshot,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _FeatureButton(
                label: 'Toggle Screenshot',
                subtitle: 'Switch between enabled / disabled',
                onPressed: _toggleScreenshot,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Screenshot Monitoring',
            subtitle: 'Android, iOS & macOS',
            children: [
              _StatusRow(
                label: 'Monitoring',
                isOn: _isMonitoring,
              ),
              const SizedBox(height: 8),
              _SnapshotInfo(snapshot: _latestSnapshot),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _FeatureButton(
                      label: 'Enable Monitoring',
                      subtitle: 'Start listening for screenshots',
                      onPressed: _startMonitoring,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FeatureButton(
                      label: 'Disable Monitoring',
                      subtitle: 'Stop listening for screenshots',
                      onPressed: _stopMonitoring,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Overlay Image',
            subtitle: 'Android, iOS & macOS',
            children: [
              _StatusRow(
                label: 'Overlay',
                isOn: _isOverlayImageOn,
              ),
              const SizedBox(height: 12),
              _FeatureButton(
                label: 'Toggle Screenshot With Image',
                subtitle:
                    'Show overlay image when app is in recents / app switcher',
                onPressed: _toggleScreenshotWithImage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              runAlignment: WrapAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(subtitle),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  void _showScreenshotAlert(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_outlined,
            size: 48, color: Colors.red),
        title: const Text('Screenshot Detected'),
        content: Text('Path: $path'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Widgets ───────────────────────────────────────────────────

class _FeatureButton extends StatelessWidget {
  const _FeatureButton({
    required this.label,
    required this.subtitle,
    required this.onPressed,
  });

  final String label;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.isOn});

  final String label;
  final bool isOn;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOn ? Colors.green : Colors.grey,
          ),
        ),
        const SizedBox(width: 6),
        Text(isOn ? 'ON' : 'OFF'),
      ],
    );
  }
}

class _SnapshotInfo extends StatelessWidget {
  const _SnapshotInfo({required this.snapshot});

  final ScreenshotSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Protection active: ${snapshot.isScreenshotProtectionOn}',
              style: style?.copyWith(
                  color: snapshot.isScreenshotProtectionOn
                      ? Colors.green
                      : Colors.red)),
          Text('Screenshot taken: ${snapshot.wasScreenshotTaken}',
              style: style),
          Text('Path: ${snapshot.screenshotPath}', style: style),
        ],
      ),
    );
  }
}
