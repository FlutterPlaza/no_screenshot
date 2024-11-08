import Cocoa
import FlutterMacOS

public class NoScreenshotPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private static var methodChannel: FlutterMethodChannel? = nil
    private static var eventChannel: FlutterEventChannel? = nil
    private static var preventScreenShot: Bool = false
    private var eventSink: FlutterEventSink? = nil
    private var lastSharedPreferencesState: String = ""
    private var hasSharedPreferencesChanged: Bool = false

    private static let ENABLESCREENSHOT = false
    private static let DISABLESCREENSHOT = true

    private static let preventScreenShotKey = "preventScreenShot"
    private static let methodChannelName = "com.flutterplaza.no_screenshot_methods"
    private static let eventChannelName = "com.flutterplaza.no_screenshot_streams"
    private static let screenshotPathPlaceholder = "screenshot_path_placeholder"

    public static func register(with registrar: FlutterPluginRegistrar) {
        methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: registrar.messenger)
        eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: registrar.messenger)

        let instance = NoScreenshotPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel!)
        eventChannel?.setStreamHandler(instance)

        // Observe when the application goes to background or foreground
        NotificationCenter.default.addObserver(instance, selector: #selector(appWillResignActive), name: NSApplication.didResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(instance, selector: #selector(appDidBecomeActive), name: NSApplication.didBecomeActiveNotification, object: nil)
    }

    @objc func appWillResignActive() {
        persistState()
    }

    @objc func appDidBecomeActive() {
        fetchPersistedState()
    }

    func persistState() {
        UserDefaults.standard.set(NoScreenshotPlugin.preventScreenShot, forKey: NoScreenshotPlugin.preventScreenShotKey)
        print("Persisted state: \(NoScreenshotPlugin.preventScreenShot)")
        updateSharedPreferencesState("")
    }

    func fetchPersistedState() {
        let fetchVal = UserDefaults.standard.bool(forKey: NoScreenshotPlugin.preventScreenShotKey) ? NoScreenshotPlugin.DISABLESCREENSHOT : NoScreenshotPlugin.ENABLESCREENSHOT
        updateScreenshotState(isScreenshotBlocked: fetchVal)
        print("Fetched state: \(NoScreenshotPlugin.preventScreenShot)")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "screenshotOff":
            shotOff()
            result(true)
        case "screenshotOn":
            shotOn()
            result(true)
        case "toggleScreenshot":
            NoScreenshotPlugin.preventScreenShot ? shotOn() : shotOff()
            result(true)
        case "startScreenshotListening":
            startListening()
            result("Listening started")
        case "stopScreenshotListening":
            stopListening()
            result("Listening stopped")
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func shotOff() {
        NoScreenshotPlugin.preventScreenShot = NoScreenshotPlugin.DISABLESCREENSHOT
        print("Screenshot and screen recording prevention activated.")

        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.sharingType = .none // Prevents both screenshots and screen recordings
            }
        }
        persistState()
    }

    private func shotOn() {
        NoScreenshotPlugin.preventScreenShot = NoScreenshotPlugin.ENABLESCREENSHOT
        print("Screenshot and screen recording prevention deactivated.")

        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.sharingType = .readOnly // Allows screenshots and screen recordings
            }
        }
        persistState()
    }

    private func startListening() {
        // macOS does not provide a direct API for detecting screen recording events, so we simulate this.
        print("Start listening for screenshot and screen recording.")
        persistState()
    }

    private func stopListening() {
        print("Stop listening for screenshot.")
        persistState()
    }

    private func updateScreenshotState(isScreenshotBlocked: Bool) {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.sharingType = isScreenshotBlocked ? .none : .readOnly
            }
        }
        print("Updated screenshot state to \(isScreenshotBlocked ? "Blocked" : "Unblocked")")
    }

    private func updateSharedPreferencesState(_ screenshotData: String) {
        let map: [String: Any] = [
            "is_screenshot_on": NoScreenshotPlugin.preventScreenShot,
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
}
