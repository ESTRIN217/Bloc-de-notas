// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get helloWorld => '¡Hola, mundo!';

  @override
  String get flutterNotes => 'BLOC DE NOTAS';

  @override
  String get search => 'Buscar...';

  @override
  String get toggleView => 'Cambiar vista';

  @override
  String get sort => 'Ordenar';

  @override
  String get menu => 'Menú';

  @override
  String get home => 'Inicio';

  @override
  String get settings => 'Ajustes';

  @override
  String get addItem => 'Añadir nota';

  @override
  String selected(Object count) {
    return '$count seleccionados';
  }

  @override
  String get select => 'Selecionar';

  @override
  String get share => 'Compartir';

  @override
  String get delete => 'Eliminar';

  @override
  String get sortAlphabetically => 'Ordenar alfabéticamente';

  @override
  String get sortByDate => 'Ordenar por fecha de modificación';

  @override
  String get customSort => 'Orden personalizado';

  @override
  String get myNotes => 'Mis notas';

  @override
  String get imageFromGallery => 'Imagen de la galería';

  @override
  String get title => 'Título';

  @override
  String get useDynamicColors => 'Usar colores dinámicos';

  @override
  String get themeMode => 'Modo oscuro';

  @override
  String get system => 'Sistema';

  @override
  String get light => 'Desactivado';

  @override
  String get dark => 'Activado';

  @override
  String get apariencia => 'Apariencia';

  @override
  String get idioma => 'Idioma';

  @override
  String get informacion => 'Información';

  @override
  String get sobre => 'Acerca de la aplicación';

  @override
  String get desarrolador => 'Desarrollada por';

  @override
  String get enlaces => 'Enlaces útiles';

  @override
  String get repositorio => 'Ver repositorio';

  @override
  String get espanol => '🇪🇸 Español';

  @override
  String get ingles => '🇺🇸 Inglés';

  @override
  String get venezolano => '🇻🇪 Español (Venezuela)';

  @override
  String get portugues => '🇵🇹 Portugués';

  @override
  String get brasileno => '🇧🇷 Portugués (Brasil)';

  @override
  String get texto_plano => 'Texto plano (.txt)';

  @override
  String get markdown => 'Markdown (.md)';

  @override
  String get archivo_pdf => 'Archivo PDF (.pdf)';

  @override
  String get html => 'Archivo HTML (.HTML)';

  @override
  String get exportar_notas_como => 'Exportar notas como:';

  @override
  String get descripcion =>
      'Una aplicación de notas sencilla y fácil de usar, con soporte para texto enriquecido e imágenes.';

  @override
  String get mit_license => 'Licencia MIT';

  @override
  String get actualizador => 'Actualizador';

  @override
  String get registro_de_cambio => 'Registro de cambios';

  @override
  String get version_actual => 'Version actual';

  @override
  String get ajuste_de_actulizacion => 'Ajustes de actualización';

  @override
  String get buscar_actualizaciones_automaticamente =>
      'Buscar actualizaciones automáticamente';

  @override
  String get habilitar_notificaciones_de_actualizacion =>
      'Habilitar notificaciones de actualización';

  @override
  String get buscar_actualizaciones => 'Buscar actualizaciones';

  @override
  String get json_crudo => 'JSON sin formato';

  @override
  String get system_default => 'Predeterminado (Sistema)';

  @override
  String get etiquetas => 'Etiquetas';

  @override
  String get archivados => 'Archivadas';

  @override
  String get papelera => 'Papelera';

  @override
  String get nueva_version_disponible => 'Nueva versión disponible';

  @override
  String appVersion(String version) {
    return 'Versión: $version';
  }

  @override
  String get lapiz => 'Lápiz';

  @override
  String get resaltado => 'Resaltado';

  @override
  String get borrador => 'Borrador';

  @override
  String get eliminar_dibujo => 'Eliminar dibujo';

  @override
  String appVersionFull(String version, String buildNumber, String platform) {
    return 'Versión $version ($buildNumber) • $platform';
  }

  @override
  String get notesRestored => 'Notas restauradas';

  @override
  String get notesArchived => 'Notas archivadas';

  @override
  String get undo => 'Deshacer';

  @override
  String get welcomeNoteTitle => '¡Bienvenido a Bloc de notas!';

  @override
  String get exerciseNoteTitle => '¡Rutina de ejercicios!';

  @override
  String get tagNotesTitle => 'Etiquetar notas';

  @override
  String get noTagsCreated =>
      'No hay etiquetas creadas. Créalas desde el menú lateral.';

  @override
  String get manageTags => 'Gestionar Etiquetas';

  @override
  String get newTagHint => 'Nueva etiqueta...';

  @override
  String get tagExistsError => 'Esta etiqueta ya existe';

  @override
  String get renameTag => 'Renombrar Etiqueta';

  @override
  String get renameTagLabel => 'Nuevo nombre';

  @override
  String get movedToTrash => 'Movido a la papelera';

  @override
  String get emptyTrashTitle => '¿Vaciar papelera?';

  @override
  String get emptyTrashMessage =>
      'Se eliminarán permanentemente todas las notas en la papelera.';

  @override
  String get deleteForever => 'Borrar definitivamente';

  @override
  String get restoreNote => 'Restablecer nota';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get close => 'Cerrar';

  @override
  String get emptyTrashAction => 'Vaciar';

  @override
  String get unarchiveTooltip => 'Desarchivar';

  @override
  String get archiveTooltip => 'Archivar';

  @override
  String get tagTooltip => 'Etiquetar';

  @override
  String deleteTagTitle(String tag) {
    return 'Eliminar $tag';
  }

  @override
  String get deleteTagMessage =>
      'La etiqueta se quitará de todas las notas, pero las notas no se borrarán.';

  @override
  String get json_subtitle => 'Formato crudo para respaldo';

  @override
  String get misNotasExportadas => 'Mis Notas Exportadas';

  @override
  String get untitled => 'Sin título';

  @override
  String get titleHtml => 'Notas Exportadas';

  @override
  String get shareHtmlMessage => 'Te comparto mis notas en formato Web';

  @override
  String get colorFilterLabel => 'Color';

  @override
  String get errorLoadingInfo => 'Error al cargar info';

  @override
  String get formatError => 'Error de formato';

  @override
  String get loading => 'Cargando...';

  @override
  String get noteTagsTitle => 'Etiquetas de la nota';

  @override
  String get yourTags => 'Tus etiquetas:';

  @override
  String get done => 'Listo';

  @override
  String get noteArchived => 'Nota archivada';

  @override
  String get noteUnarchived => 'Nota desarchivada';

  @override
  String get pdfExportHeader => 'Exportación desde Bloc de notas';

  @override
  String shareNoteMessage(String title) {
    return 'Te comparto mi nota: $title';
  }

  @override
  String get titleHint => 'Titulo';

  @override
  String get editorPlaceholder => 'Escribe algo increíble...';

  @override
  String modifiedAt(String date) {
    return 'Modificado el: $date';
  }

  @override
  String get stopRecording => 'Detener grabación';

  @override
  String get recordVoiceNote => 'Grabar nota de voz';

  @override
  String get selectAudioFile => 'Seleccionar archivo de audio';

  @override
  String get eliminarEtiqueta => 'Eliminar etiqueta';

  @override
  String get ordenar => 'Ordenar';

  @override
  String ultima(String version) {
    return 'Última versión disponible: $version';
  }

  @override
  String get ocultarRegistroDeCambios => 'Ocultar registro de cambios';

  @override
  String get verRegistroDeCambios => 'Ver registro de cambios';

  @override
  String get actualizacionDisponible => 'Actualización disponible';

  @override
  String get actualizacionesDeLaApp => 'Actualizaciones de la app';

  @override
  String get chaneldescripcion => 'Ya tienes la última versión';

  @override
  String get desing => 'Hecho con ❤️ en Venezuela';
}

