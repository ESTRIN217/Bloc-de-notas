import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Título para las secciones de los ajustes
class SettingsSectionTitle extends StatelessWidget {
  final String title;

  const SettingsSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Unifiqué el padding de ambos archivos para mantener consistencia
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 16),
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
}

/// Contenedor con fondo semitransparente para los iconos (Material 3)
class SettingsIconContainer extends StatelessWidget {
  final IconData icon;

  const SettingsIconContainer({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}
/// Contenedor con fondo semitransparente específico para FontAwesome
class SettingsFaIconContainer extends StatelessWidget {
  final FaIconData icon; 

  const SettingsFaIconContainer({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: FaIcon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

/// Tarjeta (Card) que agrupa las opciones
class SettingsCardGroup extends StatelessWidget {
  final Widget child;

  const SettingsCardGroup({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
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
}

/// Etiqueta pequeña (Badge) para mostrar versiones o plataformas
class SettingsBadge extends StatelessWidget {
  final String text;
  final double fontSize;

  const SettingsBadge({
    super.key,
    required this.text,
    this.fontSize = 11.0, // Valor por defecto para la pantalla 'Sobre la app'
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

/// Switch estilizado para la pantalla de ajustes/actualizador
class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: SettingsIconContainer(icon: icon),
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