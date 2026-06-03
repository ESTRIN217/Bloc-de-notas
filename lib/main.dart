import 'dart:convert';
import 'dart:io';

import 'package:bloc_de_notas/services/backup_service.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:markdown_quill/markdown_quill.dart';
import 'package:flutter_quill_to_pdf/flutter_quill_to_pdf.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart'
    hide ListItem;
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/widgets/list_item.dart';
import 'presentation/screens/editor_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/updater_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bloc_de_notas/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'presentation/widgets/update_widget.dart';
import 'theme/theme.dart';
import 'presentation/widgets/note_item_widget.dart';
import 'presentation/animations/entry_animation.dart';
import 'presentation/search/custom_search_delegate.dart';
import 'providers/notes_provider.dart';
import 'package:bloc_de_notas/presentation/widgets/create_category_dialog.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // Ajusta según tu tema
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),

        ChangeNotifierProvider(create: (context) => UpdaterProvider()),
        
        ChangeNotifierProvider(create: (context) => NotesProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // 1. Definimos el TextTheme base (puedes ajustar el brillo según prefieras)
        final textTheme = GoogleFonts.notoSansTextTheme(
          Theme.of(context).textTheme,
        );

        // 2. Instanciamos tu clase personalizada
        final materialTheme = MaterialTheme(textTheme);

        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            ThemeData lightTheme;
            ThemeData darkTheme;

            // 3. Lógica para colores dinámicos vs. esquema estático de tu archivo
            if (themeProvider.useDynamicColors &&
                lightDynamic != null &&
                darkDynamic != null) {
              // Usamos el método theme() de tu clase con los colores del sistema
              lightTheme = materialTheme.theme(lightDynamic);
              darkTheme = materialTheme.theme(darkDynamic);
            } else {
              // Usamos los esquemas definidos manualmente en tu theme.dart [cite: 6, 21]
              lightTheme = materialTheme.light();
              darkTheme = materialTheme.dark();
            }

            return MaterialApp(
              title: 'Bloc de notas',
              // 4. Asignamos los temas generados por tu clase
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeProvider.themeMode,
              locale: themeProvider.locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                FlutterQuillLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('es'),
                Locale('es', 'VE'),
                Locale('pt'),
                Locale('pt', 'BR'),
              ],
              home: const EntryScreen(),
            );
          },
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  bool _isListView = true;

  bool _isSelectionMode = false;
  final List<ListItem> _selectedItems = [];
  // Definimos el canal de comunicación
  //static const platform = MethodChannel('com.estrin217.bloc_de_notas/settings');
  bool _isTrashView =
      false; // Controla si estamos viendo el inicio o la papelera
  String? _selectedTagFilter;

  bool _isArchiveView = false;
  int? _selectedColorFilter;
  bool _isFavoriteView = false;
  CategoryItem? _selectedCategoryFilter;
  List<ListItem> currentSourceItems = [];
  
  BackupService get _backupService => BackupService();


  @override
  void initState() {
  super.initState();
  _backupService.isSignedIn();
  WidgetsBinding.instance.addObserver(this);
  
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    
    // 1. Cargamos los datos de las notas
    final notesProvider = context.read<NotesProvider>();
    await notesProvider.loadAllData(languageCode);
    
    // 2. RECUPERAMOS EL MODO DE VISTA GUARDADO 
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isListView = prefs.getBool('is_list_view') ?? true; // Si no existe, por defecto es lista
      });
    }
    
    if (mounted) {
      context.read<UpdaterProvider>().checkUpdateOnStartup();
    }
  });
  }

  @override
  void dispose() {
    // Retiramos el observador para evitar fugas de memoria
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Si la app pasó de estar minimizada a estar visible nuevamente
    if (state == AppLifecycleState.resumed) {
      if (kDebugMode) {
        print(
          'La app volvió a primer plano. Buscando actualizaciones silenciosamente...',
        );
      }
      // Llamamos a nuestro método silencioso de nuevo
      context.read<UpdaterProvider>().checkUpdateOnStartup();
    }
  }

  void _archiveSelectedItems() async {
  if (_selectedItems.isEmpty) return;
  if (!context.mounted) return;
  final itemsToMove = List<ListItem>.from(_selectedItems);
  final wasInArchiveView = _isArchiveView;
  final notesProvider = context.read<NotesProvider>();
  final localization = AppLocalizations.of(context)!;

  // Ejecutamos la acción inicial (Si estaba en archivo, va a principal. Si no, se archiva)
  await notesProvider.toggleArchiveMultiple(
    selectedItems: itemsToMove,
    toArchive: !wasInArchiveView,
  );

  setState(() {
    _exitSelectionMode();
  });

  // SnackBar nativo usando tus traducciones existentes
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        wasInArchiveView
            ? localization.notesRestored
            : localization.notesArchived,
      ),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: localization.undo,
        onPressed: () async {
          // Revertir: Volvemos a alternar pero al estado inverso original
          await notesProvider.toggleArchiveMultiple(
            selectedItems: itemsToMove,
            toArchive: wasInArchiveView,
          );
          if (!context.mounted) return;
        },
      ),
    ),
  );
  }

  void _toggleView() async {
    setState(() {
      _isListView = !_isListView;
    });

    // Guardamos la preferencia
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_list_view', _isListView);
  }

  Future<void> _navigateToEditor([ListItem? item]) async {
  if (_isSelectionMode) return;

  final originalItem = item ?? ListItem(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: '',
    summary: '',
    lastModified: DateTime.now(),
    tags: _selectedTagFilter != null ? [_selectedTagFilter!] : [],
  );

  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => EditorScreen(item: originalItem)),
  );

  if (!mounted) return;

  final notesProvider = context.read<NotesProvider>();

  // Si canceló sin retornar datos, recargamos el estado local por si acaso
  if (result == null) return;
  

  // Dejamos que el provider haga toda la magia pesada en background
  await notesProvider.handleEditorResult(
    result: result,
    originalItem: originalItem,
  );

  // Si fue una eliminación, disparamos el snackbar desde aquí usando los datos del Provider
  if (result == "DELETE" && notesProvider.trashedItems.isNotEmpty) {
    _showUndoSnackbar([notesProvider.trashedItems.first]);
  }
  }

  void _startSelectionMode(ListItem item) {
    if (_isSelectionMode) return;
    setState(() {
      _isSelectionMode = true;
      _selectedItems.add(item);
    });
  }

  void _toggleSelection(ListItem item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
      if (_selectedItems.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedItems.clear();
    });
  }

