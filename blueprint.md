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

- **Versión actual:** `5.0.0+1`
