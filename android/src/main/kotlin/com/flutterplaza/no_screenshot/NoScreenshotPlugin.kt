package com.flutterplaza.no_screenshot

import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.SharedPreferences
import android.database.ContentObserver
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.RenderEffect
import android.graphics.Shader
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.renderscript.Allocation
import android.renderscript.Element
import android.renderscript.RenderScript
import android.renderscript.ScriptIntrinsicBlur
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager.LayoutParams
import android.widget.FrameLayout
import android.widget.ImageView
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import org.json.JSONObject

const val SCREENSHOT_ON_CONST = "screenshotOn"
const val SCREENSHOT_OFF_CONST = "screenshotOff"
const val TOGGLE_SCREENSHOT_CONST = "toggleScreenshot"
const val PREF_NAME = "screenshot_pref"
const val START_SCREENSHOT_LISTENING_CONST = "startScreenshotListening"
const val STOP_SCREENSHOT_LISTENING_CONST = "stopScreenshotListening"
const val SCREENSHOT_PATH = "screenshot_path"
const val PREF_KEY_SCREENSHOT = "is_screenshot_on"
const val SCREENSHOT_TAKEN = "was_screenshot_taken"
const val SET_IMAGE_CONST = "toggleScreenshotWithImage"
const val SET_BLUR_CONST = "toggleScreenshotWithBlur"
const val PREF_KEY_IMAGE_OVERLAY = "is_image_overlay_mode_enabled"
const val PREF_KEY_BLUR_OVERLAY = "is_blur_overlay_mode_enabled"
const val IS_SCREEN_RECORDING = "is_screen_recording"
const val START_SCREEN_RECORDING_LISTENING_CONST = "startScreenRecordingListening"
const val STOP_SCREEN_RECORDING_LISTENING_CONST = "stopScreenRecordingListening"
const val SCREENSHOT_METHOD_CHANNEL = "com.flutterplaza.no_screenshot_methods"
const val SCREENSHOT_EVENT_CHANNEL = "com.flutterplaza.no_screenshot_streams"

class NoScreenshotPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
    EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private val preferences: SharedPreferences by lazy {
        context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    }
    private var screenshotObserver: ContentObserver? = null
    private val handler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var lastSharedPreferencesState: String = ""
    private var hasSharedPreferencesChanged: Boolean = false
    private var isImageOverlayModeEnabled: Boolean = false
    private var isBlurOverlayModeEnabled: Boolean = false
    private var overlayImageView: ImageView? = null
    private var overlayBlurView: View? = null
    private var lifecycleCallbacks: Application.ActivityLifecycleCallbacks? = null
    private var isScreenRecording: Boolean = false
    private var isRecordingListening: Boolean = false
    private var screenCaptureCallback: Any? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        methodChannel =
            MethodChannel(flutterPluginBinding.binaryMessenger, SCREENSHOT_METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, SCREENSHOT_EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)

        initScreenshotObserver()
        registerLifecycleCallbacks()
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        screenshotObserver?.let { context.contentResolver.unregisterContentObserver(it) }
        unregisterLifecycleCallbacks()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        restoreScreenshotState()
        if (isRecordingListening) {
            registerScreenCaptureCallback()
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        unregisterScreenCaptureCallback()
        removeImageOverlay()
        removeBlurOverlay()
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        restoreScreenshotState()
        if (isRecordingListening) {
            registerScreenCaptureCallback()
        }
    }

    override fun onDetachedFromActivity() {
        unregisterScreenCaptureCallback()
        removeImageOverlay()
        removeBlurOverlay()
        activity = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            SCREENSHOT_ON_CONST -> {
                result.success(screenshotOn().also { updateSharedPreferencesState("") })
            }

            SCREENSHOT_OFF_CONST -> {
                result.success(screenshotOff().also { updateSharedPreferencesState("") })
            }

            TOGGLE_SCREENSHOT_CONST -> {
                toggleScreenshot()
                result.success(true.also { updateSharedPreferencesState("") })
            }

            START_SCREENSHOT_LISTENING_CONST -> {
                startListening()
                result.success("Listening started")
            }

            STOP_SCREENSHOT_LISTENING_CONST -> {
                stopListening()
                result.success("Listening stopped".also { updateSharedPreferencesState("") })
            }

            SET_IMAGE_CONST -> {
                result.success(toggleScreenshotWithImage())
            }

            SET_BLUR_CONST -> {
                result.success(toggleScreenshotWithBlur())
            }

            START_SCREEN_RECORDING_LISTENING_CONST -> {
                startRecordingListening()
                result.success("Recording listening started")
            }

            STOP_SCREEN_RECORDING_LISTENING_CONST -> {
                stopRecordingListening()
                result.success("Recording listening stopped".also { updateSharedPreferencesState("") })
            }

            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        handler.postDelayed(screenshotStream, 1000)
    }

    override fun onCancel(arguments: Any?) {
        handler.removeCallbacks(screenshotStream)
        eventSink = null
    }

    private fun registerLifecycleCallbacks() {
        val app = context as? Application ?: return
        lifecycleCallbacks = object : Application.ActivityLifecycleCallbacks {
            override fun onActivityPaused(act: Activity) {
                if (act == activity && isImageOverlayModeEnabled) {
                    act.window?.clearFlags(LayoutParams.FLAG_SECURE)
                    showImageOverlay(act)
                } else if (act == activity && isBlurOverlayModeEnabled) {
                    act.window?.clearFlags(LayoutParams.FLAG_SECURE)
                    showBlurOverlay(act)
                }
            }

            override fun onActivityResumed(act: Activity) {
                if (act == activity && isImageOverlayModeEnabled) {
                    removeImageOverlay()
                    act.window?.addFlags(LayoutParams.FLAG_SECURE)
                } else if (act == activity && isBlurOverlayModeEnabled) {
                    removeBlurOverlay()
                    act.window?.addFlags(LayoutParams.FLAG_SECURE)
                }
            }

            override fun onActivityCreated(act: Activity, savedInstanceState: Bundle?) {}
            override fun onActivityStarted(act: Activity) {}
            override fun onActivityStopped(act: Activity) {}
            override fun onActivitySaveInstanceState(act: Activity, outState: Bundle) {
                if (act == activity && isImageOverlayModeEnabled) {
                    showImageOverlay(act)
                } else if (act == activity && isBlurOverlayModeEnabled) {
                    showBlurOverlay(act)
                }
            }
            override fun onActivityDestroyed(act: Activity) {}
        }
        app.registerActivityLifecycleCallbacks(lifecycleCallbacks)
    }

    private fun unregisterLifecycleCallbacks() {
        val app = context as? Application ?: return
        lifecycleCallbacks?.let { app.unregisterActivityLifecycleCallbacks(it) }
        lifecycleCallbacks = null
    }

    private fun showImageOverlay(activity: Activity) {
        if (overlayImageView != null) return
        val resId = activity.resources.getIdentifier("image", "drawable", activity.packageName)
        if (resId == 0) return
        activity.runOnUiThread {
            val imageView = ImageView(activity).apply {
                setImageResource(resId)
                scaleType = ImageView.ScaleType.CENTER_CROP
                layoutParams = FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
            }
            (activity.window.decorView as? ViewGroup)?.addView(imageView)
            overlayImageView = imageView
        }
    }

    private fun removeImageOverlay() {
        val imageView = overlayImageView ?: return
        val act = activity
        if (act != null) {
            act.runOnUiThread {
                (imageView.parent as? ViewGroup)?.removeView(imageView)
                overlayImageView = null
            }
        } else {
            (imageView.parent as? ViewGroup)?.removeView(imageView)
            overlayImageView = null
        }
    }

    private fun toggleScreenshotWithImage(): Boolean {
        isImageOverlayModeEnabled = !preferences.getBoolean(PREF_KEY_IMAGE_OVERLAY, false)
        saveImageOverlayState(isImageOverlayModeEnabled)

        if (isImageOverlayModeEnabled) {
            // Deactivate blur mode if active (mutual exclusivity)
            if (isBlurOverlayModeEnabled) {
                isBlurOverlayModeEnabled = false
                saveBlurOverlayState(false)
                removeBlurOverlay()
            }
            screenshotOff()
        } else {
            screenshotOn()
            removeImageOverlay()
        }
        updateSharedPreferencesState("")
        return isImageOverlayModeEnabled
    }

    private fun toggleScreenshotWithBlur(): Boolean {
        isBlurOverlayModeEnabled = !preferences.getBoolean(PREF_KEY_BLUR_OVERLAY, false)
        saveBlurOverlayState(isBlurOverlayModeEnabled)

        if (isBlurOverlayModeEnabled) {
            // Deactivate image mode if active (mutual exclusivity)
            if (isImageOverlayModeEnabled) {
                isImageOverlayModeEnabled = false
                saveImageOverlayState(false)
                removeImageOverlay()
            }
            screenshotOff()
        } else {
            screenshotOn()
            removeBlurOverlay()
        }
        updateSharedPreferencesState("")
        return isBlurOverlayModeEnabled
    }

    @Suppress("DEPRECATION")
    private fun showBlurOverlay(activity: Activity) {
        if (overlayBlurView != null) return
        val decorView = activity.window?.decorView ?: return

        if (Build.VERSION.SDK_INT >= 31) {
            // API 31+: GPU blur via RenderEffect on decorView
            activity.runOnUiThread {
                decorView.setRenderEffect(
                    RenderEffect.createBlurEffect(30f, 30f, Shader.TileMode.CLAMP)
                )
                overlayBlurView = decorView
            }
        } else if (Build.VERSION.SDK_INT >= 17) {
            // API 17–30: Capture bitmap, blur with RenderScript, show as ImageView
            activity.runOnUiThread {
                val width = decorView.width
                val height = decorView.height
                if (width <= 0 || height <= 0) return@runOnUiThread

                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bitmap)
                decorView.draw(canvas)

                val rs = RenderScript.create(activity)
                val input = Allocation.createFromBitmap(rs, bitmap)
                val output = Allocation.createTyped(rs, input.type)
                val script = ScriptIntrinsicBlur.create(rs, Element.U8_4(rs))
                script.setRadius(25f)
                script.setInput(input)
                script.forEach(output)
                output.copyTo(bitmap)
                script.destroy()
                input.destroy()
                output.destroy()
                rs.destroy()

                val imageView = ImageView(activity).apply {
                    setImageBitmap(bitmap)
                    scaleType = ImageView.ScaleType.FIT_XY
                    layoutParams = FrameLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT
                    )
                }
                (decorView as? ViewGroup)?.addView(imageView)
                overlayBlurView = imageView
            }
        }
        // API <17: FLAG_SECURE alone prevents app switcher preview; no blur needed.
    }

    private fun removeBlurOverlay() {
        val blurView = overlayBlurView ?: return
        val act = activity
        if (act != null) {
            act.runOnUiThread {
                if (Build.VERSION.SDK_INT >= 31 && blurView === act.window?.decorView) {
                    blurView.setRenderEffect(null)
                } else {
                    (blurView.parent as? ViewGroup)?.removeView(blurView)
                }
                overlayBlurView = null
            }
        } else {
            if (Build.VERSION.SDK_INT >= 31) {
                blurView.setRenderEffect(null)
            } else {
                (blurView.parent as? ViewGroup)?.removeView(blurView)
            }
            overlayBlurView = null
        }
    }

    // ── Screen Recording Detection ─────────────────────────────────────

    private fun startRecordingListening() {
        if (isRecordingListening) return
        isRecordingListening = true
        registerScreenCaptureCallback()
        updateSharedPreferencesState("")
    }

    private fun stopRecordingListening() {
        if (!isRecordingListening) return
        isRecordingListening = false
        unregisterScreenCaptureCallback()
        isScreenRecording = false
        updateSharedPreferencesState("")
    }

    private fun registerScreenCaptureCallback() {
        if (android.os.Build.VERSION.SDK_INT >= 34) {
            val act = activity ?: return
            if (screenCaptureCallback != null) return

            val callback = Activity.ScreenCaptureCallback {
                isScreenRecording = true
                updateSharedPreferencesState("")
            }
            act.registerScreenCaptureCallback(act.mainExecutor, callback)
            screenCaptureCallback = callback
        }
    }

    private fun unregisterScreenCaptureCallback() {
        if (android.os.Build.VERSION.SDK_INT >= 34) {
            val act = activity ?: return
            val callback = screenCaptureCallback as? Activity.ScreenCaptureCallback ?: return
            act.unregisterScreenCaptureCallback(callback)
            screenCaptureCallback = null
        }
    }

    private fun initScreenshotObserver() {
        screenshotObserver = object : ContentObserver(Handler()) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                uri?.let {
                    if (it.toString()
                            .contains(MediaStore.Images.Media.EXTERNAL_CONTENT_URI.toString())
                    ) {
                        Log.d("ScreenshotProtection", "Screenshot detected")
                        updateSharedPreferencesState(it.path ?: "")
                    }
                }
            }
        }
    }

    private fun startListening() {
        screenshotObserver?.let {
            context.contentResolver.registerContentObserver(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                true,
                it
            )
        }
    }

    private fun stopListening() {
        screenshotObserver?.let { context.contentResolver.unregisterContentObserver(it) }
    }

    private fun screenshotOff(): Boolean = try {
        activity?.window?.addFlags(LayoutParams.FLAG_SECURE)
        saveScreenshotState(true)
        true
    } catch (e: Exception) {
        false
    }

    private fun screenshotOn(): Boolean = try {
        activity?.window?.clearFlags(LayoutParams.FLAG_SECURE)
        saveScreenshotState(false)
        true
    } catch (e: Exception) {
        false
    }

    private fun toggleScreenshot() {
        activity?.window?.attributes?.flags?.let { flags ->
            if (flags and LayoutParams.FLAG_SECURE != 0) {
                screenshotOn()
            } else {
                screenshotOff()
            }
        }
    }

    private fun saveScreenshotState(isSecure: Boolean) {
        Executors.newSingleThreadExecutor().execute {
            preferences.edit().putBoolean(PREF_KEY_SCREENSHOT, isSecure).apply()
        }
    }

    private fun saveImageOverlayState(enabled: Boolean) {
        Executors.newSingleThreadExecutor().execute {
            preferences.edit().putBoolean(PREF_KEY_IMAGE_OVERLAY, enabled).apply()
        }
    }

    private fun saveBlurOverlayState(enabled: Boolean) {
        Executors.newSingleThreadExecutor().execute {
            preferences.edit().putBoolean(PREF_KEY_BLUR_OVERLAY, enabled).apply()
        }
    }

    private fun restoreScreenshotState() {
        Executors.newSingleThreadExecutor().execute {
            val isSecure = preferences.getBoolean(PREF_KEY_SCREENSHOT, false)
            val overlayEnabled = preferences.getBoolean(PREF_KEY_IMAGE_OVERLAY, false)
            val blurEnabled = preferences.getBoolean(PREF_KEY_BLUR_OVERLAY, false)
            isImageOverlayModeEnabled = overlayEnabled
            isBlurOverlayModeEnabled = blurEnabled

            activity?.runOnUiThread {
                if (isImageOverlayModeEnabled || isBlurOverlayModeEnabled || isSecure) {
                    screenshotOff()
                } else {
                    screenshotOn()
                }
            }
        }
    }

    private fun updateSharedPreferencesState(screenshotData: String) {
        Handler(Looper.getMainLooper()).postDelayed({
            val isSecure =
                (activity?.window?.attributes?.flags ?: 0) and LayoutParams.FLAG_SECURE != 0
            val jsonString = convertMapToJsonString(
                mapOf(
                    PREF_KEY_SCREENSHOT to isSecure,
                    SCREENSHOT_PATH to screenshotData,
                    SCREENSHOT_TAKEN to screenshotData.isNotEmpty(),
                    IS_SCREEN_RECORDING to isScreenRecording
                )
            )
            if (lastSharedPreferencesState != jsonString) {
                hasSharedPreferencesChanged = true
                lastSharedPreferencesState = jsonString
            }
        }, 100)
    }

    private fun convertMapToJsonString(map: Map<String, Any>): String {
        return JSONObject(map).toString()
    }

    private val screenshotStream = object : Runnable {
        override fun run() {
            if (hasSharedPreferencesChanged) {
                eventSink?.success(lastSharedPreferencesState)
                hasSharedPreferencesChanged = false
            }
            handler.postDelayed(this, 1000)
        }
    }
}