// Diálogo para asignar etiquetas en modo selección
  void _showAssignTagDialog() {
  final notesProvider = context.read<NotesProvider>();
  final localization = AppLocalizations.of(context)!;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(localization.tagNotesTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: notesProvider.availableTags.isEmpty
              ? Text(localization.noTagsCreated)
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: notesProvider.availableTags.length,
                  itemBuilder: (context, index) {
                    final tag = notesProvider.availableTags[index];
                    return ListTile(
                      leading: const Icon(Icons.label_outline), // Iconos outlined preservados
                      title: Text(tag),
                      trailing: const Icon(Icons.sell_outlined), 
                      onTap: () async {
                        // Clonamos la lista para procesarla de forma segura
                        final selectedItemsCopy = List<ListItem>.from(_selectedItems);
                        final itemsCount = selectedItemsCopy.length;

                        // Todo el proceso asíncrono ocurre en el Provider
                        await notesProvider.toggleTagMultiple(
                          selectedItems: selectedItemsCopy,
                          tag: tag,
                        );

                        if (!context.mounted) return;

                        Navigator.pop(context);
                        setState(() {
                          _exitSelectionMode();
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              localization.updatesTag(itemsCount.toString()),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      );
    },
  );
  }

  //   Diálogo para gestionar/crear etiquetas desde el Drawer
  void _showManageTagsDialog() {
    final TextEditingController tagController = TextEditingController();
    final notesProvider = context.read<NotesProvider>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.manageTags),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tagController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.newTagHint,
                        // Icono para limpiar el texto (Equis)
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            tagController.clear();
                            setModalState(() {});
                          },
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final newTag = tagController.text.trim();

                            // VALIDACIÓN: ¿Está vacía o ya existe?
                            if (newTag.isEmpty) return;

                            if (notesProvider.availableTags.any(
                              (t) => t.toLowerCase() == newTag.toLowerCase(),
                            )) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.tagExistsError,
                                  ),
                                ),
                              );
                              return;
                            }

                            setState(() {
                              notesProvider.availableTags.add(newTag);
                              notesProvider.saveTags();
                            });
                            setModalState(() {});
                            tagController.clear();
                          },
                        ),
                      ),
                      onChanged: (text) => setModalState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: notesProvider.availableTags.length,
                        itemBuilder: (context, index) {
                          final tag = notesProvider.availableTags[index];
                          return ListTile(
                            // Icono de etiqueta al inicio
                            leading: const Icon(Icons.label_outline),
                            title: Text(tag),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icono para editar
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () {
                                  
                                    _showRenameTagDialog(tag);
                                  },
                                ),
                                // Icono para eliminar
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    _confirmDeleteTag(tag);
                                  },
                                ),
                              ],
                            ),
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
                  child: Text(AppLocalizations.of(context)!.close),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRenameTagDialog(String oldTag) {
  final TextEditingController renameController = TextEditingController(text: oldTag);
  final notesProvider = context.read<NotesProvider>();
  String? errorText;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.renameTag),
            content: TextField(
              controller: renameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.renameTagLabel,
                errorText: errorText,
                prefixIcon: const Icon(Icons.edit_outlined), // Iconos outlined preservados
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    renameController.clear();
                    setDialogState(() => errorText = null);
                  },
                ),
              ),
              onChanged: (value) {
                if (errorText != null) setDialogState(() => errorText = null);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  final newTag = renameController.text.trim();

                  // 1. Si no hubo cambios en el texto, salimos inmediatamente
                  if (newTag == oldTag) {
                    Navigator.pop(context);
                    return;
                  }

                  // 2. Validación de duplicados consumiendo el estado limpio del Provider
                  bool exists = notesProvider.availableTags.any(
                    (t) => t.toLowerCase() == newTag.toLowerCase() && t != oldTag,
                  );

                  if (exists) {
                    setDialogState(() {
                      errorText = AppLocalizations.of(context)!.tagExistsError;
                    });
                    return;
                  }

                  if (newTag.isNotEmpty) {
                    // 3. Delegamos el renombrado completo al Provider de manera asíncrona
                    await notesProvider.renameTagGlobal(oldTag: oldTag, newTag: newTag);

                    // 4. Actualizamos el filtro de la UI local en caso de que estuviéramos visualizando esta etiqueta
                    if (_selectedTagFilter == oldTag) {
                      setState(() {
                        _selectedTagFilter = newTag;
                      });
                    }

                    if (!context.mounted) return;
                    Navigator.pop(context);
                  }
                },
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          );
        },
      );
    },
  );
  }

  void _showUndoSnackbar(List<ListItem> restoredItems) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(AppLocalizations.of(context)!.movedToTrash), // Ajusta según tu traducción
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: AppLocalizations.of(context)!.undo,
        onPressed: () async {
          // El provider se encarga de reinsertar los ítems en sus listas correctas y guardar
          await context.read<NotesProvider>().restoreFromTrash(restoredItems);
        },
      ),
    ),
  );
  }

  void _deleteSelectedItems() async {
  if (_selectedItems.isEmpty) return;

  final itemsToDelete = List<ListItem>.from(_selectedItems);
  final isTrash = _isTrashView;
  final notesProvider = context.read<NotesProvider>();

  // Ejecutamos la eliminación en el Provider
  await notesProvider.deleteMultiple(
    selectedItems: itemsToDelete,
    isTrashView: isTrash,
    // Pasamos tu función nativa de limpieza de imágenes como callback seguro
    onPermanentDeleteCleanup: (items) => _cleanupImagesForItems(items),
  );

  setState(() {
    _exitSelectionMode();
  });

  // Si no estábamos en la papelera, mostramos la opción de deshacer la acción
  if (!isTrash) {
    _showUndoSnackbar(itemsToDelete);
  }
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
                  _shareAsHtml(); 
                },
              ),
              ListTile(
                leading: const Icon(Icons.code_outlined, color: Colors.blue),
                title: Text(AppLocalizations.of(context)!.json_crudo),
                subtitle: Text(
                  AppLocalizations.of(context)!.json_subtitle,
                ), 
                onTap: () {
                  Navigator.pop(context);
                  _shareAsJson();
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
    final content = _selectedItems
        .map((item) => "${item.title}\n${item.document.toPlainText()}")
        .join('\n\n---\n\n');
    SharePlus.instance.share(ShareParams(text: content));
    _exitSelectionMode();
  }

  void _shareAsMarkdown() {
    final content = _selectedItems
        .map((item) {
          // 1. Extraemos el Delta del documento actual
          final delta = item.document.toDelta();

          // 2. Convertimos ese Delta a Markdown conservando el formato
          final markdownContent = DeltaToMarkdown().convert(delta);

          // 3. Estructuramos el texto final (Título como H1 + contenido)
          return "# ${item.title}\n\n$markdownContent";
        })
        .join('\n\n---\n\n');

    // 4. Compartimos usando la sintaxis correcta de SharePlus
    SharePlus.instance.share(
      ShareParams(
        text: content,
        subject: 'Mis notas en Markdown', // Opcional, útil para correos
      ),
    );

    _exitSelectionMode();
  }

// --- COMPARTIR COMO PDF EN MAIN.DART ---
  Future<void> _shareAsPdf() async {
    final pdf = pw.Document();
    final header = AppLocalizations.of(context)!.misNotasExportadas;
    final untitledText = AppLocalizations.of(context)!.untitled;

    List<pw.Widget> pdfContent = [pw.Header(level: 0, child: pw.Text(header))];
    
    for (var item in _selectedItems) {
      final converter = PDFConverter(
        document: item.document.toDelta(),
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
      pdfContent.add(pw.SizedBox(height: 15));
      pdfContent.add(
        pw.Text(
          item.title.isEmpty ? untitledText : item.title,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
        ),
      );
      pdfContent.add(pw.Divider());

      if (richTextWidget != null) {
        pdfContent.add(richTextWidget);
      }

      pdfContent.add(pw.SizedBox(height: 20));
    }

    pdf.addPage(pw.MultiPage(build: (pw.Context context) => pdfContent));
    
    final String baseName = "mis_notas_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      // Solución Web: Creamos el XFile directo desde los bytes en memoria
      final xFile = XFile.fromData(
        pdfBytes,
        name: baseName,
        mimeType: 'application/pdf',
      );
      await SharePlus.instance.share(
        ShareParams(text: 'Te comparto mis notas', files: [xFile]),
      );
    } else {
      // Solución nativa Móvil existente usando almacenamiento temporal
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/$baseName");
      await file.writeAsBytes(pdfBytes);

      await SharePlus.instance.share(
        ShareParams(text: 'Te comparto mis notas', files: [XFile(file.path)]),
      );
    }
    _exitSelectionMode();
  }

  // --- COMPARTIR COMO HTML EN MAIN.DART ---
  Future<void> _shareAsHtml() async {
    final String shareHtmlMessage = AppLocalizations.of(context)!.shareHtmlMessage;
    try {
      String combinedHtmlContent = '';
      String titlehtml = '';
      
      for (var item in _selectedItems) {
        final List<dynamic> deltaOps = item.document.toDelta().toJson();
        final converter = QuillDeltaToHtmlConverter(
          deltaOps.cast<Map<String, dynamic>>(),
          ConverterOptions(
            converterOptions: OpConverterOptions(inlineStylesFlag: true),
          ),
        );
        final String htmlContent = converter.convert();

        combinedHtmlContent += '<h1>${item.title}</h1>\n$htmlContent\n<hr>\n';
        titlehtml += AppLocalizations.of(context)!.titleHtml;
      }

      final String fullHtml = '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$titlehtml</title>
  <style>
    body { font-family: sans-serif; line-height: 1.6; padding: 20px; color: #333; max-width: 800px; margin: auto; }
    blockquote { border-left: 4px solid #007bff; padding-left: 16px; font-style: italic; color: #555; background: #f9f9f9; padding: 10px 10px 10px 16px;}
    pre { background: #f4f4f4; padding: 15px; border-radius: 8px; overflow-x: auto; font-family: monospace; }
    h1 { color: #222; border-bottom: 2px solid #007bff; padding-bottom: 5px; margin-top: 30px; }
    hr { border: 0; height: 1px; background: #ccc; margin: 30px 0; }
  </style>
</head>
<body>
  $combinedHtmlContent
</body>
</html>
''';

      final String baseName = "notas_${DateTime.now().millisecondsSinceEpoch}.html";

      if (kIsWeb) {
        // Solución Web: Transformamos el String HTML a bytes UTF-8 planos
        final htmlBytes = Uint8List.fromList(utf8.encode(fullHtml));
        final xFile = XFile.fromData(
          htmlBytes,
          name: baseName,
          mimeType: 'text/html',
        );
        await SharePlus.instance.share(
          ShareParams(text: shareHtmlMessage, files: [xFile]),
        );
      } else {
        // Solución nativa Móvil existente
        final directory = await getTemporaryDirectory();
        final File file = File('${directory.path}/$baseName');
        await file.writeAsString(fullHtml);

        await SharePlus.instance.share(
          ShareParams(text: shareHtmlMessage, files: [XFile(file.path)]),
        );
      }
      _exitSelectionMode();
    } catch (e) {
      if (kDebugMode) print('Error al generar el archivo HTML: $e');
    }
  }

  void _shareAsJson() {
    // 1. Convertimos los ítems seleccionados a sus mapas JSON completos usando toJson()
    final jsonList = _selectedItems.map((item) => item.toJson()).toList();
    
    // 2. Usamos un encoder con indentación para que el formato JSON sea legible y estético
    const encoder = JsonEncoder.withIndent('  ');
    
    // 3. Si solo hay una nota seleccionada, compartimos su objeto individual. 
    // Si hay varias, compartimos la lista completa de notas en un array JSON.
    final String content = jsonList.length == 1 
        ? encoder.convert(jsonList.first) 
        : encoder.convert(jsonList);

    // 4. Enviamos el texto estructurado a través de tu canal habitual de SharePlus
    SharePlus.instance.share(ShareParams(text: content));
    
    _exitSelectionMode();
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.sort_by_alpha),
            title: Text(AppLocalizations.of(context)!.sortAlphabetically),
            onTap: () => _sortAlphabetically(),
          ),
          ListTile(
            leading: Icon(Icons.date_range),
            title: Text(AppLocalizations.of(context)!.sortByDate),
            onTap: () => _sortByDate(),
          ),
          ListTile(
            leading: Icon(Icons.drag_handle),
            title: Text(AppLocalizations.of(context)!.customSort),
            onTap: () => _setCustomSort(),
          ),
        ],
      ),
    );
  }

  void _setCustomSort({bool preserveState = true}) {
    if (preserveState) Navigator.pop(context);
    context.read<NotesProvider>().changeSortMethod(SortMethod.custom);
  }

  void _sortAlphabetically({bool preserveState = true}) {
  if (preserveState) Navigator.pop(context);
  context.read<NotesProvider>().changeSortMethod(SortMethod.alphabetical);
  }

void _sortByDate({bool preserveState = true}) {
  if (preserveState) Navigator.pop(context);
  context.read<NotesProvider>().changeSortMethod(SortMethod.byDate);
  }

  void _onReorderItem(int oldIndex, int newIndex) async {
  // Si estamos en la papelera, no permitimos reordenar las notas de la lista principal
  if (_isTrashView) return; 

  // Llamamos al método centralizado del Provider
  await context.read<NotesProvider>().reorderItemByIndex(oldIndex, newIndex);
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: _exitSelectionMode,
        ),
        title: Text('${_selectedItems.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: AppLocalizations.of(context)!.categoriesHeader,
            onPressed: () => showAssignCategoryDialog(context: context, selectedNotes: _selectedItems),
          ),
          IconButton(
            icon: const Icon(Icons.star_outline),
            tooltip: _isFavoriteView
            ? AppLocalizations.of(context)!.unfavoriteTooltip
            : AppLocalizations.of(context)!.favorites,
            onPressed: _toggleFavoriteSelectedItems,
          ),
          IconButton(
            isSelected: !_isArchiveView,
            icon: Icon(
              Icons.unarchive_outlined,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            selectedIcon: Icon(
              Icons.archive_outlined,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _archiveSelectedItems,
            tooltip: _isArchiveView
                ? AppLocalizations.of(context)!.unarchiveTooltip
                : AppLocalizations.of(context)!.archiveTooltip,
          ),
          IconButton(
            icon: Icon(
              Icons.label_outline,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _showAssignTagDialog,
            tooltip: AppLocalizations.of(context)!.tagTooltip,
          ),
          IconButton(
            icon: Icon(
              Icons.share_outlined,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => _showShareMenu(context),
            tooltip: AppLocalizations.of(context)!.share,
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _deleteSelectedItems,
            tooltip: AppLocalizations.of(context)!.delete,
          ),
        ],
      );
    }
    // Título dinámico según la vista
    Widget titleWidget;
    List<Widget> actions = [];

    if (_isTrashView) {
      // PAPELERA: Ocultar búsqueda y opciones, mostrar botón vaciar
      titleWidget = Text(AppLocalizations.of(context)!.papelera);
      actions = [
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined),
          onPressed: _emptyTrash,
          tooltip: AppLocalizations.of(context)!.emptyTrashTitle,
        ),
      ];
    } else {
      // VISTA NORMAL, ARCHIVO O ETIQUETAS
      titleWidget = GestureDetector(
  onTap: () async {
    final notesProvider = context.read<NotesProvider>();

    // Abrimos el buscador inyectando los datos directamente desde el Provider
    final ListItem? selectedNote = await showSearch<ListItem?>(
      context: context,
      delegate: CustomSearchDelegate(
        allNotes: notesProvider.allSearchableNotes,
        availableTags: notesProvider.availableTags,
        availableColors: notesProvider.uniqueNotesColors,
      ),
    );

    // Si el usuario seleccionó una nota desde la búsqueda, la abrimos usando tu editor
    if (selectedNote != null) {
      _navigateToEditor(selectedNote);
    }
  },
  child: SearchBar(
    enabled: false, // Actúa estrictamente como botón visual
    hintText: AppLocalizations.of(context)!.search,
    leading: const Icon(Icons.search_outlined), // Icono outlined preservado
    elevation: WidgetStateProperty.all(0),
    backgroundColor: WidgetStateProperty.all(
      Theme.of(context).colorScheme.surfaceContainerHigh, // Estilo Material 3
    ),
    constraints: const BoxConstraints(minHeight: 48, maxHeight: 48),
  ),
  );

      actions = [
        IconButton(
          isSelected: !_isListView,
          icon: const Icon(Icons.view_agenda_outlined),
          selectedIcon: const Icon(Icons.grid_view),
          onPressed: _toggleView,
        ),
        if (_selectedTagFilter == null)
          // Si NO hay etiqueta seleccionada, mostrar icono de importación (ordenar)
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: _showSortOptions,
            tooltip: AppLocalizations.of(context)!.ordenar,
          )
        else
          // Si HAY una etiqueta seleccionada, mostrar menú de opciones de etiqueta
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'rename') {
                _showRenameTagDialog(_selectedTagFilter!);
              } else if (value == 'delete') {
                _confirmDeleteTag(_selectedTagFilter!);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 12),
                    Text(AppLocalizations.of(context)!.renameTag),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.eliminarEtiqueta,
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ];
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_open),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: titleWidget,
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isHomeView = !_isTrashView && 
                            !_isArchiveView && 
                            !_isFavoriteView &&
                            _selectedTagFilter == null && 
                            _selectedColorFilter == null && 
                            _selectedCategoryFilter == null &&
                            !_isSelectionMode;
    final notesProvider = context.watch<NotesProvider>();
  
    if (_isTrashView) {
  currentSourceItems = notesProvider.sortedTrashedItems;
} else if (_isArchiveView) {
  currentSourceItems = notesProvider.sortedArchivedItems;
} else if (_isFavoriteView) {
  currentSourceItems = notesProvider.sortedFavoriteItems;
} else if (_selectedTagFilter != null) {
  currentSourceItems = notesProvider.sortedItems
      .where((item) => item.tags.contains(_selectedTagFilter!))
      .toList();
} else if (_selectedCategoryFilter != null) {
  // Filtramos las notas ordenadas cuyo categoryId coincida con la categoría seleccionada
  currentSourceItems = notesProvider.sortedItems
      .where((item) => item.categoryId == _selectedCategoryFilter!.id)
      .toList();
} else {
  currentSourceItems = notesProvider.sortedItems;
}

    // 2. Envolvemos el Scaffold con PopScope para interceptar el botón atrás
    return PopScope(
      canPop: isHomeView, // Si es 'true', sale de la app de una. Si es 'false', ejecuta lo de abajo.
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // Si ya se procesó el retroceso normal, no hacemos nada

        // 3. Prioridad 1: Si hay elementos seleccionados, quitamos el modo selección primero
        if (_isSelectionMode) {
          _exitSelectionMode();
        } 
        // 4. Prioridad 2: Si está en otra vista o filtro, restablecemos los valores para volver a Inicio
        else {
          setState(() {
            _isTrashView = false;
            _isArchiveView = false;
            _isFavoriteView = false;
            _selectedTagFilter = null;
            _selectedColorFilter = null;
            _selectedCategoryFilter = null;
          });
          
        }
      },
    child: Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      drawer: Drawer(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerLow, // Color MD3
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: SafeArea(
                bottom:
                    false, // Evita añadir espacio extra en la parte inferior
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  leading: Image.asset(
                    'assets/icon/notas.png',
                    width: 40,
                    height: 40,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.flutterNotes,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                // Redondeado estilo MD3
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),

                // Color de fondo cuando está seleccionado
                selectedTileColor: Theme.of(
                  context,
                ).colorScheme.secondaryContainer,

                // Color del texto e iconos cuando está seleccionado
                selectedColor: Theme.of(
                  context,
                ).colorScheme.onSecondaryContainer,

                // Cambia el icono a uno relleno (opcional) si está seleccionado para más feedback visual
                leading: Icon(
                  !_isTrashView && _selectedTagFilter == null && _selectedCategoryFilter == null && !_isArchiveView && !_isFavoriteView
                      ? Icons
                            .home // Icono relleno
                      : Icons.home_outlined, // Tu icono outlined por defecto
                ),

                title: Text(
                  AppLocalizations.of(context)!.home,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),

                selected:
                    !_isTrashView &&
                    _selectedTagFilter == null &&
                    _selectedCategoryFilter == null &&
                    !_isArchiveView && !_isFavoriteView,

                onTap: () {
                  setState(() {
                    _isTrashView = false;
                    _isArchiveView = false;
                    _isFavoriteView = false;
                    _selectedTagFilter = null;
                    _selectedCategoryFilter = null;
                  });
                   
                  Navigator.pop(context);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                selectedTileColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,

                  // Color del texto e iconos cuando está seleccionado
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.onSecondaryContainer,
                leading: Icon(
                _isFavoriteView
                  ? Icons.star
                  : Icons.star_outline),
                title: Text(AppLocalizations.of(context)!.favorites),
                selected: _isFavoriteView,
                onTap: () {
                  setState(() {
                    _isArchiveView = false;
                    _isFavoriteView = true;
                    _isTrashView = false;
                    _selectedTagFilter = null;
                    _selectedCategoryFilter = null;
                  });
                   
                  Navigator.pop(context);
                },
              ),
            ),
            // NUEVA SECCIÓN: Etiquetas
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.etiquetas,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () {
                      Navigator.pop(context);
                      _showManageTagsDialog();
                    },
                  ),
                ],
              ),
            ),
            ...context.read<NotesProvider>().availableTags.map(
              (tag) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  selectedTileColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,

                  // Color del texto e iconos cuando está seleccionado
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.onSecondaryContainer,
                  leading: Icon(
                  _selectedTagFilter == tag && !_isTrashView
                  ? Icons.label
                  : Icons.label_outline),
                  title: Text(tag),
                  selected: _selectedTagFilter == tag && !_isTrashView,
                  onTap: () {
                    setState(() {
                      _isTrashView = false;
                      _isArchiveView = false;
                      _isFavoriteView = false;
                      _selectedTagFilter = tag;
                      _selectedCategoryFilter = null;
                    });
                     
                    Navigator.pop(context);
                  },
                ),
              ),
            ),

            const Divider(),
Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 4.0,
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        AppLocalizations.of(context)!.categoriesHeader,
        style: Theme.of(context).textTheme.labelSmall,
      ),
      IconButton(
        icon: const Icon(Icons.add_outlined, size: 20), // Icono Outlined
        onPressed: () {
          Navigator.pop(context); // Cierra el Drawer primero
          // Muestra el diálogo utilizando el widget CreateCategoryDialog que ya creaste
          showDialog(
            context: context,
            builder: (context) => const CreateCategoryDialog(),
          );
        },
      ),
    ],
  ),
),
// Mapeamos directamente desde la lista de categorías del Provider
...notesProvider.categories.map(
  (category) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 4,
    ),
    child: ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
      selectedColor: Theme.of(context).colorScheme.onSecondaryContainer,
      leading: Icon(
        _selectedCategoryFilter?.id == category.id && !_isTrashView
            ? Icons.folder
            : Icons.folder_outlined, // Icono Outlined por defecto
      ),
      title: Text(category.name), // Utilizamos la propiedad name de tu CategoryItem
      selected: _selectedCategoryFilter?.id == category.id && !_isTrashView,
      onTap: () {
        setState(() {
          _isTrashView = false;
          _isArchiveView = false;
          _isFavoriteView = false;
          _selectedTagFilter = null; // Limpiamos el filtro de etiqueta al cambiar a una lista
          _selectedCategoryFilter = category;
        });
          
        Navigator.pop(context);
      },
    ),
  ),
),
const Divider(),
            //   Ítem de Archivados
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                selectedTileColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,

                  // Color del texto e iconos cuando está seleccionado
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.onSecondaryContainer,
                leading: Icon(
                _isArchiveView
                  ? Icons.archive
                  : Icons.archive_outlined),
                title: Text(AppLocalizations.of(context)!.archivados),
                selected: _isArchiveView,
                onTap: () {
                  setState(() {
                    _isArchiveView = true;
                    _isFavoriteView = false;
                    _isTrashView = false;
                    _selectedTagFilter = null;
                    _selectedCategoryFilter = null;
                  });
                   
                  Navigator.pop(context);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                selectedTileColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,

                  // Color del texto e iconos cuando está seleccionado
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.onSecondaryContainer,
                leading: Icon(
                 _isTrashView
                  ? Icons.delete
                  : Icons.delete_outline),
                title: Text(AppLocalizations.of(context)!.papelera),
                selected: _isTrashView,
                onTap: () {
                  setState(() {
                    _isTrashView = true;
                    _isArchiveView = false;
                    _isFavoriteView = false;
                    _selectedTagFilter =
                        null;
                    _selectedCategoryFilter = null;
                  });
                   
                  Navigator.pop(context);
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                leading: Badge(
                  isLabelVisible: context.watch<UpdaterProvider>().hasUpdate,
                  backgroundColor: Colors.red,
                  smallSize: 10,
                  child: const Icon(Icons.settings_outlined),
                ),
                title: Text(AppLocalizations.of(context)!.settings),
                onTap: () async {
                  Navigator.pop(context); // Cierra el drawer

                  //if (Platform.isAndroid) {
                  // Lógica para Android: MethodChannel
                  //  final themeProvider = context.read<ThemeProvider>();
                  //   try {
                  //   final Map<dynamic, dynamic>? result = await platform
                  //     .invokeMethod('openNativeSettings', {
                  //     'useDynamicColors': themeProvider.useDynamicColors,
                  //   'themeMode': themeProvider.themeMode.toString(),
                  //  'languageCode': themeProvider.locale.languageCode,
                  //});

                  //if (result != null) {
                  //if (result['useDynamicColors'] != null) {
                  //themeProvider.setUseDynamicColors(
                  //result['useDynamicColors'],
                  //);
                  //}
                  //if (result['themeMode'] != null) {
                  //ThemeMode mode = ThemeMode.system;
                  //if (result['themeMode'] == 'ThemeMode.light') {
                  //  mode = ThemeMode.light;
                  //}
                  //if (result['themeMode'] == 'ThemeMode.dark') {
                  //  mode = ThemeMode.dark;
                  //}
                  //themeProvider.setThemeMode(mode);
                  //}
                  // Puedes agregar aquí la actualización del locale si lo necesitas
                  //}
                  //} on PlatformException catch (e) {
                  //debugPrint(
                  //  "Error al abrir ajustes nativos: '${e.message}'.",
                  //);
                  //}
                  //} else {
                  // Lógica para iOS/Otros: Pantalla de Flutter
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  notesProvider.loadAllData;
                  // }
                },
              ),
            ),
            const Divider(),
            const UpdateAvailableWidget(isDrawerTile: true),
            ListTile(
  enabled: false,
  leading: const Icon(Icons.info_outline, size: 20),
  title: FutureBuilder<List<dynamic>>(
    future: Future.wait([
      PackageInfo.fromPlatform(),
      DeviceInfoPlugin().deviceInfo,
    ]),
    builder: (context, snapshot) {
      // 1. Verificar si hubo un error
      if (snapshot.hasError) {
        return Text(
          AppLocalizations.of(context)!.errorLoadingInfo,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.error,
          ),
        );
      }

      if (snapshot.hasData) {
        try {
          final PackageInfo packageInfo = snapshot.data![0];
          final deviceData = snapshot.data![1];

          String platformDetail = "";

          if (kIsWeb) {
            if (deviceData is WebBrowserInfo) {
              final browserName = deviceData.browserName.name.toUpperCase();
              final userAgent = deviceData.userAgent ?? "";
              String version = "";

              // Expresiones regulares para extraer la versión real según el navegador
              final regexMap = {
                BrowserName.chrome: RegExp(r'Chrome\/([0-9\.]+)'),
                BrowserName.firefox: RegExp(r'Firefox\/([0-9\.]+)'),
                BrowserName.safari: RegExp(r'Version\/([0-9\.]+)'),
                BrowserName.edge: RegExp(r'Edg\/([0-9\.]+)'),
              };

              final regex = regexMap[deviceData.browserName];
              if (regex != null) {
                final match = regex.firstMatch(userAgent);
                if (match != null) {
                  version = match.group(1) ?? "";
                }
              }

              // Fallback por si la detección por Regex falla
              if (version.isEmpty) {
                version = (deviceData.appVersion ?? "").split(' ').first;
              }

              platformDetail = "WEB ($browserName $version)".trim();
            } else {
              platformDetail = "WEB";
            }
          } else {
            // Verificación segura para Android
            final androidInfo = deviceData as AndroidDeviceInfo;
            final arch = androidInfo.supportedAbis.isNotEmpty
                ? androidInfo.supportedAbis.first.toUpperCase()
                : "";
            
            platformDetail = arch.isNotEmpty ? "ANDROID ($arch)" : "ANDROID";
          }

          return Text(
            AppLocalizations.of(context)!.appVersionFull(
              packageInfo.version,
              packageInfo.buildNumber,
              platformDetail,
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          );
        } catch (e) {
          return Text(
            AppLocalizations.of(context)!.formatError,
            style: const TextStyle(fontSize: 12),
          );
        }
      }

      return Text(
        AppLocalizations.of(context)!.loading,
        style: const TextStyle(fontSize: 12),
      );
    },
  ),
),
          ],
        ),
      ),
      body: notesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_isListView ? _buildListView() : _buildGridView()),
      floatingActionButton: (_isSelectionMode || _isTrashView || _isArchiveView)
          ? null
          : FloatingActionButton(
              onPressed: () => _navigateToEditor(),
              tooltip: AppLocalizations.of(context)!.addItem,
              child: const Icon(Icons.add),
            ),
    ),
    );
  }

  Widget _buildItem(ListItem item, {bool isListView = true}) {
    return EntryAnimation(
    key: ValueKey(item.id), // Asegúrate de mantener tus llaves para la lista
    index: currentSourceItems.indexOf(item),
    child: NoteItemWidget(
    item: item,
    isListView: isListView,
    isSelected: _selectedItems.contains(item),
    isSelectionMode: _isSelectionMode,
    canReorder: context.watch<NotesProvider>().currentSortMethod == SortMethod.custom,
    isTrashView: _isTrashView,
    itemIndex: currentSourceItems.indexOf(item),
    moreButtonTooltip: AppLocalizations.of(context)!.select,
    onTap: () {
      if (_isSelectionMode) {
        _toggleSelection(item);
      } else if (_isTrashView) {
        // MOSTRAR DIÁLOGO EN PAPELERA
        showModalBottomSheet(
  context: context,
  builder: (context) {
    final notesProvider = context.read<NotesProvider>();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.restore_outlined), // Iconos outlined preservados
            title: Text(AppLocalizations.of(context)!.restoreNote),
            onTap: () async {
              // Reutilizamos el método existente del Provider pasando el ítem en una lista
              await notesProvider.restoreFromTrash([item]);

              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.red,
            ),
            title: Text(AppLocalizations.of(context)!.deleteForever),
            onTap: () async {
              // Reutilizamos deleteMultiple simulando el estado de la papelera activo (isTrashView: true)
              await notesProvider.deleteMultiple(
                selectedItems: [item],
                isTrashView: true,
                onPermanentDeleteCleanup: (items) => _cleanupImagesForItems(items),
              );

              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  },
);
      } else {
        _navigateToEditor(item);
      }
    },
    onLongPress: () => !_isSelectionMode ? _startSelectionMode(item) : null,
    onMorePressed: () => _startSelectionMode(item),
  ),
  );
}

  Widget _buildListView() {
    final bool canReorder =
        context.watch<NotesProvider>().currentSortMethod == SortMethod.custom;
    if (canReorder) {
      return ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemCount: currentSourceItems.length,
        itemBuilder: (context, index) {
          final item = currentSourceItems[index];
          return Container(
            key: ValueKey(item.id),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildItem(item),
          );
        },
        onReorderItem: _onReorderItem,
      );
    }
    return ListView.builder(
      itemCount: currentSourceItems.length,
      itemBuilder: (context, index) {
        final item = currentSourceItems[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildItem(item, isListView: true),
        );
      },
    );
  }

  Widget _buildGridView() {
  final bool canReorder = context.watch<NotesProvider>().currentSortMethod == SortMethod.custom;
  final scrollController = ScrollController(); // Sincronización obligatoria

  // 1. Detectamos la orientación de la pantalla usando el contexto
  final bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
  
  // 2. Definimos la cantidad exacta de columnas según la orientación
  final int crossAxisCount = isPortrait ? 2 : 3;

  if (canReorder) {
    return ReorderableBuilder<ListItem>(
      key: const Key('reorderable_grid'),
      scrollController: scrollController,
      longPressDelay: const Duration(milliseconds: 300), // UX recomendada
      // Configuración de animaciones y feedback visual
      dragChildBoxDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
        ],
      ),

      // Uso del nuevo callback de reordenamiento de la v5.6.0
      onReorder: (ReorderedListFunction<ListItem> reorderCallback) async {
        final notesProvider = context.read<NotesProvider>();
        // Calculamos la nueva lista ordenada usando la función que provee el Grid
        final updatedList = reorderCallback(notesProvider.items);
        // Le delegamos el nuevo orden y el guardado al Provider de forma asíncrona
        await notesProvider.reorderNotes(updatedList);
      },

      // Se generan las llaves únicas obligatorias para cada hijo
      builder: (children) {
        return GridView(
          controller: scrollController, // El controlador debe ser el mismo
          padding: const EdgeInsets.all(16.0),
          // 3. Cambiamos a FixedCrossAxisCount para forzar el número de columnas
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          children: children,
        );
      },
      children: currentSourceItems.map((item) {
        return Container(
          key: ValueKey(item.id), // Clave única obligatoria
          child: _buildItem(item, isListView: false),
        );
      }).toList(),
    );
  }

  // Vista estática cuando no se puede reordenar
  return GridView.builder(
    padding: const EdgeInsets.all(16.0),
    // 4. Aplicamos el mismo delegado fijo aquí
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.75,
    ),
    itemCount: currentSourceItems.length,
    itemBuilder: (context, index) =>
        _buildItem(currentSourceItems[index], isListView: false),
  );
}

  Future<void> _cleanupImagesForItems(List<ListItem> itemsToClean) async {
    for (final item in itemsToClean) {
      try {
        // 1. Decodificamos el summary que guardaste como JSON
        final List<dynamic> delta = jsonDecode(item.summary);

        for (final op in delta) {
          if (op is Map && op.containsKey('insert') && op['insert'] is Map) {
            final insert = op['insert'] as Map;

            // 2. Buscamos si hay una clave 'image'
            if (insert.containsKey('image')) {
              final String path = insert['image'];
              final file = File(path);

              // 3. Verificamos que sea de nuestra carpeta de caché antes de borrar
              // Ajustado para coincidir con la ruta temporal del image_picker
              if (await file.exists() &&
                      path.contains('com.estrin217.bloc_de_notas/cache') ||
                  path.contains('com.estrin217.bloc_de_notas/app_flutter')) {
                await file.delete();
                if (kDebugMode) {
                  print('Imagen de caché eliminada desde main: $path');
                }
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error al limpiar imágenes de la nota ${item.id}: $e');
        }
      }
    }
  }

  void _emptyTrash() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.emptyTrashTitle),
      content: Text(AppLocalizations.of(context)!.emptyTrashMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: () async {
            final notesProvider = context.read<NotesProvider>();

            // Ejecutamos el vaciado asíncrono en el Provider
            await notesProvider.clearTrash(
              onPermanentDeleteCleanup: (items) => _cleanupImagesForItems(items),
            );

            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: Text(AppLocalizations.of(context)!.emptyTrashAction),
        ),
      ],
    ),
  );
  }

  void _confirmDeleteTag(String tag) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.deleteTagTitle(tag)),
      content: Text(AppLocalizations.of(context)!.deleteTagMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () async {
            final notesProvider = context.read<NotesProvider>();

            // 1. Ejecutar la remoción global en segundo plano
            await notesProvider.deleteTagGlobal(tag);

            // 2. Modificar el estado local de la UI de forma segura
            setState(() {
              _selectedTagFilter = null; // Volvemos a la vista general si estábamos filtrando por ella
            });

            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: Text(
            AppLocalizations.of(context)!.delete,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
  }
  void _toggleFavoriteSelectedItems() async {
  if (_selectedItems.isEmpty) return;

  // Pasamos una copia de la lista de seleccionados para evitar problemas de referencia
  final itemsToToggle = List<ListItem>.from(_selectedItems);

  // Llamada asíncrona al Provider
  await context.read<NotesProvider>().toggleFavoriteMultiple(itemsToToggle);

  // Limpiamos la UI en la vista local
  setState(() {
    _exitSelectionMode();
  });
  }

  void showAssignCategoryDialog({
  required BuildContext context,
  required List<ListItem> selectedNotes,
}) {
  final notesProvider = Provider.of<NotesProvider>(context, listen: false);
  final localizations = AppLocalizations.of(context)!;
  
  // Si es solo una nota, pre-seleccionamos su categoría actual para mejorar la UX
  String? currentSelectedId = selectedNotes.length == 1 ? selectedNotes.first.categoryId : null;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            icon: const Icon(Icons.folder_outlined), // Icono Outlined (MD3 style)
            title: Text(localizations.categoriesHeader),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Opción por defecto para eliminar la nota de cualquier categoría
                  RadioListTile<String?>(
                    title: const Text('No category'),
                    value: null,
                    groupValue: currentSelectedId,
                    onChanged: (value) {
                      setState(() => currentSelectedId = value);
                    },
                  ),
                  const Divider(),
                  // Listado dinámico de categorías existentes
                  ...notesProvider.categories.map((category) {
                    return RadioListTile<String?>(
                      title: Text(category.name),
                      value: category.id,
                      groupValue: currentSelectedId,
                      onChanged: (value) {
                        setState(() => currentSelectedId = value);
                      },
                    );
                  }),
                  const Divider(),
                  // Acción rápida por si desea crear una categoría al instante
                  ListTile(
                    leading: const Icon(Icons.add_outlined),
                    title: Text(localizations.addCategory), // Traducción ej: "Nueva categoría"
                    onTap: () async {
                      final inputController = TextEditingController();
                      final newCatName = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(localizations.addCategory),
                          content: TextField(
                            controller: inputController,
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: localizations.categoryNameLabel,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(localizations.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, inputController.text.trim()),
                              child: Text(localizations.save),
                            ),
                          ],
                        ),
                      );

                      if (newCatName != null && newCatName.isNotEmpty) {
                        await notesProvider.addCategory(newCatName);
                        setState(() {
                          // Forzar redibujado interno del diálogo para que aparezca la nueva categoría
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.cancel),
              ),
              TextButton(
                onPressed: () async {
                  await notesProvider.assignCategoryMultiple(selectedNotes, currentSelectedId);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(localizations.create),
              ),
            ],
          );
        },
      );
    },
  );
  }
}
