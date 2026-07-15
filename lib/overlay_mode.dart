import 'package:no_screenshot/no_screenshot.dart';

/// The protection mode to apply.
enum OverlayMode { none, secure, blur, color, image }

/// Applies the given [mode] using the idempotent NoScreenshot API.
///
/// - [none] re-enables screenshots (no protection).
/// - [secure] blocks screenshots and screen recording.
/// - [blur] shows a blur overlay in the app switcher.
/// - [color] shows a solid color overlay in the app switcher.
/// - [image] shows a custom image overlay in the app switcher.
Future<void> applyOverlayMode(
  OverlayMode mode, {
  double blurRadius = 30.0,
  int color = 0xFF000000,
}) async {
  final noScreenshot = NoScreenshot.instance;
  switch (mode) {
    case OverlayMode.none:
      // Clear any active overlay mode first — screenshotOn() alone only
      // lifts prevention and would leave a persisted overlay showing in
      // the app switcher.
      await noScreenshot.overlayOff();
      await noScreenshot.screenshotOn();
    case OverlayMode.secure:
      // Clear any active overlay mode first — switching e.g. blur → secure
      // must not leave the overlay flag set (the overlay would keep
      // showing in the app switcher and persist across restarts).
      await noScreenshot.overlayOff();
      await noScreenshot.screenshotOff();
    case OverlayMode.blur:
      await noScreenshot.screenshotWithBlur(blurRadius: blurRadius);
    case OverlayMode.color:
      await noScreenshot.screenshotWithColor(color: color);
    case OverlayMode.image:
      await noScreenshot.screenshotWithImage();
  }
}
