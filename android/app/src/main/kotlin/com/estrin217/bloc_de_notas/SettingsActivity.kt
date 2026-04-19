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
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

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
                            .background(MaterialTheme.colorScheme.surface)
                            .verticalScroll(rememberScrollState())
                    ) {
                        Spacer(modifier = Modifier.height(16.dp))

                        // Título de la sección
                        Text(
                            text = "Apariencia",
                            style = MaterialTheme.typography.labelLarge,
                            color = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.padding(start = 24.dp, bottom = 8.dp)
                        )

                        // Contenedor agrupado de la lista
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp),
                            shape = RoundedCornerShape(24.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)
                            ),
                            elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
                        ) {
                            Column(modifier = Modifier.padding(vertical = 8.dp)) {
                                
                                // Ítem 1: Colores Dinámicos usando ListItem
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

                                HorizontalDivider(
                                    modifier = Modifier.padding(horizontal = 24.dp),
                                    thickness = 1.dp, 
                                    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)
                                )

                                // Ítem 2: Título de Modo Oscuro usando ListItem
                                ListItem(
                                    leadingContent = {
                                        IconContainer(icon = Icons.Default.DarkMode)
                                    },
                                    headlineContent = {
                                        Text("Modo oscuro", style = MaterialTheme.typography.bodyLarge)
                                    },
                                    colors = ListItemDefaults.colors(
                                        containerColor = Color.Transparent // Fondo transparente para ver la Card
                                    )
                                )
                                
                                // Selector de botones rellenados
                                ConnectedThemePicker(
                                    selectedMode = themeMode,
                                    onModeSelected = { themeMode = it }
                                )
                                Spacer(modifier = Modifier.height(8.dp))
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

// === COMPONENTES REUTILIZABLES ===

@Composable
fun IconContainer(icon: androidx.compose.ui.graphics.vector.ImageVector) {
    Surface(
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.secondaryContainer,
        modifier = Modifier.size(40.dp)
    ) {
        Icon(
            imageVector = icon, 
            contentDescription = null, 
            tint = MaterialTheme.colorScheme.onSecondaryContainer,
            modifier = Modifier.padding(8.dp)
        )
    }
}

// Implementación de ListItem que proporcionaste
@Composable
fun SettingsRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector, 
    title: String, 
    control: @Composable () -> Unit
) {
    ListItem(
        leadingContent = {
            IconContainer(icon = icon)
        },
        headlineContent = { 
            Text(title, style = MaterialTheme.typography.bodyLarge) 
        },
        trailingContent = {
            control()
        },
        // Hacemos el fondo transparente para que se mezcle con la Card grupal
        colors = ListItemDefaults.colors(
            containerColor = Color.Transparent
        )
    )
}

// Implementación de tus botones rellenados conectados
@Composable
fun ConnectedThemePicker(selectedMode: String, onModeSelected: (String) -> Unit) {
    val modes = listOf(
        "ThemeMode.light" to "Apagado",
        "ThemeMode.system" to "Sistema",
        "ThemeMode.dark" to "Encendido"
    )

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(2.dp) // El espaciado que solicitaste
    ) {
        modes.forEachIndexed { index, (modeValue, label) ->
            val isSelected = selectedMode == modeValue
            
            val shape = when (index) {
                0 -> RoundedCornerShape(topStart = 20.dp, bottomStart = 20.dp)
                modes.size - 1 -> RoundedCornerShape(topEnd = 20.dp, bottomEnd = 20.dp)
                else -> RectangleShape
            }

            Button(
                onClick = { onModeSelected(modeValue) },
                modifier = Modifier.weight(1f),
                shape = shape,
                contentPadding = PaddingValues(0.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (isSelected) 
                        MaterialTheme.colorScheme.primaryContainer 
                    else 
                        MaterialTheme.colorScheme.surfaceVariant,
                    contentColor = if (isSelected) 
                        MaterialTheme.colorScheme.onPrimaryContainer 
                    else 
                        MaterialTheme.colorScheme.onSurfaceVariant
                )
            ) {
                Text(label, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}