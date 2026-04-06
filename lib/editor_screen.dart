import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_to_pdf/flutter_quill_to_pdf.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart' hide ListItem;
import 'package:image_picker/image_picker.dart';
import 'package:markdown_quill/markdown_quill.dart';
import 'package:bloc_de_notas/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'list_item.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

enum TtsState { playing, stopped }

class EditorScreen extends StatefulWidget {
  final ListItem item;

  const EditorScreen({super.key, required this.item});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
  title: Text(
                  AppLocalizations.of(context)!.json_crudo,
                ),
  subtitle: const Text("Formato crudo para respaldo"),
  onTap: () {
    Navigator.pop(context); // Cerramos el menú/modal
    _shareAsJson();        // Ejecutamos la función
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
      ShareParams(
        text: '$title\n\n$markdownContent',
        subject: title,
      ),
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
        width: 595,  // Ancho en puntos (A4)
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
          pw.Header(level: 0, child: pw.Text("Exportación desde Bloc de notas")),
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

  Future<void> shareAsHtml(quill.QuillController controller, String noteTitle) async {
    try {
      final deltaOps = controller.document.toDelta().toJson();

      final converter = QuillDeltaToHtmlConverter(
        deltaOps,
        ConverterOptions(
          converterOptions: OpConverterOptions(inlineStylesFlag: true),
        ),
      );

      final String htmlContent = converter.convert();

      final String fullHtml = '''
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
      
      String fileName = noteTitle.replaceAll(RegExp(r'[^\w\s]+'), '').trim().replaceAll(' ', '_');
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
        )
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
        return Wrap(
          children: <Widget>[
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
          embedButtons: FlutterQuillEmbeds.toolbarButtons(
            imageButtonOptions: QuillToolbarImageButtonOptions(
              // El callback ahora vive dentro de imageButtonConfig
              imageButtonConfig: QuillToolbarImageConfig(
                onImageInsertedCallback: (imagePath) async {
                  await _onImagePickCallback(File(imagePath));
                },
              ),
            ),
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
      return Theme.of(context).brightness == Brightness.dark;
    }
    return Color(colorValue).computeLuminance() < 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isColorDark(_backgroundColorValue);
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white70 : Colors.black54;
    final appBarColor = _backgroundColorValue != null
        ? Color(_backgroundColorValue!)
        : null;

    BoxDecoration? backgroundDecoration;
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
    }

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        _saveAndExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: _saveAndExit,
          ),
          backgroundColor: appBarColor,
          elevation: _backgroundColorValue != null ? 0 : null,
          title: null,
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert, color: textColor),
              onPressed: _showEditorMenu,
            ),
          ],
        ),
        body: Container(
          decoration: backgroundDecoration,
          child: Column(
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
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Título',
                    hintStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: hintColor,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: // Busca tu QuillEditor.basic y actualízalo así:
quill.QuillEditor.basic(
  controller: _contentController,
  config: quill.QuillEditorConfig(
    autoFocus: false,
    placeholder: 'Escribe algo increíble...',
    expands: false,
    padding: EdgeInsets.zero,
    embedBuilders: FlutterQuillEmbeds.editorBuilders(),
  ),
),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          elevation: 0,
          color: Colors.transparent,
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.palette_outlined, color: textColor),
                onPressed: _showBackgroundSheet,
              ),
              IconButton(
                icon: Icon(Icons.text_fields, color: textColor),
                onPressed: _showTextTools,
              ),
              IconButton(
                icon: Icon(
                  _ttsState == TtsState.playing ? Icons.stop : Icons.volume_up,
                  color: textColor,
                ),
                onPressed: _toggleSpeak,
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _onImagePickCallback(File file) async {
    try {
      // 1. Obtenemos el directorio permanente de la aplicación
      final appDir = await getApplicationDocumentsDirectory();
      
      // 2. Creamos una subcarpeta para organizar las imágenes (opcional pero recomendado)
      final imagesDir = Directory('${appDir.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // 3. Generamos un nombre único basado en el tiempo para evitar duplicados
      final String fileName = 'img_${DateTime.now().millisecondsSinceEpoch}${file.path.substring(file.path.lastIndexOf('.'))}';
      final String permanentPath = '${imagesDir.path}/$fileName';

      // 4. Copiamos el archivo de la caché al almacenamiento permanente
      final File savedImage = await file.copy(permanentPath);

      // 5. Insertamos la ruta PERMANENTE en el editor
      final index = _contentController.selection.baseOffset;
      final length = _contentController.selection.extentOffset - index;
      
      _contentController.replaceText(
        index, 
        length, 
        quill.BlockEmbed.image(savedImage.path), 
        null
      );
      
      if (kDebugMode) {
        print('Imagen guardada permanentemente en: ${savedImage.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al guardar la imagen: $e');
      }
      // Aquí podrías mostrar un SnackBar informando el error al usuario
    }
  }
  Future<void> _cleanupImages() async {
  final delta = _contentController.document.toDelta().toJson();
  
  for (final op in delta) {
    if (op.containsKey('insert') && op['insert'] is Map) {
      final insert = op['insert'] as Map;
      if (insert.containsKey('image')) {
        final String path = insert['image'];
        final file = File(path);
        
        // Solo borramos si el archivo está dentro de nuestra carpeta de la app
        if (await file.exists() && path.contains('/app_flutter/images/')) {
          await file.delete();
          if (kDebugMode) print('Imagen eliminada: $path');
        }
      }
    }
  }
}
}
