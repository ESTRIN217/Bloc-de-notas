import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'about_screen.dart';
import 'l10n/app_localizations.dart';
import 'updater_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  _buildSectionTitle(
                    context,
                    AppLocalizations.of(context)!.apariencia,
                  ),

                  _buildSettingsGroup(
                    context,
                    children: [
                      if (isDynamicColorSupported) ...[
                        SwitchListTile(
                          title: Text(
                            AppLocalizations.of(context)!.useDynamicColors,
                          ),
                          // Aplicamos el fondo al icono de la paleta
                          secondary: _buildIconContainer(
                            context,
                            Icons.palette,
                          ),
                          value: themeProvider.useDynamicColors,
                          onChanged: (value) {
                            themeProvider.setUseDynamicColors(value);
                          },
                          thumbIcon: WidgetStateProperty.resolveWith<Icon?>((
                            Set<WidgetState> states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return const Icon(Icons.check);
                            }
                            return const Icon(Icons.close);
                          }),
                        ),
                      ],
                      ListTile(
                        // Aplicamos el fondo al icono del modo oscuro
                        leading: _buildIconContainer(context, Icons.dark_mode),
                        title: Text(AppLocalizations.of(context)!.themeMode),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SegmentedButton<ThemeMode>(
                          segments: <ButtonSegment<ThemeMode>>[
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.system,
                              label: Text(AppLocalizations.of(context)!.system),
                              icon: const Icon(Icons.brightness_auto),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.light,
                              label: Text(AppLocalizations.of(context)!.light),
                              icon: const Icon(Icons.light_mode),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.dark,
                              label: Text(AppLocalizations.of(context)!.dark),
                              icon: const Icon(Icons.dark_mode),
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

                  _buildSectionTitle(
                    context,
                    AppLocalizations.of(context)!.idioma,
                  ),
                  _buildSettingsGroup(
                    context,
                    children: [
                      ListTile(
                        // Aplicamos el fondo al icono de idioma
                        leading: _buildIconContainer(context, Icons.language),
                        title: Text(
                          // 1. Si el locale es nulo, es porque está en modo sistema
                          themeProvider.locale.countryCode == "VE"
                              ? AppLocalizations.of(context)!.venezolano
                              : themeProvider.locale.countryCode == "BR"
                              ? AppLocalizations.of(context)!.brasileno
                              // 3. Por último, los idiomas genéricos
                              : themeProvider.locale.languageCode == 'es'
                              ? AppLocalizations.of(context)!.espanol
                              : themeProvider.locale.languageCode == 'pt'
                              ? AppLocalizations.of(context)!.portugues
                              : themeProvider.locale.languageCode == 'en'
                              ? AppLocalizations.of(context)!.ingles
                              : '🌐 ${themeProvider.locale.languageCode.toUpperCase()}',
                        ),
                        subtitle: Text(AppLocalizations.of(context)!.idioma),
                        onTap: () {
                          _showLanguageDialog(context, themeProvider);
                        },
                      ),
                    ],
                  ),

                  _buildSectionTitle(
                    context,
                    AppLocalizations.of(context)!.informacion,
                  ),
                  _buildSettingsGroup(
                    context,
                    children: [
                      // Solo se mostrará si NO es Web
                      if (!kIsWeb)
                        ListTile(
                          leading: _buildIconContainer(context, Icons.update),
                          title: Text(
                            AppLocalizations.of(context)!.actualizador,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UpdaterScreen(),
                              ),
                            );
                          },
                        ),

                      ListTile(
                        // Aplicamos el fondo al icono de GitHub (FontAwesome también funciona con IconData)
                        leading: _buildFaIconContainer(
                          context,
                          FontAwesomeIcons.github,
                        ),
                        title: Text(
                          AppLocalizations.of(context)!.registro_de_cambio,
                        ),
                        onTap: () {
                          _showChangelogBottomSheet(context);
                        },
                      ),
                      ListTile(
                        // Aplicamos el fondo al icono de información
                        leading: _buildIconContainer(
                          context,
                          Icons.info_outline_rounded,
                        ),
                        title: Text(AppLocalizations.of(context)!.sobre),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // --- FUNCIONES DE AYUDA ---

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 32.0,
        right: 32.0,
        bottom: 8.0,
        top: 16.0,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Card.outlined(
  elevation: 0,
  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
  color: Theme.of(context).colorScheme.surface,
  clipBehavior: Clip.antiAlias,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(24),
    side: BorderSide(
      color: Theme.of(context).colorScheme.outlineVariant,
      width: 1.0,
    ),
  ),
  child: Column(children: children),
);
  }

  Widget _buildIconContainer(BuildContext context, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }

  Widget _buildFaIconContainer(BuildContext context, FaIconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: FaIcon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  leading: const Text('🌐'),
                  title: Text(
                    AppLocalizations.of(context)!.system_default,
                  ), // Usa la clave del ARB
                  onTap: () {
                    themeProvider.setLocale(WidgetsBinding.instance.platformDispatcher.locale);
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

class ChangelogSheet extends StatelessWidget {
  const ChangelogSheet({super.key});

  /// Obtiene la lista de releases desde la API de GitHub
  Future<List<dynamic>> _fetchReleases() async {
    final url = Uri.parse(
      'https://api.github.com/repos/ESTRIN217/Bloc-de-notas/releases',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al cargar releases: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> _launchGitHub() async {
    final url = Uri.parse('https://github.com/ESTRIN217/Bloc-de-notas');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'No se pudo abrir $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Registro de cambios'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchReleases(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ocurrió un error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No hay registros de cambios disponibles.'),
            );
          }

          final releases = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
            itemCount: releases.length,
            itemBuilder: (context, index) {
              final release = releases[index];
              final String version = release['tag_name'] ?? 'v?';
              final String title = release['name'] ?? 'Sin título';
              final String body = release['body'] ?? '';
              final String date = release['published_at'].toString().substring(
                0,
                10,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera de la versión
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBadge(context, version),
                        Text(
                          date,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    // --- Renderizador de Markdown ---
                    MarkdownBody(
                      data: body,
                      selectable:
                          true, // Permite al usuario seleccionar y copiar texto
                      styleSheet:
                          MarkdownStyleSheet.fromTheme(
                            Theme.of(context),
                          ).copyWith(
                            // Ajusta el espacio entre párrafos si es necesario
                            pPadding: const EdgeInsets.only(bottom: 8),
                          ),
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
                    ),

                    // ---------------------------------
                    const Divider(height: 32),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _launchGitHub,
        icon: const FaIcon(FontAwesomeIcons.github),
        label: const Text('Ver en GitHub'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
    /// Etiquetas pequeñas para la versión
  Widget _buildBadge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
