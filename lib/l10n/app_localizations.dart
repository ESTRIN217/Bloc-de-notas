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
