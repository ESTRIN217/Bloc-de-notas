//@file:OptIn(ExperimentalMaterial3Api::class)
//package com.estrin217.bloc_de_notas

//import android.content.Intent
//import android.os.Bundle
//import androidx.activity.ComponentActivity
//import androidx.activity.compose.setContent
//import androidx.activity.enableEdgeToEdge
//import androidx.compose.foundation.background
//import androidx.compose.foundation.layout.*
//import androidx.compose.foundation.rememberScrollState
//import androidx.compose.foundation.shape.RoundedCornerShape
//import androidx.compose.foundation.verticalScroll
//import androidx.compose.material.icons.Icons
//import androidx.compose.material.icons.automirrored.filled.ArrowBack
//import androidx.compose.material.icons.filled.*
//import androidx.compose.material3.*
//import androidx.compose.runtime.*
//import androidx.compose.ui.Modifier
//import androidx.compose.ui.graphics.Color
//import androidx.compose.ui.graphics.vector.ImageVector
//import androidx.compose.ui.text.font.FontWeight
//import androidx.compose.ui.unit.dp
//import androidx.compose.material3.ButtonGroupDefaults
//import androidx.compose.material3.ToggleButton


//class SettingsActivity : ComponentActivity() {

    //override fun onCreate(savedInstanceState: Bundle?) {
        //super.onCreate(savedInstanceState)
        //enableEdgeToEdge()

        //val initialDynamic = intent.getBooleanExtra("useDynamicColors", true)
        //val initialTheme = intent.getStringExtra("themeMode") ?: "system"

        //setContent {
           // var useDynamicColors by remember { mutableStateOf(initialDynamic) }
            //var themeMode by remember { mutableStateOf(initialTheme) }
            //val scrollState = rememberScrollState()

            //MaterialTheme {
              //  Scaffold(
                //    topBar = {
                  //      TopAppBar(
                    //        title = { Text("Configuración", fontWeight = FontWeight.SemiBold) },
                      //      navigationIcon = {
                        //        IconButton(onClick = { finish() }) {
                          //          Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Atrás")
                            //    }
                        //    }
                        //)
                    //}
            //    ) { innerPadding ->
              //      Column(
                //        modifier = Modifier
                  //          .padding(innerPadding)
                    //        .fillMaxSize()
                      //      .background(MaterialTheme.colorScheme.surface)
                        //    .verticalScroll(scrollState)
                          //  .padding(bottom = 24.dp)
                //    ) {
                        
                        // SECCIÓN: APARIENCIA
                  //      SectionTitle("Apariencia")
                    //    SegmentedContainer {
                      //      SettingsListItem(
                        //        icon = Icons.Default.Palette,
                          //      title = "Colores dinámicos",
                            //    trailing = {
                              //      Switch(
                                //        checked = useDynamicColors,
                                  //      onCheckedChange = { useDynamicColors = it }
                                //    )
                            //    }
                        //    )
                          //  SettingsDivider()
                            //ListItem(
                              //  leadingContent = { IconContainer(Icons.Default.DarkMode) },
                            //    headlineContent = { Text("Modo oscuro") },
                              //  colors = ListItemDefaults.colors(containerColor = Color.Transparent)
                        //    )
                          //  ThemePickerRow(
                            //    selectedMode = themeMode,
                              //  onModeSelected = { themeMode = it }
                            //)
                        //}

                        // SECCIÓN: INFORMACIÓN (Actualizador, Registro, Acerca de)
                        //SectionTitle("Información")
                        //SegmentedContainer {
                            // 1. Actualizador
                          //  SettingsListItem(
                            //    icon = Icons.Default.Update,
                              //  title = "Actualizar aplicación",
                                //subtitle = "Buscar nuevas versiones",
                            //    onClick = { /* Abrir UpdaterScreen */ }
                            //)
                            //SettingsDivider()

                            // 2. Registro de cambios
                            //SettingsListItem(
                              //  icon = Icons.Default.History,
                                //title = "Registro de cambios",
                                //subtitle = "Novedades de la versión 4.1.0",
                                //onClick = { /* Mostrar changelog */ }
                            //)
                            //SettingsDivider()

                            // 3. Acerca de
                            //SettingsListItem(
                              //  icon = Icons.Default.Info,
                                //title = "Acerca de",
                            //subtitle = "Información del desarrollador y licencias",
                              //  onClick = { /* Abrir AboutScreen */ }
                        //    )
                //}

                        // SECCIÓN: AYUDA (Opcional, separada para limpieza)
                  //      SectionTitle("Soporte")
                    //    SegmentedContainer {
                      //      SettingsListItem(
                        //        icon = Icons.Default.HelpOutline,
                          //      title = "Ayuda y comentarios",
                            //    onClick = { /* Enviar feedback */ }
                            //)
                        //}
                //    }
                //}
            //}
        //}
    //}