/// The translations for Spanish Castilian, as used in Venezuela (`es_VE`).
class AppLocalizationsEsVe extends AppLocalizationsEs {
  AppLocalizationsEsVe() : super('es_VE');

  @override
  String get helloWorld => '¡Hola, mundo!';

  @override
  String get flutterNotes => 'BLOC DE NOTAS';

  @override
  String get search => 'Busca algo...';

  @override
  String get toggleView => 'Cambiar vista';

  @override
  String get sort => 'Ordenar';

  @override
  String get menu => 'Menú';

  @override
  String get home => 'Inicio';

  @override
  String get settings => 'Ajustes';

  @override
  String get addItem => 'Añadir nota';

  @override
  String selected(Object count) {
    return '$count seleccionados';
  }

  @override
  String get select => 'Selecionar';

  @override
  String get share => 'Compartir';

  @override
  String get delete => 'Eliminar';

  @override
  String get sortAlphabetically => 'Ordenar alfabéticamente';

  @override
  String get sortByDate => 'Ordenar por fecha de modificación';

  @override
  String get customSort => 'Orden personalizado';

  @override
  String get myNotes => 'Mis notas';

  @override
  String get imageFromGallery => 'Imagen de la galería';

  @override
  String get title => 'Título';

  @override
  String get useDynamicColors => 'Usar colores dinámicos';

