import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'updater_provider.dart';
import 'updater_screen.dart';

class UpdateAvailableWidget extends StatelessWidget {
  final bool isDrawerTile;

  const UpdateAvailableWidget({super.key, this.isDrawerTile = false});

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

  @override
  Widget build(BuildContext context) {
    final updater = context.watch<UpdaterProvider>();

    if (!updater.hasUpdate) return const SizedBox.shrink();

    return ListTile(
      leading: Badge(
        backgroundColor: Colors.red,
        smallSize: 12,
        child: _buildIconContainer(context, Icons.system_update_alt_rounded),
      ),
      title: const Text(
        'Nueva versión disponible',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('Versión ${updater.latestVersion}'),
      onTap: () {
        if (isDrawerTile) Navigator.pop(context); // Cierra el drawer
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UpdaterScreen()),
        );
      },
    );
  }
}
