import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Clé lue depuis Info.plist, elle-même alimentée par
    // ios/Flutter/Secrets.xcconfig (non versionné).
    if let key = Bundle.main.object(forInfoDictionaryKey: "MAPS_API_KEY") as? String,
       !key.isEmpty, key != "VOTRE_CLE_IOS_ICI" {
      GMSServices.provideAPIKey(key)
    } else {
      NSLog("⚠️ MAPS_API_KEY absente — renseigner ios/Flutter/Secrets.xcconfig")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
