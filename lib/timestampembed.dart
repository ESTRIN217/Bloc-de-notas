import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
// Tip: Si usas el paquete 'intl', puedes usar DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime)
// Aquí lo haremos de forma nativa para evitar dependencias extra si no las tienes.

class TimeStampEmbed extends Embeddable {
  const TimeStampEmbed(
    String value,
  ) : super(timeStampType, value);

  static const String timeStampType = 'timeStamp';

  static TimeStampEmbed fromDocument(Document document) =>
      TimeStampEmbed(jsonEncode(document.toDelta().toJson()));

  Document get document => Document.fromJson(jsonDecode(data));
}

class TimeStampEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'timeStamp';

  @override
  String toPlainText(Embed node) {
    return node.value.data;
  }

  @override
  Widget build(
    BuildContext context,
    EmbedContext embedContext,
  ) {
    // Intentamos parsear la fecha guardada, si falla o está vacía, usamos la actual
    DateTime dateTime;
    try {
      dateTime = DateTime.parse(embedContext.node.value.data as String);
    } catch (_) {
      dateTime = DateTime.now();
    }

    // Formatear componentes de la fecha completa
    String year = dateTime.year.toString();
    String month = dateTime.month.toString().padLeft(2, '0');
    String day = dateTime.day.toString().padLeft(2, '0');

    // Formatear la hora estrictamente en hh:mm:ss (24h en este ejemplo, cambia a % 12 si prefieres 12h)
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String second = dateTime.second.toString().padLeft(2, '0');

    // Combinación manteniendo la fecha completa y la hora requerida
    final String formattedDateTime = '$day/$month/$year $hour:$min:$second';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.access_time_outlined), // Icono en estilo outlined
        const SizedBox(width: 8),
        Text(formattedDateTime),
      ],
    );
  }
}