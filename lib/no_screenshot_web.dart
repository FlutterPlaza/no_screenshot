import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:no_screenshot/no_screenshot_platform_interface.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';
import 'package:web/web.dart' as web;

/// Web implementation of [NoScreenshotPlatform].
///
/// Browsers cannot truly prevent OS-level screenshots. This provides
/// best-effort JS deterrents: right-click blocking, PrintScreen
/// interception, `user-select: none`, and `visibilitychange` detection.
class NoScreenshotWeb extends NoScreenshotPlatform {
  NoScreenshotWeb._();

  /// Creates an instance for testing without going through [registerWith].
  factory NoScreenshotWeb.createForTest() => NoScreenshotWeb._();

  static void registerWith(Registrar registrar) {
    NoScreenshotPlatform.instance = NoScreenshotWeb._();
  }

  bool _isProtectionOn = false;
  bool _isListening = false;

  final StreamController<ScreenshotSnapshot> _controller =
      StreamController<ScreenshotSnapshot>.broadcast();

  // ── JS event listeners (stored for removal) ────────────────────────

  JSFunction? _contextMenuHandler;
  JSFunction? _keyDownHandler;
  JSFunction? _visibilityHandler;

  // ── Stream ─────────────────────────────────────────────────────────

  @override
  Stream<ScreenshotSnapshot> get screenshotStream => _controller.stream;

  // ── Protection ─────────────────────────────────────────────────────

  @override
  Future<bool> screenshotOff() async {
    _enableProtection();
    return true;
  }

  @override
  Future<bool> screenshotOn() async {
    _disableProtection();
    return true;
  }

  @override
  Future<bool> toggleScreenshot() async {
    _isProtectionOn ? _disableProtection() : _enableProtection();
    return true;
  }

  @override
  Future<bool> toggleScreenshotWithImage() async {
    _isProtectionOn ? _disableProtection() : _enableProtection();
    return _isProtectionOn;
  }

  @override
  Future<bool> toggleScreenshotWithBlur({double blurRadius = 30.0}) async {
    _isProtectionOn ? _disableProtection() : _enableProtection();
    return _isProtectionOn;
  }

  @override
  Future<bool> toggleScreenshotWithColor({int color = 0xFF000000}) async {
    _isProtectionOn ? _disableProtection() : _enableProtection();
    return _isProtectionOn;
  }

  @override
  Future<bool> screenshotWithImage() async {
    _enableProtection();
    return true;
  }

  @override
  Future<bool> screenshotWithBlur({double blurRadius = 30.0}) async {
    _enableProtection();
    return true;
  }

  @override
  Future<bool> screenshotWithColor({int color = 0xFF000000}) async {
    _enableProtection();
    return true;
  }

  // ── Screenshot Listening ───────────────────────────────────────────

  @override
  Future<void> startScreenshotListening() async {
    if (_isListening) return;
    _isListening = true;
    _addVisibilityListener();
  }

  @override
  Future<void> stopScreenshotListening() async {
    _isListening = false;
    _removeVisibilityListener();
  }

  // ── Recording Listening (no-op on web) ─────────────────────────────

  @override
  Future<void> startScreenRecordingListening() async {}

  @override
  Future<void> stopScreenRecordingListening() async {}

  // ── Internal ───────────────────────────────────────────────────────

  void _enableProtection() {
    if (_isProtectionOn) return;
    _isProtectionOn = true;
    _addContextMenuBlocker();
    _addPrintScreenBlocker();
    _setUserSelectNone(true);
    _emitState();
  }

  void _disableProtection() {
    if (!_isProtectionOn) return;
    _isProtectionOn = false;
    _removeContextMenuBlocker();
    _removePrintScreenBlocker();
    _setUserSelectNone(false);
    _emitState();
  }

  void _emitState({bool wasScreenshotTaken = false}) {
    _controller.add(ScreenshotSnapshot(
      screenshotPath: '',
      isScreenshotProtectionOn: _isProtectionOn,
      wasScreenshotTaken: wasScreenshotTaken,
    ));
  }

  // ── Context menu blocker ───────────────────────────────────────────

  void _addContextMenuBlocker() {
    _contextMenuHandler = ((web.Event e) {
      e.preventDefault();
    }).toJS;
    web.document.addEventListener('contextmenu', _contextMenuHandler!);
  }

  void _removeContextMenuBlocker() {
    if (_contextMenuHandler != null) {
      web.document.removeEventListener('contextmenu', _contextMenuHandler!);
      _contextMenuHandler = null;
    }
  }

  // ── PrintScreen blocker ────────────────────────────────────────────

  void _addPrintScreenBlocker() {
    _keyDownHandler = ((web.KeyboardEvent e) {
      if (e.key == 'PrintScreen') {
        e.preventDefault();
      }
    }).toJS;
    web.document.addEventListener('keydown', _keyDownHandler!);
  }

  void _removePrintScreenBlocker() {
    if (_keyDownHandler != null) {
      web.document.removeEventListener('keydown', _keyDownHandler!);
      _keyDownHandler = null;
    }
  }

  // ── user-select CSS ────────────────────────────────────────────────

  void _setUserSelectNone(bool disable) {
    final style = web.document.body?.style;
    if (style == null) return;
    style.setProperty('user-select', disable ? 'none' : '');
    style.setProperty('-webkit-user-select', disable ? 'none' : '');
  }

  // ── Visibility listener ────────────────────────────────────────────

  void _addVisibilityListener() {
    _visibilityHandler = ((web.Event _) {
      if (web.document.visibilityState == 'visible') {
        _emitState(wasScreenshotTaken: true);
      }
    }).toJS;
    web.document.addEventListener('visibilitychange', _visibilityHandler!);
  }

  void _removeVisibilityListener() {
    if (_visibilityHandler != null) {
      web.document.removeEventListener('visibilitychange', _visibilityHandler!);
      _visibilityHandler = null;
    }
  }
}
