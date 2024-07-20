package com.flutterplaza.no_screenshot_example

import com.flutterplaza.no_screenshot.NoScreenshotPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        // Ensure your plugin registration is included if it's not auto-registered
        flutterEngine.plugins.add(NoScreenshotPlugin())
    }
}
