// import 'package:flutter_test/flutter_test.dart';
// import 'package:no_screenshot/no_screenshot.dart';
// import 'package:no_screenshot/no_screenshot_platform_interface.dart';
// import 'package:no_screenshot/no_screenshot_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';
// import 'package:screenshots/screenshots.dart';

// class MockNoScreenshotPlatform
//     with MockPlatformInterfaceMixin
//     implements NoScreenshotPlatform {

//   @override
//   Future<bool> screenshotOff() {

//   }

//   @override
//   Future<bool> screenshotOn() {
//   }

//   @override
//   Future<bool> toggleScreenshot() {

//   }
// }

// void main() {
//   final NoScreenshotPlatform initialPlatform = NoScreenshotPlatform.instance;

//   test('$MethodChannelNoScreenshot is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelNoScreenshot>());
//   });

//   test('getPlatformVersion', () async {
//     NoScreenshot noScreenshotPlugin = NoScreenshot();
//     MockNoScreenshotPlatform fakePlatform = MockNoScreenshotPlatform();
//     NoScreenshotPlatform.instance = fakePlatform;

//     expect(await noScreenshotPlugin.getPlatformVersion(), '42');
//   });
// }
