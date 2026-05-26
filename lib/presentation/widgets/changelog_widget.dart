import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:bloc_de_notas/presentation/widgets/settings_ui_widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';

class ChangelogSheet extends StatelessWidget {
  const ChangelogSheet({super.key});

  /// Obtiene la lista de releases desde la API de GitHub
  Future<List<dynamic>> _fetchReleases() async {
    final url = Uri.parse(
      'https://api.github.com/repos/ESTRIN217/Bloc-de-notas/releases',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al cargar releases: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> _launchGitHub() async {
    final url = Uri.parse('https://github.com/ESTRIN217/Bloc-de-notas');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'No se pudo abrir $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Registro de cambios'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchReleases(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ocurrió un error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No hay registros de cambios disponibles.'),
            );
          }

          final releases = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: releases.length,
            itemBuilder: (context, index) {
              final release = releases[index];
              final String version = release['tag_name'] ?? 'v?';
              final String title = release['name'] ?? 'Sin título';
              final String body = release['body'] ?? '';
              final String date = release['published_at'].toString().substring(
                0,
                10,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera de la versión
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SettingsBadge(
                          text: version,
                          fontSize: 18.0,
                        ),
                        Text(
                          date,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    // --- Renderizador de Markdown ---
                    SettingsCardGroup(
                      child: MarkdownBody(
                      data: body,
                      selectable:
                          true, // Permite al usuario seleccionar y copiar texto
                      styleSheet:
                          MarkdownStyleSheet.fromTheme(
                            Theme.of(context),
                          ).copyWith(
                            // Ajusta el espacio entre párrafos si es necesario
                            pPadding: const EdgeInsets.only(bottom: 8),
                          ),
                      // Hace que los enlaces en el markdown funcionen
                      onTapLink: (text, href, title) async {
                        if (href != null) {
                          final uri = Uri.parse(href);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        }
                      },
                    ),
                    ),
                  ],
                ),
                )
                );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _launchGitHub,
        icon: const FaIcon(FontAwesomeIcons.github),
        label: const Text('Ver en GitHub'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

}
