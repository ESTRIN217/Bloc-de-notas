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
                          title: Text('Versión: ${updater.currentVersion}',
                          style: TextStyle(fontWeight: FontWeight.bold),),
                        ),
                        const ListTile(
                          title: Text('universal'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: 16.0, left: 16.0, right: 16.0, bottom: 8.0,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.ajuste_de_actulizacion,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Card(
                    clipBehavior: Clip.hardEdge,
                    child: SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.buscar_actualizaciones_automaticamente,
                      style: TextStyle(fontWeight: FontWeight.bold),),
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
                      title: Text(AppLocalizations.of(context)!.habilitar_notificaciones_de_actualizacion,
                      style: TextStyle(fontWeight: FontWeight.bold),),
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
                  Padding(
                    padding: EdgeInsets.only(
                      top: 16.0, left: 16.0, right: 16.0, bottom: 8.0,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.buscar_actualizaciones,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Card(
                    clipBehavior: Clip.hardEdge,
                    child: ListTile(
                      leading: updater.isChecking 
                          ? const CircularProgressIndicator() // Muestra un loader si está buscando
                          : const Icon(Icons.refresh),
                      title: Text(AppLocalizations.of(context)!.buscar_actualizaciones,
                      style: TextStyle(fontWeight: FontWeight.bold),),
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