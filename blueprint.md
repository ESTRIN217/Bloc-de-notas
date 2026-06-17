# Blueprint: Blog de notas

## 1. Descripción general

Este documento describe el diseño y las características de una aplicación moderna e intuitiva para tomar notas con Flutter. La aplicación proporciona una interfaz flexible y fácil de usar para crear, Gestiona y organiza notas, con funciones avanzadas de personalización y localización.

## 2. Características por versión

### 2.1. Versión 3.0.0

- **Temas e interfaz de usuario avanzados:**
  - **Modos de tema:** Compatibilidad total con los modos **claro y oscuro**, además de una configuración del **sistema** para sincronizar con el sistema operativo.
  - **Color dinámico:** En las versiones de Android compatibles (Material You), la combinación de colores de la aplicación se puede generar dinámicamente a partir del fondo de pantalla del usuario.
  - **Tipografía personalizada:** Integración con **Google Fonts** para una apariencia de texto pulida y uniforme.
  - **Persistencia de la configuración:** Todas las preferencias del usuario, incluidos el tema, el idioma y el orden de clasificación, se guardan entre sesiones de la aplicación mediante `shared_preferences`.
- **Internacionalización (i10n):**
  - **Soporte multilingüe:** La interfaz de usuario está totalmente localizada para **inglés** y **español**.
  - **Selección de idioma:** Los usuarios pueden cambiar manualmente el idioma de la aplicación desde la pantalla de configuración.
- **Editor de texto enriquecido mejorado (Flutter Quill):**
  - El editor personalizado anterior ha sido reemplazado por la potente biblioteca `flutter_quill`, que proporciona una experiencia de edición más robusta y con más funciones.
- **Conversión de texto a voz:**
  - **Accesibilidad:** Una función integrada de conversión de texto a voz puede leer las notas en voz alta.

### 2.2. Versión 2.0.0 (Características integradas y mejoradas en v3.0)

- **Mejoras en el editor:**
  - **Funcionalidad de deshacer/rehacer:** Deshacer y rehacer los cambios de texto y estilo.
  - **Personalización del fondo:** Cambia el color de fondo de una nota o establece una imagen de fondo desde la galería.
  - **Formato de texto:** Formato básico de texto, como tamaño de fuente, negrita y cursiva.
  - **Listas de verificación:** Crea listas de verificación interactivas dentro de las notas.
  
*Nota: Estas funciones formaban parte originalmente de un editor personalizado y han sido reemplazadas por la implementación de `flutter_quill` en la versión 3.0.*

### 2.3. Versión 1.0.0 (Características principales)

- **Pantalla principal y diseño:**
  - **Modos de doble visualización:** Cambia entre la vista de lista y la vista de cuadrícula.
  - **Clasificación personalizable:** Ordena las notas alfabéticamente, por fecha de modificación o utiliza un orden personalizado arrastrando y soltando.
  - **Búsqueda funcional:** Filtrado de notas en tiempo real por título o contenido.
- **Editor de notas:**
  - **Edición de texto enriquecido:** Una pantalla dedicada para editar notas.
  - **Ahorro automático:** Los cambios se guardan automáticamente cuando el usuario sale del editor.
  - **Manejo de notas vacías:** Las notas en blanco se descartan automáticamente..
- **Selección y acción masivas:**
  - **Modo de selección:** Mantén pulsada una nota para entrar en el modo de selección y elegir varios elementos.
  - **Barra de aplicaciones contextual:** Aparece en el modo de selección para permitir compartir o eliminar en bloque las notas seleccionadas.

### 2.4 Versión 4.0.0

- **Mejoras de la interfaz gráfica:**
    - **Configuración:** Rediseño completo implementando las directrices de Material Design 3\.
    - **Acerca de:** Interfaz de información actualizada al estándar de Material Design 3\.
    - **Pantalla principal:** Las tarjetas ahora renderizan y muestran vistas previas dinámicas del texto enriquecido\.
    - **Editor:** Experiencia visual optimizada con fondo extendido y botones de la barra de herramientas con estilo contorneado \(_outlined_\)\.
- **Internacionalización \(i18n\):**
    - **Español \(Venezuela\):** Localización regional añadida\.
    - **Portugués \(Brasil\):** Localización regional añadida\.
    - **Portugués:** Traducción estándar añadida\.
- **Sistema de actualizaciones:**
    - **Verificación automática:** Nueva funcionalidad para comprobar y descargar la última versión directamente \(exclusivo para versiones móviles; no aplicable en la web\)\.
    - **Pantalla dedicada:** Interfaz de actualización integrada para gestionar las descargas\.
- **Historial de versiones \(Changelog\):**
    - **Visor in\-app:** Integración para consultar los cambios recientes dentro de la aplicación\.
    - **Carga dinámica:** Nuevo cuadro de diálogo inferior \(_bottom sheet_\) que obtiene los datos del registro de versiones directamente desde GitHub\.
