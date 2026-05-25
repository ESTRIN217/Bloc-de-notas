import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bloc_de_notas/providers/updater_provider.dart';
import 'package:bloc_de_notas/l10n/app_localizations.dart';
// Para detectar Android/iOS
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar si es Web
import 'package:device_info_plus/device_info_plus.dart';
import 'package:bloc_de_notas/presentation/widgets/settings_ui_widgets.dart';

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
        padding: const EdgeInsets.only(bottom: 24, top: 8),
        children: [
          SettingsSectionTitle(title: AppLocalizations.of(context)!.version_actual),
          SettingsCardGroup(
            child: ListTile(
    title: Text(AppLocalizations.of(context)!.appVersion(updater.currentVersion),
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 17,
      ),
    ),
    subtitle: FutureBuilder<BaseDeviceInfo>(
      future: DeviceInfoPlugin().deviceInfo,
      builder: (context, snapshot) {
        String arch = AppLocalizations.of(context)!.loading;
        
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

          SettingsSectionTitle(title: AppLocalizations.of(context)!.ajuste_de_actulizacion),
          SettingsCardGroup(
            child: SizedBox(
                    height: 72,
                    child: Center(
                      child: SettingsSwitchTile(
                        title: AppLocalizations.of(context)!.buscar_actualizaciones_automaticamente,
                        icon: Icons.refresh_rounded,
                        value: updater.autoUpdate,
                        onChanged: (val) => context.read<UpdaterProvider>().toggleAutoUpdate(val),
                      ),
                      ),
                ),
                ),
                SettingsCardGroup(
                  child: SizedBox(
                    height: 72,
                    child: Center(
                      child: SettingsSwitchTile(
                  title: AppLocalizations.of(context)!.habilitar_notificaciones_de_actualizacion,
                  icon: Icons.notifications_none_rounded,
                  value: updater.notifications,
                  onChanged: (val) =>
                      context.read<UpdaterProvider>().toggleNotifications(val),
                ),
              ),
              ),
          ),

          SettingsSectionTitle(title: AppLocalizations.of(context)!.buscar_actualizaciones),
          SettingsCardGroup(
            child: 
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
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
                  leading: SettingsIconContainer(icon: updater.isChecking
                        ? Icons.hourglass_empty
                        : (updater.hasUpdate
                              ? Icons.download_outlined
                              : Icons.refresh_rounde)),
                  title: Text(
                    updater.hasUpdate
                        ? AppLocalizations.of(context)!.ultima(updater.currentVersion)
                        : AppLocalizations.of(context)!.buscar_actualizaciones,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
                ),
                if (updater.hasUpdate && updater.latestChangelog != null) ...[
               SettingsCardGroup(
                 child:
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
        child: TextButton.icon(
          onPressed: () {
            setState(() {
              _showChangelog = !_showChangelog;
            });
          },
          icon: Icon(
            _showChangelog ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          label: Text(
            _showChangelog
                ? AppLocalizations.of(context)!.ocultarRegistroDeCambios
                : AppLocalizations.of(context)!.verRegistroDeCambios,
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 50),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      ),
      ),
      SettingsCardGroup(
        child:
      // Contenido del Changelog con su propia animación
      AnimatedCrossFade(
        firstChild: const SizedBox(width: double.infinity),
        secondChild: Padding(
          // Modificado aquí también para mantener consistencia si lo deseas
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
          child: MarkdownBody(
            data: updater.latestChangelog!,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
            selectable: true,
            onTapLink: (text, href, title) async {
              if (href != null) {
                final uri = Uri.parse(href);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
          ),
        ),
        crossFadeState: _showChangelog
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 300),
      ),
),
],
          ),
        ],
      ),
    );
  }
}
