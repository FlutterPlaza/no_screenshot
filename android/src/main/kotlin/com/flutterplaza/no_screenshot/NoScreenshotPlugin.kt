package com.flutterplaza.no_screenshot

import android.app.Activity
import android.content.Context
import android.content.SharedPreferences
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
import android.view.WindowManager.LayoutParams
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
const val SCREENSHOT_METHOD_CHANNEL = "com.flutterplaza.no_screenshot_methods"
const val SCREENSHOT_EVENT_CHANNEL = "com.flutterplaza.no_screenshot_streams"

class NoScreenshotPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware, EventChannel.StreamHandler {
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

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, SCREENSHOT_METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, SCREENSHOT_EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)

        initScreenshotObserver()
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        screenshotObserver?.let { context.contentResolver.unregisterContentObserver(it) }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        restoreScreenshotState()
    }

    override fun onDetachedFromActivityForConfigChanges() {}
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        restoreScreenshotState()
    }

    override fun onDetachedFromActivity() {}

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

    private fun initScreenshotObserver() {
        screenshotObserver = object : ContentObserver(Handler()) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                uri?.let {
                    if (it.toString().contains(MediaStore.Images.Media.EXTERNAL_CONTENT_URI.toString())) {
                        Log.d("ScreenshotProtection", "Screenshot detected")
                        updateSharedPreferencesState(it.path ?: "")
                    }
                }
            }
        }
    }

    private fun startListening() {
        screenshotObserver?.let {
            context.contentResolver.registerContentObserver(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, true, it)
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
        preferences.edit().putBoolean(PREF_KEY_SCREENSHOT, isSecure).apply()
    }

    private fun restoreScreenshotState() {
        Executors.newSingleThreadExecutor().execute {
            val isSecure = preferences.getBoolean(PREF_KEY_SCREENSHOT, false)

            // Post back to main thread to update UI flags
            activity?.runOnUiThread {
                if (isSecure) {
                    screenshotOff()
                } else {
                    screenshotOn()
                }
            }
        }
    }

    private fun updateSharedPreferencesState(screenshotData: String) {
        val jsonString = convertMapToJsonString(mapOf(
            PREF_KEY_SCREENSHOT to preferences.getBoolean(PREF_KEY_SCREENSHOT, false),
            SCREENSHOT_PATH to screenshotData,
            SCREENSHOT_TAKEN to screenshotData.isNotEmpty()
        ))
        if (lastSharedPreferencesState != jsonString) {
            hasSharedPreferencesChanged = true
            lastSharedPreferencesState = jsonString
        }
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