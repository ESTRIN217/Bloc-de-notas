package com.estrin217.bloc_de_notas

import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ColorLens
import androidx.compose.material.icons.filled.DarkMode
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

        val initialDynamic = intent.getBooleanExtra("useDynamicColors", true)
        val initialTheme = intent.getStringExtra("themeMode") ?: "ThemeMode.system"

        setContent {
            var useDynamicColors by remember { mutableStateOf(initialDynamic) }
            var themeMode by remember { mutableStateOf(initialTheme) }

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
                            title = { Text("Configuración", fontWeight = FontWeight.SemiBold) },
                            navigationIcon = {
                                IconButton(onClick = { finishWithResult(useDynamicColors, themeMode) }) {
                                    Icon(Icons.Default.ArrowBack, contentDescription = "Regresar")
                                }
                            }
                        )
                    }
                ) { innerPadding ->
                    Column(
                        modifier = Modifier
                            .padding(innerPadding)
                            .fillMaxSize()
                            // El fondo de la pantalla debe contrastar sutilmente con las tarjetas
                            .background(MaterialTheme.colorScheme.surface) 
                            .verticalScroll(rememberScrollState())
                    ) {
                        Spacer(modifier = Modifier.height(16.dp))

                        // Título de la sección (Como "Interfaz" en tu imagen)
                        Text(
                            text = "Apariencia",
                            style = MaterialTheme.typography.labelLarge,
                            color = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.padding(start = 24.dp, bottom = 8.dp)
                        )

                        // Tarjeta agrupada que contiene las opciones
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp),
                            shape = RoundedCornerShape(24.dp), // Bordes bien redondeados
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)
                            ),
                            elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
                        ) {
                            Column(modifier = Modifier.padding(vertical = 8.dp)) {
                                
                                // Ítem 1: Colores Dinámicos
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

                                // Divisor sutil entre ítems del grupo
                                HorizontalDivider(
                                    modifier = Modifier.padding(horizontal = 24.dp),
                                    thickness = 1.dp, 
                                    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)
                                )

                                // Ítem 2: Modo oscuro
                                Column(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(horizontal = 16.dp, vertical = 12.dp)
                                ) {
                                    // Fila con el ícono y título para el modo oscuro
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        IconContainer(icon = Icons.Default.DarkMode)
                                        Spacer(modifier = Modifier.width(16.dp))
                                        Text("Modo oscuro", style = MaterialTheme.typography.bodyLarge)
                                    }
                                    
                                    Spacer(modifier = Modifier.height(16.dp))
                                    
                                    // Selector de botones que pediste separado
                                    ConnectedThemePicker(
                                        selectedMode = themeMode,
                                        onModeSelected = { themeMode = it }
                                    )
                                }
                            }
                        }
                        
                        Spacer(modifier = Modifier.height(24.dp))
                    }
                }
            }
        }
    }

    private fun finishWithResult(dynamic: Boolean, theme: String) {
        val resultIntent = Intent().apply {
            putExtra("useDynamicColors", dynamic) 
            putExtra("themeMode", theme)
        }
        setResult(RESULT_OK, resultIntent)
        finish()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        super.onBackPressed()
    }
}

// === COMPONENTES DE DISEÑO ===

// Nuevo componente para recrear el fondo redondeado de los íconos de la imagen
@Composable
fun IconContainer(icon: androidx.compose.ui.graphics.vector.ImageVector) {
    Surface(
        shape = RoundedCornerShape(12.dp), // Forma de rectángulo redondeado
        color = MaterialTheme.colorScheme.secondaryContainer,
        modifier = Modifier.size(40.dp)
    ) {
        Icon(
            imageVector = icon, 
            contentDescription = null, 
            tint = MaterialTheme.colorScheme.onSecondaryContainer,
            modifier = Modifier.padding(8.dp) // Tamaño del ícono dentro de su caja
        )
    }
}

@Composable
fun SettingsRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector, 
    title: String, 
    control: @Composable () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp), // Padding interno similar al de la imagen
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconContainer(icon = icon) // Usamos el contenedor que creamos arriba
            Spacer(modifier = Modifier.width(16.dp))
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
            
            val shape = when (index) {
                0 -> RoundedCornerShape(topStart = 24.dp, bottomStart = 24.dp)
                modes.size - 1 -> RoundedCornerShape(topEnd = 24.dp, bottomEnd = 24.dp)
                else -> RectangleShape
            }

            OutlinedButton(
                onClick = { onModeSelected(modeValue) },
                shape = shape,
                modifier = Modifier
                    .weight(1f)
                    .offset(x = if (index > 0) (-1 * index).dp else 0.dp), 
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