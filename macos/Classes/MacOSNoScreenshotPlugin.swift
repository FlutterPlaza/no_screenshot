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
    private var isBlurOverlayModeEnabled: Bool = false
    private var isColorOverlayModeEnabled: Bool = false
    private var blurRadius: Double = 30.0
    private var colorValue: Int = 0xFF000000
    private var overlayImageView: NSImageView? = nil
    private var blurOverlayView: NSView? = nil
    private var colorOverlayView: NSView? = nil
    private var metadataQuery: NSMetadataQuery? = nil
    private var isListening: Bool = false
    private var lastScreenshotDate: Date = Date()
    private var isScreenCaptureUIRunning: Bool = false
    private var screenCaptureUITerminatedAt: Date? = nil
    private var lastPasteboardChangeCount: Int = NSPasteboard.general.changeCount
    private var pasteboardPollTimer: Timer? = nil
    private var lastDetectionTime: Date = Date.distantPast
    private var isScreenRecording: Bool = false
    private var isRecordingListening: Bool = false
    private var recordingPollTimer: Timer? = nil

    private static let knownRecordingBundleIDs: Set<String> = [
        "com.apple.QuickTimePlayerX",
        "com.obsproject.obs-studio",
        "com.loom.desktop",
        "com.kap.Kap"
    ]

    private static let knownRecordingProcessNames: Set<String> = [
        "ffmpeg",
        "screencapture",
        "obs",
        "simplescreenrecorder"
    ]

    private static let ENABLESCREENSHOT = false
    private static let DISABLESCREENSHOT = true

    private static let preventScreenShotKey = "preventScreenShot"
    private static let imageOverlayModeKey = "imageOverlayMode"
    private static let blurOverlayModeKey = "blurOverlayMode"
    private static let blurRadiusKey = "blurRadius"
    private static let colorOverlayModeKey = "colorOverlayMode"
    private static let colorValueKey = "colorValue"
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
        instance.isBlurOverlayModeEnabled = UserDefaults.standard.bool(forKey: blurOverlayModeKey)
        let savedRadius = UserDefaults.standard.double(forKey: blurRadiusKey)
        instance.blurRadius = savedRadius > 0 ? savedRadius : 30.0
        instance.isColorOverlayModeEnabled = UserDefaults.standard.bool(forKey: colorOverlayModeKey)
        let savedColor = UserDefaults.standard.integer(forKey: colorValueKey)
        instance.colorValue = savedColor != 0 ? savedColor : 0xFF000000

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
        } else if isBlurOverlayModeEnabled {
            DispatchQueue.main.async {
                if let window = NSApplication.shared.windows.first {
                    window.sharingType = .readOnly
                }
            }
            showBlurOverlay(radius: blurRadius)
        } else if isColorOverlayModeEnabled {
            DispatchQueue.main.async {
                if let window = NSApplication.shared.windows.first {
                    window.sharingType = .readOnly
                }
            }
            showColorOverlay(color: colorValue)
        }
    }

    @objc func appDidBecomeActive() {
        // Remove overlays first, then restore screenshot protection.
        if isImageOverlayModeEnabled {
            removeImageOverlay()
        } else if isBlurOverlayModeEnabled {
            removeBlurOverlay()
        } else if isColorOverlayModeEnabled {
            removeColorOverlay()
        }
        fetchPersistedState()
    }

    func persistState() {
        UserDefaults.standard.set(MacOSNoScreenshotPlugin.preventScreenShot, forKey: MacOSNoScreenshotPlugin.preventScreenShotKey)
        UserDefaults.standard.set(isImageOverlayModeEnabled, forKey: MacOSNoScreenshotPlugin.imageOverlayModeKey)
        UserDefaults.standard.set(isBlurOverlayModeEnabled, forKey: MacOSNoScreenshotPlugin.blurOverlayModeKey)
        UserDefaults.standard.set(blurRadius, forKey: MacOSNoScreenshotPlugin.blurRadiusKey)
        UserDefaults.standard.set(isColorOverlayModeEnabled, forKey: MacOSNoScreenshotPlugin.colorOverlayModeKey)
        UserDefaults.standard.set(colorValue, forKey: MacOSNoScreenshotPlugin.colorValueKey)
        print("Persisted state: \(MacOSNoScreenshotPlugin.preventScreenShot), imageOverlay: \(isImageOverlayModeEnabled), blurOverlay: \(isBlurOverlayModeEnabled), blurRadius: \(blurRadius), colorOverlay: \(isColorOverlayModeEnabled), colorValue: \(colorValue)")
        updateSharedPreferencesState("")
    }

    func fetchPersistedState() {
        let fetchVal = UserDefaults.standard.bool(forKey: MacOSNoScreenshotPlugin.preventScreenShotKey) ? MacOSNoScreenshotPlugin.DISABLESCREENSHOT : MacOSNoScreenshotPlugin.ENABLESCREENSHOT
        isImageOverlayModeEnabled = UserDefaults.standard.bool(forKey: MacOSNoScreenshotPlugin.imageOverlayModeKey)
        isBlurOverlayModeEnabled = UserDefaults.standard.bool(forKey: MacOSNoScreenshotPlugin.blurOverlayModeKey)
        let savedRadius = UserDefaults.standard.double(forKey: MacOSNoScreenshotPlugin.blurRadiusKey)
        blurRadius = savedRadius > 0 ? savedRadius : 30.0
        isColorOverlayModeEnabled = UserDefaults.standard.bool(forKey: MacOSNoScreenshotPlugin.colorOverlayModeKey)
        colorValue = UserDefaults.standard.integer(forKey: MacOSNoScreenshotPlugin.colorValueKey)
        if colorValue == 0 { colorValue = 0xFF000000 }
        updateScreenshotState(isScreenshotBlocked: fetchVal)
        print("Fetched state: \(MacOSNoScreenshotPlugin.preventScreenShot), imageOverlay: \(isImageOverlayModeEnabled), blurOverlay: \(isBlurOverlayModeEnabled), blurRadius: \(blurRadius), colorOverlay: \(isColorOverlayModeEnabled), colorValue: \(colorValue)")
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
        case "toggleScreenshotWithBlur":
            let radius = (call.arguments as? [String: Any])?["radius"] as? Double ?? 30.0
            let isActive = toggleScreenshotWithBlur(radius: radius)
            result(isActive)
        case "toggleScreenshotWithColor":
            let color = (call.arguments as? [String: Any])?["color"] as? Int ?? 0xFF000000
            let isActive = toggleScreenshotWithColor(color: color)
            result(isActive)
        case "startScreenshotListening":
            startListening()
            result("Listening started")
        case "stopScreenshotListening":
            stopListening()
            result("Listening stopped")
        case "startScreenRecordingListening":
            startRecordingListening()
            result("Recording listening started")
        case "stopScreenRecordingListening":
            stopRecordingListening()
            result("Recording listening stopped")
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
            // Deactivate blur mode if active (mutual exclusivity)
            if isBlurOverlayModeEnabled {
                isBlurOverlayModeEnabled = false
                removeBlurOverlay()
            }
            if isColorOverlayModeEnabled {
                isColorOverlayModeEnabled = false
                removeColorOverlay()
            }
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

    private func toggleScreenshotWithBlur(radius: Double) -> Bool {
        isBlurOverlayModeEnabled.toggle()
        blurRadius = radius

        if isBlurOverlayModeEnabled {
            // Deactivate image mode if active (mutual exclusivity)
            if isImageOverlayModeEnabled {
                isImageOverlayModeEnabled = false
                removeImageOverlay()
            }
            if isColorOverlayModeEnabled {
                isColorOverlayModeEnabled = false
                removeColorOverlay()
            }
            MacOSNoScreenshotPlugin.preventScreenShot = MacOSNoScreenshotPlugin.DISABLESCREENSHOT
            DispatchQueue.main.async {
                if let window = NSApplication.shared.windows.first {
                    window.sharingType = .none
                }
            }
        } else {
            MacOSNoScreenshotPlugin.preventScreenShot = MacOSNoScreenshotPlugin.ENABLESCREENSHOT
            DispatchQueue.main.async {
                if let window = NSApplication.shared.windows.first {
                    window.sharingType = .readOnly
                }
            }
            removeBlurOverlay()
        }

        persistState()
        return isBlurOverlayModeEnabled
    }

    private func showBlurOverlay(radius: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.blurOverlayView == nil else { return }
            guard let window = NSApplication.shared.windows.first,
                  let contentView = window.contentView else { return }

            // Capture window content and apply CIGaussianBlur
            let windowID = CGWindowID(window.windowNumber)
            if let cgImage = CGWindowListCreateImage(
                .null, .optionIncludingWindow, windowID,
                [.boundsIgnoreFraming, .bestResolution]
            ) {
                let ciImage = CIImage(cgImage: cgImage)
                let filter = CIFilter(name: "CIGaussianBlur")!
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                filter.setValue(radius, forKey: kCIInputRadiusKey)

                if let outputImage = filter.outputImage {
                    let context = CIContext()
                    let extent = ciImage.extent
                    if let blurredCGImage = context.createCGImage(outputImage, from: extent) {
                        let nsImage = NSImage(cgImage: blurredCGImage, size: contentView.bounds.size)
                        let imageView = NSImageView(frame: contentView.bounds)
                        imageView.image = nsImage
                        imageView.imageScaling = .scaleProportionallyUpOrDown
                        imageView.autoresizingMask = [.width, .height]
                        contentView.addSubview(imageView, positioned: .above, relativeTo: contentView.subviews.last)
                        self.blurOverlayView = imageView
                        return
                    }
                }
            }

            // Fallback: NSVisualEffectView
            let blurView = NSVisualEffectView(frame: contentView.bounds)
            blurView.material = .hudWindow
            blurView.blendingMode = .behindWindow
            blurView.state = .active
            blurView.autoresizingMask = [.width, .height]
            contentView.addSubview(blurView, positioned: .above, relativeTo: contentView.subviews.last)
            self.blurOverlayView = blurView
        }
    }

    private func removeBlurOverlay() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.blurOverlayView?.removeFromSuperview()
            self.blurOverlayView = nil
        }
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

    private func toggleScreenshotWithColor(color: Int) -> Bool {
        isColorOverlayModeEnabled.toggle()
        colorValue = color

        if isColorOverlayModeEnabled {
            if isImageOverlayModeEnabled {
                isImageOverlayModeEnabled = false
                removeImageOverlay()
            }
            if isBlurOverlayModeEnabled {
                isBlurOverlayModeEnabled = false
                removeBlurOverlay()
            }
            MacOSNoScreenshotPlugin.preventScreenShot = MacOSNoScreenshotPlugin.DISABLESCREENSHOT
            DispatchQueue.main.async {
                if let window = NSApplication.shared.windows.first {
                    window.sharingType = .none
                }
            }
        } else {
            MacOSNoScreenshotPlugin.preventScreenShot = MacOSNoScreenshotPlugin.ENABLESCREENSHOT
            DispatchQueue.main.async {
                if let window = NSApplication.shared.windows.first {
                    window.sharingType = .readOnly
                }
            }
            removeColorOverlay()
        }

        persistState()
        return isColorOverlayModeEnabled
    }

    private func showColorOverlay(color: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.colorOverlayView == nil else { return }
            guard let window = NSApplication.shared.windows.first,
                  let contentView = window.contentView else { return }

            let a = CGFloat((color >> 24) & 0xFF) / 255.0
            let r = CGFloat((color >> 16) & 0xFF) / 255.0
            let g = CGFloat((color >> 8) & 0xFF) / 255.0
            let b = CGFloat(color & 0xFF) / 255.0
            let nsColor = NSColor(red: r, green: g, blue: b, alpha: a)

            let colorView = NSView(frame: contentView.bounds)
            colorView.wantsLayer = true
            colorView.layer?.backgroundColor = nsColor.cgColor
            colorView.autoresizingMask = [.width, .height]
            contentView.addSubview(colorView, positioned: .above, relativeTo: contentView.subviews.last)
            self.colorOverlayView = colorView
        }
    }

    private func removeColorOverlay() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.colorOverlayView?.removeFromSuperview()
            self.colorOverlayView = nil
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

    // MARK: - Screen Recording Detection

    private func startRecordingListening() {
        guard !isRecordingListening else { return }
        isRecordingListening = true

        checkForRecordingProcesses()

        recordingPollTimer = Timer.scheduledTimer(
            timeInterval: 2.0,
            target: self,
            selector: #selector(checkForRecordingProcesses),
            userInfo: nil,
            repeats: true
        )
        print("Recording detection started (2s polling).")
    }

    @objc private func checkForRecordingProcesses() {
        let apps = NSWorkspace.shared.runningApplications
        let detected = apps.contains { app in
            if let bundleID = app.bundleIdentifier,
               MacOSNoScreenshotPlugin.knownRecordingBundleIDs.contains(bundleID) {
                return true
            }
            if let name = app.localizedName?.lowercased(),
               MacOSNoScreenshotPlugin.knownRecordingProcessNames.contains(name) {
                return true
            }
            if let execName = app.executableURL?.lastPathComponent.lowercased(),
               MacOSNoScreenshotPlugin.knownRecordingProcessNames.contains(execName) {
                return true
            }
            return false
        }

        if detected != isScreenRecording {
            isScreenRecording = detected
            updateSharedPreferencesState("")
        }
    }

    private func stopRecordingListening() {
        guard isRecordingListening else { return }
        isRecordingListening = false

        recordingPollTimer?.invalidate()
        recordingPollTimer = nil

        isScreenRecording = false
        updateSharedPreferencesState("")
        print("Recording detection stopped.")
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
            "was_screenshot_taken": !screenshotData.isEmpty,
            "is_screen_recording": isScreenRecording
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