  @override
  String get themeMode => 'Modo oscuro';

  @override
  String get system => 'Sistema';

  @override
  String get light => 'Apagado';

  @override
  String get dark => 'Encendido';

  @override
  String get apariencia => 'Apariencia';

  @override
  String get idioma => 'Idioma';

  @override
  String get informacion => 'Información';

  @override
  String get sobre => 'Sobre la aplicación';

  @override
  String get desarrolador => 'Desarrollado por';

  @override
  String get enlaces => 'Enlaces útiles';

  @override
  String get repositorio => 'Ver repositorio';

  @override
  String get espanol => '🇪🇸 Español';

  @override
  String get ingles => '🇺🇸 Inglés';

  @override
  String get venezolano => '🇻🇪 Español (Venezuela)';

  @override
  String get portugues => '🇵🇹 Portugués';

  @override
  String get brasileno => '🇧🇷 Portugués (Brasil)';

  @override
  String get texto_plano => 'Texto plano (.txt)';

  @override
  String get markdown => 'Markdown (.md)';

  @override
  String get archivo_pdf => 'Archivo PDF (.pdf)';

  @override
  String get html => 'Archivo HTML (.HTML)';

  @override
  String get exportar_notas_como => 'Exportar notas como:';

  @override
  String get descripcion =>
      'Una aplicación de notas simple y fácil de usar, con soporte para texto enriquecido, imágenes.';

  @override
  String get mit_license => 'Licencia MIT';

  @override
  String get actualizador => 'Actualizador';

  @override
  String get registro_de_cambio => 'Registro de cambios';

  @override
  String get version_actual => 'Version actual';

  @override
  String get ajuste_de_actulizacion => 'Ajustes de actualización';

  @override
  String get buscar_actualizaciones_automaticamente =>
      'Buscar actualizaciones automáticamente';

  @override
  String get habilitar_notificaciones_de_actualizacion =>
      'Habilitar notificaciones de actualización';

  @override
  String get buscar_actualizaciones => 'Buscar actualizaciones';

  @override
  String get json_crudo => 'JSON sin formato';

  @override
  String get system_default => 'Predeterminado (Sistema)';

  @override
  String get etiquetas => 'Etiquetas';

  @override
  String get archivados => 'Archivadas';

  @override
  String get papelera => 'Papelera';

  @override
  String get nueva_version_disponible => 'Nueva versión disponible';

  @override
  String appVersion(String version) {
    return 'Versión: $version';
  }

  @override
  String get lapiz => 'Lápiz';

  @override
  String get resaltado => 'Resaltado';

  @override
  String get borrador => 'Borrador';

  @override
  String get eliminar_dibujo => 'Eliminar dibujo';

  @override
  String appVersionFull(String version, String buildNumber, String platform) {
    return 'Versión $version ($buildNumber) • $platform';
  }