- **Mejoras del editor multimedia:**
    - **Soporte de imágenes:** Inserción directa en las notas \(integrado vía flutter\_quill\_extensions\)\.
    - **Soporte de vídeo:** Reproducción e inserción en el cuerpo de la nota \(integrado vía flutter\_quill\_extensions\)\.
    - **Soporte de audio:** Capacidad para incluir notas de voz mediante bloques personalizados \(quill\.CustomBlockEmbed\)\.
    - **Soporte de dibujo:** Nuevo lienzo integrado en el editor con persistencia de datos directa en el archivo JSON principal \(quill\.CustomBlockEmbed\)\.
- **Nuevos formatos de exportación:**
    - **Opciones de uso compartido:** Capacidad ampliada para exportar notas en formato PDF, Markdown, HTML y JSON en crudo \(soportado mediante extensiones oficiales de renderizado\)\.

### 2.5 🚀 Novedades en Bloc de notas v5\.0\.0
### 🎨 Interfaz y Experiencia de Usuario \(Material 3\)
- **Rediseño Visual:** Interfaz mejorada siguiendo las directrices de _Material Design 3_ con un enfoque limpio y el uso consistente de iconos _outlined_\.
- **Nueva Barra de Búsqueda:** Implementación de una Search Bar dinámica y limpia \(vía SearchDelegate\)\. Ahora incluye _chips_ de filtrado rápido por etiquetas, archivadas y color de fondo\.
- **Animaciones Fluídas:** Añadidas transiciones y animaciones más vivas al iniciar la aplicación y al abrir o interactuar con tus notas\.
- **Herramientas Flotantes:** La barra de herramientas del editor ahora flota sobre el contenido y el teclado, optimizando el espacio en pantalla\.

### 🗂️ Organización y Gestión de Notas
- **Notas Fijadas y Favoritos:** Añadida la posibilidad de fijar notas importantes en la parte superior y un nuevo sistema de favoritos\.
- **Categorías y Etiquetas:** Crea listas personalizadas y asigna múltiples etiquetas a tus notas para mantener todo en orden\.
- **Archivo y Papelera:** Mueve las notas que no uses al archivo para limpiar tu pantalla principal, o envíalas a la papelera antes de eliminarlas definitivamente\.
- **Reorganización Visual:** Ahora puedes reordenar tus notas arrastrándolas \(Drag & Drop\) directamente en la vista de cuadrícula \(_GridView_\)\. Al activar la selección, la interfaz se adapta limpiamente\.

### 📝 Editor y Rendimiento
- **Mejoras en el Editor:** Integración de _Embed Timestamp_ para registrar marcas de tiempo y optimizaciones en la escritura\.
- **Escritura Inteligente:** Corrección de palabras y sistema de autocompletado mejorado\.

### 🔒 Privacidad y Copias de Seguridad
- **Filosofía Client\-Side:** Tus datos son tuyos\. Implementación de copias de seguridad locales y sincronización en la nube utilizando **tu propia cuota de Google Drive**, garantizando privacidad absoluta\.

### 🌐 Optimización para la Versión Web
- **Navegación Mejorada:** Sistema de retorno inteligente que te devuelve a la pantalla de inicio antes de salir de la aplicación\.
- **Compatibilidad Multiplataforma:** Los métodos para compartir notas en formatos **PDF** y **HTML** ahora son totalmente compatibles con la web\.
- **Exportación Completa:** El método para compartir en **JSON** ahora envía la estructura e información interna completa de la nota\.

### 🛠️ Sistema y Mejoras Internas
- **Actualizaciones Inteligentes:** Nuevo sistema de notificaciones de actualización integrado en el _Drawer_, en los ajustes y en el actualizador de la plataforma correspondiente\.
- **Información de Compilación Dinámica:** Se eliminó la etiqueta genérica "Universal"\. Ahora la app detecta y muestra la arquitectura exacta del dispositivo \(ej\. _ARM64\-V8A_\), la plataforma actual o la versión del navegador en la web\.
- **Globalización:** Consistencia mejorada en el sistema de selección de idiomas y traducciones\.
- **Estabilidad:** Corrección de errores menores y optimizaciones internas de rendimiento\.

## 3. Calidad del código y control de versiones

### 3.1. Dependencias

- El proyecto utiliza `flutter_quill`, `provider`, `dynamic_color`, `google_fonts`, `shared_preferences`, `flutter_tts`, y más para respaldar su conjunto de funciones avanzadas.

### 3.2. Control de versiones

- **Versión actual:** `6.0.0+1`

---

# 🗺️ Hoja de Ruta — Bloc de Notas v6.0.0

