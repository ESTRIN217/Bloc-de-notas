import 'dart:convert';
import 'dart:io';
import 'package:bloc_de_notas/audioembedbuilder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_to_pdf/flutter_quill_to_pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart'
    hide ListItem;
import 'package:image_picker/image_picker.dart';
import 'package:markdown_quill/markdown_quill.dart';
import 'package:bloc_de_notas/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'list_item.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:record/record.dart';
import 'drawing_embed.dart';
import 'package:intl/intl.dart';

enum TtsState { playing, stopped }

class EditorScreen extends StatefulWidget {
  final ListItem item;

  const EditorScreen({super.key, required this.item});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  late TextEditingController _titleController;
  late quill.QuillController _contentController;
  late FlutterTts _flutterTts;
  TtsState _ttsState = TtsState.stopped;

  int? _backgroundColorValue;
  String? _backgroundImagePath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _contentController = quill.QuillController(
      document: widget.item.document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _backgroundColorValue = widget.item.backgroundColor;
    _backgroundImagePath = widget.item.backgroundImagePath;
    _initTts();
  }

  void _initTts() {
    _flutterTts = FlutterTts();

    _flutterTts.setStartHandler(() {
      if (!mounted) return;
      setState(() {
        _ttsState = TtsState.playing;
      });
    });

    _flutterTts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _ttsState = TtsState.stopped;
      });
    });

    _flutterTts.setErrorHandler((_) {
      if (!mounted) return;
      setState(() {
        _ttsState = TtsState.stopped;
      });
    });
    _flutterTts.setCancelHandler(() {
      if (!mounted) return;
      setState(() {
        _ttsState = TtsState.stopped;
      });
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _saveAndExit() {
    _flutterTts.stop();
    if (!mounted) return;
    final summaryJson = jsonEncode(
      _contentController.document.toDelta().toJson(),
    );

    final updatedItem = ListItem(
      id: widget.item.id,
      title: _titleController.text,
      summary: summaryJson,
      lastModified: DateTime.now(),
      backgroundColor: _backgroundColorValue,
      backgroundImagePath: _backgroundImagePath,
    );
    Navigator.pop(context, updatedItem);
  }

  void _showShareMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppLocalizations.of(context)!.exportar_notas_como,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet),
                title: Text(AppLocalizations.of(context)!.texto_plano),
                onTap: () {
                  Navigator.pop(context);
                  _shareAsText();
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_ethernet_rounded),
                title: Text(AppLocalizations.of(context)!.markdown),
                onTap: () {
                  Navigator.pop(context);
                  _shareAsMarkdown();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(AppLocalizations.of(context)!.archivo_pdf),
                onTap: () {
                  Navigator.pop(context);
                  _shareAsPdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.html, color: Colors.orange),
                title: Text(AppLocalizations.of(context)!.html),
                onTap: () {
                  Navigator.pop(context);
                  shareAsHtml(_contentController, _titleController.text);
                },
              ),
              ListTile(
                leading: const Icon(Icons.code_rounded, color: Colors.blue),
                title: Text(AppLocalizations.of(context)!.json_crudo),
                subtitle: const Text("Formato crudo para respaldo"),
                onTap: () {
                  Navigator.pop(context); // Cerramos el menú/modal
                  _shareAsJson(); // Ejecutamos la función
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // --- Lógica de procesamiento ---

  void _shareAsText() {
    final title = _titleController.text;
    final summary = _contentController.document.toPlainText();
    SharePlus.instance.share(
      ShareParams(text: '$title\n\n$summary', subject: title),
    );
  }

  void _shareAsMarkdown() {
    final title = _titleController.text;
    final delta = _contentController.document.toDelta();

    final markdownContent = DeltaToMarkdown().convert(delta);

    SharePlus.instance.share(
      ShareParams(text: '$title\n\n$markdownContent', subject: title),
    );
  }

  Future<void> _shareAsPdf() async {
    final pdf = pw.Document();
    final title = _titleController.text;

    final delta = _contentController.document.toDelta();

    final converter = PDFConverter(
      document: delta,
      // Usa PDFPageFormat proporcionado por el paquete
      pageFormat: PDFPageFormat(
        width: 595, // Ancho en puntos (A4)
        height: 841, // Alto en puntos
        marginTop: 20,
        marginBottom: 20,
        marginLeft: 20,
        marginRight: 20,
      ),
      fallbacks: [],
    );

    final pw.Widget? richTextWidget = await converter.generateWidget();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text("Exportación desde Bloc de notas"),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(height: 15),
              pw.Text(
                title.isEmpty ? "Sin título" : title,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              pw.Divider(),

              ?richTextWidget,

              pw.SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final fileName = title.replaceAll(RegExp(r'[^\w\s]+'), '_');
    final file = File(
      "${output.path}/${fileName}_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );

    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(
        text: 'Te comparto mi nota: $title',
        files: [XFile(file.path)],
      ),
    );
  }

  Future<void> shareAsHtml(
    quill.QuillController controller,
    String noteTitle,
  ) async {
    try {
      final deltaOps = controller.document.toDelta().toJson();

      final converter = QuillDeltaToHtmlConverter(
        deltaOps,
        ConverterOptions(
          converterOptions: OpConverterOptions(inlineStylesFlag: true),
        ),
      );

      final String htmlContent = converter.convert();

      final String fullHtml =
          '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$noteTitle</title>
  <style>
    body { font-family: sans-serif; line-height: 1.6; padding: 20px; color: #333; }
    blockquote { border-left: 4px solid #007bff; padding-left: 16px; font-style: italic; color: #555; background: #f9f9f9; padding-top: 5px; padding-bottom: 5px;}
    pre { background: #f4f4f4; padding: 15px; border-radius: 8px; overflow-x: auto; font-family: monospace; }
    h1 { color: #222; border-bottom: 1px solid #eee; padding-bottom: 10px; }
  </style>
</head>
<body>
  $htmlContent
</body>
</html>
''';

      final directory = await getTemporaryDirectory();

      String fileName = noteTitle
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .trim()
          .replaceAll(' ', '_');
      if (fileName.isEmpty) {
        fileName = 'Nota_Sin_Titulo';
      }

      final File file = File('${directory.path}/$fileName.html');

      await file.writeAsString(fullHtml);

      // CORRECCIÓN: Actualizado a la sintaxis moderna de SharePlus
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Archivo HTML: $noteTitle',
          text: 'Te comparto esta nota exportada desde Bloc de notas.',
          files: [XFile(file.path)],
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error al exportar desde el editor: $e');
      }
    }
  }

  void _shareAsJson() {
    // 1. Obtenemos el título del controlador
    final title = _titleController.text;

    // 2. Convertimos el contenido de Flutter Quill a JSON (Delta)
    final rawJson = jsonEncode(_contentController.document.toDelta().toJson());

    // 3. Compartimos con el formato híbrido: Título + Separador + JSON
    SharePlus.instance.share(
      ShareParams(
        text: '$title\n\n$rawJson',
        subject: title, // Esto ayuda en apps como Gmail para poner el asunto
      ),
    );
  }

  void _deleteItem() async {
    if (!mounted) return;

    // 1. Limpiamos las imágenes del almacenamiento interno
    await _cleanupImages();

    // 2. VERIFICACIÓN CRÍTICA: ¿Sigue el widget en el árbol después del await?
    if (!mounted) return;

    // 3. Ahora es seguro usar el context para el Navigator
    Navigator.pop(context, "DELETE");
  }

  Future<void> _toggleSpeak() async {
    if (_ttsState == TtsState.playing) {
      await _flutterTts.stop();
      if (mounted) {
        setState(() {
          _ttsState = TtsState.stopped;
        });
      }
    } else {
      final title = _titleController.text;
      final content = _contentController.document.toPlainText();
      final fullText = '$title. $content';
      if (fullText.trim().isNotEmpty) {
        await _flutterTts.speak(fullText);
      }
    }
  }

  void _showEditorMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        String fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(widget.item.lastModified);

        return Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center( // Center ayuda a que el texto quede centrado en el menú
                child: Text(
                  'Modificado el: $fechaFormateada',
                  style: const TextStyle(
                    color: Colors.grey, // Un color gris para que parezca información secundaria
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const Divider(height: 1), // Una línea separadora visual
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(AppLocalizations.of(context)!.share),
              onTap: () => _showShareMenu(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text(AppLocalizations.of(context)!.delete),
              onTap: () {
                Navigator.pop(ctx);
                _deleteItem();
              },
            ),
          ],
        );
      },
    );
  }

  void _showBackgroundSheet() {
    final colors = [
      null, // Default
      Colors.blueGrey[100]!.toARGB32(),
      Colors.amber[200]!.toARGB32(),
      Colors.deepOrange[200]!.toARGB32(),
      Colors.lightGreen[200]!.toARGB32(),
      Colors.teal[100]!.toARGB32(),
      Colors.purple[100]!.toARGB32(),
    ];

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: colors.length,
                itemBuilder: (context, index) {
                  final colorValue = colors[index];
                  final isSelected = _backgroundColorValue == colorValue;

                  return GestureDetector(
                    onTap: () {
                      _changeBackgroundColor(colorValue);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorValue != null
                            ? Color(colorValue)
                            : Theme.of(context).scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: colorValue == null
                          ? const Icon(Icons.format_color_reset)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(AppLocalizations.of(context)!.imageFromGallery),
              onTap: () {
                _pickImage();
                Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }

  void _showTextTools() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return quill.QuillSimpleToolbar(
          controller: _contentController,
          config: quill.QuillSimpleToolbarConfig(
            // Añadimos los botones de extensiones predeterminados (incluye cámara, galería y video)
            embedButtons: FlutterQuillEmbeds.toolbarButtons(
              // Ya no es necesario redefinir imageButtonOptions a menos que
              // quieras cambiar iconos o deshabilitar algo específico.
            ),
          ),
        );
      },
    );
  }

  void _changeBackgroundColor(int? colorValue) {
    setState(() {
      _backgroundColorValue = colorValue;
      _backgroundImagePath = null;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _backgroundImagePath = pickedFile.path;
        _backgroundColorValue = null;
      });
    }
  }

  bool _isColorDark(int? colorValue) {
    if (colorValue == null) {
      // Si no hay color, nos basamos en el brillo del tema actual del sistema
      return Theme.of(context).brightness == Brightness.dark;
    }
    final color = Color(colorValue);
    // computeLuminance() devuelve un valor entre 0.0 (negro) y 1.0 (blanco)
    // Si es menor a 0.5, el color es oscuro.
    return color.computeLuminance() < 0.5;
  }

  @override
  Widget build(BuildContext context) {
    // Determinamos si el fondo actual es oscuro
    final isDarkBackground = _isColorDark(_backgroundColorValue);

    // Si el fondo es oscuro -> texto blanco. Si es claro -> texto negro.
    final dynamicTextColor = isDarkBackground ? Colors.white : Colors.black87;
    final dynamicHintColor = isDarkBackground ? Colors.white70 : Colors.black54;
    final dynamicIconColor = isDarkBackground ? Colors.white : Colors.black87;

    // 1. Configuramos la decoración del fondo.
    // Si no hay color ni imagen seleccionada, usamos el color base de tu tema actual.
    BoxDecoration backgroundDecoration;
    if (_backgroundImagePath != null) {
      backgroundDecoration = BoxDecoration(
        image: DecorationImage(
          image: FileImage(File(_backgroundImagePath!)),
          fit: BoxFit.cover,
        ),
      );
    } else if (_backgroundColorValue != null) {
      backgroundDecoration = BoxDecoration(
        color: Color(_backgroundColorValue!),
      );
    } else {
      backgroundDecoration = BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      );
    }

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        _saveAndExit();
      },
      // 2. Envolvemos toda la estructura en el Container que tiene tu fondo
      child: Container(
        decoration: backgroundDecoration,
        child: Scaffold(
          // 3. Hacemos que el Scaffold y el AppBar sean invisibles para que se vea el fondo de atrás
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: dynamicIconColor),
              onPressed: _saveAndExit,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: null,
            actions: [
              IconButton(
                icon: Icon(Icons.more_vert, color: dynamicIconColor),
                onPressed: _showEditorMenu,
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: TextField(
                  controller: _titleController,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: dynamicTextColor,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Título',
                    hintStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: dynamicHintColor,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),

                  // Envolvemos el editor en un Theme para forzar el color de todo el texto
                  child: quill.QuillEditor.basic(
                    controller: _contentController,
                    config: quill.QuillEditorConfig(
                      autoFocus: false,
                      placeholder: 'Escribe algo increíble...',
                      expands: false,
                      padding: EdgeInsets.zero,

                      customStyles: quill.DefaultStyles(
                        // Estilo para texto normal
                        paragraph: quill.DefaultTextBlockStyle(
                          TextStyle(color: dynamicTextColor, fontSize: 16),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(0, 0),
                          const quill.VerticalSpacing(0, 0),
                          null,
                        ),
                        // Estilo para Títulos Grandes (H1)
                        h1: quill.DefaultTextBlockStyle(
                          TextStyle(
                            color: dynamicTextColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(10, 0),
                          const quill.VerticalSpacing(0, 0),
                          null,
                        ),
                        // Estilo para Títulos Medianos (H2)
                        h2: quill.DefaultTextBlockStyle(
                          TextStyle(
                            color: dynamicTextColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(8, 0),
                          const quill.VerticalSpacing(0, 0),
                          null,
                        ),
                        // Estilo para Listas (Bullets y Checkboxes)
                        lists: quill.DefaultListBlockStyle(
                          TextStyle(color: dynamicTextColor, fontSize: 16),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(0, 0),
                          const quill.VerticalSpacing(0, 0),
                          null,
                          null, // Algunos versiones requieren un parámetro extra aquí para el checkbox
                        ),
                          // 1. Citas (Blockquotes) - La línea con la barra lateral
  quote: quill.DefaultTextBlockStyle(
    TextStyle(color: dynamicTextColor, fontSize: 16, fontStyle: FontStyle.italic),
    const quill.HorizontalSpacing(16, 0), // Espacio para la barra
    const quill.VerticalSpacing(8, 8),
    const quill.VerticalSpacing(0, 0),
    // Esto es para que la barra lateral no sea blanca si no quieres
    BoxDecoration(
      border: Border(left: BorderSide(width: 4, color: dynamicTextColor.withValues(alpha: 0.3))),
    ),
  ),

  // 2. Enlaces (Links)
  link: TextStyle(
    color: isDarkBackground ? Colors.blue[300] : Colors.blue[700], // Azul legible según fondo
    decoration: TextDecoration.underline,
  ),

  // 4. Marcadores de listas (Los puntitos o números)
  indent: quill.DefaultTextBlockStyle(
    TextStyle(color: dynamicTextColor),
    const quill.HorizontalSpacing(0, 0),
    const quill.VerticalSpacing(0, 0),
    const quill.VerticalSpacing(0, 0),
    null,
  ),

  // 5. Estilo "Leading" (Para asegurar que el checkbox/bullet use el color)
  leading: quill.DefaultTextBlockStyle(
    TextStyle(color: dynamicTextColor),
    const quill.HorizontalSpacing(0, 0),
    const quill.VerticalSpacing(0, 0),
    const quill.VerticalSpacing(0, 0),
    null,
  ),
                        // Estilo para el texto pequeño
                        small: TextStyle(color: dynamicTextColor, fontSize: 12),
                      ),

                      embedBuilders: [
                        ...FlutterQuillEmbeds.editorBuilders(),
                        AudioEmbedBuilder(),
                        DrawingEmbedBuilder(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomAppBar(
            elevation: 0,
            color: Colors.transparent,
            child: Row(
              children: [
                IconButton.outlined(
                  icon: Icon(Icons.palette_outlined, color: dynamicIconColor),
                  onPressed: _showBackgroundSheet,
                ),
                IconButton.outlined(
                  icon: Icon(Icons.tune, color: dynamicIconColor),
                  onPressed: _showTextTools,
                ),
                IconButton.outlined(
                  icon: Icon(
                    _ttsState == TtsState.playing
                        ? Icons.stop
                        : Icons.volume_up,
                    color: dynamicIconColor,
                  ),
                  onPressed: _toggleSpeak,
                ),
                IconButton.outlined(
                  icon: Icon(
                    Icons.fiber_manual_record,
                    color: dynamicIconColor,
                  ),
                  onPressed: _showAudioMenu,
                ),
                IconButton.outlined(
                  icon: Icon(Icons.gesture, color: dynamicIconColor),
                  onPressed: _insertarLienzo,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cleanupImages() async {
    final delta = _contentController.document.toDelta().toJson();

    for (final op in delta) {
      if (op.containsKey('insert') && op['insert'] is Map) {
        final insert = op['insert'] as Map;
        if (insert.containsKey('image')) {
          final String path = insert['image'];
          final file = File(path);

          // Verificamos que el archivo exista Y que esté dentro de tu carpeta de caché
          if (await file.exists() &&
              path.contains('com.estrin217.bloc_de_notas/cache')) {
            await file.delete();
            if (kDebugMode) {
              print('Imagen eliminada de la caché (Editor): $path');
            }
          }
        }
      }
    }
  }

  // --- MÉTODO 1: SELECCIONAR AUDIO EXISTENTE ---
  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final originalPath = result.files.single.path!;

        // (Opcional pero recomendado) Copiar el archivo a la carpeta de tu app
        // para que si el usuario lo borra de "Descargas", la nota no se rompa.
        final dir = await getApplicationDocumentsDirectory();
        final fileName = result.files.single.name;
        final savedFile = await File(
          originalPath,
        ).copy('${dir.path}/$fileName');

        _insertarAudioAlEditor(savedFile.path);
      }
    } catch (e) {
      debugPrint('Error al seleccionar audio: $e');
    }
  }

  // --- MÉTODO 2: GRABAR NOTA DE VOZ ---
  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        // DETENER GRABACIÓN
        final path = await _audioRecorder.stop();

        // GUARDIA: Verificar si el widget sigue en el árbol antes de actualizar UI
        if (!mounted) return;
        setState(() => _isRecording = false);

        if (path != null) {
          _insertarAudioAlEditor(path);
        }
      } else {
        // INICIAR GRABACIÓN
        final status = await Permission.microphone.request();

        if (status.isGranted) {
          final dir = await getApplicationDocumentsDirectory();
          final path =
              '${dir.path}/nota_voz_${DateTime.now().millisecondsSinceEpoch}.m4a';

          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: path,
          );

          if (!mounted) return; // Guardia tras el await de inicio
          setState(() => _isRecording = true);
        } else {
          // GUARDIA: Antes de usar el context para el SnackBar
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se requiere permiso de micrófono para grabar'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error en la grabación: $e');
      if (mounted) {
        setState(() => _isRecording = false);
      }
    }
  }

  // (El método que ya teníamos del paso anterior)
  void _insertarAudioAlEditor(String filePath) {
    final index = _contentController.selection.baseOffset;
    _contentController.document.insert(
      index,
      quill.BlockEmbed.custom(quill.CustomBlockEmbed('audio', filePath)),
    );
    _contentController.updateSelection(
      TextSelection.collapsed(offset: index + 1),
      quill.ChangeSource.local,
    );
  }

  void _showAudioMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Usamos un StatefulBuilder para poder actualizar el UI del BottomSheet
        // (por ejemplo, cambiar el texto a "Grabando..." en tiempo real)
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(
                        _isRecording ? Icons.stop_circle : Icons.mic,
                        color: _isRecording
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      title: Text(
                        _isRecording
                            ? 'Detener grabación'
                            : 'Grabar nota de voz',
                        style: TextStyle(
                          color: _isRecording ? Colors.red : null,
                          fontWeight: _isRecording ? FontWeight.bold : null,
                        ),
                      ),
                      onTap: () async {
                        // 1. Ejecutamos la grabación (contiene awaits internos)
                        await _toggleRecording();

                        // 2. Verificamos si el contexto del modal/botón sigue vivo
                        if (!context.mounted) return;

                        // 3. Actualizamos el estado del modal de forma segura
                        setModalState(() {});

                        // 4. Si terminó de grabar, cerramos el modal usando el context validado
                        if (!_isRecording) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    if (!_isRecording) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.audio_file),
                        title: const Text('Seleccionar archivo de audio'),
                        onTap: () {
                          Navigator.pop(context);
                          _pickAudioFile();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _insertarLienzo() {
    final index = _contentController.selection.baseOffset;
    // Insertamos el bloque personalizado "drawing"
    _contentController.document.insert(
      index,
      quill.BlockEmbed.custom(const DrawingBlockEmbed('nuevo_dibujo')),
    );
    // Movemos el cursor justo debajo del dibujo
    _contentController.updateSelection(
      TextSelection.collapsed(offset: index + 1),
      quill.ChangeSource.local,
    );
  }
}
