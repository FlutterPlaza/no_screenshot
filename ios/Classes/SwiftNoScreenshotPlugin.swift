import Flutter
import UIKit


public class SwiftNoScreenshotPlugin: NSObject, FlutterPlugin{
    static var field = UITextField()
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.flutterplaza.no_screenshot", binaryMessenger: registrar.messenger())
        let instance = SwiftNoScreenshotPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.field =  UIApplication.shared.keyWindow!.initializeUITextField(field: field)
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if(call.method == "screenshotOff"){
            SwiftNoScreenshotPlugin.field.isSecureTextEntry = true
        }else if(call.method == "screenshotOn"){
            SwiftNoScreenshotPlugin.field.isSecureTextEntry = false
        }else if(call.method == "toggleScreenshot"){
            SwiftNoScreenshotPlugin.field.isSecureTextEntry = SwiftNoScreenshotPlugin.field.isSecureTextEntry
            ? false
            : true
        }
        result(true)
    }
}

extension UIWindow {
    func initializeUITextField(field :UITextField) -> UITextField{
        self.addSubview(field)
        field.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        field.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.layer.superlayer?.addSublayer(field.layer)
        field.layer.sublayers?.first?.addSublayer(self.layer)
        return field;
    }
}
