import 'dart:convert';
import 'dart:io';
import 'dart:io' as io show Directory, File;
import 'package:bloc_de_notas/embeds/audioembedbuilder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_to_pdf/flutter_quill_to_pdf.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart'
    hide ListItem;
import 'package:image_picker/image_picker.dart';
import 'package:markdown_quill/markdown_quill.dart';
import 'package:bloc_de_notas/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:bloc_de_notas/presentation/widgets/list_item.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:path/path.dart' as path;
import 'package:record/record.dart';
import 'package:bloc_de_notas/embeds/drawing_embed.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // IMPORTANTE AÑADIR
import 'package:bloc_de_notas/embeds/timestampembed.dart';

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
  // NUEVO: Estado de etiquetas
  List<String> _currentTags = [];
  List<String> _availableGlobalTags = [];
  bool _isArchived = false; // NUEVO: Estado de archivo
  bool _isFavorite = false;
  bool _isPinned = false;
  final quill.QuillController _controller = () {
    return quill.QuillController.basic(
      config: quill.QuillControllerConfig(
        clipboardConfig: quill.QuillClipboardConfig(
          enableExternalRichPaste: true,
          onImagePaste: (imageBytes) async {
            if (kIsWeb) {
              // Dart IO is unsupported on the web.
              return null;
            }
            // Save the image somewhere and return the image URL that will be
            // stored in the Quill Delta JSON (the document).
            final newFileName =
                'image-file-${DateTime.now().toIso8601String()}.png';
            final newPath = path.join(
              io.Directory.systemTemp.path,
              newFileName,
            );
            final file = await io.File(
              newPath,
            ).writeAsBytes(imageBytes, flush: true);
            return file.path;
          },
        ),
      ),
    );
  }();
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  

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
    _currentTags = List.from(widget.item.tags); // Inicializamos las etiquetas
    _isArchived = widget.item.isArchived; // Cargar estado inicial
    _isFavorite = widget.item.isFavorite;
    _isPinned = widget.item.isPinned;
    _initTts();
    _loadGlobalTags();
  }

  // NUEVO: Cargar etiquetas globales para el modal
  Future<void> _loadGlobalTags() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _availableGlobalTags = prefs.getStringList('available_tags') ?? [];
    });
  }

  // NUEVO: Guardar una nueva etiqueta global desde el editor
  Future<void> _saveNewGlobalTag(String tag) async {
    if (!_availableGlobalTags.contains(tag)) {
      _availableGlobalTags.add(tag);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('available_tags', _availableGlobalTags);
    }
  }

  // ACTUALIZADO: Método para archivar/desarchivar con opción de deshacer
  void _toggleArchive() {
    setState(() {
      _isArchived = !_isArchived; // Cambiar el estado actual
    });

    // Limpiamos cualquier snackbar previo para evitar acumulación
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isArchived
              ? AppLocalizations.of(context)!.noteArchived
              : AppLocalizations.of(context)!.noteUnarchived,
        ),
        duration: const Duration(
          seconds: 4,
        ), // Damos tiempo suficiente para reaccionar
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.undo,
          // Si el usuario presiona "Deshacer", revertimos el cambio de estado
          onPressed: () {
            setState(() {
              _isArchived = !_isArchived;
            });
          },
        ),
      ),
    );
  }
  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite; // Cambiar el estado actual
    });

    // Limpiamos cualquier snackbar previo para evitar acumulación
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite
              ? AppLocalizations.of(context)!.noteFavorite
              : AppLocalizations.of(context)!.noteUnfavorite,
        ),
        duration: const Duration(
          seconds: 4,
        ), // Damos tiempo suficiente para reaccionar
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.undo,
          // Si el usuario presiona "Deshacer", revertimos el cambio de estado
          onPressed: () {
            setState(() {
              _isFavorite = !_isFavorite;
            });
          },
        ),
      ),
    );
  }
  void _togglePin() {
    setState(() {
      _isPinned = !_isPinned; // Cambiar el estado actual
    });

    // Limpiamos cualquier snackbar previo para evitar acumulación
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isPinned
              ? AppLocalizations.of(context)!.pinned
              : AppLocalizations.of(context)!.unpinned,
        ),
        duration: const Duration(
          seconds: 4,
        ), // Damos tiempo suficiente para reaccionar
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.undo,
          // Si el usuario presiona "Deshacer", revertimos el cambio de estado
          onPressed: () {
            setState(() {
              _isPinned = !_isPinned;
            });
          },
        ),
      ),
    );
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
    _editorScrollController.dispose();
    _editorFocusNode.dispose();
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
      tags: _currentTags, // NUEVO: Pasamos las etiquetas al guardar
      isArchived: _isArchived, // NUEVO: Guardar el estado de archivo
      isFavorite: _isFavorite,
      isPinned: _isPinned,
    );
    Navigator.pop(context, updatedItem);
  }

  // NUEVO: Diálogo para gestionar las etiquetas de la nota actual
  void _showTagsDialog() {
    final TextEditingController newTagController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.noteTagsTitle),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo para crear nueva
                    TextField(
                      controller: newTagController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.newTagHint,
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.clear_outlined),
                          onPressed: () {
                            newTagController.clear();
                            setModalState(() {});
                          },
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_outlined),
                          onPressed: () {
                            final tag = newTagController.text.trim();
                            if (tag.isNotEmpty) {
                              _saveNewGlobalTag(tag);
                              setState(() {
                                if (!_currentTags.contains(tag)) {
                                  _currentTags.add(tag);
                                }
                              });
                              setModalState(() {});
                              newTagController.clear();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.yourTags,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // Lista de etiquetas con checkboxes (estilo Material 3)
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _availableGlobalTags.length,
                        itemBuilder: (context, index) {
                          final tag = _availableGlobalTags[index];
                          final isSelected = _currentTags.contains(tag);

                          return CheckboxListTile(
                            title: Text(tag),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _currentTags.add(tag);
                                } else {
                                  _currentTags.remove(tag);
                                }
                              });
                              setModalState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.done),
                ),
              ],
            );
          },
        );
      },
    );
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
                leading: const Icon(Icons.text_snippet_outlined),
                title: Text(AppLocalizations.of(context)!.texto_plano),
                onTap: () {
                  Navigator.pop(context);
                  _shareAsText();
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_ethernet_outlined),
                title: Text(AppLocalizations.of(context)!.markdown),
                onTap: () {
                  Navigator.pop(context);
                  _shareAsMarkdown();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Colors.red,
                ),
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
                leading: const Icon(Icons.code_outlined, color: Colors.blue),
                title: Text(AppLocalizations.of(context)!.json_crudo),
                subtitle: Text(AppLocalizations.of(context)!.json_subtitle),
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

