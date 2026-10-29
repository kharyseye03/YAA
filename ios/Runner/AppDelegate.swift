import Flutter
import UIKit
import GoogleMaps
import UserNotifications

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

    // Notifications : flutter_local_notifications a besoin que
    // quelqu'un soit délégué du centre de notifications pour afficher
    // une bannière alors que l'app est déjà au premier plan — iOS ne
    // le fait pas de lui-même. On l'installe avant l'enregistrement
    // des greffons, pour que firebase_messaging puisse ensuite passer
    // devant et relayer ce qu'il doit relayer.
    UNUserNotificationCenter.current().delegate = self

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
