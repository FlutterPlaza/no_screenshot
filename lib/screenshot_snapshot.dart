class ScreenshotSnapshot {
  /// File path of the captured screenshot.
  ///
  /// Only available on **macOS** (via Spotlight / `NSMetadataQuery`) and
  /// **Linux** (via GFileMonitor / inotify).
  /// On Android and iOS the OS does not expose the screenshot file path —
  /// this field will contain a placeholder string.
  /// Use [wasScreenshotTaken] to detect screenshot events on all platforms.
  final String screenshotPath;

  final bool isScreenshotProtectionOn;
  final bool wasScreenshotTaken;
  final bool isScreenRecording;

  /// Milliseconds since epoch when the event was detected.
  ///
  /// `0` means unknown (e.g. the native platform did not provide timing data).
  final int timestamp;

  /// Human-readable name of the application that triggered the event.
  ///
  /// Empty string means unknown or not applicable.
  final String sourceApp;

  ScreenshotSnapshot({
    required this.screenshotPath,
    required this.isScreenshotProtectionOn,
    required this.wasScreenshotTaken,
    this.isScreenRecording = false,
    this.timestamp = 0,
    this.sourceApp = '',
  });

  factory ScreenshotSnapshot.fromMap(Map<String, dynamic> map) {
    return ScreenshotSnapshot(
      screenshotPath: map['screenshot_path'] as String? ?? '',
      isScreenshotProtectionOn: map['is_screenshot_on'] as bool? ?? false,
      wasScreenshotTaken: map['was_screenshot_taken'] as bool? ?? false,
      isScreenRecording: map['is_screen_recording'] as bool? ?? false,
      timestamp: map['timestamp'] as int? ?? 0,
      sourceApp: map['source_app'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'screenshot_path': screenshotPath,
      'is_screenshot_on': isScreenshotProtectionOn,
      'was_screenshot_taken': wasScreenshotTaken,
      'is_screen_recording': isScreenRecording,
      'timestamp': timestamp,
      'source_app': sourceApp,
    };
  }

  @override
  String toString() {
    return 'ScreenshotSnapshot(\nscreenshotPath: $screenshotPath, \nisScreenshotProtectionOn: $isScreenshotProtectionOn, \nwasScreenshotTaken: $wasScreenshotTaken, \nisScreenRecording: $isScreenRecording, \ntimestamp: $timestamp, \nsourceApp: $sourceApp\n)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScreenshotSnapshot &&
        other.screenshotPath == screenshotPath &&
        other.isScreenshotProtectionOn == isScreenshotProtectionOn &&
        other.wasScreenshotTaken == wasScreenshotTaken &&
        other.isScreenRecording == isScreenRecording &&
        other.timestamp == timestamp &&
        other.sourceApp == sourceApp;
  }

  @override
  int get hashCode {
    return screenshotPath.hashCode ^
        isScreenshotProtectionOn.hashCode ^
        wasScreenshotTaken.hashCode ^
        isScreenRecording.hashCode ^
        timestamp.hashCode ^
        sourceApp.hashCode;
  }
}
