// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get helloWorld => 'Hello World!';

  @override
  String get flutterNotes => 'NOTEPAD';

  @override
  String get search => 'Search...';

  @override
  String get toggleView => 'Toggle View';

  @override
  String get sort => 'Sort';

  @override
  String get menu => 'Menu';

  @override
  String get home => 'Home';

  @override
  String get settings => 'Settings';

  @override
  String get addItem => 'Add Note';

  @override
  String selected(Object count) {
    return '$count selected';
  }

  @override
  String get select => 'Select';

  @override
  String get share => 'Share';

  @override
  String get delete => 'Delete';

  @override
  String get sortAlphabetically => 'Sort Alphabetically';

  @override
  String get sortByDate => 'Sort by Modification Date';

  @override
  String get customSort => 'Custom Sort';

  @override
  String get myNotes => 'My Notes';

  @override
  String get imageFromGallery => 'Image from gallery';

  @override
  String get title => 'Title';

  @override
  String get useDynamicColors => 'Use Dynamic Colors';

  @override
  String get themeMode => 'Mode dark';

  @override
  String get system => 'System';

  @override
  String get light => 'Off';

  @override
  String get dark => 'On';

  @override
  String get apariencia => 'Appearance';

  @override
  String get idioma => 'Language';

  @override
  String get informacion => 'Information';

  @override
  String get sobre => 'About';

  @override
  String get desarrolador => 'Developed by';

  @override
  String get enlaces => 'Useful links';

  @override
  String get repositorio => 'View repository';

  @override
  String get espanol => ' 🇪🇸 Spanish';

  @override
  String get ingles => ' 🇺🇸 English';

  @override
  String get venezolano => ' 🇻🇪 Spanish (Venezuela)';

  @override
  String get portugues => ' 🇵🇹 Portuguese';

  @override
  String get brasileno => ' 🇧🇷 Portuguese (Brazil)';

  @override
  String get texto_plano => 'Plain text (.txt)';

  @override
  String get markdown => 'Markdown (.md)';

  @override
  String get archivo_pdf => 'Archive PDF (.pdf)';

  @override
  String get html => 'Archive HTML (.HTML)';

  @override
  String get exportar_notas_como => 'Export notes as:';

  @override
  String get descripcion =>
      'A simple note-taking app built with Flutter, designed to be fast, intuitive, and easy to use. It allows you to create, edit, and organize your notes efficiently.';

  @override
  String get mit_license => 'MIT License';

  @override
  String get actualizador => 'Updater';

  @override
  String get registro_de_cambio => 'Changelog';

  @override
  String get version_actual => 'Current version';

  @override
  String get ajuste_de_actulizacion => 'Update settings';

  @override
  String get buscar_actualizaciones_automaticamente =>
      'Automatically check for updates';

  @override
  String get habilitar_notificaciones_de_actualizacion =>
      'Enable update notifications';

  @override
  String get buscar_actualizaciones => 'Check for updates';

  @override
  String get json_crudo => 'Raw JSON';

  @override
  String get system_default => 'Default (System)';

  @override
  String get etiquetas => 'Labels';

  @override
  String get archivados => 'Archived';

  @override
  String get papelera => 'Bin';

  @override
  String get nueva_version_disponible => 'New version available';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get lapiz => 'Pencil';

  @override
  String get resaltado => 'Highlighted';

  @override
  String get borrador => 'Eraser';

  @override
  String get eliminar_dibujo => 'Delete drawing';

  @override
  String appVersionFull(String version, String buildNumber, String platform) {
    return 'Version $version ($buildNumber) • $platform';
  }

  @override
  String get notesRestored => 'Notes restored';

  @override
  String get notesArchived => 'Notes archived';

  @override
  String get undo => 'Undo';

  @override
  String get welcomeNoteTitle => 'Welcome to Notepad!';

  @override
  String get exerciseNoteTitle => 'Workout Routine!';

  @override
  String get tagNotesTitle => 'Tag notes';

  @override
  String get noTagsCreated =>
      'No tags created. Create them from the side menu.';

  @override
  String get manageTags => 'Manage Tags';

  @override
  String get newTagHint => 'New tag...';

  @override
  String get tagExistsError => 'This tag already exists';

  @override
  String get renameTag => 'Rename Tag';

  @override
  String get renameTagLabel => 'New name';

  @override
  String get movedToTrash => 'Moved to trash';

  @override
  String get emptyTrashTitle => 'Empty trash?';

  @override
  String get emptyTrashMessage =>
      'All notes in the trash will be permanently deleted.';

  @override
  String get deleteForever => 'Delete permanently';

  @override
  String get restoreNote => 'Restore note';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get emptyTrashAction => 'Empty';

  @override
  String get unarchiveTooltip => 'Unarchive';

  @override
  String get archiveTooltip => 'Archive';

  @override
  String get tagTooltip => 'Label';

  @override
  String deleteTagTitle(String tag) {
    return 'Remove $tag';
  }

  @override
  String get deleteTagMessage =>
      'The label will be removed from all notes, but the notes will not be deleted.';

  @override
  String get json_subtitle => 'Raw format for backup';

  @override
  String get misNotasExportadas => 'My Exported Notes';

  @override
  String get untitled => 'WITHOUT TITLE';

  @override
  String get titleHtml => 'Exported notes';

  @override
  String get shareHtmlMessage => 'I share my notes in web format';

  @override
  String get colorFilterLabel => 'color';

  @override
  String get errorLoadingInfo => 'Error loading info';

  @override
  String get formatError => 'Format error';

  @override
  String get loading => 'Loading...';

  @override
  String get noteTagsTitle => 'Note tags';

  @override
  String get yourTags => 'Your tags:';

  @override
  String get done => 'Done';

  @override
  String get noteArchived => 'Archived note';

  @override
  String get noteUnarchived => 'Unarchived note';

  @override
  String get pdfExportHeader => 'Exporting from Notepad';

  @override
  String shareNoteMessage(String title) {
    return 'I\'m sharing my note with you: $title';
  }

  @override
  String get titleHint => 'Title';

  @override
  String get editorPlaceholder => 'Write something amazing...';

  @override
  String modifiedAt(String date) {
    return 'Modified on: $date';
  }

  @override
  String get stopRecording => 'Stop recording';

  @override
  String get recordVoiceNote => 'Record voice note';

  @override
  String get selectAudioFile => 'Select Audio File';
}
