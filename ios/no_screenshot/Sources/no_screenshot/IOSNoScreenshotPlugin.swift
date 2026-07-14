import Flutter
import UIKit

#if SWIFT_PACKAGE
@objc(NoScreenshotPlugin)
#endif
public class IOSNoScreenshotPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, FlutterSceneLifeCycleDelegate {
    private var screenPrevent = UITextField()
    private var screenImage: UIImageView? = nil
    private weak var attachedWindow: UIWindow? = nil
    private static var methodChannel: FlutterMethodChannel? = nil
    private static var eventChannel: FlutterEventChannel? = nil
    // On a macOS host prevention can never engage (see isiOSAppOnMac), so
    // clamp the flag to false at the source: every writer — including the
    // overlay modes, which also enable prevention — would otherwise persist
    // and broadcast is_screenshot_on: true for protection that isn't active.
    // The flag deliberately tracks the ACTUAL protection state, not the
    // requested one: on a Mac an overlay mode can be active while prevention
    // is off, and is_screenshot_on reports prevention, not overlay
    // visibility. toggleScreenshot is short-circuited on macOS hosts, so the
    // toggle direction never depends on this clamp. Assigning inside didSet
    // does not re-trigger the observer.
    private static var preventScreenShot: Bool = false {
        didSet {
            if isiOSAppOnMac && preventScreenShot {
                preventScreenShot = false
            }
        }
    }
    private var eventSink: FlutterEventSink? = nil
    private var lastSharedPreferencesState: String = ""
    private var hasSharedPreferencesChanged: Bool = false
    private var isImageOverlayModeEnabled: Bool = false
    private var isBlurOverlayModeEnabled: Bool = false
    private var blurOverlayView: UIView? = nil
    private var blurRadius: Double = 30.0
    private var isColorOverlayModeEnabled: Bool = false
    private var colorOverlayView: UIView? = nil
    private var colorValue: Int = 0xFF000000
    private var isScreenRecording: Bool = false
    private var isRecordingListening: Bool = false

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

