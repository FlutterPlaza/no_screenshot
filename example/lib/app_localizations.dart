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
      'blurOverlaySectionTitle': 'Overlay Blur',
      'blurOverlay': 'Blur Overlay',
      'toggleScreenshotWithBlur': 'Toggle Screenshot With Blur',
      'blurOverlaySubtitle':
          'Show blurred overlay when app is in recents / app switcher',
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
      'colorOverlaySectionTitle': 'Overlay Color',
      'colorOverlay': 'Color Overlay',
      'toggleScreenshotWithColor': 'Toggle Screenshot With Color',
      'colorOverlaySubtitle':
          'Show solid color overlay when app is in recents / app switcher',
      'secureWidgetSectionTitle': 'SecureWidget Demo',
      'secureWidgetSubtitle': 'Declarative protection via widget wrapper',
      'openSecureWidgetDemo': 'Open SecureWidget Demo',
      'secureWidgetDemoSubtitle':
          'Opens a page wrapped in SecureWidget (blur mode)',
      'perRouteSectionTitle': 'Per-Route Protection Demo',
      'perRouteSubtitle': 'Different protection per named route',
      'openPerRouteDemo': 'Open Per-Route Demo',
      'perRouteDemoSubtitle':
          'Navigate between routes with different protection policies',
      'secureWidgetDemoTitle': 'SecureWidget Demo',
      'secureWidgetDemoBody':
          'This page is wrapped in a SecureWidget with blur mode.\nScreenshot protection is active while this page is visible.',
      'paymentPage': 'Payment Page',
      'paymentPageBody': 'Route: /payment — Full screenshot block (secure)',
      'profilePage': 'Profile Page',
      'profilePageBody': 'Route: /profile — Blur overlay (blurRadius: 50)',
      'publicPage': 'Public Page',
      'publicPageBody': 'Route: /public — No protection (none)',
      'goToPayment': 'Go to Payment',
      'goToProfile': 'Go to Profile',
      'goToPublic': 'Go to Public',
      'back': 'Back',
      'callbacksSectionTitle': 'Granular Callbacks',
      'callbacksSubtitle': 'Named event callbacks (P15)',
      'callbacks': 'Callbacks',
      'lastCallbackEvent': 'Last event',
      'noEventsYet': 'No events yet',
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
      'blurOverlaySectionTitle': 'تراكب ضبابي',
      'blurOverlay': 'تراكب ضبابي',
      'toggleScreenshotWithBlur': 'تبديل لقطة الشاشة مع ضبابية',
      'blurOverlaySubtitle':
          'عرض تراكب ضبابي عند ظهور التطبيق في التطبيقات الأخيرة',
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
      'colorOverlaySectionTitle': 'تراكب لوني',
      'colorOverlay': 'تراكب لوني',
      'toggleScreenshotWithColor': 'تبديل لقطة الشاشة مع لون',
      'colorOverlaySubtitle':
          'عرض تراكب لوني عند ظهور التطبيق في التطبيقات الأخيرة',
      'secureWidgetSectionTitle': 'عرض SecureWidget',
      'secureWidgetSubtitle': 'حماية تصريحية عبر غلاف الودجت',
      'openSecureWidgetDemo': 'فتح عرض SecureWidget',
      'secureWidgetDemoSubtitle':
          'يفتح صفحة مغلفة بـ SecureWidget (وضع الضبابية)',
      'perRouteSectionTitle': 'عرض الحماية حسب المسار',
      'perRouteSubtitle': 'حماية مختلفة لكل مسار مسمى',
      'openPerRouteDemo': 'فتح عرض حسب المسار',
      'perRouteDemoSubtitle': 'التنقل بين مسارات بسياسات حماية مختلفة',
      'secureWidgetDemoTitle': 'عرض SecureWidget',
      'secureWidgetDemoBody':
          'هذه الصفحة مغلفة بـ SecureWidget مع وضع الضبابية.\nحماية لقطة الشاشة نشطة أثناء عرض هذه الصفحة.',
      'paymentPage': 'صفحة الدفع',
      'paymentPageBody': 'المسار: /payment — حظر لقطة الشاشة الكامل (آمن)',
      'profilePage': 'صفحة الملف الشخصي',
      'profilePageBody': 'المسار: /profile — تراكب ضبابي (نصف القطر: 50)',
      'publicPage': 'صفحة عامة',
      'publicPageBody': 'المسار: /public — بدون حماية',
      'goToPayment': 'الذهاب إلى الدفع',
      'goToProfile': 'الذهاب إلى الملف الشخصي',
      'goToPublic': 'الذهاب إلى العامة',
      'back': 'رجوع',
      'callbacksSectionTitle': 'ردود الاتصال التفصيلية',
      'callbacksSubtitle': 'ردود اتصال الأحداث المسماة (P15)',
      'callbacks': 'ردود الاتصال',
      'lastCallbackEvent': 'آخر حدث',
      'noEventsYet': 'لا أحداث بعد',
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
  String get blurOverlaySectionTitle =>
      _localizedValues[locale.languageCode]!['blurOverlaySectionTitle']!;
  String get blurOverlay =>
      _localizedValues[locale.languageCode]!['blurOverlay']!;
  String get toggleScreenshotWithBlur =>
      _localizedValues[locale.languageCode]!['toggleScreenshotWithBlur']!;
  String get blurOverlaySubtitle =>
      _localizedValues[locale.languageCode]!['blurOverlaySubtitle']!;
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
  String get recordingMonitoringSectionTitle => _localizedValues[
      locale.languageCode]!['recordingMonitoringSectionTitle']!;
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
  String get colorOverlaySectionTitle =>
      _localizedValues[locale.languageCode]!['colorOverlaySectionTitle']!;
  String get colorOverlay =>
      _localizedValues[locale.languageCode]!['colorOverlay']!;
  String get toggleScreenshotWithColor =>
      _localizedValues[locale.languageCode]!['toggleScreenshotWithColor']!;
  String get colorOverlaySubtitle =>
      _localizedValues[locale.languageCode]!['colorOverlaySubtitle']!;
  String get secureWidgetSectionTitle =>
      _localizedValues[locale.languageCode]!['secureWidgetSectionTitle']!;
  String get secureWidgetSubtitle =>
      _localizedValues[locale.languageCode]!['secureWidgetSubtitle']!;
  String get openSecureWidgetDemo =>
      _localizedValues[locale.languageCode]!['openSecureWidgetDemo']!;
  String get secureWidgetDemoSubtitle =>
      _localizedValues[locale.languageCode]!['secureWidgetDemoSubtitle']!;
  String get perRouteSectionTitle =>
      _localizedValues[locale.languageCode]!['perRouteSectionTitle']!;
  String get perRouteSubtitle =>
      _localizedValues[locale.languageCode]!['perRouteSubtitle']!;
  String get openPerRouteDemo =>
      _localizedValues[locale.languageCode]!['openPerRouteDemo']!;
  String get perRouteDemoSubtitle =>
      _localizedValues[locale.languageCode]!['perRouteDemoSubtitle']!;
  String get secureWidgetDemoTitle =>
      _localizedValues[locale.languageCode]!['secureWidgetDemoTitle']!;
  String get secureWidgetDemoBody =>
      _localizedValues[locale.languageCode]!['secureWidgetDemoBody']!;
  String get paymentPage =>
      _localizedValues[locale.languageCode]!['paymentPage']!;
  String get paymentPageBody =>
      _localizedValues[locale.languageCode]!['paymentPageBody']!;
  String get profilePage =>
      _localizedValues[locale.languageCode]!['profilePage']!;
  String get profilePageBody =>
      _localizedValues[locale.languageCode]!['profilePageBody']!;
  String get publicPage =>
      _localizedValues[locale.languageCode]!['publicPage']!;
  String get publicPageBody =>
      _localizedValues[locale.languageCode]!['publicPageBody']!;
  String get goToPayment =>
      _localizedValues[locale.languageCode]!['goToPayment']!;
  String get goToProfile =>
      _localizedValues[locale.languageCode]!['goToProfile']!;
  String get goToPublic =>
      _localizedValues[locale.languageCode]!['goToPublic']!;
  String get back => _localizedValues[locale.languageCode]!['back']!;
  String get callbacksSectionTitle =>
      _localizedValues[locale.languageCode]!['callbacksSectionTitle']!;
  String get callbacksSubtitle =>
      _localizedValues[locale.languageCode]!['callbacksSubtitle']!;
  String get callbacks =>
      _localizedValues[locale.languageCode]!['callbacks']!;
  String get lastCallbackEvent =>
      _localizedValues[locale.languageCode]!['lastCallbackEvent']!;
  String get noEventsYet =>
      _localizedValues[locale.languageCode]!['noEventsYet']!;
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
