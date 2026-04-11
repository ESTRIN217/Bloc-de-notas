import 'package:flutter_quill/flutter_quill.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

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

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final QuillController controller;
  final Embed node; // Referencia al nodo dentro del editor
  final bool readOnly;

  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
    required this.controller,
    required this.node,
    this.readOnly = false,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool _isDragging = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  Future<void> _setupAudioPlayer() async {
    // Escuchar cambios de duración
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    // Escuchar la posición actual
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    // Escuchar el estado de reproducción (play/pause/stop/completed)
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);

        // Si el audio termina, devolvemos el slider al principio
        if (state == PlayerState.completed) {
          setState(() => _position = Duration.zero);
        }
      }
    });

    // Usamos DeviceFileSource explicitamente
    final source = DeviceFileSource(widget.audioPath);

    // Asignamos la fuente sin reproducir
    await _audioPlayer.setSource(source);

    // Obtenemos la duración inicial (si está disponible inmediatamente)
    final initialDuration = await _audioPlayer.getDuration();
    if (initialDuration != null && mounted) {
      setState(() => _duration = initialDuration);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _deleteAudioPermanently() async {
    // 1. Confirmar con el usuario
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar audio?'),
        content: const Text(
          'Esto eliminará el archivo del dispositivo permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Detener el reproductor si está sonando
    await _audioPlayer.stop();

    // 3. Eliminar el archivo físico de Android
    try {
      final file = File(widget.audioPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error eliminando el archivo de audio: $e');
    }

    // 4. Eliminar el Embed del documento de Quill
    // Obtenemos la posición exacta del bloque de audio en el documento
    final offset = widget.node.documentOffset;

    // Eliminamos 1 caracter (el bloque embed cuenta como 1 de longitud)
    widget.controller.replaceText(
      offset,
      1,
      '',
      TextSelection.collapsed(offset: offset),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          // Botón Play/Pause
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            ),
            iconSize: 36,
            color: Theme.of(context).colorScheme.primary,
            onPressed: () {
              if (_isPlaying) {
                _audioPlayer.pause();
              } else {
                _audioPlayer.resume();
              }
            },
          ),

          // Slider de progreso y tiempo
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(
                    min: 0,
                    max: _duration.inMilliseconds.toDouble() > 0
                        ? _duration.inMilliseconds.toDouble()
                        : 1,
                    value: _position.inMilliseconds.toDouble().clamp(
                      0.0,
                      _duration.inMilliseconds.toDouble() > 0
                          ? _duration.inMilliseconds.toDouble()
                          : 1,
                    ),
                    onChangeStart: (value) {
                      setState(() => _isDragging = true);
                    },
                    onChanged: (value) {
                      // Solo actualizamos la UI mientras arrastramos, no le pedimos al reproductor que salte aún
                      setState(() {
                        _position = Duration(milliseconds: value.toInt());
                      });
                    },
                    onChangeEnd: (value) async {
                      // Al soltar el dedo, hacemos el seek real en el audio
                      await _audioPlayer.seek(
                        Duration(milliseconds: value.toInt()),
                      );
                      setState(() => _isDragging = false);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Botón Eliminar Permanente (Oculto en solo lectura si quieres)
          if (!widget.readOnly)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.redAccent,
              tooltip: 'Eliminar audio permanentemente',
              onPressed: _deleteAudioPermanently,
            ),
        ],
      ),
    );
  }
}
