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
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import android.view.WindowManager.LayoutParams
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
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


/** NoScreenshotPlugin */
class NoScreenshotPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
    EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private lateinit var preferences: SharedPreferences
    private var screenshotObserver: ContentObserver? = null
    private lateinit var eventChannel: EventChannel
    private val handler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null

    private var lastSharedPreferencesState: String = ""
    private fun convertMapToJsonString(map: Map<String, Any>): String {
        return JSONObject(map).toString()
    }

    private fun getCurrentSharedPreferencesState(
        screenshotData: String
    ): String {
        val map = mapOf(
            PREF_KEY_SCREENSHOT to preferences.getBoolean(PREF_KEY_SCREENSHOT, false),
            SCREENSHOT_PATH to screenshotData,
            SCREENSHOT_TAKEN to screenshotData.isNotEmpty()
        )
        val jsonString = convertMapToJsonString(map)
        if (lastSharedPreferencesState != jsonString) {
            hasSharedPreferencesChanged = true
        }
        return jsonString
    }

    private var hasSharedPreferencesChanged: Boolean = false


    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel =
            MethodChannel(
                flutterPluginBinding.binaryMessenger,
                SCREENSHOT_METHOD_CHANNEL
            )
        eventChannel =
            EventChannel(
                flutterPluginBinding.binaryMessenger,
                SCREENSHOT_EVENT_CHANNEL
            )
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        context = flutterPluginBinding.applicationContext
        preferences = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        initScreenshotObserver()
    }

    private val screenshotStream = object : Runnable {
        override fun run() {
            if (hasSharedPreferencesChanged) {
                // SharedPreferences values have changed, proceed with logic
                eventSink?.success(lastSharedPreferencesState)
                hasSharedPreferencesChanged = false
            }
            // Continue posting this runnable to keep checking periodically
            handler.postDelayed(this, 1000)
        }
    }


    private fun initScreenshotObserver() {
        screenshotObserver = object : ContentObserver(Handler()) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                if (uri != null && uri.toString()
                        .contains(MediaStore.Images.Media.EXTERNAL_CONTENT_URI.toString())
                ) {
                    Log.d("ScreenshotProtection", "Screenshot detected")
                    val screenshotPath = uri.path
                    if (screenshotPath != null) {
                        lastSharedPreferencesState =
                            getCurrentSharedPreferencesState(screenshotPath)
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

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            SCREENSHOT_OFF_CONST -> {
                val value = screenshotOff()
                lastSharedPreferencesState =
                    getCurrentSharedPreferencesState("")
                result.success(value)
            }

            SCREENSHOT_ON_CONST -> {
                val value = screenshotOn()
                lastSharedPreferencesState =
                    getCurrentSharedPreferencesState("")
                result.success(value)
            }

            TOGGLE_SCREENSHOT_CONST -> {
                val flags = activity?.window?.attributes?.flags
                if ((flags?.and(LayoutParams.FLAG_SECURE)) != 0) {
                    screenshotOn()
                } else {
                    screenshotOff()
                }
                lastSharedPreferencesState =
                    getCurrentSharedPreferencesState("")
                result.success(true)
            }

            START_SCREENSHOT_LISTENING_CONST -> {
                startListening()
                result.success("Listening started")
            }

            STOP_SCREENSHOT_LISTENING_CONST -> {
                stopListening()
                lastSharedPreferencesState =
                    getCurrentSharedPreferencesState("")
                result.success("Listening stopped")
            }

            else -> result.notImplemented()
        }
    }

    private fun screenshotOff(): Boolean {
        return try {
            activity?.window?.addFlags(LayoutParams.FLAG_SECURE)
            saveScreenshotState(true)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun screenshotOn(): Boolean {
        return try {
            activity?.window?.clearFlags(LayoutParams.FLAG_SECURE)
            saveScreenshotState(false)
            true
        } catch (e: Exception) {
            false
        }
    }


    private fun saveScreenshotState(isSecure: Boolean) {
        preferences.edit().putBoolean(PREF_KEY_SCREENSHOT, isSecure).apply()
    }


    private fun restoreScreenshotState() {
        // Restore screenshot state
        val isSecure = preferences.getBoolean(PREF_KEY_SCREENSHOT, false)
        if (isSecure) {
            screenshotOff()
        } else {
            screenshotOn()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        screenshotObserver?.let {
            context.contentResolver.unregisterContentObserver(it)
        }
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
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        handler.postDelayed(screenshotStream, 1000)
    }

    override fun onCancel(arguments: Any?) {
        handler.removeCallbacks(screenshotStream)
        eventSink = null
    }
}
