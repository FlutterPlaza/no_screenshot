import Flutter
import UIKit
import ScreenProtectorKit

public class SwiftNoScreenshotPlugin: NSObject, FlutterPlugin {
    private var screenProtectorKit: ScreenProtectorKit? = nil
    private static var channel: FlutterMethodChannel? = nil
    static private var preventScreenShot: Bool = false

    init(screenProtectorKit: ScreenProtectorKit) {
        self.screenProtectorKit = screenProtectorKit
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        // Corrected the domain name in the method channel to match a typical domain format
        SwiftNoScreenshotPlugin.channel = FlutterMethodChannel(name: "com.flutterplaza.no_screenshot", binaryMessenger: registrar.messenger())
        let window = UIApplication.shared.delegate?.window

        let screenProtectorKit = ScreenProtectorKit(window: window as? UIWindow)
        screenProtectorKit.configurePreventionScreenshot()

        let instance = SwiftNoScreenshotPlugin(screenProtectorKit: screenProtectorKit)
        registrar.addMethodCallDelegate(instance, channel: SwiftNoScreenshotPlugin.channel!)
        registrar.addApplicationDelegate(instance)
    }

    public func applicationWillResignActive(_ application: UIApplication) {
        if SwiftNoScreenshotPlugin.preventScreenShot == true {
            screenProtectorKit?.enabledPreventScreenshot()
        } else if SwiftNoScreenshotPlugin.preventScreenShot == false {
            screenProtectorKit?.disablePreventScreenshot()
        }
    }

    public func applicationDidBecomeActive(_ application: UIApplication) {
        if SwiftNoScreenshotPlugin.preventScreenShot == true {
            screenProtectorKit?.enabledPreventScreenshot()
        } else if SwiftNoScreenshotPlugin.preventScreenShot == false {
            screenProtectorKit?.disablePreventScreenshot()
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (call.method == "screenshotOff") {
            SwiftNoScreenshotPlugin.preventScreenShot = false
            shotOff()

        } else if (call.method == "screenshotOn") {
            SwiftNoScreenshotPlugin.preventScreenShot = true
            shotOn()
        } else if (call.method == "toggleScreenshot") {
            let res:Bool = SwiftNoScreenshotPlugin.preventScreenShot
            SwiftNoScreenshotPlugin.preventScreenShot = !res
            res ? shotOff() : shotOn()
        }
        result(true)
    }

    private func shotOff() {
        screenProtectorKit?.enabledPreventScreenshot()
    }

    private func shotOn() {
        screenProtectorKit?.disablePreventScreenshot()
    }

    deinit {
        screenProtectorKit?.removeAllObserver()
    }
}
