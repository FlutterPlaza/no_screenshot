import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:no_screenshot/overlay_mode.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';
import 'package:no_screenshot/secure_navigator_observer.dart';
import 'package:no_screenshot/secure_widget.dart';

import 'app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isRTL = false;

  void _toggleRTL(bool value) {
    setState(() => _isRTL = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'No Screenshot Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      locale: _isRTL ? const Locale('ar') : const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HomePage(isRTL: _isRTL, onRTLChanged: _toggleRTL),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.isRTL, required this.onRTLChanged});

  final bool isRTL;
  final ValueChanged<bool> onRTLChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _noScreenshot = NoScreenshot.instance;
  StreamSubscription<ScreenshotSnapshot>? _streamSubscription;
  bool _isMonitoring = false;
  bool _isRecordingMonitoring = false;
  bool _isOverlayImageOn = false;
  bool _isOverlayBlurOn = false;
  bool _isOverlayColorOn = false;
  ScreenshotSnapshot _latestSnapshot = ScreenshotSnapshot(
    isScreenshotProtectionOn: false,
    wasScreenshotTaken: false,
    screenshotPath: '',
  );

  @override
  void initState() {
    super.initState();
    _streamSubscription = _noScreenshot.screenshotStream.listen((value) {
      if (!mounted) return;
      setState(() => _latestSnapshot = value);
      if (value.wasScreenshotTaken) {
        debugPrint('Screenshot taken at path: ${value.screenshotPath}');
        _showScreenshotAlert(value.screenshotPath);
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
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

  // ── Recording Monitoring ───────────────────────────────────────────

  Future<void> _startRecordingMonitoring() async {
    await _noScreenshot.startScreenRecordingListening();
    setState(() => _isRecordingMonitoring = true);
  }

  Future<void> _stopRecordingMonitoring() async {
    await _noScreenshot.stopScreenRecordingListening();
    setState(() => _isRecordingMonitoring = false);
  }

  // ── Set Overlay Image ──────────────────────────────────────────────

  Future<void> _toggleScreenshotWithImage() async {
    final result = await _noScreenshot.toggleScreenshotWithImage();
    debugPrint('toggleScreenshotWithImage: $result');
    setState(() {
      _isOverlayImageOn = result;
      if (result) {
        _isOverlayBlurOn = false;
        _isOverlayColorOn = false;
      }
    });
  }

  Future<void> _toggleScreenshotWithBlur() async {
    final result = await _noScreenshot.toggleScreenshotWithBlur();
    debugPrint('toggleScreenshotWithBlur: $result');
    setState(() {
      _isOverlayBlurOn = result;
      if (result) {
        _isOverlayImageOn = false;
        _isOverlayColorOn = false;
      }
    });
  }

  Future<void> _toggleScreenshotWithColor() async {
    final result = await _noScreenshot.toggleScreenshotWithColor();
    debugPrint('toggleScreenshotWithColor: $result');
    setState(() {
      _isOverlayColorOn = result;
      if (result) {
        _isOverlayImageOn = false;
        _isOverlayBlurOn = false;
      }
    });
  }

  // ── UI ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          Text(l.rtl),
          Switch(
            value: widget.isRTL,
            onChanged: widget.onRTLChanged,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: l.protectionSectionTitle,
            subtitle: l.platformSubtitle,
            children: [
              _StatusRow(
                label: l.protection,
                isOn: _latestSnapshot.isScreenshotProtectionOn,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _FeatureButton(
                      label: l.disableScreenshot,
                      subtitle: l.blocksCapture,
                      onPressed: _disableScreenshot,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FeatureButton(
                      label: l.enableScreenshot,
                      subtitle: l.allowsCapture,
                      onPressed: _enableScreenshot,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _FeatureButton(
                label: l.toggleScreenshot,
                subtitle: l.toggleScreenshotSubtitle,
                onPressed: _toggleScreenshot,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: l.monitoringSectionTitle,
            subtitle: l.platformSubtitle,
            children: [
              _StatusRow(
                label: l.monitoring,
                isOn: _isMonitoring,
              ),
              const SizedBox(height: 8),
              _SnapshotInfo(snapshot: _latestSnapshot),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _FeatureButton(
                      label: l.enableMonitoring,
                      subtitle: l.startListening,
                      onPressed: _startMonitoring,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FeatureButton(
                      label: l.disableMonitoring,
                      subtitle: l.stopListening,
                      onPressed: _stopMonitoring,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: l.recordingMonitoringSectionTitle,
            subtitle: l.platformSubtitle,
            children: [
              _StatusRow(
                label: l.recordingMonitoring,
                isOn: _isRecordingMonitoring,
              ),
              const SizedBox(height: 8),
              _StatusRow(
                label: l.screenRecording,
                isOn: _latestSnapshot.isScreenRecording,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _FeatureButton(
                      label: l.enableRecordingMonitoring,
                      subtitle: l.startRecordingListening,
                      onPressed: _startRecordingMonitoring,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FeatureButton(
                      label: l.disableRecordingMonitoring,
                      subtitle: l.stopRecordingListening,
                      onPressed: _stopRecordingMonitoring,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: l.overlaySectionTitle,
            subtitle: l.platformSubtitle,
            children: [
              _StatusRow(
                label: l.overlay,
                isOn: _isOverlayImageOn,
              ),
              const SizedBox(height: 12),
              _FeatureButton(
                label: l.toggleScreenshotWithImage,
                subtitle: l.overlaySubtitle,
                onPressed: _toggleScreenshotWithImage,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: l.blurOverlaySectionTitle,
            subtitle: l.platformSubtitle,
            children: [
              _StatusRow(
                label: l.blurOverlay,
                isOn: _isOverlayBlurOn,
              ),
              const SizedBox(height: 12),
              _FeatureButton(
                label: l.toggleScreenshotWithBlur,
                subtitle: l.blurOverlaySubtitle,
                onPressed: _toggleScreenshotWithBlur,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: l.colorOverlaySectionTitle,
            subtitle: l.platformSubtitle,
            children: [
              _StatusRow(
                label: l.colorOverlay,
                isOn: _isOverlayColorOn,
              ),
              const SizedBox(height: 12),
              _FeatureButton(
                label: l.toggleScreenshotWithColor,
                subtitle: l.colorOverlaySubtitle,
                onPressed: _toggleScreenshotWithColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: l.secureWidgetSectionTitle,
            subtitle: l.secureWidgetSubtitle,
            children: [
              _FeatureButton(
                label: l.openSecureWidgetDemo,
                subtitle: l.secureWidgetDemoSubtitle,
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const _SecureWidgetDemoPage(),
                  ));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: l.perRouteSectionTitle,
            subtitle: l.perRouteSubtitle,
            children: [
              _FeatureButton(
                label: l.openPerRouteDemo,
                subtitle: l.perRouteDemoSubtitle,
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const _PerRouteDemoHub(),
                  ));
                },
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
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_outlined,
            size: 48, color: Colors.red),
        title: Text(l.screenshotDetected),
        content: Text('${l.path}: $path'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.ok),
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
          alignment: AlignmentDirectional.centerStart,
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
    final l = AppLocalizations.of(context);
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
        Text(isOn ? l.on : l.off),
      ],
    );
  }
}

class _SnapshotInfo extends StatelessWidget {
  const _SnapshotInfo({required this.snapshot});

  final ScreenshotSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
          Text('${l.protectionActive}: ${snapshot.isScreenshotProtectionOn}',
              style: style?.copyWith(
                  color: snapshot.isScreenshotProtectionOn
                      ? Colors.green
                      : Colors.red)),
          Text('${l.screenshotTaken}: ${snapshot.wasScreenshotTaken}',
              style: style),
          Text('${l.screenRecording}: ${snapshot.isScreenRecording}',
              style: style?.copyWith(
                  color: snapshot.isScreenRecording ? Colors.red : null)),
          Text('${l.path}: ${snapshot.screenshotPath}', style: style),
        ],
      ),
    );
  }
}

// ── SecureWidget Demo ─────────────────────────────────────────────────

class _SecureWidgetDemoPage extends StatelessWidget {
  const _SecureWidgetDemoPage();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SecureWidget(
      mode: OverlayMode.blur,
      blurRadius: 30.0,
      child: Scaffold(
        appBar: AppBar(title: Text(l.secureWidgetDemoTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l.secureWidgetDemoBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Per-Route Demo ────────────────────────────────────────────────────

final _secureNavigatorObserver = SecureNavigatorObserver(
  policies: {
    '/payment': const SecureRouteConfig(mode: OverlayMode.secure),
    '/profile':
        const SecureRouteConfig(mode: OverlayMode.blur, blurRadius: 50.0),
    '/public': const SecureRouteConfig(mode: OverlayMode.none),
  },
  defaultConfig: const SecureRouteConfig(mode: OverlayMode.none),
);

class _PerRouteDemoHub extends StatelessWidget {
  const _PerRouteDemoHub();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Navigator(
      observers: [_secureNavigatorObserver],
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/payment':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => _DemoRoutePage(
                title: l.paymentPage,
                body: l.paymentPageBody,
                color: Colors.red.shade50,
              ),
            );
          case '/profile':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => _DemoRoutePage(
                title: l.profilePage,
                body: l.profilePageBody,
                color: Colors.blue.shade50,
              ),
            );
          case '/public':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => _DemoRoutePage(
                title: l.publicPage,
                body: l.publicPageBody,
                color: Colors.green.shade50,
              ),
            );
          default:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => _PerRouteMainPage(),
            );
        }
      },
    );
  }
}

class _PerRouteMainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.perRouteSectionTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FeatureButton(
            label: l.goToPayment,
            subtitle: 'OverlayMode.secure',
            onPressed: () => Navigator.of(context).pushNamed('/payment'),
          ),
          const SizedBox(height: 8),
          _FeatureButton(
            label: l.goToProfile,
            subtitle: 'OverlayMode.blur (radius: 50)',
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
          const SizedBox(height: 8),
          _FeatureButton(
            label: l.goToPublic,
            subtitle: 'OverlayMode.none',
            onPressed: () => Navigator.of(context).pushNamed('/public'),
          ),
        ],
      ),
    );
  }
}

class _DemoRoutePage extends StatelessWidget {
  const _DemoRoutePage({
    required this.title,
    required this.body,
    required this.color,
  });

  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: color,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.back),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
