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