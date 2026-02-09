import Flutter
import UIKit
import ScreenProtectorKit

public class IOSNoScreenshotPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var screenProtectorKit: ScreenProtectorKit? = nil
    private weak var attachedWindow: UIWindow? = nil
    private static var methodChannel: FlutterMethodChannel? = nil
    private static var eventChannel: FlutterEventChannel? = nil
    private static var preventScreenShot: Bool = false
    private var eventSink: FlutterEventSink? = nil
    private var lastSharedPreferencesState: String = ""
    private var hasSharedPreferencesChanged: Bool = false
    private var isImageOverlayModeEnabled: Bool = false

    private static let ENABLESCREENSHOT = false
    private static let DISABLESCREENSHOT = true

    private static let preventScreenShotKey = "preventScreenShot"
    private static let imageOverlayModeKey = "imageOverlayMode"
    private static let methodChannelName = "com.flutterplaza.no_screenshot_methods"
    private static let eventChannelName = "com.flutterplaza.no_screenshot_streams"
    private static let screenshotPathPlaceholder = "screenshot_path_placeholder"

    init(screenProtectorKit: ScreenProtectorKit? = nil) {
        self.screenProtectorKit = screenProtectorKit
        super.init()

        // Restore the saved state from UserDefaults
        let fetchVal = UserDefaults.standard.bool(forKey: IOSNoScreenshotPlugin.preventScreenShotKey)
        isImageOverlayModeEnabled = UserDefaults.standard.bool(forKey: IOSNoScreenshotPlugin.imageOverlayModeKey)
        updateScreenshotState(isScreenshotBlocked: fetchVal)
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: registrar.messenger())
        eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: registrar.messenger())

        let instance = IOSNoScreenshotPlugin()

        registrar.addMethodCallDelegate(instance, channel: methodChannel!)
        eventChannel?.setStreamHandler(instance)
        registrar.addApplicationDelegate(instance)
    }

    // MARK: - App Lifecycle
    //
    // Image overlay lifecycle is intentionally handled in exactly two places:
    //   SHOW: applicationWillResignActive  (app is about to lose focus)
    //   HIDE: applicationDidBecomeActive   (app is fully interactive again)
    //
    // willResignActive always fires before didEnterBackground, and
    // didBecomeActive always fires after willEnterForeground, so a single
    // show/hide pair covers both the app-switcher peek and the full
    // background → foreground round-trip without double-showing the image.

    public func applicationWillResignActive(_ application: UIApplication) {
        persistState()

        if isImageOverlayModeEnabled {
            // Temporarily lift screenshot prevention so the overlay image is
            // visible in the app switcher (otherwise ScreenProtectorKit's
            // secure text field would show a blank screen).
            screenProtectorKit?.disablePreventScreenshot()
            screenProtectorKit?.enabledImageScreen(named: "image")
        }
    }

    public func applicationDidBecomeActive(_ application: UIApplication) {
        // Remove the image overlay FIRST, while screenProtectorKit still
        // points to the instance that showed it.
        if isImageOverlayModeEnabled {
            screenProtectorKit?.disableImageScreen()
        }

        // Now restore screenshot protection (and re-attach the window if it
        // changed while the app was in the background).
        fetchPersistedState()
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        // Image overlay removal is handled in applicationDidBecomeActive
        // which always fires after this callback.
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        persistState()
        // Image overlay was already shown in applicationWillResignActive
        // which always fires before this callback.
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        persistState()
    }

    func persistState() {
        // Persist the state when changed
        UserDefaults.standard.set(IOSNoScreenshotPlugin.preventScreenShot, forKey: IOSNoScreenshotPlugin.preventScreenShotKey)
        UserDefaults.standard.set(isImageOverlayModeEnabled, forKey: IOSNoScreenshotPlugin.imageOverlayModeKey)
        print("Persisted state: \(IOSNoScreenshotPlugin.preventScreenShot), imageOverlay: \(isImageOverlayModeEnabled)")
        updateSharedPreferencesState("")
    }

    func fetchPersistedState() {
        // Restore the saved state from UserDefaults
        let fetchVal = UserDefaults.standard.bool(forKey: IOSNoScreenshotPlugin.preventScreenShotKey) ? IOSNoScreenshotPlugin.DISABLESCREENSHOT : IOSNoScreenshotPlugin.ENABLESCREENSHOT
        isImageOverlayModeEnabled = UserDefaults.standard.bool(forKey: IOSNoScreenshotPlugin.imageOverlayModeKey)
        updateScreenshotState(isScreenshotBlocked: fetchVal)
        print("Fetched state: \(IOSNoScreenshotPlugin.preventScreenShot), imageOverlay: \(isImageOverlayModeEnabled)")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "screenshotOff":
            shotOff()
            result(true)
        case "screenshotOn":
            shotOn()
            result(true)
        case "toggleScreenshotWithImage":
            let isActive = toggleScreenshotWithImage()
            result(isActive)
        case "toggleScreenshot":
            IOSNoScreenshotPlugin.preventScreenShot ? shotOn() : shotOff()
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
        IOSNoScreenshotPlugin.preventScreenShot = IOSNoScreenshotPlugin.DISABLESCREENSHOT
        screenProtectorKit?.enabledPreventScreenshot()
        persistState()
    }

    private func shotOn() {
        IOSNoScreenshotPlugin.preventScreenShot = IOSNoScreenshotPlugin.ENABLESCREENSHOT
        screenProtectorKit?.disablePreventScreenshot()
        persistState()
    }

    private func toggleScreenshotWithImage() -> Bool {
        // Toggle the image overlay mode state
        isImageOverlayModeEnabled.toggle()

        if isImageOverlayModeEnabled {
            // Mode is now active (true) - screenshot prevention should be ON (screenshots blocked)
            IOSNoScreenshotPlugin.preventScreenShot = IOSNoScreenshotPlugin.DISABLESCREENSHOT
            screenProtectorKit?.enabledPreventScreenshot()
        } else {
            // Mode is now inactive (false) - screenshot prevention should be OFF (screenshots allowed)
            IOSNoScreenshotPlugin.preventScreenShot = IOSNoScreenshotPlugin.ENABLESCREENSHOT
            screenProtectorKit?.disablePreventScreenshot()
            screenProtectorKit?.disableImageScreen()
        }

        persistState()
        return isImageOverlayModeEnabled
    }

    private func startListening() {
        NotificationCenter.default.addObserver(self, selector: #selector(screenshotDetected), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        persistState()
    }

    private func stopListening() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        persistState()
    }

    @objc private func screenshotDetected() {
        print("Screenshot detected")
        updateSharedPreferencesState(IOSNoScreenshotPlugin.screenshotPathPlaceholder)
    }

    private func updateScreenshotState(isScreenshotBlocked: Bool) {
        attachWindowIfNeeded()
        if isScreenshotBlocked {
            screenProtectorKit?.enabledPreventScreenshot()
        } else {
            screenProtectorKit?.disablePreventScreenshot()
        }
    }

    private func updateSharedPreferencesState(_ screenshotData: String) {
        let map: [String: Any] = [
            "is_screenshot_on": IOSNoScreenshotPlugin.preventScreenShot,
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

    private func attachWindowIfNeeded() {
        var activeWindow: UIWindow?

        if #available(iOS 13.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let active = windowScene.windows.first(where: { $0.isKeyWindow }) {
                activeWindow = active
            }
        } else {
            activeWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        }

        guard let window = activeWindow else {
            print("❗️No active window found to attach ScreenProtectorKit.")
            return
        }

        // Skip re-creation if already attached to this window.
        if window === attachedWindow && screenProtectorKit != nil {
            return
        }

        // Clean up the old instance: remove its image overlay and screenshot
        // protection UI before replacing it. A new ScreenProtectorKit instance
        // cannot remove UI elements added by the previous one.
        if isImageOverlayModeEnabled {
            screenProtectorKit?.disableImageScreen()
        }
        screenProtectorKit?.disablePreventScreenshot()

        let kit = ScreenProtectorKit(window: window)
        kit.configurePreventionScreenshot()
        self.screenProtectorKit = kit
        self.attachedWindow = window
    }

    deinit {
        screenProtectorKit?.removeAllObserver()
    }
}