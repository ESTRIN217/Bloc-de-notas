package com.estrin217.bloc_de_notas

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.estrin217.bloc_de_notas/settings"
    private var pendingFlutterResult: MethodChannel.Result? = null
    private val SETTINGS_REQUEST_CODE = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openNativeSettings") {
                pendingFlutterResult = result
                
                val intent = Intent(this, SettingsActivity::class.java).apply {
                    putExtra("useDynamicColors", call.argument<Boolean>("useDynamicColors"))
                    putExtra("themeMode", call.argument<String>("themeMode"))
                    putExtra("languageCode", call.argument<String>("languageCode"))
                }
                
                // Usamos el método tradicional compatible con FlutterActivity
                startActivityForResult(intent, SETTINGS_REQUEST_CODE)
            } else {
                result.notImplemented()
            }
        }
    }

    // Recibimos el resultado aquí
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == SETTINGS_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val updatedSettings = mapOf(
                    "useDynamicColors" to data.getBooleanExtra("useDynamicColors", true),
                    "themeMode" to data.getStringExtra("themeMode"),
                    "languageCode" to data.getStringExtra("languageCode")
                )
                pendingFlutterResult?.success(updatedSettings)
            } else {
                pendingFlutterResult?.success(null)
            }
            pendingFlutterResult = null
        }
    }
}
