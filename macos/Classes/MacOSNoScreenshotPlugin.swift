import Cocoa
import FlutterMacOS

public class MacOSNoScreenshotPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private static var methodChannel: FlutterMethodChannel? = nil
    private static var eventChannel: FlutterEventChannel? = nil
    private static var preventScreenShot: Bool = false
    private var eventSink: FlutterEventSink? = nil
    private var lastSharedPreferencesState: String = ""
    private var hasSharedPreferencesChanged: Bool = false
    private var isImageOverlayModeEnabled: Bool = false
    private var overlayImageView: NSImageView? = nil

    private static let ENABLESCREENSHOT = false
    private static let DISABLESCREENSHOT = true

    private static let preventScreenShotKey = "preventScreenShot"
    private static let imageOverlayModeKey = "imageOverlayMode"
    private static let methodChannelName = "com.flutterplaza.no_screenshot_methods"
    private static let eventChannelName = "com.flutterplaza.no_screenshot_streams"
    private static let screenshotPathPlaceholder = "screenshot_path_placeholder"

    public static func register(with registrar: FlutterPluginRegistrar) {
        methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: registrar.messenger)
        eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: registrar.messenger)

        let instance = MacOSNoScreenshotPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel!)
        eventChannel?.setStreamHandler(instance)

        instance.isImageOverlayModeEnabled = UserDefaults.standard.bool(forKey: imageOverlayModeKey)

        // Observe when the application goes to background or foreground
        NotificationCenter.default.addObserver(instance, selector: #selector(appWillResignActive), name: NSApplication.didResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(instance, selector: #selector(appDidBecomeActive), name: NSApplication.didBecomeActiveNotification, object: nil)
    }

    @objc func appWillResignActive() {
        persistState()

        if isImageOverlayModeEnabled {
            // Temporarily lift screenshot prevention so the overlay image is
            // visible in Mission Control / app switcher (sharingType .none
            // would show a blank window).
            DispatchQueue.main.async {
                if let window = NSApplication.shared.windows.first {
                    window.sharingType = .readOnly
                }
            }
            showImageOverlay()
        }
    }

    @objc func appDidBecomeActive() {
        // Remove the image overlay first, then restore screenshot protection.
        if isImageOverlayModeEnabled {
            removeImageOverlay()
        }
        fetchPersistedState()
    }

    func persistState() {
        UserDefaults.standard.set(MacOSNoScreenshotPlugin.preventScreenShot, forKey: MacOSNoScreenshotPlugin.preventScreenShotKey)
        UserDefaults.standard.set(isImageOverlayModeEnabled, forKey: MacOSNoScreenshotPlugin.imageOverlayModeKey)
        print("Persisted state: \(MacOSNoScreenshotPlugin.preventScreenShot), imageOverlay: \(isImageOverlayModeEnabled)")
        updateSharedPreferencesState("")
    }

    func fetchPersistedState() {
        let fetchVal = UserDefaults.standard.bool(forKey: MacOSNoScreenshotPlugin.preventScreenShotKey) ? MacOSNoScreenshotPlugin.DISABLESCREENSHOT : MacOSNoScreenshotPlugin.ENABLESCREENSHOT
        isImageOverlayModeEnabled = UserDefaults.standard.bool(forKey: MacOSNoScreenshotPlugin.imageOverlayModeKey)
        updateScreenshotState(isScreenshotBlocked: fetchVal)
        print("Fetched state: \(MacOSNoScreenshotPlugin.preventScreenShot), imageOverlay: \(isImageOverlayModeEnabled)")
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
            MacOSNoScreenshotPlugin.preventScreenShot ? shotOn() : shotOff()
            result(true)
        case "toggleScreenshotWithImage":
            let isActive = toggleScreenshotWithImage()
            result(isActive)
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
        MacOSNoScreenshotPlugin.preventScreenShot = MacOSNoScreenshotPlugin.DISABLESCREENSHOT
        print("Screenshot and screen recording prevention activated.")

        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.sharingType = .none // Prevents both screenshots and screen recordings
            }
        }
        persistState()
    }

    private func shotOn() {
        MacOSNoScreenshotPlugin.preventScreenShot = MacOSNoScreenshotPlugin.ENABLESCREENSHOT
        print("Screenshot and screen recording prevention deactivated.")

        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.sharingType = .readOnly // Allows screenshots and screen recordings
            }
        }
        persistState()
    }

    private func toggleScreenshotWithImage() -> Bool {
        isImageOverlayModeEnabled.toggle()

        if isImageOverlayModeEnabled {
            // Enable screenshot prevention
            MacOSNoScreenshotPlugin.preventScreenShot = MacOSNoScreenshotPlugin.DISABLESCREENSHOT
            DispatchQueue.main.async {
                if let window = NSApplication.shared.windows.first {
                    window.sharingType = .none
                }
            }
        } else {
            // Disable screenshot prevention and remove any overlay
            MacOSNoScreenshotPlugin.preventScreenShot = MacOSNoScreenshotPlugin.ENABLESCREENSHOT
            DispatchQueue.main.async {
                if let window = NSApplication.shared.windows.first {
                    window.sharingType = .readOnly
                }
            }
            removeImageOverlay()
        }

        persistState()
        return isImageOverlayModeEnabled
    }

    private func showImageOverlay() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.overlayImageView == nil else { return }
            guard let window = NSApplication.shared.windows.first,
                  let contentView = window.contentView else { return }
            guard let image = NSImage(named: "image") else {
                print("No overlay image named 'image' found in asset catalog.")
                return
            }

            let imageView = NSImageView(frame: contentView.bounds)
            imageView.image = image
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.autoresizingMask = [.width, .height]
            contentView.addSubview(imageView, positioned: .above, relativeTo: contentView.subviews.last)
            self.overlayImageView = imageView
        }
    }

    private func removeImageOverlay() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.overlayImageView?.removeFromSuperview()
            self.overlayImageView = nil
        }
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
            "is_screenshot_on": MacOSNoScreenshotPlugin.preventScreenShot,
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