## 1. 🌐 Traducir toda la interfaz (i18n completo)

| Ítem | Estado | Prioridad |
|------|--------|-----------|
| Revisar que TODOS los textos visibles usen `AppLocalizations.of(context)` | Completado | Alta |
| Eliminar strings hardcodeadas en `main.dart`, `editor_screen.dart`, `settings_screen.dart`, widgets, etc. | Completado | Alta |
| Verificar traducciones faltantes en `app_localizations_en.dart`, `app_localizations_es.dart`, `app_localizations_pt.dart` | Completado | Alta |
| Asegurar que los idiomas `es-VE` y `pt-BR` tengan cobertura completa | Completado | Media |
| Agregar detección automática de idioma del sistema como fallback | Pendiente | Media |

## 2. 🎨 Consistencia visual (estilo outlined)

| Ítem | Estado | Prioridad |
|------|--------|-----------|
| Auditar TODOS los iconos en la app y asegurar que usen variantes `_outlined` | Completado | Alta |
| Revisar `main.dart`: `AppBar`, `Drawer`, `FloatingActionButton`, `SearchBar` | Completado | Alta |
| Revisar `editor_screen.dart`: toolbar, botones de acción, diálogos | Completado | Alta |
| Revisar `note_item_widget.dart`: tarjetas, iconos de pin/fav/star | Completado | Alta |
| Revisar `settings_screen.dart`, `about_screen.dart`, `backup_screen.dart` | Completado | Alta |
| Revisar `create_category_dialog.dart`, `changelog_widget.dart` | Pendiente | Media |
| Asegurar botones `FilledButton`/`TextButton` sigan MD3 con estilo outlined donde corresponda | Pendiente | Media |

## 3. 📱 Compatibilidad Web + Android

| Ítem | Estado | Prioridad |
|------|--------|-----------|
| Verificar `kIsWeb` en todas las ramas de `main.dart` (compartir PDF/HTML, imports `dart:io`) | Pendiente | Alta |
| Probar `flutter build web` y `flutter build apk` sin errores | Pendiente | Alta |
| Revisar dependencias con `dart:io` protegidas con `kIsWeb` (editor_screen, note_item_widget) | Pendiente | Alta |
| Asegurar que `flutter_quill_extensions` funcione en ambas plataformas | Pendiente | Media |
| Verificar `file_picker`, `image_picker`, `record` en web con guards | Pendiente | Media |

## 4. 🧹 Principio DRY (Don't Repeat Yourself)

| Ítem | Estado | Prioridad |
|------|--------|-----------|
| Extraer lógica repetida de `togglePinMultiple`, `toggleFavoriteMultiple`, `toggleArchiveMultiple` en un helper genérico | Completado | Alta |
| Refactorizar `_batchUpdateItemTags` en `notes_provider.dart` para cubrir más campos | Pendiente | Alta |
| Unificar `reorderNotes` y `reorderItemByIndex` en un solo método de reordenamiento | Pendiente | Alta |
| Eliminar código duplicado en `_shareAsText`, `_shareAsMarkdown`, `_shareAsHtml` con un builder común | Pendiente | Media |
| Centralizar la creación de `SnackBar` con "Undo" en un único helper | Pendiente | Media |
| Unificar los diálogos de confirmación (`_confirmDeleteTag`, `_emptyTrash`, `deleteMultiple`) | Pendiente | Media |

## 5. ⚡ Eficiencia y carga de la app

| Ítem | Estado | Prioridad |
|------|--------|-----------|
| Implementar `Future.wait` para carga paralela de datos en `loadAllData` | Completado | Alta |
| Usar `const` constructors donde sea posible (widgets, iconos, estilos) | Pendiente | Alta |
| Reemplazar `context.watch` en `_buildListView`/`_buildGridView` por `Consumer` local | Pendiente | Media |
| Lazy loading de `GoogleFonts` (usar `GoogleFonts.notoSansTextTheme` ya está, verificar impacto) | Pendiente | Media |
| Evitar reconstrucciones innecesarias con `RepaintBoundary` en la lista de notas | Pendiente | Media |
| Agregar `const` en los `EdgeInsets`, `SizedBox`, estilos repetidos | Pendiente | Baja |

## 6. 📋 Logcat detallado y completo

| Ítem | Estado | Prioridad |
|------|--------|-----------|
| Crear un `LogService` singleton con niveles V/D/I/W/E | Completado | Alta |
| Implementar `DeveloperLog` class con método `log(level, message, [error, stackTrace])` | Completado | Alta |
| Integrar `dart:developer` para logs estructurados visibles en DevTools | Completado | Alta |
| Crear wrapper: `Log.v()`, `Log.d()`, `Log.i()`, `Log.w()`, `Log.e()` | Completado | Alta |
| Reemplazar todos los `debugPrint` y `print` esparcidos por el código con el nuevo LogService | Completado | Alta |

