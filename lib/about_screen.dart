import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bloc_de_notas/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Funciones de lanzamiento de URL existentes
  Future<void> _openUrl(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      debugPrint('No se pudo abrir $url');
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. Cabecera de la Aplicación
          _buildHeaderCard(context),

          const SizedBox(height: 16),

          // 2. Card del Desarrollador
          _buildDeveloperCard(context),

          const SizedBox(height: 24),

          // 3. Título de sección y Enlaces
          _buildSectionTitle(context, AppLocalizations.of(context)!.enlaces),
          _buildLinkGroup(context),

          const SizedBox(height: 32),

          // Nota de pie sutil
          Center(
            child: Text(
              "Hecho con ❤️ en Venezuela",
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
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.data?.version ?? "...";
                    return Row(
                      children: [
                        _buildBadge(context, version),
                        const SizedBox(width: 8),
                        _buildBadge(context, "UNIVERSAL"),
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
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  /// Títulos de sección (como los de la pantalla de ajustes)
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// Grupo de enlaces (Repositorio, Licencia)
  Widget _buildLinkGroup(BuildContext context) {
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
      child: Column(
        children: [
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.github),
            title: Text(AppLocalizations.of(context)!.repositorio),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openUrl('https://github.com/ESTRIN217/Bloc-de-notas'),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(AppLocalizations.of(context)!.mit_license),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openUrl(
              'https://github.com/ESTRIN217/Bloc-de-notas/blob/master/LICENSE',
            ),
          ),
        ],
      ),
    );
  }
}
