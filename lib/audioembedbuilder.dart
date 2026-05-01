import 'package:flutter_quill/flutter_quill.dart';
// Eliminamos dart:io de la parte superior para evitar errores de compilación en web
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'dart:io' as io; // Usamos un alias para usarlo solo cuando NO sea web
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'audio'; 

  @override
  bool get expanded => false; 

  @override
  Widget build(
    BuildContext context,
    EmbedContext embedContext,
  ) {
    final controller = embedContext.controller; 
    final node = embedContext.node; 
    final readOnly = embedContext.readOnly; 

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
  final Embed node; 
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
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    }); 

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    }); 

    _audioPlayer.onPlayerStateChanged.listen((state) {
  if (mounted) {
    setState(() => _isPlaying = state == PlayerState.playing);
    if (state == PlayerState.completed) {
      // Agregamos el seek para que el reproductor vuelva al inicio internamente
      _audioPlayer.seek(Duration.zero); 
      setState(() => _position = Duration.zero);
    }
  }
    }); 

    // --- CAMBIO PARA COMPATIBILIDAD WEB ---
    Source source;
    // Si la ruta es una URL, un Blob (Web) o estamos en Web, usamos UrlSource
    if (kIsWeb || widget.audioPath.startsWith('blob:') || widget.audioPath.startsWith('data:')) {
      source = UrlSource(widget.audioPath);
    } else {
      source = DeviceFileSource(widget.audioPath); 
    }

    await _audioPlayer.setSource(source); 
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar audio?'),
        content: Text(kIsWeb 
          ? '¿Quitar este audio de la nota?' 
          : 'Esto eliminará el archivo del dispositivo permanentemente.'), 
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

    await _audioPlayer.stop(); 

    // --- CAMBIO PARA COMPATIBILIDAD WEB ---
    // La eliminación física solo ocurre si NO estamos en la web
    if (!kIsWeb) {
      try {
        final file = io.File(widget.audioPath);
        if (await file.exists()) {
          await file.delete(); 
        }
      } catch (e) {
        debugPrint('Error eliminando el archivo de audio: $e'); 
      }
    }

    final offset = widget.node.documentOffset; 
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
    // UI compatible con Material 3 según tus directrices 
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
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            ),
            iconSize: 36,
            color: Theme.of(context).colorScheme.primary, 
            onPressed: () async {
  if (_isPlaying) {
    await _audioPlayer.pause();
  } else {
    // Si la posición actual es igual o mayor a la duración, 
    // forzamos el regreso al inicio antes de reproducir.
    if (_position >= _duration && _duration > Duration.zero) {
      await _audioPlayer.seek(Duration.zero);
    }
    await _audioPlayer.resume();
  }
}, 
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4, 
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), 
                  ),
                  child: Slider(
                    min: 0,
                    max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1, 
                    value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1), 
                    onChanged: (value) {
                      setState(() {
                        _position = Duration(milliseconds: value.toInt()); 
                      });
                    },
                    onChangeEnd: (value) async {
                      await _audioPlayer.seek(Duration(milliseconds: value.toInt())); 
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_position), style: const TextStyle(fontSize: 12)),
                      Text(_formatDuration(_duration), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!widget.readOnly)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.redAccent,
              onPressed: _deleteAudioPermanently,
            ), 
        ],
      ),
    );
  }
}