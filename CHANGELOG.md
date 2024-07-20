## 0.0.1

Package has 3 basic functionalities on android and IOS via method channel.
    - Disable screenshot support in app
    - Enable screenshot support in app
    - Toggle between enable and disable state

## 0.0.1+1

Updated readme and added sample usage.

## 0.0.1+2

- Adopted MIT license

## 0.0.1+3

- Reverted to BSD 3 license
- Added documentation
- Made `NoScreenshot` class a singleton

## 0.0.1+4

- Fixed issue #1[Crashes app when backgrounded on iOS](https://github.com/FlutterPlaza/no_screenshot/issues/1)

## 0.0.1+5

- Fixed broken link from pub dev analyses

## 0.0.1+6

- Removed the non implemented override functions in android life-cycle

## 0.0.1+7

- Set the namespace for android
- Specify a more current version of ScreenProtectorKit.  This resolves iOS17 issues.
- fix: screenshot prevention on iOS
- updated readme by @Musaddiq635 PR[https://github.com/FlutterPlaza/no_screenshot/pull/26]
- merged fix by @ggiordan PR[https://github.com/FlutterPlaza/no_screenshot/pull/29]

## 0.2.0

- Upgrade android to support AGP 8.X
- merged fix by @alberto-cappellina PR[https://github.com/FlutterPlaza/no_screenshot/pull/27]
- gradle:7.1.2 -> 7.4.2
- kotlin_version = '1.6.10' -> '1.6.21'

## 0.2.1

### Summary of Changes

- **Automatic State Persistence**: Removed the need to track `didChangeAppLifecycleState`. The state will now be automatically persisted using native platform SharedPreferences.
- **Enhanced Example**: Updated the example app to demonstrate the new automatic state persistence and usage of the `NoScreenshot` plugin.
- **Stream Support**: Provided a stream to listen for screenshot activities, making it easier to react to screenshots in real-time.
- **Bug Fixes**: Fixed various bugs related to screenshot detection and state management on both Android and iOS platforms.
- **Documentation Updates**: Improved documentation to reflect the new features and provide clearer usage examples.
- **Deprecation Notice**: Deprecated the use of the constructor `NoScreenshot()` in favor of the singleton `NoScreenshot.instance`.
