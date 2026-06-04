# Bloc de notas

Una solución de toma de notas avanzada, multiplataforma y de alto rendimiento desarrollada con Flutter. Esta aplicación ofrece una experiencia de usuario moderna centrada en la personalización, la localización y una edición de texto robusta.

[![Latest release](https://img.shields.io/github/v/release/ESTRIN217/Bloc-de-notas?style=for-the-badge&labelColor=0d1117)](https://github.com/ESTRIN217/Bloc-de-notas/releases)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

## 📸 Capturas de Pantalla

Para mantener la consistencia visual y un diseño limpio en cualquier pantalla, puedes visualizar la interfaz aquí:

<table align="center">
  <tr>
    <td align="center">
      <img src="URL_DE_TU_IMAGEN_1.png" width="220" alt="Vista Principal (Material 3)"/>
      <br><b>Vista Principal</b>
    </td>
    <td align="center">
      <img src="URL_DE_TU_IMAGEN_2.png" width="220" alt="Editor Enriquecido"/>
      <br><b>Editor Flotante</b>
    </td>
    <td align="center">
      <img src="URL_DE_TU_IMAGEN_3.png" width="220" alt="Búsqueda Dinámica"/>
      <br><b>Búsqueda y Filtros</b>
    </td>
  </tr>
</table>

> 💡 *Nota técnica sobre imágenes:* En este repositorio, para ajustar el tamaño de las imágenes de forma personalizada, utilizamos la etiqueta HTML `<img>` con el atributo `width="220"` dentro de tablas, lo que permite un alineado perfecto y responsivo en GitHub.

## 🧠 Filosofía del Proyecto

Este desarrollo se rige bajo pilares fundamentales que garantizan la libertad del usuario y la calidad del software:

- **Soberanía de Datos (Client-Side Absolute):** El usuario es el dueño absoluto de su información. La aplicación no depende de servidores centralizados de terceros para el almacenamiento de notas; en su lugar, integra sincronización directa con la **propia cuota de Google Drive del usuario**, asegurando privacidad y control total.
- **Material Design 3 & Consistencia Visual:** Fiel apego a las directrices de diseño modernas de Google, priorizando el uso de componentes limpios y un sistema coherente de iconos *outlined*.
- **Código Limpio (DRY - Don't Repeat Yourself):** Arquitectura enfocada en evitar la redundancia de código, facilitando el mantenimiento, la escalabilidad multiplataforma y la optimización del rendimiento en hardware móvil.
- **Inclusión y Localización:** Un ecosistema diseñado desde el primer día para ser accesible globalmente mediante traducciones nativas minuciosas.

## Características Destacadas

### Interfaz y Experiencia de Usuario (UI/UX)

- **Material Design 3:** Implementación completa de las últimas directrices de diseño de Google, incluyendo componentes refinados en las pantallas de configuración y "Acerca de".
- **Color Dinámico (Material You)**: Adaptación inteligente del esquema cromático basado en el fondo de pantalla del dispositivo en Android compatible.
- **Modos de Visualización:** Soporte nativo para temas claro, oscuro y sincronización automática con el sistema.
- **Gestión de Vistas:** Organización flexible mediante cuadrículas visuales (con soporte de reordenación por arrastre) o listas compactas.
- **Tipografía de Alta Calidad:** Integración con Google Fonts para una legibilidad superior.

### Edición Multimedia Avanzada

- **Motor de Texto Enriquecido:** Impulsado por la biblioteca flutter_quill para una edición compleja y profesional con herramientas flotantes optimizadas.
- **Integración de Medios**: Soporte nativo para insertar y visualizar imágenes y vídeos directamente en el cuerpo de las notas.
- **Herramientas Creativas**: Módulo de dibujo integrado que permite realizar bocetos y guardarlos directamente en el esquema de datos JSON de la nota.
- **Notas de Audio:** Capacidad para adjuntar y gestionar grabaciones de audio mediante bloques personalizados.
- **Formatos de Exportación:** Soporte para compartir o exportar documentos en formatos industriales como PDF, Markdown, HTML y JSON con compatibilidad web extendida.

### Localización e Internacionalización (i18n)

- **Soporte Multilingüe Extendido:** Interfaz totalmente traducida al Inglés, Español (Estándar y Venezolano) y Portugués (Estándar y Brasileño).
- **Gestión de Idiomas:** Selector manual de idioma integrado en el panel de configuración del usuario con consistencia global en la app.

### Rendimiento y Sistema

- **Actualizaciones Dinámicas:** Sistema interno mejorado para verificar y descargar nuevas versiones de la aplicación, notificando de manera inteligente en el *drawer*, ajustes y el actualizador.
- **Información de Arquitectura:** En lugar de etiquetas universales estáticas, la app detecta dinámicamente la arquitectura de hardware del dispositivo móvil (ej. ARM64-V8A) o el navegador en plataformas web.
- **Sincronización con GitHub:** Visualización en tiempo real del registro de cambios (*changelog*) directamente desde el repositorio oficial.
- **Persistencia de Datos:** Almacenamiento local eficiente de preferencias y configuraciones mediante shared_preferences.
- **Accesibilidad**: Función de Texto a Voz (TTS) para lectura automatizada de notas.

## Instalación

1. Asegúrate de tener Flutter instalado. Para obtener instrucciones, consulta la [documentación de Flutter](https://flutter.dev/docs/get-started/install).
2. Clona el repositorio:

   ```sh
   git clone https://github.com/ESTRIN217/Bloc-de-notas.git
   ```

3. Navega al directorio del proyecto:

   ```sh
   cd Bloc-de-notas
   ```

4. Instala las dependencias:

   ```sh
   flutter pub get
   ```
  
## Uso

1. Ejecuta la aplicación:

   ```sh
   flutter run
   ```

2. ¡Comienza a tomar notas!

## Contribuciones

¡Las contribuciones son bienvenidas! Si tienes alguna idea para una nueva característica o has encontrado un error, abre un [issue](https://github.com/ESTRIN217/Bloc-de-notas/issues) o envía un [pull request](https://github.com/ESTRIN217/Bloc-de-notas/pulls).

## Licencia

Este proyecto está licenciado bajo la Licencia MIT. Consulta el archivo [LICENSE](LICENSE) para obtener más detalles.

---

<p align="center">
  Desarrollado con pasión por <b>ESTRIN217</b>.
</p>

<p align="center">
  Hecho con ❤️ en Venezuela.
</p>