import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bloc_de_notas/providers/updater_provider.dart';
import 'package:bloc_de_notas/presentation/screens/updater_screen.dart';
import 'package:bloc_de_notas/l10n/app_localizations.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateAvailableWidget extends StatelessWidget {
  final bool isDrawerTile;

  const UpdateAvailableWidget({super.key, this.isDrawerTile = false});

  Widget _buildIconContainer(BuildContext context, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      // Se usan iconos outlined según la preferencia guardada
      child: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final updater = context.watch<UpdaterProvider>();

    if (!updater.hasUpdate) return const SizedBox.shrink();

    return Padding(
      // Si es para el drawer, añadimos el margen horizontal típico de MD3
      padding: isDrawerTile 
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4) 
          : EdgeInsets.zero,
      child: ListTile(
        // Aplicamos bordes redondeados si está en el drawer para que parezca un botón
        shape: isDrawerTile 
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)) 
            : null,
        leading: Badge(
          backgroundColor: Colors.red,
          smallSize: 12,
          child: isDrawerTile ? Icon(Icons.system_update_alt_outlined) :_buildIconContainer(context, Icons.system_update_alt_outlined),
        ),
        title:  Text(AppLocalizations.of(context)!.nueva_version_disponible,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: isDrawerTile
        ? null
        : Icon(Icons.chevron_right_outlined),
        subtitle: Text(AppLocalizations.of(context)!.appVersion(updater.latestVersion ?? ''),
        ),
        onTap: () {
          if (isDrawerTile) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UpdaterScreen()),
          );
        },
      ),
    );
  }
} 

class CustomMarkdownBody extends StatelessWidget {
  final String data;
  final EdgeInsets? pPadding;

  const CustomMarkdownBody({
    super.key,
    required this.data,
    this.pPadding,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        pPadding: pPadding,
      ),
      onTapLink: (text, href, title) async {
        if (href != null) {
          final Uri uri = Uri.parse(href);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
    );
  }
}