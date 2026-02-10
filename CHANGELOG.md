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


## 1.0.0-beta.1

### Summary of Changes

- **Automatic State Persistence**: Removed the need to track `didChangeAppLifecycleState`. The state will now be automatically persisted using native platform SharedPreferences.
- **Enhanced Example**: Updated the example app to demonstrate the new automatic state persistence and usage of the `NoScreenshot` plugin.
- **Stream Support**: Provided a stream to listen for screenshot activities, making it easier to react to screenshots in real-time.
- **Bug Fixes**: Fixed various bugs related to screenshot detection and state management on both Android and iOS platforms.
- **Documentation Updates**: Improved documentation to reflect the new features and provide clearer usage examples.
- **Deprecation Notice**: Deprecated the use of the constructor `NoScreenshot()` in favor of the singleton `NoScreenshot.instance`.

## 1.0.0-beta.2

- fix: Pub Point analysis failure.

## 0.3.1

- feat: added MacOS support
- fix: fix screenshot state not persisting on iOS
- chore: added more examples.

## 0.3.2-beta.1

- fix: fix screenshot state not persisting on iOS by @fonkamloic in https://github.com/FlutterPlaza/no_screenshot/pull/45
- chore(deps): bump actions/checkout from 2 to 4 by @dependabot in https://github.com/FlutterPlaza/no_screenshot/pull/43
- chore(deps): bump codecov/codecov-action from 4.0.1 to 4.5.0 by @dependabot in https://github.com/FlutterPlaza/no_screenshot/pull/42
- feat: macos support by @fonkamloic in https://github.com/FlutterPlaza/no_screenshot/pull/51

## 0.3.2-beta.3

- chore: updated pkg version by @fonkamloic in https://github.com/FlutterPlaza/no_screenshot/pull/63
- fix: duplicate interface definition for class 'NoScreenshotPlugin' by @fonkamloic in https://github.com/FlutterPlaza/no_screenshot/pull/62

## 0.3.2

- feat: macos support by @fonkamloic in https://github.com/FlutterPlaza/no_screenshot/pull/51
- fix: fix screenshot state not persisting on iOS by @fonkamloic in https://github.com/FlutterPlaza/no_screenshot/pull/45
- fix: duplicate interface definition for class 'NoScreenshotPlugin' by @fonkamloic in https://github.com/FlutterPlaza/no_screenshot/pull/62
- chore(deps): bump actions/checkout from 2 to 4 by @dependabot in https://github.com/FlutterPlaza/no_screenshot/pull/43
- chore(deps): bump codecov/codecov-action from 4.0.1 to 4.5.0 by @dependabot in https://github.com/FlutterPlaza/no_screenshot/pull/42

## 0.3.3-beta.1

- feat: added `toggleScreenshotWithImage()` API to display a custom image overlay when the app goes to the background or app switcher, preventing screenshot content exposure on both Android and iOS by @zhangyuanyuan-bear and @fonkamloic.
- feat: image overlay mode persists across app restarts via platform SharedPreferences/UserDefaults by @zhangyuanyuan-bear and @fonkamloic.
- fix: use `Executors` for SharedPreferences access on Android to avoid strict mode violations on startup by @qk7b.
- fix: properly clean up image overlay and activity references on detach/config changes (Android) by @fonkamloic.
- chore: updated Kotlin and Gradle versions in Android build configuration by @T-moz.
- chore: updated example app to demonstrate the new image overlay feature by @fonkamloic.
- ci: added automated pub.dev publish workflow by @fonkamloic.

## 0.3.3

- feat(macos): added macOS support for `toggleScreenshotWithImage()` by @fonkamloic.
- feat: added `toggleScreenshotWithImage()` API to display a custom image overlay when the app goes to the background or app switcher, preventing screenshot content exposure on both Android and iOS by @zhangyuanyuan-bear and @fonkamloic.
- feat: image overlay mode persists across app restarts via platform SharedPreferences/UserDefaults by @zhangyuanyuan-bear and @fonkamloic.
- fix(ios): prevent stale image overlay by consolidating lifecycle handling by @BranislavKljaic96 and @fonkamloic.
- fix(ios): native code now works with both SceneDelegate and AppDelegate by @BranislavKljaic96 in https://github.com/FlutterPlaza/no_screenshot/pull/86.
- fix: use `Executors` for SharedPreferences access on Android to avoid strict mode violations on startup by @qk7b in https://github.com/FlutterPlaza/no_screenshot/pull/74.
- fix: properly clean up image overlay and activity references on detach/config changes (Android) by @fonkamloic.
- chore: updated Kotlin and Gradle versions in Android build configuration by @T-moz in https://github.com/FlutterPlaza/no_screenshot/pull/76.
- chore: updated example app to demonstrate the new image overlay feature by @fonkamloic.
- test: added `toggleScreenshotWithImage` tests and fixed CI codecov upload by @fonkamloic.
- ci: added automated pub.dev publish workflow by @fonkamloic.


## 0.3.4

- fix(macos): detect clipboard-only screenshots (Cmd+Ctrl+Shift+3/4) via pasteboard polling by @fonkamloic.
- fix(macos): detect repeated screenshots while `screencaptureui` is still running by @fonkamloic.
- fix(macos): track `screencaptureui` process lifecycle (launch + termination) for reliable detection by @fonkamloic.
- fix(macos): add 2s debounce to suppress duplicate detection events while allowing file-path upgrades from `NSMetadataQuery` by @fonkamloic.
- docs: updated macOS screenshot monitoring documentation to reflect three detection methods by @fonkamloic.

## 0.3.5

- fix(ios): fix iOS 26 RTL layout shift by dropping `ScreenProtectorKit` and inlining screenshot prevention with `forceLeftToRight` semantics by @fonkamloic.
- fix(ios): fix `EXC_BAD_ACCESS` crash in `_collectExistingTraitCollectionsForTraitTracking` on iOS 26+ caused by circular view hierarchy by @fonkamloic.
- fix(ios): fix bottom-right content alignment caused by Auto Layout constraint offset during layer reparenting by @fonkamloic.
- feat(ios): removed `ScreenProtectorKit` dependency — all iOS screenshot prevention is now inlined by @fonkamloic.
- feat(example): add EN/AR localization and RTL toggle to example app for testing RTL layout by @fonkamloic.
- docs: document `screenshotPath` availability — file path is only available on macOS; Android and iOS return a placeholder by @fonkamloic.
- docs: add LTR/RTL language support note to README by @fonkamloic.
- docs: add GIF demo placeholders for every feature on every platform by @fonkamloic.
