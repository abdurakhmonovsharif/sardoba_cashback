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
    let apiKey = envValue(for: "YANDEX_MAPKIT_API_KEY")
      ?? Bundle.main.object(forInfoDictionaryKey: "YANDEX_MAPKIT_API_KEY") as? String
    if let apiKey, !apiKey.isEmpty {
      YMKMapKit.setLocale("ru_RU")
      YMKMapKit.setApiKey(apiKey)
    } else {
#if DEBUG
      NSLog("⚠️ Yandex MapKit API key is missing. Set YANDEX_MAPKIT_API_KEY in Info.plist.")
#endif
    }
  }

  private func envValue(for key: String) -> String? {
    guard let path = envFilePath(),
          let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
      return nil
    }

    for rawLine in contents.split(whereSeparator: \.isNewline) {
      let line = rawLine.trimmingCharacters(in: .whitespaces)
      if line.isEmpty || line.hasPrefix("#") {
        continue
      }
      let parts = line.split(separator: "=", maxSplits: 1).map {
        $0.trimmingCharacters(in: .whitespacesAndNewlines)
      }
      if parts.count == 2 && parts[0] == key {
        return parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
      }
    }

    return nil
  }

  private func envFilePath() -> String? {
    let assetKey = FlutterDartProject.lookupKey(forAsset: ".env")
    return Bundle.main.path(forResource: assetKey, ofType: nil)
  }
}
