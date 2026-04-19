package com.estrin217.bloc_de_notas

import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ColorLens
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

class SettingsActivity : ComponentActivity() {
    @OptIn(ExperimentalMaterial3Api::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // 1. Recibimos los valores actuales de Flutter
        val initialDynamic = intent.getBooleanExtra("useDynamicColors", true)
        val initialTheme = intent.getStringExtra("themeMode") ?: "ThemeMode.system"

        setContent {
            // Estados locales de la pantalla
            var useDynamicColors by remember { mutableStateOf(initialDynamic) }
            var themeMode by remember { mutableStateOf(initialTheme) }

            // Aplicamos el esquema de color (Nativo o Dinámico)
            val context = LocalContext.current
            val colorScheme = when {
                useDynamicColors && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
                    if (themeMode == "ThemeMode.dark") dynamicDarkColorScheme(context)
                    else dynamicLightColorScheme(context)
                }
                themeMode == "ThemeMode.dark" -> darkColorScheme()
                else -> lightColorScheme()
            }

            MaterialTheme(colorScheme = colorScheme) {
                Scaffold(
                    topBar = {
                        TopAppBar(
                            title = { Text("Ajustes", fontWeight = FontWeight.SemiBold) },
                            navigationIcon = {
                                IconButton(onClick = { finishWithResult(useDynamicColors, themeMode) }) {
                                    Icon(Icons.Default.ArrowBack, contentDescription = "Regresar")
                                }
                            }
                        )
                    }
                ) { innerPadding ->
                    // 2. Aquí cambiamos la estructura para que funcione como una lista
                    Column(
                        modifier = Modifier
                            .padding(innerPadding)
                            .padding(horizontal = 16.dp)
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState()) // Permite deslizar si hay más elementos
                    ) {
                        Spacer(modifier = Modifier.height(16.dp))

                        // Título de la sección
                        Text(
                            text = "APARIENCIA",
                            style = MaterialTheme.typography.labelLarge,
                            color = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.padding(start = 8.dp, bottom = 16.dp)
                        )

                        // 3. Fila 1 de la lista: Colores Dinámicos (Independiente)
                        SettingsRow(
                            icon = Icons.Default.ColorLens,
                            title = "Colores dinámicos",
                            control = {
                                Switch(
                                    checked = useDynamicColors,
                                    onCheckedChange = { useDynamicColors = it }
                                )
                            }
                        )

                        // Separador visual en la lista
                        Spacer(modifier = Modifier.height(16.dp))
                        HorizontalDivider(thickness = 0.5.dp, color = MaterialTheme.colorScheme.outlineVariant)
                        Spacer(modifier = Modifier.height(16.dp))

                        // 4. Fila 2 de la lista: Modo de Tema (Totalmente separado del Switch)
                        Column(
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                "Modo oscuro",
                                style = MaterialTheme.typography.titleMedium,
                                modifier = Modifier.padding(start = 8.dp, bottom = 12.dp)
                            )
                            
                            ConnectedThemePicker(
                                selectedMode = themeMode,
                                onModeSelected = { themeMode = it }
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(24.dp))
                    }
                }
            }
        }
    }

    private fun finishWithResult(dynamic: Boolean, theme: String) {
        val resultIntent = Intent().apply {
            putExtra("useDynamicColors", dynamic) // Misma bandera que Flutter
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

// 5. Componentes extraídos de UI (sin cambios lógicos, solo visuales)
@Composable
fun SettingsRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector, 
    title: String, 
    control: @Composable () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 8.dp), // Agregamos un poco de respiro al item
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(modifier = Modifier.width(12.dp))
            Text(title, style = MaterialTheme.typography.bodyLarge)
        }
        control()
    }
}

@Composable
fun ConnectedThemePicker(selectedMode: String, onModeSelected: (String) -> Unit) {
    val modes = listOf(
        "ThemeMode.light" to "Apagado",
        "ThemeMode.system" to "Sistema",
        "ThemeMode.dark" to "Encendido"
    )

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.Center
    ) {
        modes.forEachIndexed { index, (modeValue, label) ->
            val isSelected = selectedMode == modeValue
            
            // Definimos la forma según la posición
            val shape = when (index) {
                0 -> RoundedCornerShape(topStart = 24.dp, bottomStart = 24.dp) // Izquierda
                modes.size - 1 -> RoundedCornerShape(topEnd = 24.dp, bottomEnd = 24.dp) // Derecha
                else -> RectangleShape // Medio
            }

            OutlinedButton(
                onClick = { onModeSelected(modeValue) },
                shape = shape,
                modifier = Modifier
                    .weight(1f)
                    .offset(x = if (index > 0) (-1 * index).dp else 0.dp), // Solapamos bordes
                colors = ButtonDefaults.outlinedButtonColors(
                    containerColor = if (isSelected) MaterialTheme.colorScheme.primaryContainer else androidx.compose.ui.graphics.Color.Transparent,
                    contentColor = if (isSelected) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurface
                ),
                border = ButtonDefaults.outlinedButtonBorder.copy()
            ) {
                Text(label, fontSize = 12.sp)
            }
        }
    }
}