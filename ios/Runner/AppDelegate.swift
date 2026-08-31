import Flutter
import UIKit
import GoogleMaps
import CoreHaptics

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  var hapticEngine: CHHapticEngine?

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

    if let controller = window?.rootViewController as? FlutterViewController {
        let hapticChannel = FlutterMethodChannel(name: "com.riderzz.app/haptic",
                                                 binaryMessenger: controller.binaryMessenger)
        hapticChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "playBookingHaptic" {
                self?.playBookingHaptic()
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        })
    }

    createAndStartHapticEngine()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  func createAndStartHapticEngine() {
      guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
      do {
          hapticEngine = try CHHapticEngine()
          try hapticEngine?.start()
          
          hapticEngine?.resetHandler = { [weak self] in
              do {
                  try self?.hapticEngine?.start()
              } catch {
                  print("Failed to restart the haptic engine: \(error)")
              }
          }
      } catch {
          print("There was an error creating the haptic engine: \(error.localizedDescription)")
      }
  }

  func playBookingHaptic() {
      guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
      do {
          try hapticEngine?.start()
          
          let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
          let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
          
          let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
          let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.2)
          let event3 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.4)
          
          let pattern = try CHHapticPattern(events: [event1, event2, event3], parameters: [])
          let player = try hapticEngine?.makePlayer(with: pattern)
          try player?.start(atTime: CHHapticTimeImmediate)
      } catch {
          print("Failed to play haptic pattern: \(error.localizedDescription)")
      }
  }
}