  @override
  String get notesRestored => 'Notas restauradas';

  @override
  String get notesArchived => 'Notas archivadas';

  @override
  String get undo => 'Echar para atrás';

  @override
  String get welcomeNoteTitle => '¡Bienvenido a Bloc de notas!';

  @override
  String get exerciseNoteTitle => '¡Rutina de ejercicios!';

  @override
  String get tagNotesTitle => 'Etiquetar notas';

  @override
  String get noTagsCreated =>
      'No hay etiquetas creadas. Créalas desde el menú lateral.';

  @override
  String get manageTags => 'Gestionar Etiquetas';

  @override
  String get newTagHint => 'Nueva etiqueta...';

  @override
  String get tagExistsError => 'Esa etiqueta ya la tienes';

  @override
  String get renameTag => 'Renombrar Etiqueta';

  @override
  String get renameTagLabel => 'Nuevo nombre';

  @override
  String get movedToTrash => 'Se fue a la papelera';

  @override
  String get emptyTrashTitle => '¿Vas a vaciar la papelera?';

  @override
  String get emptyTrashMessage =>
      'Se eliminarán permanentemente todas las notas en la papelera.';

  @override
  String get deleteForever => 'Borrar definitivamente';

  @override
  String get restoreNote => 'Restablecer nota';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get close => 'Cerrar';

  @override
  String get emptyTrashAction => 'Vaciar';

  @override
  String get unarchiveTooltip => 'Desarchivar';

  @override
  String get archiveTooltip => 'Archivar';

  @override
  String get tagTooltip => 'Etiquetar';

  @override
  String deleteTagTitle(String tag) {
    return 'Eliminar $tag';
  }

  @override
  String get deleteTagMessage =>
      'La etiqueta se quitará de todas las notas, pero las notas no se borrarán.';

  @override
  String get json_subtitle => 'Formato crudo para respaldo';

  @override
  String get misNotasExportadas => 'Mis Notas Exportadas';

  @override
  String get untitled => 'Sin título';

  @override
  String get titleHtml => 'Notas Exportadas';

  @override
  String get shareHtmlMessage => 'Te comparto mis notas en formato Web';

  @override
  String get colorFilterLabel => 'Color';

  @override
  String get errorLoadingInfo => 'Error al cargar info';

  @override
  String get formatError => 'Error de formato';

  @override
  String get loading => 'Cargando...';

  @override
  String get noteTagsTitle => 'Etiquetas de la nota';

  @override
  String get yourTags => 'Tus etiquetas:';

  @override
  String get done => 'Listo';

  @override
  String get noteArchived => 'Nota archivada';

  @override
  String get noteUnarchived => 'Nota desarchivada';

  @override
  String get pdfExportHeader => 'Exportación desde Bloc de notas';

  @override
  String shareNoteMessage(String title) {
    return 'Te comparto mi nota: $title';
  }

  @override
  String get titleHint => 'Titulo';

  @override
  String get editorPlaceholder => 'Escribe algo increíble...';

  @override
  String modifiedAt(String date) {
    return 'Modificado el: $date';
  }

  @override
  String get stopRecording => 'Detener grabación';

  @override
  String get recordVoiceNote => 'Grabar nota de voz';

  @override
  String get selectAudioFile => 'Seleccionar archivo de audio';

  @override
  String get eliminarEtiqueta => 'Eliminar etiqueta';

  @override
  String get ordenar => 'Ordenar';

  @override
  String ultima(String version) {
    return 'Última versión disponible: $version';
  }

  @override
  String get ocultarRegistroDeCambios => 'Ocultar registro de cambios';

  @override
  String get verRegistroDeCambios => 'Ver registro de cambios';

  @override
  String get actualizacionDisponible => 'Actualización disponible';

  @override
  String get actualizacionesDeLaApp => 'Actualizaciones de la app';

  @override
  String get chaneldescripcion => 'Ya tienes la última versión';

  @override
  String get desing => 'Hecho con ❤️ en Venezuela';
}
