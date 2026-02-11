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

  ScreenshotSnapshot({
    required this.screenshotPath,
    required this.isScreenshotProtectionOn,
    required this.wasScreenshotTaken,
  });

  factory ScreenshotSnapshot.fromMap(Map<String, dynamic> map) {
    return ScreenshotSnapshot(
      screenshotPath: map['screenshot_path'] as String? ?? '',
      isScreenshotProtectionOn: map['is_screenshot_on'] as bool? ?? false,
      wasScreenshotTaken: map['was_screenshot_taken'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'screenshot_path': screenshotPath,
      'is_screenshot_on': isScreenshotProtectionOn,
      'was_screenshot_taken': wasScreenshotTaken,
    };
  }

  @override
  String toString() {
    return 'ScreenshotSnapshot(\nscreenshotPath: $screenshotPath, \nisScreenshotProtectionOn: $isScreenshotProtectionOn, \nwasScreenshotTaken: $wasScreenshotTaken\n)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScreenshotSnapshot &&
        other.screenshotPath == screenshotPath &&
        other.isScreenshotProtectionOn == isScreenshotProtectionOn &&
        other.wasScreenshotTaken == wasScreenshotTaken;
  }

  @override
  int get hashCode {
    return screenshotPath.hashCode ^
        isScreenshotProtectionOn.hashCode ^
        wasScreenshotTaken.hashCode;
  }
}
