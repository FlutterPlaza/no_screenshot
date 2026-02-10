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
    private var metadataQuery: NSMetadataQuery? = nil
    private var isListening: Bool = false
    private var lastScreenshotDate: Date = Date()
    private var isScreenCaptureUIRunning: Bool = false
    private var screenCaptureUITerminatedAt: Date? = nil
    private var lastPasteboardChangeCount: Int = NSPasteboard.general.changeCount
    private var pasteboardPollTimer: Timer? = nil
    private var lastDetectionTime: Date = Date.distantPast

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
        guard !isListening else { return }
        isListening = true
        lastScreenshotDate = Date()

        // 1. NSMetadataQuery — detects screenshots saved to disk (always available).
        let query = NSMetadataQuery()
        query.predicate = NSPredicate(format: "kMDItemIsScreenCapture = 1")
        query.searchScopes = [NSMetadataQueryLocalComputerScope]

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(metadataQueryDidFinishGathering(_:)),
            name: .NSMetadataQueryDidFinishGathering,
            object: query
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(metadataQueryDidUpdate(_:)),
            name: .NSMetadataQueryDidUpdate,
            object: query
        )

        query.start()
        metadataQuery = query
        print("Start listening for screenshots via NSMetadataQuery.")

        // 2. NSWorkspace process monitor — detects screencaptureui launch.
        //    Catches screenshots from any source (keyboard shortcuts, Screenshot.app,
        //    Touch Bar, CLI, etc.) including those saved only to clipboard.
        //    No special permissions required; works in sandboxed apps.
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceDidLaunchApplication(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )

        // 3. NSWorkspace terminate monitor — tracks when screencaptureui exits.
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceDidTerminateApplication(_:)),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )

        // Check if screencaptureui is already running
        isScreenCaptureUIRunning = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.apple.screencaptureui"
        }

        print("NSWorkspace observer active — monitoring for screencaptureui process.")

        // 4. Pasteboard polling — detects clipboard-only screenshots.
        lastPasteboardChangeCount = NSPasteboard.general.changeCount
        pasteboardPollTimer = Timer.scheduledTimer(
            timeInterval: 0.5,
            target: self,
            selector: #selector(checkPasteboardForScreenshot),
            userInfo: nil,
            repeats: true
        )
        print("Pasteboard poll timer active (0.5s interval).")

        persistState()
    }

    @objc private func workspaceDidLaunchApplication(_ notification: Notification) {
        guard isListening,
              let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == "com.apple.screencaptureui" else {
            return
        }
        isScreenCaptureUIRunning = true
        updateSharedPreferencesState(MacOSNoScreenshotPlugin.screenshotPathPlaceholder)
    }

    @objc private func workspaceDidTerminateApplication(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == "com.apple.screencaptureui" else {
            return
        }
        isScreenCaptureUIRunning = false
        screenCaptureUITerminatedAt = Date()
    }

    @objc private func checkPasteboardForScreenshot() {
        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount
        guard currentCount != lastPasteboardChangeCount else { return }
        lastPasteboardChangeCount = currentCount

        // Only treat as a screenshot if screencaptureui is running or recently terminated (< 3s)
        let isRecentlyTerminated: Bool
        if let terminatedAt = screenCaptureUITerminatedAt {
            isRecentlyTerminated = Date().timeIntervalSince(terminatedAt) < 3.0
        } else {
            isRecentlyTerminated = false
        }

        guard isScreenCaptureUIRunning || isRecentlyTerminated else { return }

        // Verify the pasteboard contains image data
        let imageTypes: [NSPasteboard.PasteboardType] = [.tiff, .png]
        guard pasteboard.availableType(from: imageTypes) != nil else { return }

        updateSharedPreferencesState(MacOSNoScreenshotPlugin.screenshotPathPlaceholder)
    }

    @objc private func metadataQueryDidFinishGathering(_ notification: Notification) {
        // Ignore pre-existing screenshots; we only care about new ones.
    }

    @objc private func metadataQueryDidUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let addedItems = userInfo[NSMetadataQueryUpdateAddedItemsKey] as? [NSMetadataItem] else {
            return
        }

        for item in addedItems {
            guard let creationDate = item.value(forAttribute: kMDItemContentCreationDate as String) as? Date,
                  creationDate > lastScreenshotDate else {
                continue
            }

            let path = (item.value(forAttribute: kMDItemPath as String) as? String) ?? MacOSNoScreenshotPlugin.screenshotPathPlaceholder
            lastScreenshotDate = creationDate
            updateSharedPreferencesState(path)
        }
    }

    private func stopListening() {
        guard isListening else { return }
        isListening = false

        if let query = metadataQuery {
            query.stop()
            NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidFinishGathering, object: query)
            NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidUpdate, object: query)
            metadataQuery = nil
        }

        NSWorkspace.shared.notificationCenter.removeObserver(
            self,
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.removeObserver(
            self,
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )

        pasteboardPollTimer?.invalidate()
        pasteboardPollTimer = nil

        isScreenCaptureUIRunning = false
        screenCaptureUITerminatedAt = nil
        lastDetectionTime = Date.distantPast

        print("Stop listening for screenshots.")
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
        // Debounce: suppress duplicate screenshot detection events within 2 seconds,
        // unless the new event carries a real file path (NSMetadataQuery upgrade).
        // Non-detection calls (empty screenshotData from persistState) are never debounced.
        if !screenshotData.isEmpty {
            let now = Date()
            let hasRealPath = screenshotData != MacOSNoScreenshotPlugin.screenshotPathPlaceholder
            if now.timeIntervalSince(lastDetectionTime) < 2.0 && !hasRealPath {
                return
            }
            lastDetectionTime = now
        }

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
