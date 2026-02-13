import 'package:flutter/widgets.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:no_screenshot/overlay_mode.dart';

/// A widget that automatically enables screenshot protection when mounted
/// and disables it when unmounted.
///
/// Wrap any subtree with [SecureWidget] to declaratively protect it:
///
/// ```dart
/// SecureWidget(
///   mode: OverlayMode.blur,
///   blurRadius: 50.0,
///   child: MySecurePage(),
/// )
/// ```
class SecureWidget extends StatefulWidget {
  const SecureWidget({
    super.key,
    required this.child,
    this.mode = OverlayMode.secure,
    this.blurRadius = 30.0,
    this.color = 0xFF000000,
  });

  final Widget child;
  final OverlayMode mode;
  final double blurRadius;
  final int color;

  @override
  State<SecureWidget> createState() => _SecureWidgetState();
}

class _SecureWidgetState extends State<SecureWidget> {
  @override
  void initState() {
    super.initState();
    _applyMode();
  }

  @override
  void didUpdateWidget(SecureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode ||
        oldWidget.blurRadius != widget.blurRadius ||
        oldWidget.color != widget.color) {
      _applyMode();
    }
  }

  @override
  void dispose() {
    NoScreenshot.instance.screenshotOn();
    super.dispose();
  }

  void _applyMode() {
    applyOverlayMode(
      widget.mode,
      blurRadius: widget.blurRadius,
      color: widget.color,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
