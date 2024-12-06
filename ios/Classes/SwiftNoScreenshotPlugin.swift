import Flutter
import UIKit
import ScreenProtectorKit

public class SwiftNoScreenshotPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var screenProtectorKit: ScreenProtectorKit? = nil
    private static var methodChannel: FlutterMethodChannel? = nil
    private static var eventChannel: FlutterEventChannel? = nil
    private static var preventScreenShot: Bool = false
    private var eventSink: FlutterEventSink? = nil
    private var lastSharedPreferencesState: String = ""
    private var hasSharedPreferencesChanged: Bool = false

    init(screenProtectorKit: ScreenProtectorKit) {
        self.screenProtectorKit = screenProtectorKit
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        methodChannel = FlutterMethodChannel(name: "com.flutterplaza.no_screenshot_methods", binaryMessenger: registrar.messenger())
        eventChannel = FlutterEventChannel(name: "com.flutterplaza.no_screenshot_streams", binaryMessenger: registrar.messenger())
        
        let window = UIApplication.shared.delegate?.window
        
        let screenProtectorKit = ScreenProtectorKit(window: window as? UIWindow)
        screenProtectorKit.configurePreventionScreenshot()
        
        let instance = SwiftNoScreenshotPlugin(screenProtectorKit: screenProtectorKit)
        registrar.addMethodCallDelegate(instance, channel: methodChannel!)
        eventChannel?.setStreamHandler(instance)
        registrar.addApplicationDelegate(instance)
    }

    public func applicationWillResignActive(_ application: UIApplication) {
        updateScreenshotState()
    }

    public func applicationDidBecomeActive(_ application: UIApplication) {
        updateScreenshotState()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "screenshotOff":
            SwiftNoScreenshotPlugin.preventScreenShot = false
            shotOff()
            updateSharedPreferencesState("")
            result(true)
        case "screenshotOn":
            SwiftNoScreenshotPlugin.preventScreenShot = true
            shotOn()
            updateSharedPreferencesState("")
            result(true)
        case "setImage":
            setImage()
            result(true)
        case "toggleScreenshot":
            SwiftNoScreenshotPlugin.preventScreenShot.toggle()
            !SwiftNoScreenshotPlugin.preventScreenShot ? shotOff() : shotOn()
            updateSharedPreferencesState("")
            result(true)
        case "startScreenshotListening":
            startListening()
            result("Listening started")
        case "stopScreenshotListening":
            stopListening()
            updateSharedPreferencesState("")
            result("Listening stopped")
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func shotOff() {
        screenProtectorKit?.enabledPreventScreenshot()
    }

    private func shotOn() {
        screenProtectorKit?.disablePreventScreenshot()
    }
    
    private func setImage() {
        screenProtectorKit?.enabledImageScreen(named: "image")
    }

    private func startListening() {
        NotificationCenter.default.addObserver(self, selector: #selector(screenshotDetected), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }

    private func stopListening() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }

    @objc private func screenshotDetected() {
        print("Screenshot detected")
        updateSharedPreferencesState("screenshot_path_placeholder")
    }

    private func updateScreenshotState() {
        if SwiftNoScreenshotPlugin.preventScreenShot {
            screenProtectorKit?.enabledPreventScreenshot()
        } else {
            screenProtectorKit?.disablePreventScreenshot()
        }
    }

    private func updateSharedPreferencesState(_ screenshotData: String) {
        let map: [String: Any] = [
            "is_screenshot_on": !SwiftNoScreenshotPlugin.preventScreenShot,
            "screenshot_path": screenshotData,
            "was_screenshot_taken": !screenshotData.isEmpty
        ]
        let jsonString = convertMapToJsonString(map)
        if lastSharedPreferencesState != jsonString {
            hasSharedPreferencesChanged = true
            lastSharedPreferencesState = jsonString
        }
    }

    private func convertMapToJsonString(_ map: [String: Any]) -> String {
        if let jsonData = try? JSONSerialization.data(withJSONObject: map, options: .prettyPrinted) {
            return String(data: jsonData, encoding: .utf8) ?? ""
        }
        return ""
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.screenshotStream()
        }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    private func screenshotStream() {
        if hasSharedPreferencesChanged {
            eventSink?(lastSharedPreferencesState)
            hasSharedPreferencesChanged = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.screenshotStream()
        }
    }

    deinit {
        screenProtectorKit?.removeAllObserver()
    }
}