    override init() {
        super.init()

        // Restore the saved state from UserDefaults
        let fetchVal = UserDefaults.standard.bool(forKey: IOSNoScreenshotPlugin.preventScreenShotKey)
        isImageOverlayModeEnabled = UserDefaults.standard.bool(forKey: IOSNoScreenshotPlugin.imageOverlayModeKey)
        isBlurOverlayModeEnabled = UserDefaults.standard.bool(forKey: IOSNoScreenshotPlugin.blurOverlayModeKey)
        let savedRadius = UserDefaults.standard.double(forKey: IOSNoScreenshotPlugin.blurRadiusKey)
        blurRadius = savedRadius > 0 ? savedRadius : 30.0
        isColorOverlayModeEnabled = UserDefaults.standard.bool(forKey: IOSNoScreenshotPlugin.colorOverlayModeKey)
        colorValue = UserDefaults.standard.integer(forKey: IOSNoScreenshotPlugin.colorValueKey)
        if colorValue == 0 { colorValue = 0xFF000000 }
        updateScreenshotState(isScreenshotBlocked: fetchVal)
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: registrar.messenger())
        eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: registrar.messenger())

        let instance = IOSNoScreenshotPlugin()

        registrar.addMethodCallDelegate(instance, channel: methodChannel!)
        eventChannel?.setStreamHandler(instance)
        registrar.addApplicationDelegate(instance)
        registrar.addSceneDelegate(instance)
    }

    // MARK: - Inline Screenshot Prevention (replaces ScreenProtectorKit)

    // The secure-field layer reparenting permanently blanks the window on
    // macOS's UIKit host ("Designed for iPhone/iPad" on Apple silicon), so
    // prevention is skipped there; overlays and detection still work.
    private static let isiOSAppOnMac: Bool = {
        if #available(iOS 14.0, *) {
            return ProcessInfo.processInfo.isiOSAppOnMac
        }
        return false
    }()

    // Returns whether the window may be recorded as attached: true when the
    // secure field was installed (or intentionally skipped on a macOS host,
    // where overlays still need the window), false when the reparenting
    // could not happen yet — e.g. the window's layer is not hosted by the
    // render server during early startup — so the caller retries later.
    private func configurePreventionScreenshot(window: UIWindow) -> Bool {
        guard !IOSNoScreenshotPlugin.isiOSAppOnMac else { return true }
        guard let rootLayer = window.layer.superlayer else { return false }
        guard screenPrevent.layer.superlayer == nil else { return true }

        screenPrevent.semanticContentAttribute = .forceLeftToRight  // RTL fix
        screenPrevent.textAlignment = .left                         // RTL fix

        // Briefly add to the window so UIKit creates the text field's
        // internal sublayer hierarchy, then force a layout pass and
        // immediately remove so screenPrevent is NOT a subview of window.
        // This avoids a circular view-hierarchy that causes EXC_BAD_ACCESS
        // (stack overflow in _collectExistingTraitCollectionsForTraitTracking)
        // on iOS 26+.
        window.addSubview(screenPrevent)
        screenPrevent.layoutIfNeeded()
        screenPrevent.removeFromSuperview()

        // Keep the layer at the origin so reparenting window.layer
        // does not shift the app content.
        screenPrevent.layer.frame = .zero

        rootLayer.addSublayer(screenPrevent.layer)
        if #available(iOS 17.0, *) {
            screenPrevent.layer.sublayers?.last?.addSublayer(window.layer)
        } else {
            screenPrevent.layer.sublayers?.first?.addSublayer(window.layer)
        }
        return true
    }

    private func enablePreventScreenshot() {
        // Attach lazily: under the UIScene lifecycle the plugin registers
        // before the scene activates, and if the host app's scene delegate
        // does not forward lifecycle events (custom SceneDelegate that is
        // not a FlutterSceneDelegate), no attach ever happens through
        // lifecycle callbacks. A method call proves the engine is running,
        // so attach here instead of silently protecting nothing (#105).
        attachWindowIfNeeded()
        screenPrevent.isSecureTextEntry = true
    }

    private func disablePreventScreenshot() {
        screenPrevent.isSecureTextEntry = false
    }

    private func enableImageScreen(named: String) {
        guard let window = attachedWindow else { return }
        let imageView = UIImageView(frame: window.bounds)
        imageView.image = UIImage(named: named)
        imageView.isUserInteractionEnabled = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        window.addSubview(imageView)
        screenImage = imageView
    }

    private func disableImageScreen() {
        screenImage?.removeFromSuperview()
        screenImage = nil
    }

    // MARK: - Shared Lifecycle Helpers
    //
    // Overlay lifecycle is intentionally handled in exactly two places:
    //   SHOW: handleWillResignActive  (app is about to lose focus)
    //   HIDE: handleDidBecomeActive   (app is fully interactive again)
    //
    // willResignActive always fires before didEnterBackground, and
    // didBecomeActive always fires after willEnterForeground, so a single
    // show/hide pair covers both the app-switcher peek and the full
    // background → foreground round-trip without double-showing the overlay.

    private func handleWillResignActive() {
        persistState()

        if isImageOverlayModeEnabled {
            // Temporarily lift screenshot prevention so the overlay image is
            // visible in the app switcher (otherwise the secure text field
            // would show a blank screen).
            disablePreventScreenshot()
            enableImageScreen(named: "NoScreenshotImage")
        } else if isBlurOverlayModeEnabled {
            disablePreventScreenshot()
            enableBlurScreen(radius: blurRadius)
        } else if isColorOverlayModeEnabled {
            disablePreventScreenshot()
            enableColorScreen(color: colorValue)
        }
    }

    private func handleDidBecomeActive() {
        // Remove overlays FIRST.
        if isImageOverlayModeEnabled {
            disableImageScreen()
        } else if isBlurOverlayModeEnabled {
            disableBlurScreen()
        } else if isColorOverlayModeEnabled {
            disableColorScreen()
        }

        // Now restore screenshot protection (and re-attach the window if it
        // changed while the app was in the background).
        fetchPersistedState()
    }

    private func handleDidEnterBackground() {
        persistState()
    }

    private func handleWillTerminate() {
        persistState()
    }

    // MARK: - App Delegate Lifecycle (for apps not yet using UIScene)

    public func applicationWillResignActive(_ application: UIApplication) { handleWillResignActive() }
    public func applicationDidBecomeActive(_ application: UIApplication) { handleDidBecomeActive() }
    public func applicationWillEnterForeground(_ application: UIApplication) { /* handled in didBecomeActive */ }
    public func applicationDidEnterBackground(_ application: UIApplication) { handleDidEnterBackground() }
    public func applicationWillTerminate(_ application: UIApplication) { handleWillTerminate() }

    // MARK: - Scene Delegate Lifecycle (for apps using UIScene)

    public func sceneWillResignActive(_ scene: UIScene) { handleWillResignActive() }
    public func sceneDidBecomeActive(_ scene: UIScene) { handleDidBecomeActive() }
    public func sceneWillEnterForeground(_ scene: UIScene) { /* handled in didBecomeActive */ }
    public func sceneDidEnterBackground(_ scene: UIScene) { handleDidEnterBackground() }

    func persistState() {
        // Persist the state when changed
        UserDefaults.standard.set(IOSNoScreenshotPlugin.preventScreenShot, forKey: IOSNoScreenshotPlugin.preventScreenShotKey)
        UserDefaults.standard.set(isImageOverlayModeEnabled, forKey: IOSNoScreenshotPlugin.imageOverlayModeKey)
        UserDefaults.standard.set(isBlurOverlayModeEnabled, forKey: IOSNoScreenshotPlugin.blurOverlayModeKey)
        UserDefaults.standard.set(blurRadius, forKey: IOSNoScreenshotPlugin.blurRadiusKey)
        UserDefaults.standard.set(isColorOverlayModeEnabled, forKey: IOSNoScreenshotPlugin.colorOverlayModeKey)
        UserDefaults.standard.set(colorValue, forKey: IOSNoScreenshotPlugin.colorValueKey)
        print("Persisted state: \(IOSNoScreenshotPlugin.preventScreenShot), imageOverlay: \(isImageOverlayModeEnabled), blurOverlay: \(isBlurOverlayModeEnabled), blurRadius: \(blurRadius), colorOverlay: \(isColorOverlayModeEnabled), colorValue: \(colorValue)")
        updateSharedPreferencesState("")
    }

    func fetchPersistedState() {
        // Restore the saved state from UserDefaults
        let fetchVal = UserDefaults.standard.bool(forKey: IOSNoScreenshotPlugin.preventScreenShotKey) ? IOSNoScreenshotPlugin.DISABLESCREENSHOT : IOSNoScreenshotPlugin.ENABLESCREENSHOT
        isImageOverlayModeEnabled = UserDefaults.standard.bool(forKey: IOSNoScreenshotPlugin.imageOverlayModeKey)
        isBlurOverlayModeEnabled = UserDefaults.standard.bool(forKey: IOSNoScreenshotPlugin.blurOverlayModeKey)
        let savedRadius = UserDefaults.standard.double(forKey: IOSNoScreenshotPlugin.blurRadiusKey)
        blurRadius = savedRadius > 0 ? savedRadius : 30.0
        isColorOverlayModeEnabled = UserDefaults.standard.bool(forKey: IOSNoScreenshotPlugin.colorOverlayModeKey)
        colorValue = UserDefaults.standard.integer(forKey: IOSNoScreenshotPlugin.colorValueKey)
        if colorValue == 0 { colorValue = 0xFF000000 }
        updateScreenshotState(isScreenshotBlocked: fetchVal)
        print("Fetched state: \(IOSNoScreenshotPlugin.preventScreenShot), imageOverlay: \(isImageOverlayModeEnabled), blurOverlay: \(isBlurOverlayModeEnabled), blurRadius: \(blurRadius), colorOverlay: \(isColorOverlayModeEnabled), colorValue: \(colorValue)")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "screenshotOff":
            // On a macOS host the secure-field protection cannot engage (see
            // isiOSAppOnMac). Skip shotOff() entirely — it would persist and
            // broadcast is_screenshot_on: true for protection that isn't
            // active — and report failure per the Dart API contract.
            if IOSNoScreenshotPlugin.isiOSAppOnMac {
                result(false)
            } else {
                result(shotOff())
            }
        case "screenshotOn":
            shotOn()
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
        case "toggleScreenshot":
            // Same macOS-host guard as screenshotOff: toggling would call
            // shotOff() and poison the persisted/stream state.
            if IOSNoScreenshotPlugin.isiOSAppOnMac {
                result(false)
            } else if IOSNoScreenshotPlugin.preventScreenShot {
                shotOn()
                result(true)
            } else {
                result(shotOff())
            }
        case "screenshotWithImage":
            enableImageOverlay()
            result(true)
        case "screenshotWithBlur":
            let radius = (call.arguments as? [String: Any])?["radius"] as? Double ?? 30.0
            enableBlurOverlay(radius: radius)
            result(true)
        case "screenshotWithColor":
            let color = (call.arguments as? [String: Any])?["color"] as? Int ?? 0xFF000000
            enableColorOverlay(color: color)
            result(true)
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

    // Returns whether protection actually engaged. The requested state is
    // persisted even on failure so the next lifecycle attach self-heals,
    // but the caller is told the truth about right now (#105).
    private func shotOff() -> Bool {
        IOSNoScreenshotPlugin.preventScreenShot = IOSNoScreenshotPlugin.DISABLESCREENSHOT
        enablePreventScreenshot()
        persistState()
        return attachedWindow != nil
    }

    private func shotOn() {
        IOSNoScreenshotPlugin.preventScreenShot = IOSNoScreenshotPlugin.ENABLESCREENSHOT
        disablePreventScreenshot()
        persistState()
    }

    private func toggleScreenshotWithImage() -> Bool {
        // Toggle the image overlay mode state
        isImageOverlayModeEnabled.toggle()

        if isImageOverlayModeEnabled {
            // Deactivate blur mode if active (mutual exclusivity)
            if isBlurOverlayModeEnabled {
                isBlurOverlayModeEnabled = false
                disableBlurScreen()
            }
            // Deactivate color mode if active (mutual exclusivity)
            if isColorOverlayModeEnabled {
                isColorOverlayModeEnabled = false
                disableColorScreen()
            }
            // Mode is now active (true) - screenshot prevention should be ON (screenshots blocked)
            IOSNoScreenshotPlugin.preventScreenShot = IOSNoScreenshotPlugin.DISABLESCREENSHOT
            enablePreventScreenshot()
        } else {
            // Mode is now inactive (false) - screenshot prevention should be OFF (screenshots allowed)
            IOSNoScreenshotPlugin.preventScreenShot = IOSNoScreenshotPlugin.ENABLESCREENSHOT
            disablePreventScreenshot()
            disableImageScreen()
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
                disableImageScreen()
            }
            // Deactivate color mode if active (mutual exclusivity)
            if isColorOverlayModeEnabled {
                isColorOverlayModeEnabled = false
                disableColorScreen()
            }
            IOSNoScreenshotPlugin.preventScreenShot = IOSNoScreenshotPlugin.DISABLESCREENSHOT
            enablePreventScreenshot()
        } else {
            IOSNoScreenshotPlugin.preventScreenShot = IOSNoScreenshotPlugin.ENABLESCREENSHOT
            disablePreventScreenshot()
            disableBlurScreen()
        }

        persistState()
        return isBlurOverlayModeEnabled
    }

    // CIContext allocates GPU resources; share one instance instead of
    // creating a new context on every blur-overlay call.
    private static let ciContext = CIContext()

    private func enableBlurScreen(radius: Double) {
        guard let window = attachedWindow else { return }

        // Capture the current window content as a snapshot.
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let snapshot = renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }

        // Apply a true CIGaussianBlur (no tinting / darkening).
        guard let ciImage = CIImage(image: snapshot),
              let filter = CIFilter(name: "CIGaussianBlur") else { return }

        // Clamp before blurring so edges don't fade to transparent,
        // then crop back to the original extent.
        filter.setValue(ciImage.clampedToExtent(), forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)

        guard let output = filter.outputImage?.cropped(to: ciImage.extent),
              let cgImage = IOSNoScreenshotPlugin.ciContext.createCGImage(output, from: ciImage.extent) else { return }

        let imageView = UIImageView(frame: window.bounds)
        imageView.image = UIImage(cgImage: cgImage)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = false
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(imageView)
        blurOverlayView = imageView
    }

    private func disableBlurScreen() {
        blurOverlayView?.removeFromSuperview()
        blurOverlayView = nil
    }

    private func toggleScreenshotWithColor(color: Int) -> Bool {
        isColorOverlayModeEnabled.toggle()
        colorValue = color

        if isColorOverlayModeEnabled {
            // Deactivate image and blur modes (mutual exclusivity)
            if isImageOverlayModeEnabled {
                isImageOverlayModeEnabled = false
                disableImageScreen()
            }
            if isBlurOverlayModeEnabled {
                isBlurOverlayModeEnabled = false
                disableBlurScreen()
            }
            IOSNoScreenshotPlugin.preventScreenShot = IOSNoScreenshotPlugin.DISABLESCREENSHOT
            enablePreventScreenshot()
        } else {
            IOSNoScreenshotPlugin.preventScreenShot = IOSNoScreenshotPlugin.ENABLESCREENSHOT
            disablePreventScreenshot()
            disableColorScreen()
        }

        persistState()
        return isColorOverlayModeEnabled
    }

    // MARK: - Idempotent enable methods (always-on, no toggle)

    private func enableImageOverlay() {
        isImageOverlayModeEnabled = true
        if isBlurOverlayModeEnabled {
            isBlurOverlayModeEnabled = false
            disableBlurScreen()
        }
        if isColorOverlayModeEnabled {
            isColorOverlayModeEnabled = false
            disableColorScreen()
        }
        IOSNoScreenshotPlugin.preventScreenShot = IOSNoScreenshotPlugin.DISABLESCREENSHOT
        enablePreventScreenshot()
        persistState()
    }

    private func enableBlurOverlay(radius: Double) {
        isBlurOverlayModeEnabled = true
        blurRadius = radius
        if isImageOverlayModeEnabled {
            isImageOverlayModeEnabled = false
            disableImageScreen()
        }
        if isColorOverlayModeEnabled {
            isColorOverlayModeEnabled = false
            disableColorScreen()
        }
        IOSNoScreenshotPlugin.preventScreenShot = IOSNoScreenshotPlugin.DISABLESCREENSHOT
        enablePreventScreenshot()
        persistState()
    }

    private func enableColorOverlay(color: Int) {
        isColorOverlayModeEnabled = true
        colorValue = color
        if isImageOverlayModeEnabled {
            isImageOverlayModeEnabled = false
            disableImageScreen()
        }
        if isBlurOverlayModeEnabled {
            isBlurOverlayModeEnabled = false
            disableBlurScreen()
        }
        IOSNoScreenshotPlugin.preventScreenShot = IOSNoScreenshotPlugin.DISABLESCREENSHOT
        enablePreventScreenshot()
        persistState()
    }

    private func enableColorScreen(color: Int) {
        guard let window = attachedWindow else { return }
        let a = CGFloat((color >> 24) & 0xFF) / 255.0
        let r = CGFloat((color >> 16) & 0xFF) / 255.0
        let g = CGFloat((color >> 8) & 0xFF) / 255.0
        let b = CGFloat(color & 0xFF) / 255.0
        let uiColor = UIColor(red: r, green: g, blue: b, alpha: a)

        let colorView = UIView(frame: window.bounds)
        colorView.backgroundColor = uiColor
        colorView.isUserInteractionEnabled = false
        colorView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(colorView)
        colorOverlayView = colorView
    }

    private func disableColorScreen() {
        colorOverlayView?.removeFromSuperview()
        colorOverlayView = nil
    }

    private func startListening() {
        NotificationCenter.default.addObserver(self, selector: #selector(screenshotDetected), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        persistState()
    }

    private func stopListening() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        persistState()
    }

    // MARK: - Screen Recording Detection

    private var isScreenCaptured: Bool {
        if let windowScene = attachedWindow?.windowScene {
            return windowScene.screen.isCaptured
        }
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            return windowScene.screen.isCaptured
        }
        return false
    }

    private func startRecordingListening() {
        guard !isRecordingListening else { return }
        isRecordingListening = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenCapturedDidChange),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        // Check initial state
        isScreenRecording = isScreenCaptured

        updateSharedPreferencesState("")
    }

    private func stopRecordingListening() {
        guard isRecordingListening else { return }
        isRecordingListening = false

        NotificationCenter.default.removeObserver(
            self,
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )

        isScreenRecording = false
        updateSharedPreferencesState("")
    }

    @objc private func screenCapturedDidChange() {
        isScreenRecording = isScreenCaptured
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        updateSharedPreferencesState("", timestamp: nowMs)
    }

    @objc private func screenshotDetected() {
        print("Screenshot detected")
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        updateSharedPreferencesState(IOSNoScreenshotPlugin.screenshotPathPlaceholder, timestamp: nowMs)
    }

    private func updateScreenshotState(isScreenshotBlocked: Bool) {
        attachWindowIfNeeded()
        if isScreenshotBlocked {
            enablePreventScreenshot()
        } else {
            disablePreventScreenshot()
        }
    }

    private func updateSharedPreferencesState(_ screenshotData: String, timestamp: Int64 = 0, sourceApp: String = "") {
        let map: [String: Any] = [
            "is_screenshot_on": IOSNoScreenshotPlugin.preventScreenShot,
            "screenshot_path": screenshotData,
            "was_screenshot_taken": !screenshotData.isEmpty,
            "is_screen_recording": isScreenRecording,
            "timestamp": timestamp,
            "source_app": sourceApp
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

        // Prefer the foreground-active scene, but fall back to a
        // foreground-inactive one: during startup (or when a method call
        // arrives before activation completes) the scene is still
        // .foregroundInactive even though its key window already exists.
        // Assumes a single Flutter scene: with multiple connected scenes
        // (iPad Split View / Stage Manager) this picks the first match,
        // not necessarily the scene hosting the calling engine.
        let scenes = UIApplication.shared.connectedScenes
        let windowScene =
            (scenes.first(where: { $0.activationState == .foregroundActive })
                ?? scenes.first(where: { $0.activationState == .foregroundInactive }))
            as? UIWindowScene
        if let windowScene = windowScene {
            if #available(iOS 15.0, *) {
                activeWindow = windowScene.keyWindow
            } else {
                activeWindow = windowScene.windows.first(where: { $0.isKeyWindow })
            }
        }

        guard let window = activeWindow else {
            print("❗️No active window found.")
            return
        }

        // Skip re-configuration if already attached to this window.
        if window === attachedWindow {
            return
        }

        // Clean up old state before re-attaching to a new window.
        if isImageOverlayModeEnabled {
            disableImageScreen()
        }
        if isBlurOverlayModeEnabled {
            disableBlurScreen()
        }
        if isColorOverlayModeEnabled {
            disableColorScreen()
        }
        disablePreventScreenshot()

        // Undo previous layer reparenting: move the old window's layer
        // back to the root layer and detach the text field's layer.
        if let oldWindow = attachedWindow,
           let rootLayer = screenPrevent.layer.superlayer {
            rootLayer.addSublayer(oldWindow.layer)
            screenPrevent.layer.removeFromSuperlayer()
        }
        // The old window is now fully detached; clear it so a failed
        // configure below leaves us unattached (retryable, and reported
        // truthfully by shotOff) rather than pointing at a stale window.
        self.attachedWindow = nil

        // Use a fresh UITextField to avoid stale layer state.
        screenPrevent = UITextField()

        // Record the window only if configuration succeeded (or was
        // intentionally skipped on a macOS host). Recording a failed
        // attach would trip the `window === attachedWindow` guard above
        // and permanently block retries for this window — reintroducing
        // the silent no-op from #105 with a false success return.
        if configurePreventionScreenshot(window: window) {
            self.attachedWindow = window
        }
    }
}

#if SWIFT_PACKAGE
// When building with Swift Package Manager, expose the plugin class name
// that matches pluginClass in pubspec.yaml for Flutter's registration.
public typealias NoScreenshotPlugin = IOSNoScreenshotPlugin
#endif