// --- COMPARTIR COMO PDF DESDE EL EDITOR ---
  Future<void> _shareAsPdf() async {
    final title = _titleController.text;
    final pdfExportHeader = AppLocalizations.of(context)!.pdfExportHeader;
    final untitledText = AppLocalizations.of(context)!.untitled;
    final shareNoteMessage = AppLocalizations.of(context)!.shareNoteMessage(title);
    final pdf = pw.Document();
    final delta = _contentController.document.toDelta();

    final converter = PDFConverter(
      document: delta,
      pageFormat: PDFPageFormat(
        width: 595,
        height: 841,
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
        build: (pw.Context pwContext) => [
          pw.Header(level: 0, child: pw.Text(pdfExportHeader)),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(height: 15),
              pw.Text(
                title.isEmpty ? untitledText : title,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
              ),
              pw.Divider(),
              ?richTextWidget,
              pw.SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );

    String fileName = title.replaceAll(RegExp(r'[^\w\s]+'), '_');
    if (fileName.trim().isEmpty) fileName = "Nota";
    final String fullFileName = "${fileName}_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      // Solución Web libre de dart:io
      final xFile = XFile.fromData(
        pdfBytes,
        name: fullFileName,
        mimeType: 'application/pdf',
      );
      await SharePlus.instance.share(
        ShareParams(text: shareNoteMessage, files: [xFile]),
      );
    } else {
      // Solución Móvil basada en path_provider
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/$fullFileName");
      await file.writeAsBytes(pdfBytes);

      await SharePlus.instance.share(
        ShareParams(text: shareNoteMessage, files: [XFile(file.path)]),
      );
    }
  }

  // --- COMPARTIR COMO HTML DESDE EL EDITOR ---
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

      String fileName = noteTitle
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .trim()
          .replaceAll(' ', '_');
      if (fileName.isEmpty) {
        fileName = 'Nota_Sin_Titulo';
      }
      final String fullFileName = "$fileName.html";

      if (kIsWeb) {
        // Solución Web libre de dart:io
        final htmlBytes = Uint8List.fromList(utf8.encode(fullHtml));
        final xFile = XFile.fromData(
          htmlBytes,
          name: fullFileName,
          mimeType: 'text/html',
        );
        await SharePlus.instance.share(
          ShareParams(
            subject: 'Archivo HTML: $noteTitle',
            text: 'Te comparto esta nota exportada desde Bloc de notas.',
            files: [xFile],
          ),
        );
      } else {
        // Solución Móvil basada en path_provider
        final directory = await getTemporaryDirectory();
        final File file = File('${directory.path}/$fullFileName');
        await file.writeAsString(fullHtml);

        await SharePlus.instance.share(
          ShareParams(
            subject: 'Archivo HTML: $noteTitle',
            text: 'Te comparto esta nota exportada desde Bloc de notas.',
            files: [XFile(file.path)],
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al exportar HTML desde el editor: $e');
      }
    }
  }

  void _shareAsJson() {
    // 1. Obtenemos el título y el contenido en formato Delta JSON
    final title = _titleController.text;
    final summaryJson = jsonEncode(_contentController.document.toDelta().toJson());

    // 2. Creamos una instancia temporal con toda la información real y actualizada
    final currentItem = ListItem(
      id: widget.item.id,
      title: title,
      summary: summaryJson,
      lastModified: DateTime.now(),
      backgroundColor: _backgroundColorValue,
      backgroundImagePath: _backgroundImagePath,
      tags: _currentTags,
      isArchived: _isArchived,
      isFavorite: _isFavorite,
      isPinned: _isPinned,
    );

    // 3. Usamos un encoder con indentación para que el JSON quede ordenado y legible
    const encoder = JsonEncoder.withIndent('  ');
    final String jsonContent = encoder.convert(currentItem.toJson());

    // 4. Enviamos el texto estructurado completo
    SharePlus.instance.share(
      ShareParams(
        text: jsonContent,
        subject: title.isNotEmpty ? title : AppLocalizations.of(context)!.untitled,
      ),
    );
  }

  void _deleteItem() async {
    if (!mounted) return;
    // Quitamos la limpieza de imágenes (await _cleanupImages();)
    // porque ahora la nota irá a la papelera primero.
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
        String fechaFormateada = DateFormat(
          'dd/MM/yyyy HH:mm',
        ).format(widget.item.lastModified);

        return Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                // Center ayuda a que el texto quede centrado en el menú
                child: Text(
                  AppLocalizations.of(context)!.modifiedAt(fechaFormateada),
                  style: const TextStyle(
                    color: Colors
                        .grey, // Un color gris para que parezca información secundaria
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const Divider(height: 1), // Una línea separadora visual
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text(AppLocalizations.of(context)!.share),
              onTap: () => _showShareMenu(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
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
                          ? const Icon(Icons.format_color_reset_outlined)
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
                imageButtonConfig: QuillToolbarImageConfig(
                  onImageInsertedCallback: (imageUrl) async {
                    // imageUrl aquí suele ser algo como 'blob:http://...'
                    if (imageUrl.startsWith('blob:')) {
                      try {
                        // 1. Convertir el blob a bytes usando http
                        final response = await http.get(Uri.parse(imageUrl));
                        final bytes = response.bodyBytes;

                        // 2. Convertir a Base64
                        final base64String = base64Encode(bytes);
                        final base64Image =
                            'data:image/png;base64,$base64String';

                        // 3. Reemplazar la imagen en el controlador
                        // Restamos 1 al offset porque el cursor ya avanzó al insertar la imagen blob
                        final index =
                            _contentController.selection.baseOffset - 1;

                        if (index >= 0) {
                          // Borramos la imagen temporal 'blob' (ocupa 1 de longitud)
                          _contentController.replaceText(index, 1, '', null);
                          // Insertamos la imagen permanente en Base64
                          _contentController.document.insert(
                            index,
                            quill.BlockEmbed.image(base64Image),
                          );
                          // Restauramos el cursor
                          _contentController.updateSelection(
                            TextSelection.collapsed(offset: index + 1),
                            quill.ChangeSource.local,
                          );
                        }
                      } catch (e) {
                        if (kDebugMode) {
                          print('Error al convertir la imagen a Base64: $e');
                        }
                      }
                    }
                  },
                ),
              ),
            ),
            showClipboardPaste: true,
            customButtons: [
              quill.QuillToolbarCustomButtonOptions(
                icon: const Icon(Icons.add_alarm_rounded),
                onPressed: () {
                  _contentController.document.insert(
                    _contentController.selection.extentOffset,
                    TimeStampEmbed(DateTime.now().toString()),
                  );

                  _contentController.updateSelection(
                    TextSelection.collapsed(
                      offset: _contentController.selection.extentOffset + 1,
                    ),
                    quill.ChangeSource.local,
                  );
                },
              ),
            ],
            buttonOptions: quill.QuillSimpleToolbarButtonOptions(
              base: quill.QuillToolbarBaseButtonOptions(
                afterButtonPressed: () {
                  final isDesktop = {
                    TargetPlatform.linux,
                    TargetPlatform.windows,
                    TargetPlatform.macOS,
                  }.contains(defaultTargetPlatform);
                  if (isDesktop) {
                    _editorFocusNode.requestFocus();
                  }
                },
              ),
              linkStyle: quill.QuillToolbarLinkStyleButtonOptions(
                validateLink: (link) {
                  // Treats all links as valid. When launching the URL,
                  // `https://` is prefixed if the link is incomplete (e.g., `google.com` → `https://google.com`)
                  // however this happens only within the editor.
                  return true;
                },
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
              icon: Icon(Icons.arrow_back_outlined, color: dynamicIconColor),
              onPressed: _saveAndExit,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: null,
            actions: [
              IconButton(
                isSelected: _isPinned,
                icon: const Icon(
                  Icons.push_pin_outlined,
                ), // Icono por defecto (sin seleccionar)
                selectedIcon: const Icon(
                  Icons.push_pin
                ), // Icono cuando isSelected es true
                color: dynamicIconColor,
                tooltip: _isPinned
                    ? AppLocalizations.of(context)!.unpin
                    : AppLocalizations.of(context)!.pin,
                onPressed: _togglePin,
              ),
              IconButton(
                isSelected: _isFavorite,
                icon: const Icon(
                  Icons.star_outline,
                ), // Icono por defecto (sin seleccionar)
                selectedIcon: const Icon(
                  Icons.star
                ), // Icono cuando isSelected es true
                color: dynamicIconColor,
                tooltip: _isFavorite
                    ? AppLocalizations.of(context)!.unfavoriteTooltip
                    : AppLocalizations.of(context)!.favorites,
                onPressed: _toggleFavorite,
              ),
              IconButton(
                isSelected: _isArchived,
                icon: const Icon(
                  Icons.archive_outlined,
                ), // Icono por defecto (sin seleccionar)
                selectedIcon: const Icon(
                  Icons.unarchive_outlined,
                ), // Icono cuando isSelected es true
                color: dynamicIconColor,
                tooltip: _isArchived
                    ? AppLocalizations.of(context)!.unarchiveTooltip
                    : AppLocalizations.of(context)!.archiveTooltip,
                onPressed: _toggleArchive,
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: dynamicIconColor),
                onPressed: _showEditorMenu,
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // NUEVO: Visualización de etiquetas justo encima o al lado del título
                  if (_currentTags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _currentTags
                            .map(
                              (tag) => ActionChip(
                                label: Text(
                                  tag,
                                  style: TextStyle(
                                    color: dynamicTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                side: BorderSide.none,
                                onPressed:
                                    _showTagsDialog, // Al tocarlas, abre el diálogo
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: TextField(
                      controller: _titleController,
                      autocorrect: true,
                      enableSuggestions: true,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: dynamicTextColor,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: AppLocalizations.of(context)!.titleHint,
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
                        focusNode: _editorFocusNode,
                        scrollController: _editorScrollController,
                        controller: _contentController,
                        config: quill.QuillEditorConfig(
                          autoFocus: false,
                          placeholder: AppLocalizations.of(
                            context,
                          )!.editorPlaceholder,
                          expands: false,
                          padding: const EdgeInsets.only(bottom: 90),

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
                            h3: quill.DefaultTextBlockStyle(
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
                              TextStyle(
                                color: dynamicTextColor,
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                              const quill.HorizontalSpacing(
                                16,
                                0,
                              ), // Espacio para la barra
                              const quill.VerticalSpacing(8, 8),
                              const quill.VerticalSpacing(0, 0),
                              // Esto es para que la barra lateral no sea blanca si no quieres
                              BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    width: 4,
                                    color: dynamicTextColor.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 2. Enlaces (Links)
                            link: TextStyle(
                              color: isDarkBackground
                                  ? Colors.blue[300]
                                  : Colors
                                        .blue[700], // Azul legible según fondo
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
                            small: TextStyle(
                              color: dynamicTextColor,
                              fontSize: 12,
                            ),
                          ),

                          embedBuilders: [
                            // 1. Builders personalizados primero
                            AudioEmbedBuilder(),
                            DrawingEmbedBuilder(),
                            TimeStampEmbedBuilder(),

                            // 2. Builders de la librería según la plataforma con sus configuraciones internas
                            if (kIsWeb)
                              ...FlutterQuillEmbeds.editorWebBuilders(
                                imageEmbedConfig: QuillEditorImageEmbedConfig(
                                  imageProviderBuilder: (context, imageUrl) {
                                    if (imageUrl.startsWith('assets/')) {
                                      return AssetImage(imageUrl);
                                    }
                                    return null;
                                  },
                                ),
                                videoEmbedConfig:
                                    const QuillEditorWebVideoEmbedConfig(),
                              )
                            else
                              ...FlutterQuillEmbeds.editorBuilders(
                                imageEmbedConfig: QuillEditorImageEmbedConfig(
                                  imageProviderBuilder: (context, imageUrl) {
                                    if (imageUrl.startsWith('assets/')) {
                                      return AssetImage(imageUrl);
                                    }
                                    return null;
                                  },
                                ),
                                videoEmbedConfig: QuillEditorVideoEmbedConfig(
                                  customVideoBuilder: (videoUrl, readOnly) {
                                    return null;
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  // Solo padding inferior, la separación visual por encima del teclado
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize:
                          MainAxisSize.min, // Evita que se estire a los bordes
                      children: [
                        IconButton.outlined(
                          icon: Icon(
                            Icons.palette_outlined,
                            color: dynamicIconColor,
                          ),
                          onPressed: _showBackgroundSheet,
                        ),
                        IconButton.outlined(
                          icon: Icon(
                            Icons.tune_outlined,
                            color: dynamicIconColor,
                          ),
                          onPressed: _showTextTools,
                        ),
                        IconButton.outlined(
                          isSelected: _ttsState == TtsState.playing,
                          // Icono por defecto (cuando NO está seleccionado)
                          icon: Icon(
                            Icons.volume_up_outlined,
                            color: dynamicIconColor,
                          ),
                          // Icono que se muestra cuando isSelected es true
                          selectedIcon: Icon(
                            Icons.stop_outlined,
                            color: dynamicIconColor,
                          ),
                          onPressed: _toggleSpeak,
                        ),

                        IconButton.outlined(
                          icon: Icon(
                            Icons.fiber_manual_record_outlined,
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
            ],
          ),
        ),
      ),
    );
  }

  // --- MÉTODO 1: SELECCIONAR AUDIO EXISTENTE ---
  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.pickFiles(
        // Cambiado a .platform
        type: FileType.audio,
        allowMultiple: false,
        withData: kIsWeb, // Importante: En web necesitamos los bytes
      );

      if (result != null) {
        String audioPath;

        if (kIsWeb) {
          // En web generamos una URL temporal para los bytes del archivo
          final bytes = result.files.single.bytes!;
          audioPath = Uri.dataFromBytes(
            bytes,
            mimeType: 'audio/mpeg',
          ).toString();
        } else {
          // Lógica existente para móviles [cite: 140, 142]
          final dir = await getApplicationDocumentsDirectory();
          final fileName = result.files.single.name;
          final savedFile = await File(
            result.files.single.path!,
          ).copy('${dir.path}/$fileName');
          audioPath = savedFile.path;
        }

        _insertarAudioAlEditor(audioPath);
      }
    } catch (e) {
      debugPrint('Error al seleccionar audio: $e');
    }
  }

  // --- MÉTODO 2: GRABAR NOTA DE VOZ ---
  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        // 1. Apagamos el estado visual inmediatamente para que el botón responda rápido
        setState(() => _isRecording = false);

        // 2. Detenemos la grabación
        final path = await _audioRecorder.stop();
        if (!mounted) return;

        // 3. Verificamos que el path sea válido antes de insertarlo
        if (path != null && path.isNotEmpty) {
          // En web, 'path' será una Blob URL (ej: blob:http://localhost:...)
          _insertarAudioAlEditor(path);
        }
      } else {
        // Verificación de permisos (en web el navegador pedirá permiso automáticamente)
        final hasPermission = await _audioRecorder.hasPermission();

        if (hasPermission) {
          if (kIsWeb) {
            // En web, dejamos RecordConfig() por defecto. El navegador usará su formato
            // nativo más compatible (usualmente WebM o WAV) evitando fallos de codec.
            await _audioRecorder.start(const RecordConfig(), path: '');
          } else {
            final dir = await getApplicationDocumentsDirectory();
            final path =
                '${dir.path}/nota_voz_${DateTime.now().millisecondsSinceEpoch}.m4a';
            await _audioRecorder.start(const RecordConfig(), path: path);
          }

          if (!mounted) return;
          setState(() => _isRecording = true);
        }
      }
    } catch (e) {
      debugPrint('Error en la grabación: $e');
      // Si algo falla catastróficamente, liberamos la interfaz para que no quede atascada
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
                        _isRecording
                            ? Icons.stop_circle_outlined
                            : Icons.mic_outlined,
                        color: _isRecording
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      title: Text(
                        _isRecording
                            ? AppLocalizations.of(context)!.stopRecording
                            : AppLocalizations.of(context)!.recordVoiceNote,
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
                        leading: const Icon(Icons.audio_file_outlined),
                        title: Text(
                          AppLocalizations.of(context)!.selectAudioFile,
                        ),
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
