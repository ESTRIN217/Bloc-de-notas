import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import 'package:bloc_de_notas/providers/theme_provider.dart';
import 'package:bloc_de_notas/presentation/screens/about_screen.dart';
import 'package:bloc_de_notas/l10n/app_localizations.dart';
import 'package:bloc_de_notas/presentation/screens/updater_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:bloc_de_notas/presentation/widgets/update_widget.dart';
import 'package:bloc_de_notas/providers/updater_provider.dart';
import 'package:bloc_de_notas/presentation/screens/backup_screen.dart';
import 'package:bloc_de_notas/presentation/widgets/settings_ui_widgets.dart';
import 'package:bloc_de_notas/presentation/widgets/changelog_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final updater = context.watch<UpdaterProvider>();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          final isDynamicColorSupported =
              lightDynamic != null && darkDynamic != null;

          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ListView(
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                children: [
                  SettingsSectionTitle(title: AppLocalizations.of(context)!.apariencia),

                  SettingsCardGroup(
                    child: 
                      if (isDynamicColorSupported) ...[
                        SizedBox(
                    height: 72,
                    child: Center(
                      child: SettingsSwitchTile(
                          title: AppLocalizations.of(context)!.useDynamicColors,
                           icon: Icons.palette_outlined,
                            value: themeProvider.useDynamicColors,
                          onChanged: (value) {
                            themeProvider.setUseDynamicColors(value);
                          },
                          ),
                        ),
                        ),
                    ],
                  ),
                  SettingsCardGroup(
                    child: Column(
                    children: [
                      ListTile(
                        // Aplicamos el fondo al icono del modo oscuro
                        leading: SettingsIconContainer(icon: Icons.dark_mode_outlined),
                        title: Text(AppLocalizations.of(context)!.themeMode),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SegmentedButton<ThemeMode>(
                          segments: <ButtonSegment<ThemeMode>>[
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.system,
                              label: Text(AppLocalizations.of(context)!.system),
                              icon: const Icon(Icons.brightness_auto_outlined),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.light,
                              label: Text(AppLocalizations.of(context)!.light),
                              icon: const Icon(Icons.light_mode_outlined),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.dark,
                              label: Text(AppLocalizations.of(context)!.dark),
                              icon: const Icon(Icons.dark_mode_outlined),
                            ),
                          ],
                          selected: {themeProvider.themeMode},
                          onSelectionChanged: (newSelection) {
                            themeProvider.setThemeMode(newSelection.first);
                          },
                        ),
                      ),
                    ],
                    ),
                  ),

                  SettingsSectionTitle(title: AppLocalizations.of(context)!.idioma),
                  SettingsCardGroup(
                    child: 
                      ListTile(
                        leading: SettingsIconContainer(icon: Icons.language),
                        title: Text(
                          themeProvider.isSystemLocale
                              ? AppLocalizations.of(context)!
                                    .system_default // Ahora mostrará "Predeterminado"
                              : themeProvider.locale.countryCode == "VE"
                              ? AppLocalizations.of(context)!.venezolano
                              : themeProvider.locale.countryCode == "BR"
                              ? AppLocalizations.of(context)!.brasileno
                              : themeProvider.locale.languageCode == 'es'
                              ? AppLocalizations.of(context)!.espanol
                              : themeProvider.locale.languageCode == 'pt'
                              ? AppLocalizations.of(context)!.portugues
                              : themeProvider.locale.languageCode == 'en'
                              ? AppLocalizations.of(context)!.ingles
                              : '🌐 ${themeProvider.locale.languageCode.toUpperCase()}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        subtitle: Text(AppLocalizations.of(context)!.idioma),
                        onTap: () {
                          _showLanguageDialog(context, themeProvider);
                        },
                      ),
                  ),
                  SettingsSectionTitle(title: AppLocalizations.of(context)!.titleSeccionBackup),
                  SettingsCardGroup(
                    child:
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
                        leading: SettingsIconContainer(icon: Icons.cloud_download_outlined),
                        title: Text(AppLocalizations.of(context)!.backupSyncTitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BackupSyncScreen(),
                              ),
                            );
                        },
                      ),
                  ),

                  SettingsSectionTitle(title: AppLocalizations.of(context)!.informacion),
                  SettingsCardGroup(
                    child:
                      // Solo se mostrará si NO es Web
                      if (!kIsWeb)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
                          leading: SettingsIconContainer(icon: Icons.update),
                          title: Text(
                            AppLocalizations.of(context)!.actualizador,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UpdaterScreen(),
                              ),
                            );
                          },
                        ),
                  ),
                  SettingsCardGroup(
                    child:
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
                        leading: SettingsIconContainer(icon: Icons.verified_outlined),
                        title: Text(
                          AppLocalizations.of(context)!.registro_de_cambio,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showChangelogBottomSheet(context);
                        },
                      ),
                  ),
                  SettingsCardGroup(
                    child:
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
                        leading: SettingsIconContainer(icon: Icons.info_outline_rounded),
                        title: Text(AppLocalizations.of(context)!.sobre),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutScreen(),
                            ),
                          );
                        },
                      ),
                  ),
                    if (!kIsWeb && updater.hasUpdate) ...[
                      SettingsSectionTitle(title:'Actualización' ),
                      SettingsCardGroup(
                        child:
                          const UpdateAvailableWidget(),
                          ),
                      SettingsCardGroup(
                        child:
                          if (updater.latestChangelog != null) ...[
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: MarkdownBody(
                                data: updater.latestChangelog!,
                                selectable:
                          true, // Permite al usuario seleccionar y copiar texto
                      // Hace que los enlaces en el markdown funcionen
                      onTapLink: (text, href, title) async {
                        if (href != null) {
                          final uri = Uri.parse(href);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        }
                      },
                                styleSheet: MarkdownStyleSheet.fromTheme(
                                  Theme.of(context),
                                ),
                              ),
                            ),
                          ],
                          
                          ),
                        ],
                      ),
                    ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // OPCIÓN PREDETERMINADO
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(AppLocalizations.of(context)!.system_default),
                  onTap: () {
                    themeProvider.setLocale(
                      null,
                    ); // Al pasar null, el provider sabe que es el sistema
                    Navigator.pop(context);
                  },
                ),
                const Divider(), // Una línea divisoria queda bien aquí
                // VENEZUELA
                ListTile(
                  leading: const Text('🇻🇪'),
                  title: const Text('Español (Venezuela)'),
                  onTap: () {
                    // IMPORTANTE: Pasar ambos códigos para que el ternario lo detecte
                    themeProvider.setLocale(const Locale('es', 'VE'));
                    Navigator.pop(context);
                  },
                ),

                // ESPAÑA
                ListTile(
                  leading: const Text('🇪🇸'),
                  title: const Text('Español (España)'),
                  onTap: () {
                    themeProvider.setLocale(const Locale('es', 'ES'));
                    Navigator.pop(context);
                  },
                ),

                // USA
                ListTile(
                  leading: const Text('🇺🇸'),
                  title: const Text('English'),
                  onTap: () {
                    themeProvider.setLocale(const Locale('en'));
                    Navigator.pop(context);
                  },
                ),

                // BRASIL
                ListTile(
                  leading: const Text('🇧🇷'),
                  title: const Text('Português (Brasil)'),
                  onTap: () {
                    themeProvider.setLocale(const Locale('pt', 'BR'));
                    Navigator.pop(context);
                  },
                ),

                // PORTUGAL
                ListTile(
                  leading: const Text('🇵🇹'),
                  title: const Text('Português (Portugal)'),
                  onTap: () {
                    themeProvider.setLocale(const Locale('pt', 'PT'));
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Función para mostrar el BottomSheet
  void _showChangelogBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que ocupe más altura si es necesario
      useSafeArea: true,
      builder: (BuildContext context) {
        return const ChangelogSheet();
      },
    );
  }
}
