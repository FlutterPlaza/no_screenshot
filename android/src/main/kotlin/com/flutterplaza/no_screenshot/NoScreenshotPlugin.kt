package com.flutterplaza.no_screenshot

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.view.WindowManager.LayoutParams
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

const val SCREENSHOT_ON_CONST = "screenshotOn"
const val SCREENSHOT_OFF_CONST = "screenshotOff"
const val TOGGLE_SCREENSHOT_CONST = "toggleScreenshot"

/** NoScreenshotPlugin */
class NoScreenshotPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var activity: Activity

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel =
            MethodChannel(flutterPluginBinding.binaryMessenger, "com.flutterplaza.no_screenshot")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext

    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) =
        when (call.method) {
            SCREENSHOT_OFF_CONST -> {
                val value: Boolean = screenshotOff()
                result.success(value)
            }
            SCREENSHOT_ON_CONST -> {
                val value = screenshotOn()

                result.success(value)
            }
            TOGGLE_SCREENSHOT_CONST -> {
                val flags: Int = activity.window.attributes.flags
                if ((flags and LayoutParams.FLAG_SECURE) != 0) {
                    screenshotOn()
                } else {
                    screenshotOff()
                }
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }

    private fun screenshotOff(): Boolean {
        try {
            activity.window.addFlags(LayoutParams.FLAG_SECURE)
            return true
        } catch (e: Exception) {
            return false
        }
    }

    private fun screenshotOn() : Boolean{
        try {
            activity.window.clearFlags(LayoutParams.FLAG_SECURE)
            return true
        } catch (e: Exception) {
            return false
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity

    }

    override fun onDetachedFromActivity() {
    }
}
