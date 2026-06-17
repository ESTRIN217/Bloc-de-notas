import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bloc_de_notas/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:bloc_de_notas/presentation/widgets/settings_ui_widgets.dart';
import 'package:bloc_de_notas/services/log_service.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Funciones de lanzamiento de URL existentes
  Future<void> _openUrl(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      Log.e('No se pudo abrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.sobre),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24, top: 8),
        children: [
          // 1. Cabecera de la Aplicación
          _buildHeaderCard(context),

          const SizedBox(height: 16),

          // 2. Card del Desarrollador
          _buildDeveloperCard(context),

          const SizedBox(height: 24),

          // 3. Título de sección y Enlaces
          SettingsSectionTitle(title: AppLocalizations.of(context)!.enlaces),
          _buildLinkGroup(context),

          const SizedBox(height: 32),

          // Nota de pie sutil
          Center(
            child: Text(
              AppLocalizations.of(context)!.desing,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  /// Crea la tarjeta superior con el icono y versión
  Widget _buildHeaderCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Image.asset('assets/icon/notas.png', width: 80, height: 80),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.flutterNotes,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<dynamic>>(
  future: Future.wait<dynamic>([
    PackageInfo.fromPlatform(),
    DeviceInfoPlugin().deviceInfo,
  ]).catchError((e) {
    // Si falla la carga, devolvemos valores por defecto para no bloquear la UI
    return <dynamic>[null, null];
  }),
  builder: (context, snapshot) {
    // 1. Valores por defecto iniciales
    String platformLabel = "...";
    String version = "...";
    String archLabel = "...";

    // 2. Si hay datos (y no son nulos por el catchError)
    if (snapshot.hasData && snapshot.data![0] != null) {
      final PackageInfo? packageInfo = snapshot.data![0];
      final deviceData = snapshot.data![1];

      version = packageInfo?.version ?? "...";

      if (kIsWeb) {
        platformLabel = "WEB";
        if (deviceData is WebBrowserInfo) {
          final browserName = deviceData.browserName.name.toUpperCase();
          final userAgent = deviceData.userAgent ?? "";
          String browserVersion = "";

          final regexMap = {
            BrowserName.chrome: RegExp(r'Chrome\/([0-9\.]+)'),
            BrowserName.firefox: RegExp(r'Firefox\/([0-9\.]+)'),
            BrowserName.safari: RegExp(r'Version\/([0-9\.]+)'),
            BrowserName.edge: RegExp(r'Edg\/([0-9\.]+)'),
          };

          final regex = regexMap[deviceData.browserName];
          if (regex != null) {
            final match = regex.firstMatch(userAgent);
            if (match != null) {
              browserVersion = match.group(1) ?? "";
            }
          }

          if (browserVersion.isEmpty) {
            browserVersion = (deviceData.appVersion ?? "").split(' ').first;
          }

          archLabel = "$browserName $browserVersion".trim();
        } else {
          archLabel = "UNKNOWN";
        }
      } else if (deviceData is AndroidDeviceInfo) {
        platformLabel = "ANDROID";
        archLabel = deviceData.supportedAbis.isNotEmpty
            ? deviceData.supportedAbis.first.toUpperCase()
            : "...";
      }
    }
    // 3. Si hay un error crítico en el Future
    else if (snapshot.hasError) {
      platformLabel = "ERROR";
      version = "Error";
      archLabel = "Error";
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsBadge(text: platformLabel),
        const SizedBox(width: 8),
        SettingsBadge(text: version),
        const SizedBox(width: 8),
        SettingsBadge(text: archLabel),
      ],
    );
  },
),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Crea la tarjeta del perfil del desarrollador
  Widget _buildDeveloperCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 45,
                backgroundImage: AssetImage('assets/icon/perfil.png'),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ESTRIN217',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    AppLocalizations.of(context)!.desarrolador,
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Botones Sociales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton(
                context,
                FontAwesomeIcons.github,
                () => _openUrl('https://github.com/ESTRIN217'),
              ),
              _buildSocialButton(
                context,
                FontAwesomeIcons.globe,
                () => {}, // Tu web si tienes
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Botón de Apoyo
          //SizedBox(
          //  width: double.infinity,
          //  child: FilledButton.icon(
          //  style: FilledButton.styleFrom(
          //    backgroundColor: const Color(0xFF8D5545), // Color café
          //    padding: const EdgeInsets.symmetric(vertical: 16),
          //    shape: RoundedRectangleBorder(
          //    borderRadius: BorderRadius.circular(16),
          //  ),
          //),
          //onPressed: () =>
          //    _openUrl('https://www.buymeacoffee.com/estrin217'),
          //  icon: const Icon(Icons.coffee),
          //  label: const Text("Buy me a coffee!"),
          //),
          //),
        ],
      ),
    );
  }

  /// Botón social circular estilizado
  Widget _buildSocialButton(
    BuildContext context,
    FaIconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: FaIcon(
          icon,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  /// Grupo de enlaces (Repositorio, Licencia)
  Widget _buildLinkGroup(BuildContext context) {
    return Column(
        children: [
          Card.outlined(
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
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
            leading: const SettingsFaIconContainer(icon: FontAwesomeIcons.github),
            title: Text(AppLocalizations.of(context)!.repositorio),
            trailing: const Icon(Icons.chevron_right_outlined),
            onTap: () => _openUrl('https://github.com/ESTRIN217/Bloc-de-notas'),
          ),
        ],
      ),
    ),
    Card.outlined(
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
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
            leading: SettingsIconContainer(icon: Icons.description_outlined),
            title: Text(AppLocalizations.of(context)!.mit_license),
            trailing: const Icon(Icons.chevron_right_outlined),
            onTap: () => _openUrl(
              'https://github.com/ESTRIN217/Bloc-de-notas/blob/master/LICENSE',
            ),
          ),
        ],
      ),
    ),
    ],
    );
  }
}
