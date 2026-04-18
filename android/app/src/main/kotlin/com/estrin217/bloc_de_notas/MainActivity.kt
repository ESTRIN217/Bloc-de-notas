package com.estrin217.bloc_de_notas

import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.estrin217.bloc_de_notas/settings"
    private var pendingFlutterResult: MethodChannel.Result? = null

    // Registramos un lanzador para esperar el resultado de SettingsActivity
    private val settingsLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        if (result.resultCode == RESULT_OK) {
            val data = result.data
            val updatedSettings = mapOf(
                "useDynamicColors" to data?.getBooleanExtra("useDynamicColors", true),
                "themeMode" to data?.getStringExtra("themeMode"),
                "languageCode" to data?.getStringExtra("languageCode")
            )
            // Devolvemos los datos a Flutter
            pendingFlutterResult?.success(updatedSettings)
        } else {
            // Si el usuario simplemente retrocedió sin cambiar nada
            pendingFlutterResult?.success(null)
        }
        pendingFlutterResult = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openNativeSettings") {
                pendingFlutterResult = result
                
                val intent = Intent(this, SettingsActivity::class.java).apply {
                    // Pasamos los valores actuales de Flutter a la Actividad Nativa
                    putExtra("useDynamicColors", call.argument<Boolean>("useDynamicColors"))
                    putExtra("themeMode", call.argument<String>("themeMode"))
                    putExtra("languageCode", call.argument<String>("languageCode"))
                }
                
                settingsLauncher.launch(intent)
            } else {
                result.notImplemented()
            }
        }
    }
}