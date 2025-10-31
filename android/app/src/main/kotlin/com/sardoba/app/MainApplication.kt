package com.sardoba.app

import android.app.Application
import android.util.Log
import com.yandex.mapkit.MapKitFactory
import com.sardoba.app.R

class MainApplication : Application() {
  override fun onCreate() {
    super.onCreate()
    MapKitFactory.setLocale("ru_RU")
    val apiKey = getString(R.string.yandex_mapkit_api_key)
    if (apiKey.isNotEmpty()) {
      MapKitFactory.setApiKey(apiKey)
    } else {
      Log.w("MainApplication", "Yandex MapKit API key is missing. Set yandex_mapkit_api_key in strings.xml")
    }
  }
}
