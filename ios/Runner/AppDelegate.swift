import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let badgeChannelName = "payhive/app_badge"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let badgeChannel = FlutterMethodChannel(
        name: badgeChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      badgeChannel.setMethodCallHandler { [weak self] call, result in
        self?.handleBadgeMethodCall(call: call, result: result)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleBadgeMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "setBadgeCount" else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard
      let arguments = call.arguments as? [String: Any],
      let count = arguments["count"] as? Int
    else {
      result(
        FlutterError(
          code: "invalid_arguments",
          message: "Expected integer `count` argument.",
          details: nil
        )
      )
      return
    }

    DispatchQueue.main.async {
      UIApplication.shared.applicationIconBadgeNumber = max(0, count)
      result(nil)
    }
  }
}
