import 'package:bloc_de_notas/audioplayer_widget.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

class AudioEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'audio'; // Este es el identificador en el JSON (ej: {"insert": {"audio": "ruta/al/archivo"}})

  @override
  bool get expanded => false;

  @override
  @override
  Widget build(
    BuildContext context,
    EmbedContext embedContext, // Agrupamos los parámetros aquí
  ) {
    // Extraemos los datos desde embedContext
    final controller = embedContext.controller;
    final node = embedContext.node;
    final readOnly = embedContext.readOnly;

    // Extraemos la ruta del archivo (ahora está en node.value.data)
    final audioPath = node.value.data as String;

    return AudioPlayerWidget(
      audioPath: audioPath,
      controller: controller,
      node: node,
      readOnly: readOnly,
    );
  }
}
