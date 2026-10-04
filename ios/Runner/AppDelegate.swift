import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // 오늘 식단을 기록했는지에 따라 홈 화면 앱 아이콘을 바꾼다 (빈 그릇 ↔ 채운 그릇).
    let appIconChannel = FlutterMethodChannel(
      name: "kr.chaerin.dietapp/app_icon",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    appIconChannel.setMethodCallHandler { call, result in
      guard call.method == "setFilled" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard UIApplication.shared.supportsAlternateIcons else {
        result(nil)
        return
      }
      let filled = (call.arguments as? [String: Any])?["filled"] as? Bool ?? false
      let name = filled ? "AppIcon-Filled" : nil
      if UIApplication.shared.alternateIconName == name {
        result(nil)
        return
      }
      UIApplication.shared.setAlternateIconName(name) { error in
        if let error = error {
          print("앱 아이콘을 바꾸지 못했어요: \(error)")
        }
      }
      result(nil)
    }
  }
}
