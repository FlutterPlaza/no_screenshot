import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'No Screenshot Example',
      'rtl': 'RTL',
      'protectionSectionTitle': 'Screenshot & Recording Protection',
      'platformSubtitle': 'Android, iOS, macOS & Linux',
      'protection': 'Protection',
      'monitoring': 'Monitoring',
      'overlay': 'Overlay',
      'disableScreenshot': 'Disable Screenshot',
      'blocksCapture': 'Blocks capture & recording',
      'enableScreenshot': 'Enable Screenshot',
      'allowsCapture': 'Allows capture & recording',
      'toggleScreenshot': 'Toggle Screenshot',
      'toggleScreenshotSubtitle': 'Switch between enabled / disabled',
      'monitoringSectionTitle': 'Screenshot Monitoring',
      'enableMonitoring': 'Enable Monitoring',
      'startListening': 'Start listening for screenshots',
      'disableMonitoring': 'Disable Monitoring',
      'stopListening': 'Stop listening for screenshots',
      'overlaySectionTitle': 'Overlay Image',
      'toggleScreenshotWithImage': 'Toggle Screenshot With Image',
      'overlaySubtitle':
          'Show overlay image when app is in recents / app switcher',
      'screenshotDetected': 'Screenshot Detected',
      'path': 'Path',
      'ok': 'OK',
      'on': 'ON',
      'off': 'OFF',
      'protectionActive': 'Protection active',
      'screenshotTaken': 'Screenshot taken',
      'recordingMonitoringSectionTitle': 'Recording Monitoring',
      'recordingMonitoring': 'Recording Monitoring',
      'enableRecordingMonitoring': 'Enable Recording Monitoring',
      'startRecordingListening': 'Start listening for screen recording',
      'disableRecordingMonitoring': 'Disable Recording Monitoring',
      'stopRecordingListening': 'Stop listening for screen recording',
      'screenRecording': 'Screen recording',
    },
    'ar': {
      'appTitle': 'مثال بدون لقطة شاشة',
      'rtl': 'من اليمين لليسار',
      'protectionSectionTitle': 'حماية لقطة الشاشة والتسجيل',
      'platformSubtitle': 'أندرويد، iOS، macOS و Linux',
      'protection': 'الحماية',
      'monitoring': 'المراقبة',
      'overlay': 'التراكب',
      'disableScreenshot': 'تعطيل لقطة الشاشة',
      'blocksCapture': 'يمنع الالتقاط والتسجيل',
      'enableScreenshot': 'تفعيل لقطة الشاشة',
      'allowsCapture': 'يسمح بالالتقاط والتسجيل',
      'toggleScreenshot': 'تبديل لقطة الشاشة',
      'toggleScreenshotSubtitle': 'التبديل بين التفعيل / التعطيل',
      'monitoringSectionTitle': 'مراقبة لقطة الشاشة',
      'enableMonitoring': 'تفعيل المراقبة',
      'startListening': 'بدء الاستماع للقطات الشاشة',
      'disableMonitoring': 'تعطيل المراقبة',
      'stopListening': 'إيقاف الاستماع للقطات الشاشة',
      'overlaySectionTitle': 'صورة التراكب',
      'toggleScreenshotWithImage': 'تبديل لقطة الشاشة مع صورة',
      'overlaySubtitle':
          'عرض صورة التراكب عند ظهور التطبيق في التطبيقات الأخيرة',
      'screenshotDetected': 'تم اكتشاف لقطة شاشة',
      'path': 'المسار',
      'ok': 'حسناً',
      'on': 'مُفعّل',
      'off': 'مُعطّل',
      'protectionActive': 'الحماية نشطة',
      'screenshotTaken': 'تم أخذ لقطة شاشة',
      'recordingMonitoringSectionTitle': 'مراقبة التسجيل',
      'recordingMonitoring': 'مراقبة التسجيل',
      'enableRecordingMonitoring': 'تفعيل مراقبة التسجيل',
      'startRecordingListening': 'بدء الاستماع لتسجيل الشاشة',
      'disableRecordingMonitoring': 'تعطيل مراقبة التسجيل',
      'stopRecordingListening': 'إيقاف الاستماع لتسجيل الشاشة',
      'screenRecording': 'تسجيل الشاشة',
    },
  };

  String get appTitle => _localizedValues[locale.languageCode]!['appTitle']!;
  String get rtl => _localizedValues[locale.languageCode]!['rtl']!;
  String get protectionSectionTitle =>
      _localizedValues[locale.languageCode]!['protectionSectionTitle']!;
  String get platformSubtitle =>
      _localizedValues[locale.languageCode]!['platformSubtitle']!;
  String get protection =>
      _localizedValues[locale.languageCode]!['protection']!;
  String get monitoring =>
      _localizedValues[locale.languageCode]!['monitoring']!;
  String get overlay => _localizedValues[locale.languageCode]!['overlay']!;
  String get disableScreenshot =>
      _localizedValues[locale.languageCode]!['disableScreenshot']!;
  String get blocksCapture =>
      _localizedValues[locale.languageCode]!['blocksCapture']!;
  String get enableScreenshot =>
      _localizedValues[locale.languageCode]!['enableScreenshot']!;
  String get allowsCapture =>
      _localizedValues[locale.languageCode]!['allowsCapture']!;
  String get toggleScreenshot =>
      _localizedValues[locale.languageCode]!['toggleScreenshot']!;
  String get toggleScreenshotSubtitle =>
      _localizedValues[locale.languageCode]!['toggleScreenshotSubtitle']!;
  String get monitoringSectionTitle =>
      _localizedValues[locale.languageCode]!['monitoringSectionTitle']!;
  String get enableMonitoring =>
      _localizedValues[locale.languageCode]!['enableMonitoring']!;
  String get startListening =>
      _localizedValues[locale.languageCode]!['startListening']!;
  String get disableMonitoring =>
      _localizedValues[locale.languageCode]!['disableMonitoring']!;
  String get stopListening =>
      _localizedValues[locale.languageCode]!['stopListening']!;
  String get overlaySectionTitle =>
      _localizedValues[locale.languageCode]!['overlaySectionTitle']!;
  String get toggleScreenshotWithImage =>
      _localizedValues[locale.languageCode]!['toggleScreenshotWithImage']!;
  String get overlaySubtitle =>
      _localizedValues[locale.languageCode]!['overlaySubtitle']!;
  String get screenshotDetected =>
      _localizedValues[locale.languageCode]!['screenshotDetected']!;
  String get path => _localizedValues[locale.languageCode]!['path']!;
  String get ok => _localizedValues[locale.languageCode]!['ok']!;
  String get on => _localizedValues[locale.languageCode]!['on']!;
  String get off => _localizedValues[locale.languageCode]!['off']!;
  String get protectionActive =>
      _localizedValues[locale.languageCode]!['protectionActive']!;
  String get screenshotTaken =>
      _localizedValues[locale.languageCode]!['screenshotTaken']!;
  String get recordingMonitoringSectionTitle =>
      _localizedValues[locale.languageCode]!['recordingMonitoringSectionTitle']!;
  String get recordingMonitoring =>
      _localizedValues[locale.languageCode]!['recordingMonitoring']!;
  String get enableRecordingMonitoring =>
      _localizedValues[locale.languageCode]!['enableRecordingMonitoring']!;
  String get startRecordingListening =>
      _localizedValues[locale.languageCode]!['startRecordingListening']!;
  String get disableRecordingMonitoring =>
      _localizedValues[locale.languageCode]!['disableRecordingMonitoring']!;
  String get stopRecordingListening =>
      _localizedValues[locale.languageCode]!['stopRecordingListening']!;
  String get screenRecording =>
      _localizedValues[locale.languageCode]!['screenRecording']!;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .map((l) => l.languageCode)
      .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
