import UIKit
import Flutter
import YandexMapsMobile

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configureYandexMapKit()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configureYandexMapKit() {
    let apiKey = Bundle.main.object(forInfoDictionaryKey: "YANDEX_MAPKIT_API_KEY") as? String
    if let apiKey, !apiKey.isEmpty {
      YMKMapKit.setLocale("ru_RU")
      YMKMapKit.setApiKey(apiKey)
    } else {
#if DEBUG
      NSLog("⚠️ Yandex MapKit API key is missing. Set YANDEX_MAPKIT_API_KEY in Info.plist.")
#endif
    }
  }
}
