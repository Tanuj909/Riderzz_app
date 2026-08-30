import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Try to load Google Maps API key from .env file bundled in assets
    var apiKey = "YOUR_GOOGLE_MAPS_API_KEY"
    let envAssetKey = FlutterDartProject.lookupKey(forAsset: ".env")
    if let envPath = Bundle.main.path(forResource: envAssetKey, ofType: nil) {
      if let content = try? String(contentsOfFile: envPath, encoding: .utf8) {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
          let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
          if trimmed.hasPrefix("GOOGLE_MAPS_API_KEY=") {
            apiKey = trimmed.replacingOccurrences(of: "GOOGLE_MAPS_API_KEY=", with: "")
              .trimmingCharacters(in: .whitespacesAndNewlines)
            break
          }
        }
      }
    }
    GMSServices.provideAPIKey(apiKey)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
