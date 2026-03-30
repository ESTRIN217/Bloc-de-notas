import 'dart:convert';
import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'list_item.dart';
import 'editor_screen.dart';
import 'settings_screen.dart';
import 'theme_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
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
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            ColorScheme lightColorScheme;
            ColorScheme darkColorScheme;

            if (themeProvider.useDynamicColors &&
                lightDynamic != null &&
                darkDynamic != null) {
              lightColorScheme = lightDynamic;
              darkColorScheme = darkDynamic;
            } else {
              lightColorScheme = ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.light,
              );
              darkColorScheme = ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              );
            }

            return MaterialApp(
              title: 'Flutter Notes',
              theme: ThemeData(
                colorScheme: lightColorScheme,
                useMaterial3: true,
                textTheme: GoogleFonts.notoSansTextTheme(
                  ThemeData(brightness: Brightness.light).textTheme,
                ),
              ),
              darkTheme: ThemeData(
                colorScheme: darkColorScheme,
                useMaterial3: true,
                textTheme: GoogleFonts.notoSansTextTheme(
                  ThemeData(brightness: Brightness.dark).textTheme,
                ),
              ),
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
              home: const MyHomePage(),
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

class _MyHomePageState extends State<MyHomePage> {
  bool _isListView = true;
  SortMethod _sortMethod = SortMethod.custom;
  late List<ListItem> _items;
  late List<ListItem> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  bool _isSelectionMode = false;
  final List<ListItem> _selectedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _items = [];
    _filteredItems = [];
    _searchController.addListener(_filterItems);
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      String? contents;
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        contents = prefs.getString('notes');
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/notes.json');
        if (await file.exists()) {
          contents = await file.readAsString();
        }
      }

      if (contents != null && contents.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(contents);
        setState(() {
          _items = jsonList.map((json) => ListItem.fromJson(json)).toList();
          _filteredItems = _items;
          _sortFilteredItems();
          _isLoading = false;
        });
      } else {
        _createWelcomeNote();
      }
    } catch (e) {
      debugPrint("Error loading items: $e");
      _createWelcomeNote();
    }
  }

  void _createWelcomeNote() {
    final welcomeNote = ListItem(
      id: 'welcome_note',
      title: '¡Bienvenido a Bloc de notas!',
      summary: jsonEncode([
          
  { "insert": "\n", "attributes": { "header": 1, "align": "center" } },
  { "insert": "Tu nuevo espacio para organizar ideas, código y tareas.\n\n" },
  { "insert": "Funciones destacadas:", "attributes": { "bold": true } },
  { "insert": "\n" },
  { "insert": "Soporte para código" },
  { "insert": "\n", "attributes": { "list": "bullet" } },
  { "insert": "Exportación a PDF y Markdown" },
  { "insert": "\n", "attributes": { "list": "bullet" } },
  { "insert": "\n" },
  { "insert": "Prueba a escribir algo aquí abajo..." },
  { "insert": "\n", "attributes": { "blockquote": true } },
        {
          'insert':
              'Esta es una nota de ejemplo para ayudarte a explorar las funciones.\n',
        },
  { "insert": "\n", "attributes": { "header": 1, "align": "center" } },
  { "insert": "Esta nota muestra el poder de " },
  { "insert": "flutter_quill", "attributes": { "bold": true, "color": "#2196F3" } },
  { "insert": " en mi app de Flutter.\n\n" },
  { "insert": "Estilos de Texto:", "attributes": { "bold": true, "underline": true } },
  { "insert": "\n" },
  { "insert": "Texto en negrita", "attributes": { "bold": true } },
  { "insert": ", " },
  { "insert": "cursiva", "attributes": { "italic": true } },
  { "insert": ", " },
  { "insert": "tachado", "attributes": { "strike": true } },
  { "insert": " y con " },
  { "insert": "color de fondo", "attributes": { "background": "#FFEB3B" } },
  { "insert": ".\n\n" },
  { "insert": "Listas y Organización" },
  { "insert": "\n", "attributes": { "header": 2 } },
  { "insert": "Tarea pendiente 1" },
  { "insert": "\n", "attributes": { "list": "unchecked" } },
  { "insert": "Tarea completada" },
  { "insert": "\n", "attributes": { "list": "checked" } },
  { "insert": "Elemento de lista con viñeta" },
  { "insert": "\n", "attributes": { "list": "bullet" } },
  { "insert": "Elemento numerado" },
  { "insert": "\n", "attributes": { "list": "ordered" } },
  { "insert": "\n" },
  { "insert": "Bloques Especiales", "attributes": { "bold": true } },
  { "insert": "\n" },
  { "insert": "Este es un bloque de cita para resaltar pensamientos importantes." },
  { "insert": "\n", "attributes": { "blockquote": true } },
  { "insert": "\n" },
  { "insert": "void main() {\n  print('Hola desde flutter_quill');\n}" },
  { "insert": "\n", "attributes": { "code-block": true } },
  { "insert": "\n" },
  { "insert": "Enlace útil: " },
  { "insert": "Repositorio del proyecto", "attributes": { "link": "https://pub.dev/packages/flutter_quill" } },
  { "insert": "\n" }

      ]),
      lastModified: DateTime.now(),
      backgroundColor: Colors.amber[200]!.toARGB32(),
    );
    setState(() {
      _items = [welcomeNote];
      _filteredItems = _items;
      _isLoading = false;
      _saveItems();
    });
  }

  Future<void> _saveItems() async {
    try {
      final List<Map<String, dynamic>> jsonList = _items
          .map((item) => item.toJson())
          .toList();
      final contents = jsonEncode(jsonList);
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('notes', contents);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/notes.json');
        await file.writeAsString(contents);
      }
    } catch (e) {
      debugPrint("Error saving items: $e");
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _items.where((item) {
        final titleMatch = item.title.toLowerCase().contains(query);
        final summaryMatch = item.document.toPlainText().toLowerCase().contains(
          query,
        );
        return titleMatch || summaryMatch;
      }).toList();
      _sortFilteredItems();
    });
  }

  void _sortFilteredItems() {
    if (_sortMethod == SortMethod.alphabetical) {
      _filteredItems.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    } else if (_sortMethod == SortMethod.byDate) {
      _filteredItems.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    } else if (_sortMethod == SortMethod.custom) {
      _filteredItems.sort((a, b) {
        final aIndex = _items.indexOf(a);
        final bIndex = _items.indexOf(b);
        return aIndex.compareTo(bIndex);
      });
    }
  }

  void _toggleView() {
    setState(() {
      _isListView = !_isListView;
    });
  }

  Future<void> _navigateToEditor([ListItem? item]) async {
    if (_isSelectionMode) return;

    final originalItem =
        item ??
        ListItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '',
          summary: '',
          lastModified: DateTime.now(),
        );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditorScreen(item: originalItem)),
    );

    if (result == null) return;

    if (result == "DELETE") {
      setState(() {
        _items.removeWhere((i) => i.id == originalItem.id);
        _filterItems();
        _saveItems();
      });
    } else if (result is ListItem) {
      setState(() {
        final index = _items.indexWhere((i) => i.id == result.id);

        if (result.title.trim().isEmpty && result.document.length <= 1) {
          if (index != -1) {
            _items.removeAt(index);
          }
          _filterItems();
          _saveItems();
          return;
        }

        if (index != -1) {
          _items[index] = result;
        } else {
          _items.insert(0, result);
        }

        _filterItems();
        _saveItems();
      });
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

  void _deleteSelectedItems() {
    setState(() {
      _items.removeWhere((item) => _selectedItems.contains(item));
      _filterItems();
      _exitSelectionMode();
      _saveItems();
    });
  }

  void _showShareMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(AppLocalizations.of(context)!.exportar_notas_como,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet),
              title:  Text(AppLocalizations.of(context)!.texto_plano),
              onTap: () {
                Navigator.pop(context);
                _shareAsText();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.settings_ethernet_rounded,
              ), // Icono representativo de MD
              title:  Text(AppLocalizations.of(context)!.markdown),
              onTap: () {
                Navigator.pop(context);
                _shareAsMarkdown();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title:  Text(AppLocalizations.of(context)!.archivo_pdf),
              onTap: () {
                Navigator.pop(context);
                _shareAsPdf();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // --- Lógica de procesamiento ---

  void _shareAsText() {
    final content = _selectedItems
        .map((item) => "${item.title}\n${item.document.toPlainText()}")
        .join('\n\n---\n\n');
    SharePlus.instance.share(
      ShareParams(text: content),
    );
    _exitSelectionMode();
  }

  void _shareAsMarkdown() {
  final content = _selectedItems
      .map((item) => "# ${item.title}\n\n${item.document.toPlainText()}")
      .join('\n\n---\n\n');

  // CORRECCIÓN: Crea una instancia de ShareParams con el contenido
  SharePlus.instance.share(
    ShareParams(text: content),
  );
  
  _exitSelectionMode();
}


  Future<void> _shareAsPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text("Mis Notas Exportadas")),
          ..._selectedItems.map((item) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 15),
                pw.Text(
                  item.title,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                pw.Divider(),
                pw.Text(item.document.toPlainText()),
                pw.SizedBox(height: 10),
              ],
            );
          }),
        ],
      ),
    );

    // Guardado y envío
    final output = await getTemporaryDirectory();
    final file = File(
      "${output.path}/notas_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );
    await file.writeAsBytes(await pdf.save());

    // La nueva forma estándar
    await SharePlus.instance.share(
      ShareParams(
        text: 'Te comparto mis notas',
        files: [XFile(file.path)], // El parámetro se llama 'files', no 'xFiles'
      ),
    );
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

  void _setCustomSort() {
    setState(() {
      _sortMethod = SortMethod.custom;
      _filterItems();
    });
    Navigator.pop(context);
  }

  void _sortAlphabetically({bool preserveState = true}) {
    if (preserveState) Navigator.pop(context);
    setState(() {
      _sortMethod = SortMethod.alphabetical;
      _items.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
      _filterItems();
    });
  }

  void _sortByDate({bool preserveState = true}) {
    if (preserveState) Navigator.pop(context);
    setState(() {
      _sortMethod = SortMethod.byDate;
      _items.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      _filterItems();
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (_searchController.text.isNotEmpty) return;

      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);

      _filteredItems = List.from(_items);
      _saveItems();
    });
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelectionMode,
        ),
        title: Text('${_selectedItems.length} seleccionados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showShareMenu(context),
            tooltip: AppLocalizations.of(context)!.share,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteSelectedItems,
            tooltip: AppLocalizations.of(context)!.delete,
          ),
        ],
      );
    }

    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.search,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 20,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isListView ? Icons.grid_view : Icons.view_list),
          onPressed: _toggleView,
          tooltip: AppLocalizations.of(context)!.toggleView,
        ),
        IconButton(
          icon: const Icon(Icons.import_export),
          onPressed: _showSortOptions,
          tooltip: AppLocalizations.of(context)!.sort,
        ),
      ],
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Text(
                AppLocalizations.of(context)!.menu,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(AppLocalizations.of(context)!.home),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(AppLocalizations.of(context)!.settings),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              enabled:
                  false, // Mantiene el ícono y texto con un tono desactivado
              leading: const Icon(
                Icons.info_outline,
                size: 20,
              ), // El nuevo ícono
              title: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final version = snapshot.data!.version;
                    final buildNumber = snapshot.data!.buildNumber;
                    return Text(
                      'Versión $version ($buildNumber) • UNIVERSAL',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  } else {
                    return const Text(
                      'Cargando...',
                      style: TextStyle(fontSize: 12),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_isListView ? _buildListView() : _buildGridView()),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => _navigateToEditor(),
              tooltip: AppLocalizations.of(context)!.addItem,
              child: const Icon(Icons.add),
            ),
    );
  }

  bool _isColorDark(int? colorValue) {
    if (colorValue == null) {
      return Theme.of(context).brightness == Brightness.dark;
    }
    return Color(colorValue).computeLuminance() < 0.5;
  }

  Widget _buildItem(ListItem item, {bool isListView = true}) {
    final isSelected = _selectedItems.contains(item);
    final bool canReorder =
        _sortMethod == SortMethod.custom && _searchController.text.isEmpty;

    final isDark = _isColorDark(item.backgroundColor);
    final textColor = isDark ? Colors.white : Colors.black;

    final plainTextSummary = item.document.toPlainText();

    final contentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.title.isNotEmpty)
          Text(
            item.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (item.title.isNotEmpty && item.document.length > 1)
          const SizedBox(height: 8),
        if (item.document.length > 1)
          isListView
              ? Text(
                  plainTextSummary,
                  style: TextStyle(
                    color: textColor.withAlpha((255 * 0.8).round()),
                  ),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                )
              : Expanded(
                  child: Text(
                    plainTextSummary,
                    style: TextStyle(
                      color: textColor.withAlpha((255 * 0.8).round()),
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
      ],
    );

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      color: isSelected
          ? Theme.of(
              context,
            ).colorScheme.primaryContainer.withAlpha((255 * 0.6).round())
          : (item.backgroundColor != null
                ? Color(item.backgroundColor!)
                : null),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () =>
            _isSelectionMode ? _toggleSelection(item) : _navigateToEditor(item),
        onLongPress: () {
          if (!_isSelectionMode) {
            _startSelectionMode(item);
          }
        },
        child: Container(
          decoration: item.backgroundImagePath != null && !kIsWeb
              ? BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(item.backgroundImagePath!)),
                    fit: BoxFit.cover,
                  ),
                )
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: contentColumn,
                ),
              ),
              if (canReorder && !_isSelectionMode && isListView)
                ReorderableDragStartListener(
                  index: _filteredItems.indexOf(item),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: 12.0,
                      top: 12.0,
                      left: 4.0,
                    ),
                    child: Icon(
                      Icons.drag_handle,
                      color: textColor.withAlpha((255 * 0.6).round()),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    final bool canReorder =
        _sortMethod == SortMethod.custom && _searchController.text.isEmpty;
    if (canReorder) {
      return ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return Container(
            key: ValueKey(item.id),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildItem(item),
          );
        },
        onReorder: _onReorder,
      );
    }
    return ListView.builder(
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildItem(item, isListView: true),
        );
      },
    );
  }

  Widget _buildGridView() {
    final bool canReorder =
        _sortMethod == SortMethod.custom && _searchController.text.isEmpty;
    const gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 200,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.75,
    );

    if (canReorder) {
      return ReorderableGridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: gridDelegate,
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) => Container(
          key: ValueKey(_filteredItems[index].id),
          child: _buildItem(_filteredItems[index], isListView: false),
        ),
        onReorder: _onReorder,
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: gridDelegate,
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) =>
          _buildItem(_filteredItems[index], isListView: false),
    );
  }
}
