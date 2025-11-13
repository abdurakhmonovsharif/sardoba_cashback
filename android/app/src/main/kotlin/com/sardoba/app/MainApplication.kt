package com.sardoba.app

import android.app.Application
import android.util.Log
import com.yandex.mapkit.MapKitFactory
import com.sardoba.app.R
import io.flutter.FlutterInjector

class MainApplication : Application() {
  override fun onCreate() {
    super.onCreate()
    MapKitFactory.setLocale("ru_RU")
    val apiKey = readEnvValue("YANDEX_MAPKIT_API_KEY")
      ?: getString(R.string.yandex_mapkit_api_key)
    if (apiKey.isNotEmpty()) {
      MapKitFactory.setApiKey(apiKey)
    } else {
      Log.w("MainApplication", "Yandex MapKit API key is missing. Set yandex_mapkit_api_key in strings.xml")
    }
  }

  private fun readEnvValue(key: String): String? {
    return try {
      val loader = FlutterInjector.instance().flutterLoader()
      loader.ensureInitializationComplete(this, null)
      val assetKey = loader.lookupKeyForAsset(".env")
      assets.open(assetKey).bufferedReader().use { reader ->
        while (true) {
          val rawLine = reader.readLine() ?: break
          val line = rawLine.trim()
          if (line.isEmpty() || line.startsWith("#")) continue
          val parts = line.split("=", limit = 2)
          if (parts.size == 2 && parts[0].trim() == key) {
            return parts[1].trim().trim('"', '\'')
          }
        }
      }
      null
    } catch (error: Exception) {
      Log.w("MainApplication", "Failed to read $key from .env: ${error.message}")
      null
    }
  }
}
