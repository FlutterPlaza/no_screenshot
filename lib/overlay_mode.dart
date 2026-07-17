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
      // Release both prevention claims: overlayOff() clears the overlay
      // mode (and its claim), screenshotOn() releases the independent
      // claim. Each call is needed — they release different claims.
      await noScreenshot.overlayOff();
      await noScreenshot.screenshotOn();
    case OverlayMode.secure:
      // Take the independent prevention claim FIRST, then release the
      // overlay's claim: prevention stays continuously engaged across an
      // overlay → secure transition (no unprotected window between the
      // two calls), and the overlay flag can't leak into the app
      // switcher or persist across restarts.
      await noScreenshot.screenshotOff();
      await noScreenshot.overlayOff();
    case OverlayMode.blur:
      await noScreenshot.screenshotWithBlur(blurRadius: blurRadius);
    case OverlayMode.color:
      await noScreenshot.screenshotWithColor(color: color);
    case OverlayMode.image:
      await noScreenshot.screenshotWithImage();
  }
}
