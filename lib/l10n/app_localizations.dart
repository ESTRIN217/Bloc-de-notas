import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('es', 'VE'),
    Locale('pt'),
    Locale('pt', 'BR'),
  ];

  /// No description provided for @helloWorld.
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// No description provided for @flutterNotes.
  ///
  /// In en, this message translates to:
  /// **'NOTEPAD'**
  String get flutterNotes;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @toggleView.
  ///
  /// In en, this message translates to:
  /// **'Toggle View'**
  String get toggleView;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addItem;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selected(Object count);

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @sortAlphabetically.
  ///
  /// In en, this message translates to:
  /// **'Sort Alphabetically'**
  String get sortAlphabetically;

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'Sort by Modification Date'**
  String get sortByDate;

  /// No description provided for @customSort.
  ///
  /// In en, this message translates to:
  /// **'Custom Sort'**
  String get customSort;

  /// No description provided for @myNotes.
  ///
  /// In en, this message translates to:
  /// **'My Notes'**
  String get myNotes;

  /// No description provided for @imageFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Image from gallery'**
  String get imageFromGallery;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @useDynamicColors.
  ///
  /// In en, this message translates to:
  /// **'Use Dynamic Colors'**
  String get useDynamicColors;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Mode dark'**
  String get themeMode;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get dark;

  /// No description provided for @apariencia.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get apariencia;

  /// No description provided for @idioma.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get idioma;

  /// No description provided for @informacion.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get informacion;

  /// No description provided for @sobre.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sobre;

  /// No description provided for @desarrolador.
  ///
  /// In en, this message translates to:
  /// **'Developed by'**
  String get desarrolador;

  /// No description provided for @enlaces.
  ///
  /// In en, this message translates to:
  /// **'Useful links'**
  String get enlaces;

  /// No description provided for @repositorio.
  ///
  /// In en, this message translates to:
  /// **'View repository'**
  String get repositorio;

  /// No description provided for @espanol.
  ///
  /// In en, this message translates to:
  /// **' 🇪🇸 Spanish'**
  String get espanol;

  /// No description provided for @ingles.
  ///
  /// In en, this message translates to:
  /// **' 🇺🇸 English'**
  String get ingles;

  /// No description provided for @venezolano.
  ///
  /// In en, this message translates to:
  /// **' 🇻🇪 Spanish (Venezuela)'**
  String get venezolano;

  /// No description provided for @portugues.
  ///
  /// In en, this message translates to:
  /// **' 🇵🇹 Portuguese'**
  String get portugues;

  /// No description provided for @brasileno.
  ///
  /// In en, this message translates to:
  /// **' 🇧🇷 Portuguese (Brazil)'**
  String get brasileno;

  /// No description provided for @texto_plano.
  ///
  /// In en, this message translates to:
  /// **'Plain text (.txt)'**
  String get texto_plano;

  /// No description provided for @markdown.
  ///
  /// In en, this message translates to:
  /// **'Markdown (.md)'**
  String get markdown;

  /// No description provided for @archivo_pdf.
  ///
  /// In en, this message translates to:
  /// **'Archive PDF (.pdf)'**
  String get archivo_pdf;

  /// No description provided for @html.
  ///
  /// In en, this message translates to:
  /// **'Archive HTML (.HTML)'**
  String get html;

  /// No description provided for @exportar_notas_como.
  ///
  /// In en, this message translates to:
  /// **'Export notes as:'**
  String get exportar_notas_como;

  /// No description provided for @descripcion.
  ///
  /// In en, this message translates to:
  /// **'A simple note-taking app built with Flutter, designed to be fast, intuitive, and easy to use. It allows you to create, edit, and organize your notes efficiently.'**
  String get descripcion;

  /// No description provided for @mit_license.
  ///
  /// In en, this message translates to:
  /// **'MIT License'**
  String get mit_license;

  /// No description provided for @actualizador.
  ///
  /// In en, this message translates to:
  /// **'Updater'**
  String get actualizador;

  /// No description provided for @registro_de_cambio.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get registro_de_cambio;

  /// No description provided for @version_actual.
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get version_actual;

  /// No description provided for @ajuste_de_actulizacion.
  ///
  /// In en, this message translates to:
  /// **'Update settings'**
  String get ajuste_de_actulizacion;

  /// No description provided for @buscar_actualizaciones_automaticamente.
  ///
  /// In en, this message translates to:
  /// **'Automatically check for updates'**
  String get buscar_actualizaciones_automaticamente;

  /// No description provided for @habilitar_notificaciones_de_actualizacion.
  ///
  /// In en, this message translates to:
  /// **'Enable update notifications'**
  String get habilitar_notificaciones_de_actualizacion;

  /// No description provided for @buscar_actualizaciones.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get buscar_actualizaciones;

  /// No description provided for @json_crudo.
  ///
  /// In en, this message translates to:
  /// **'Raw JSON'**
  String get json_crudo;

  /// No description provided for @system_default.
  ///
  /// In en, this message translates to:
  /// **'Default (System)'**
  String get system_default;

  /// No description provided for @etiquetas.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get etiquetas;

  /// No description provided for @archivados.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archivados;

  /// No description provided for @papelera.
  ///
  /// In en, this message translates to:
  /// **'Bin'**
  String get papelera;

  /// No description provided for @nueva_version_disponible.
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get nueva_version_disponible;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version: {version}'**
  String appVersion(String version);

  /// No description provided for @lapiz.
  ///
  /// In en, this message translates to:
  /// **'Pencil'**
  String get lapiz;

  /// No description provided for @resaltado.
  ///
  /// In en, this message translates to:
  /// **'Highlighted'**
  String get resaltado;

  /// No description provided for @borrador.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get borrador;

  /// No description provided for @eliminar_dibujo.
  ///
  /// In en, this message translates to:
  /// **'Delete drawing'**
  String get eliminar_dibujo;

  /// No description provided for @appVersionFull.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({buildNumber}) • {platform}'**
  String appVersionFull(String version, String buildNumber, String platform);

  /// No description provided for @notesRestored.
  ///
  /// In en, this message translates to:
  /// **'Notes restored'**
  String get notesRestored;

  /// No description provided for @notesArchived.
  ///
  /// In en, this message translates to:
  /// **'Notes archived'**
  String get notesArchived;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @welcomeNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Notepad!'**
  String get welcomeNoteTitle;

  /// No description provided for @exerciseNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Routine!'**
  String get exerciseNoteTitle;

  /// No description provided for @tagNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Tag notes'**
  String get tagNotesTitle;

  /// No description provided for @noTagsCreated.
  ///
  /// In en, this message translates to:
  /// **'No tags created. Create them from the side menu.'**
  String get noTagsCreated;

  /// No description provided for @manageTags.
  ///
  /// In en, this message translates to:
  /// **'Manage Tags'**
  String get manageTags;

  /// No description provided for @newTagHint.
  ///
  /// In en, this message translates to:
  /// **'New tag...'**
  String get newTagHint;

  /// No description provided for @tagExistsError.
  ///
  /// In en, this message translates to:
  /// **'This tag already exists'**
  String get tagExistsError;

  /// No description provided for @renameTag.
  ///
  /// In en, this message translates to:
  /// **'Rename Tag'**
  String get renameTag;

  /// No description provided for @renameTagLabel.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get renameTagLabel;

  /// No description provided for @movedToTrash.
  ///
  /// In en, this message translates to:
  /// **'Moved to trash'**
  String get movedToTrash;

  /// No description provided for @emptyTrashTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty trash?'**
  String get emptyTrashTitle;

  /// No description provided for @emptyTrashMessage.
  ///
  /// In en, this message translates to:
  /// **'All notes in the trash will be permanently deleted.'**
  String get emptyTrashMessage;

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteForever;

  /// No description provided for @restoreNote.
  ///
  /// In en, this message translates to:
  /// **'Restore note'**
  String get restoreNote;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @emptyTrashAction.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get emptyTrashAction;

  /// No description provided for @unarchiveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchiveTooltip;

  /// No description provided for @archiveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveTooltip;

  /// No description provided for @tagTooltip.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get tagTooltip;

  /// No description provided for @deleteTagTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {tag}'**
  String deleteTagTitle(String tag);

  /// No description provided for @deleteTagMessage.
  ///
  /// In en, this message translates to:
  /// **'The label will be removed from all notes, but the notes will not be deleted.'**
  String get deleteTagMessage;

  /// No description provided for @json_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Raw format for backup'**
  String get json_subtitle;

  /// No description provided for @misNotasExportadas.
  ///
  /// In en, this message translates to:
  /// **'My Exported Notes'**
  String get misNotasExportadas;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'WITHOUT TITLE'**
  String get untitled;

  /// No description provided for @titleHtml.
  ///
  /// In en, this message translates to:
  /// **'Exported notes'**
  String get titleHtml;

  /// No description provided for @shareHtmlMessage.
  ///
  /// In en, this message translates to:
  /// **'I share my notes in web format'**
  String get shareHtmlMessage;

  /// No description provided for @colorFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'color'**
  String get colorFilterLabel;

  /// No description provided for @errorLoadingInfo.
  ///
  /// In en, this message translates to:
  /// **'Error loading info'**
  String get errorLoadingInfo;

  /// No description provided for @formatError.
  ///
  /// In en, this message translates to:
  /// **'Format error'**
  String get formatError;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noteTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Note tags'**
  String get noteTagsTitle;

  /// No description provided for @yourTags.
  ///
  /// In en, this message translates to:
  /// **'Your tags:'**
  String get yourTags;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @noteArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived note'**
  String get noteArchived;

  /// No description provided for @noteUnarchived.
  ///
  /// In en, this message translates to:
  /// **'Unarchived note'**
  String get noteUnarchived;

  /// No description provided for @pdfExportHeader.
  ///
  /// In en, this message translates to:
  /// **'Exporting from Notepad'**
  String get pdfExportHeader;

  /// No description provided for @shareNoteMessage.
  ///
  /// In en, this message translates to:
  /// **'I\'m sharing my note with you: {title}'**
  String shareNoteMessage(String title);

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleHint;

  /// No description provided for @editorPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write something amazing...'**
  String get editorPlaceholder;

  /// No description provided for @modifiedAt.
  ///
  /// In en, this message translates to:
  /// **'Modified on: {date}'**
  String modifiedAt(String date);

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get stopRecording;

  /// No description provided for @recordVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Record voice note'**
  String get recordVoiceNote;

  /// No description provided for @selectAudioFile.
  ///
  /// In en, this message translates to:
  /// **'Select Audio File'**
  String get selectAudioFile;

  /// No description provided for @eliminarEtiqueta.
  ///
  /// In en, this message translates to:
  /// **'Remove label'**
  String get eliminarEtiqueta;

  /// No description provided for @ordenar.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get ordenar;

  /// No description provided for @ultima.
  ///
  /// In en, this message translates to:
  /// **'Latest version available: {version}'**
  String ultima(String version);

  /// No description provided for @ocultarRegistroDeCambios.
  ///
  /// In en, this message translates to:
  /// **'Hide change log'**
  String get ocultarRegistroDeCambios;

  /// No description provided for @verRegistroDeCambios.
  ///
  /// In en, this message translates to:
  /// **'View change log'**
  String get verRegistroDeCambios;

  /// No description provided for @actualizacionDisponible.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get actualizacionDisponible;

  /// No description provided for @actualizacionesDeLaApp.
  ///
  /// In en, this message translates to:
  /// **'App updates'**
  String get actualizacionesDeLaApp;

  /// No description provided for @chaneldescripcion.
  ///
  /// In en, this message translates to:
  /// **'You already have the latest version'**
  String get chaneldescripcion;

  /// No description provided for @desing.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ in Venezuela'**
  String get desing;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'es':
      {
        switch (locale.countryCode) {
          case 'VE':
            return AppLocalizationsEsVe();
        }
        break;
      }
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
