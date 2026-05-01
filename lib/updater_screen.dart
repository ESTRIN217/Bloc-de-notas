import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'updater_provider.dart';
import 'l10n/app_localizations.dart';
import 'dart:io' show Platform; // Para detectar Android/iOS
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar si es Web
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

class UpdaterScreen extends StatefulWidget {
  const UpdaterScreen({super.key});

  @override
  State<UpdaterScreen> createState() => _UpdaterScreenState();
}

class _UpdaterScreenState extends State<UpdaterScreen> {
  bool _showChangelog = false;

  @override
  Widget build(BuildContext context) {
    final updater = context.watch<UpdaterProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.actualizador),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSectionTitle(
            context,
            AppLocalizations.of(context)!.version_actual,
          ),
          _buildGroup(
  context,
  child: ListTile(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 8,
    ),
    title: Text(
      'Versión: ${updater.currentVersion}',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 17,
      ),
    ),
    subtitle: FutureBuilder<BaseDeviceInfo>(
      future: DeviceInfoPlugin().deviceInfo,
      builder: (context, snapshot) {
        String arch = "Cargando...";
        
        if (snapshot.hasData) {
          if (kIsWeb) {
            final webInfo = snapshot.data as WebBrowserInfo;
            arch = webInfo.browserName.name.toUpperCase();
          } else {
            final androidInfo = snapshot.data as AndroidDeviceInfo;
            arch = androidInfo.supportedAbis.first.toUpperCase();
          }
        }

        return Text(
          '$arch - FOSS',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        );
      },
    ),
  ),
),

          const SizedBox(height: 16),

          _buildSectionTitle(
            context,
            AppLocalizations.of(context)!.ajuste_de_actulizacion,
          ),
          _buildGroup(
            context,
            child: Column(
              children: [
                _buildSwitchTile(
                  context,
                  title: AppLocalizations.of(
                    context,
                  )!.buscar_actualizaciones_automaticamente,
                  icon: Icons.refresh_rounded,
                  value: updater.autoUpdate,
                  onChanged: (val) =>
                      context.read<UpdaterProvider>().toggleAutoUpdate(val),
                ),
                const Divider(height: 1, indent: 70, endIndent: 20),
                _buildSwitchTile(
                  context,
                  title: AppLocalizations.of(
                    context,
                  )!.habilitar_notificaciones_de_actualizacion,
                  icon: Icons.notifications_none_rounded,
                  value: updater.notifications,
                  onChanged: (val) =>
                      context.read<UpdaterProvider>().toggleNotifications(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildSectionTitle(
            context,
            AppLocalizations.of(context)!.buscar_actualizaciones,
          ),
          _buildGroup(
            context,
            child: Column(
              children: [
                ListTile(
                  onTap: updater.isChecking
                      ? null
                      : () {
                          if (updater.hasUpdate) {
                            updater.launchDownloadUrl();
                          } else {
                            context.read<UpdaterProvider>().checkForUpdates(
                              context,
                            );
                          }
                        },
                  leading: _buildIconContainer(
                    context,
                    updater.isChecking
                        ? Icons.hourglass_empty
                        : (updater.hasUpdate
                              ? Icons.download_rounded
                              : Icons.refresh_rounded),
                  ),
                  title: Text(
                    updater.hasUpdate
                        ? 'Última: ${updater.latestVersion}'
                        : AppLocalizations.of(context)!.buscar_actualizaciones,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                // Botón Toggle para el Changelog (Solo visible si hay actualización)
                if (updater.hasUpdate && updater.latestChangelog != null) ...[
                  const Divider(height: 1),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showChangelog = !_showChangelog;
                      });
                    },
                    icon: Icon(
                      _showChangelog ? Icons.visibility_off : Icons.visibility,
                    ),
                    label: Text(
                      _showChangelog
                          ? 'Ocultar registro de cambios'
                          : 'Ver registro de cambios',
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),

                  // Contenido del Changelog
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: MarkdownBody(
                        data: updater.latestChangelog!,
                        styleSheet: MarkdownStyleSheet.fromTheme(
                          Theme.of(context),
                        ),
                      ),
                    ),
                    crossFadeState: _showChangelog
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Funciones de Ayuda de Diseño ---
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 12),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildGroup(BuildContext context, {required Widget child}) {
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
      child: child,
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

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: _buildIconContainer(context, icon),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      value: value,
      onChanged: onChanged,
      thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Icon(Icons.check);
        }
        return const Icon(Icons.close);
      }),
    );
  }
}
