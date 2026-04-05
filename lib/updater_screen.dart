import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
// Importa tu nuevo provider aquí
import 'updater_provider.dart'; 
import 'l10n/app_localizations.dart';

class UpdaterScreen extends StatelessWidget {
  const UpdaterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el UpdaterProvider para reconstruir la UI cuando cambien los switches o la versión
    final updater = context.watch<UpdaterProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.actualizador)),
      body: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          // final isDynamicColorSupported = lightDynamic != null && darkDynamic != null;

          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ListView(
                padding: const EdgeInsets.all(8),
                children: [
                   Padding(
                    padding: EdgeInsets.only(
                      top: 16.0, left: 16.0, right: 16.0, bottom: 8.0,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.version_actual,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: Text('Versión: ${updater.currentVersion}'),
                        ),
                        const ListTile(
                          title: Text('Universal'),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(
                      top: 16.0, left: 16.0, right: 16.0, bottom: 8.0,
                    ),
                    child: Text(
                      'Ajustes de actualización',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Card(
                    clipBehavior: Clip.hardEdge,
                    child: SwitchListTile(
                      title: const Text('Buscar actualizaciones automáticamente'),
                      secondary: const Icon(Icons.update),
                      value: updater.autoUpdate, // Conectado al estado
                      onChanged: (bool value) {
                        context.read<UpdaterProvider>().toggleAutoUpdate(value);
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
                  ),
                  Card(
                    clipBehavior: Clip.hardEdge,
                    child: SwitchListTile(
                      title: const Text('Habilitar notificaciones de actualización'),
                      secondary: const Icon(Icons.notifications),
                      value: updater.notifications, // Conectado al estado
                      onChanged: (bool value) {
                        context.read<UpdaterProvider>().toggleNotifications(value);
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
                  ),
                  const Padding(
                    padding: EdgeInsets.only(
                      top: 16.0, left: 16.0, right: 16.0, bottom: 8.0,
                    ),
                    child: Text(
                      'Buscar actualizaciones',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Card(
                    clipBehavior: Clip.hardEdge,
                    child: ListTile(
                      leading: updater.isChecking 
                          ? const CircularProgressIndicator() // Muestra un loader si está buscando
                          : const Icon(Icons.info_outline_rounded),
                      title: const Text('Buscar actualizaciones'),
                      onTap: updater.isChecking
                          ? null // Deshabilita el botón si ya está buscando
                          : () {
                              context.read<UpdaterProvider>().checkForUpdates(context);
                            },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}