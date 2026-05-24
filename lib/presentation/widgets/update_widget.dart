import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bloc_de_notas/providers/updater_provider.dart';
import 'package:bloc_de_notas/presentation/screens/updater_screen.dart';
import 'package:bloc_de_notas/l10n/app_localizations.dart';

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