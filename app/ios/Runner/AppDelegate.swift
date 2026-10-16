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
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PlatformMetadata")!
    let channel = FlutterMethodChannel(
      name: "six_minute_walk_test/platform_metadata",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "getCommitHash" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let url = Bundle.main.url(forResource: "build_metadata", withExtension: "json"),
        let data = try? Data(contentsOf: url),
        let metadata = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
      else {
        result(nil)
        return
      }
      result(metadata["commitHash"] as? String)
    }
  }
}