### Niveles de prioridad

| Nivel | Tag | Uso |
|-------|-----|-----|
| **V** (Verbose) | `Log.v()` | Traza detallada de desarrollo (flujo interno) |
| **D** (Debug) | `Log.d()` | Depuración: valores de variables, puntos de control |
| **I** (Info) | `Log.i()` | Éxito: "Nota guardada", "Backup completado" |
| **W** (Warning) | `Log.w()` | Advertencia: "Conexión lenta", "Actualización no disponible" |
| **E** (Error) | `Log.e()` | Error grave: excepciones, crashes, fallos de I/O |

## 7. 🔍 Rastreo de errores en tiempo real

| Ítem | Estado | Prioridad |
|------|--------|-----------|
| Capturar excepciones no controladas con `FlutterError.onError` + `PlatformDispatcher.instance.onError` | Completado | Alta |
| Envolver operaciones asíncronas con try-catch y `Log.e()` | Completado | Alta |
| Loggear crashes con stacktrace completo en el nuevo LogService | Completado | Alta |
| Mostrar notificación visual si ocurre un error crítico (SnackBar/Banner) | Pendiente | Media |

## 8. 🔄 Monitoreo de flujo de funciones

| Ítem | Estado | Prioridad |
|------|--------|-----------|
| Agregar `Log.v("→ [NombreFunción] iniciado")` al inicio de métodos clave | Completado | Alta |
| Agregar `Log.v("← [NombreFunción] completado")` al finalizar | Completado | Alta |
| Monitorear flujo: `loadAllData`, `handleEditorResult`, `saveNotesList`, `reorderNotes` | Completado | Alta |
| Monitorear acciones del usuario: crear/editar/eliminar/archivar notas | Completado | Media |

## 9. 🎯 Bugfix: Reordenamiento por arrastre en vista de lista

### Problema detectado

El reordenamiento drag & drop en `ReorderableListView.builder` (línea 1829 de `main.dart`) tiene inconsistencias cuando:

1. Hay notas **fijadas (pinned)** — el índice visual (`sortedItems`) no coincide con el índice real (`items`)
2. Se cambia de vista (lista ↔ cuadrícula) después de reordenar
3. Se alterna entre filtros (etiquetas, categorías, favoritos) y luego se vuelve al inicio

### Causa raíz

El método `reorderItemByIndex` en `notes_provider.dart:623` trabaja con `sortedItems` (que aplica `_applySort` separando pinned), pero intenta mapear los índices de vuelta a la lista cruda `items`. Cuando hay pinned items, el mapeo es incorrecto porque:

- `sortedItems = [...pinnedNotes, ...normalNotes]` 
- `items` tiene el orden crudo sin separar
- El cálculo de `realNewIndex` puede caer en una posición equivocada

| Ítem | Estado | Prioridad |
|------|--------|-----------|
| Refactorizar `reorderItemByIndex` para usar `items` directamente en lugar de `sortedItems` | Completado | **Crítica** |
| Extraer el `currentSourceItems` filtrado y usarlo en `onReorderItem` en lugar de `sortedItems` | Completado | **Crítica** |
| Deshabilitar reordenamiento visual en vistas filtradas (tags, categorías, favoritos, archivo) | Completado | Alta |
| Sincronizar el estado de reorden entre `_buildListView` y `_buildGridView` | Completado | Alta |
| Agregar tests de reordenamiento con pinned items | Pendiente | Alta |
| Usar `ListenableBuilder` o `ValueNotifier` para el estado `canReorder` y evitar `context.watch` en build | Pendiente | Media |

### Plan de acción para el bug

```
1. En main.dart: 
   - Envolver el área reordenable con un Consumer<NotesProvider> 
   - Pasar currentSourceItems filtrado (sin pinned processing duplicado)
2. En notes_provider.dart:
   - Simplificar reorderItemByIndex para operar sobre 'items' directamente 
   - Agregar validación: si currentSortMethod != SortMethod.custom, no reordenar
3. En note_item_widget.dart:
   - Asegurar que ReorderableDragStartListener solo aparezca en vista "Inicio" 
   - con sortMethod == custom y sin filtros activos
```

---

## Resumen de prioridades

| Prioridad | Ítems |
|-----------|-------|
| 🔴 Crítica | Bugfix reordenamiento (sección 9) |
| 🟠 Alta | i18n completo, consistencia outlined, DRY en providers, LogService, rastreo errores |
| 🟡 Media | Compatibilidad web, eficiencia de carga, monitoreo de flujo |
| 🟢 Baja | Optimizaciones menores (const, RepaintBoundary) |

**Estado general:** 8/9 secciones completadas. Pendiente: compatibilidad Web + Android (sección 3).
