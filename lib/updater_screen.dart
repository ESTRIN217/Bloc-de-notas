import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'updater_provider.dart';
import 'l10n/app_localizations.dart';

class UpdaterScreen extends StatelessWidget {
  const UpdaterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el UpdaterProvider para reconstruir la UI
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
          // Sección: Versión Actual
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
                'Version: ${updater.currentVersion}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              subtitle: Text(
                'universal - FOSS', // Texto descriptivo según la imagen
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sección: Ajustes de actualización
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

          // Sección: Buscar actualizaciones
          _buildSectionTitle(
            context,
            AppLocalizations.of(context)!.buscar_actualizaciones,
          ),
          _buildGroup(
            context,
            child: ListTile(
              onTap: updater.isChecking
                  ? null
                  : () => context.read<UpdaterProvider>().checkForUpdates(
                      context,
                    ),
              leading: _buildIconContainer(
                context,
                updater.isChecking
                    ? Icons.hourglass_empty
                    : Icons.refresh_rounded,
              ),
              title: Text(
                AppLocalizations.of(context)!.buscar_actualizaciones,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
