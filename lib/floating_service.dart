import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_window/flutter_floating_window.dart';
import 'list_item.dart';

class FloatingService {
  static Future<void> showFloatingWindow(BuildContext context, ListItem item) async {
    // First, check for platform compatibility.
    if (kIsWeb || !Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El modo flotante solo está disponible en Android.')),
      );
      return;
    }

    // Then, manage permissions.
    try {
      final bool hasPermission = await FloatingWindowManager.instance.hasOverlayPermission();
      if (!hasPermission) {
        final bool granted = await FloatingWindowManager.instance.requestOverlayPermission();
        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso denegado para mostrar la ventana flotante.')),
          );
          return;
        }
      }
final config = FloatingWindowConfig(
  width: 300, // Ajusta el tamaño según necesites
  height: 200,
  isDraggable: true,
  // El color de fondo se suele manejar dentro del widget que pasas, 
  // no en la configuración de la ventana del sistema.
);
      // Finally, create the self-contained floating window.
      await FloatingWindowManager.instance.createWindow(config);

    } catch (e) {
      debugPrint('Error al crear la ventana flotante: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar el modo flotante: $e')),
      );
    }
  }

  // This widget MUST be self-contained and NOT rely on the app's context.
  // It runs in a separate Isolate.
  static Widget _buildFloatingWidget(ListItem item) {
    return Material(
      color: Colors.transparent, // Important for the rounded corners to show through
      elevation: 0,
      child: Card(
        elevation: 8.0,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias, // Ensures the content respects the rounded corners
        child: Container(
          width: 300,
          height: 400,
          color: Colors.white, // Set a solid background color for the card content
          child: Column(
            children: [
              // Draggable Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 48,
                // Use a hardcoded color as the theme is not available here
                color: Colors.deepPurple,
                child: Row(
                  children: [
                    const Icon(Icons.drag_handle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.title.isEmpty ? "Nota flotante" : item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none, // Explicitly remove any text decorations
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    item.document.toPlainText(),
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        decoration: TextDecoration.none, // Ensure no unwanted decorations
                     ), 
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
