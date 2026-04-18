package com.estrin217.bloc_de_notas

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

class SettingsActivity : ComponentActivity() {
    @OptIn(ExperimentalMaterial3Api::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Recibimos los valores que mandó Flutter
        val initialDynamicColors = intent.getBooleanExtra("useDynamicColors", true)
        val initialThemeMode = intent.getStringExtra("themeMode") ?: "ThemeMode.system"

        setContent {
            // Variables de estado en Compose
            var useDynamicColors by remember { mutableStateOf(initialDynamicColors) }
            var themeMode by remember { mutableStateOf(initialThemeMode) }

            MaterialTheme {
                Scaffold(
                    topBar = {
                        TopAppBar(
                            title = { Text("Ajustes") },
                            navigationIcon = {
                                IconButton(onClick = { returnDataToFlutter(useDynamicColors, themeMode) }) {
                                    Icon(Icons.Default.ArrowBack, contentDescription = "Regresar")
                                }
                            }
                        )
                    }
                ) { padding ->
                    Column(modifier = Modifier.padding(padding).padding(16.dp)) {
                        
                        Text("Apariencia", color = MaterialTheme.colorScheme.primary, style = MaterialTheme.typography.labelLarge)
                        Spacer(modifier = Modifier.height(8.dp))

                        // Tarjeta estilo "SettingsGroup" de tu Flutter original
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                        ) {
                            Column {
                                // Switch de Colores Dinámicos
                                Row(
                                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Icon(Icons.Default.Palette, contentDescription = null)
                                        Spacer(modifier = Modifier.width(16.dp))
                                        Text("Usar colores dinámicos")
                                    }
                                    Switch(
                                        checked = useDynamicColors,
                                        onCheckedChange = { useDynamicColors = it }
                                    )
                                }
                                
                                Divider()

                                // Selector de Tema (Simplificado para el ejemplo)
                                Row(
                                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Text("Modo de Tema")
                                    // Aquí puedes implementar un DropdownMenu o un SegmentedButton nativo
                                    Text(themeMode.replace("ThemeMode.", ""), style = MaterialTheme.typography.bodyMedium)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Método para devolver la información al presionar atrás
    private fun returnDataToFlutter(dynamicColors: Boolean, theme: String) {
        val resultIntent = Intent().apply {
            putExtra("useDynamicColors", dynamicColors)
            putExtra("themeMode", theme)
        }
        setResult(RESULT_OK, resultIntent)
        finish()
    }
    
    // Sobrescribimos el botón de retroceso físico del dispositivo
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Asegurarnos de guardar la info si usan el gesto de atrás del sistema
        // Para implementar esto correctamente en Compose moderno se usa BackHandler,
        // pero este método clásico te funcionará como puente rápido.
        super.onBackPressed() 
    }
}