//}

// === COMPONENTES UI REUTILIZABLES ===

//@Composable
//fun SectionTitle(text: String) {
  //  Text(
    //    text = text,
      //  style = MaterialTheme.typography.labelLarge,
        //color = MaterialTheme.colorScheme.primary,
        //modifier = Modifier.padding(start = 28.dp, top = 24.dp, bottom = 8.dp)
    //)
//}

//@Composable
//fun SegmentedContainer(content: @Composable ColumnScope.() -> Unit) {
  //  Card(
    //    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
      //  shape = RoundedCornerShape(28.dp),
        //colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerHigh),
        //elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        //content = content
    //)
//}

//@Composable
//fun SettingsListItem(
  //  icon: ImageVector,
    //title: String,
    //subtitle: String? = null,
    //onClick: (() -> Unit)? = null,
    //trailing: @Composable (() -> Unit)? = null
//) {
  //  ListItem(
    //    modifier = if (onClick != null) Modifier.fillMaxWidth() else Modifier,
      //  leadingContent = { IconContainer(icon) },
        //headlineContent = { Text(title, style = MaterialTheme.typography.bodyLarge) },
        //supportingContent = subtitle?.let { { Text(it) } },
        //trailingContent = trailing,
        //colors = ListItemDefaults.colors(containerColor = Color.Transparent)
    //)
//}

//@Composable
//fun IconContainer(icon: ImageVector) {
   // Surface(
     //   shape = RoundedCornerShape(12.dp),
       // color = MaterialTheme.colorScheme.secondaryContainer,
        //modifier = Modifier.size(40.dp)
    //) {
      //  Box(contentAlignment = androidx.compose.ui.Alignment.Center) {
        //    Icon(
          //      imageVector = icon,
            //    contentDescription = null,
              //  tint = MaterialTheme.colorScheme.onSecondaryContainer,
                //modifier = Modifier.size(20.dp)
            //)
        //}
    //}
//}

//@Composable
//fun SettingsDivider() {
  //  HorizontalDivider(
    //    modifier = Modifier.padding(horizontal = 24.dp),
      //  thickness = 0.5.dp,
        //color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
    //)
//}

//@OptIn(ExperimentalMaterial3Api::class)
//@Composable
//fun ThemePickerRow(selectedMode: String, onModeSelected: (String) -> Unit) {
  //  val options = listOf("light" to "Claro", "system" to "Sistema", "dark" to "Oscuro")
    //Row(
      //  modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 12.dp),
        //horizontalArrangement = Arrangement.spacedBy(ButtonGroupDefaults.ConnectedSpaceBetween)
    //) {
      //  options.forEachIndexed { index, (value, label) ->
        //    val isSelected = selectedMode == value
          //  ToggleButton(
            //    checked = isSelected,
              //  onCheckedChange = { onModeSelected(value) },
                //modifier = Modifier.weight(1f),
                //shapes = when (index) {
                  //  0 -> ButtonGroupDefaults.connectedLeadingButtonShapes()
                //    options.lastIndex -> ButtonGroupDefaults.connectedTrailingButtonShapes()
                  //  else -> ButtonGroupDefaults.connectedMiddleButtonShapes()
                //}
            //) {
              //  if (isSelected) {
                //    Icon(Icons.Default.Check, null, modifier = Modifier.size(16.dp))
                  //  Spacer(Modifier.width(4.dp))
                //}
                //Text(label, style = MaterialTheme.typography.labelMedium)
            //}
        //}
    //}
//}