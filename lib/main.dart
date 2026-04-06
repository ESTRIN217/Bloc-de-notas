import 'dart:convert';
import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:markdown_quill/markdown_quill.dart';
import 'package:flutter_quill_to_pdf/flutter_quill_to_pdf.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart' hide ListItem;
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
import 'updater_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bloc_de_notas/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        
        ChangeNotifierProvider(create: (context) => UpdaterProvider()),
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
title: '¡Bienvenido a Bloc de notas!', // Este es el título en la lista
summary: jsonEncode([
// TÍTULO DENTRO DE LA NOTA
{ "insert": "¡Bienvenido a Bloc de notas!" },
{ "insert": "\n", "attributes": { "header": 1, "align": "center" } },

{ "insert": "Tu nuevo espacio para organizar ideas, código y tareas.\n\n" },

{ "insert": "Funciones destacadas:", "attributes": { "bold": true } },
{ "insert": "\n" },
{ "insert": "Soporte para código" },
{ "insert": "\n", "attributes": { "list": "bullet" } },
{ "insert": "Exportación a PDF y Markdown" },
{ "insert": "\n", "attributes": { "list": "bullet" } },
{ "insert": "\n" },
{ "insert": "Esta es una nota de ejemplo para ayudarte a explorar las funciones." },
{ "insert": "\n", "attributes": { "blockquote": true } },

{ "insert": "\nEstilos de Texto:", "attributes": { "bold": true, "underline": true } },
{ "insert": "\n" },
{ "insert": "Texto en negrita", "attributes": { "bold": true } },
{ "insert": ", " },
{ "insert": "cursiva", "attributes": { "italic": true } },
{ "insert": " y " },
{ "insert": "color de fondo", "attributes": { "background": "#FFEB3B" } },
{ "insert": ".\n\n" },

{ "insert": "Listas y Organización" },
{ "insert": "\n", "attributes": { "header": 2 } },
{ "insert": "Tarea pendiente" },
{ "insert": "\n", "attributes": { "list": "unchecked" } },
{ "insert": "Tarea completada" },
{ "insert": "\n", "attributes": { "list": "checked" } },

{ "insert": "\n" },
{ "insert": "void main() {\n  print('Hola desde Bloc de notas');\n}" },
{ "insert": "\n", "attributes": { "code-block": true } },

{ "insert": "\nEnlace útil: " },
{ "insert": "Repositorio Flutter Quill", "attributes": { "link": "https://pub.dev/packages/flutter_quill" } },
{ "insert": "\n" }
]),
lastModified: DateTime.now(),
// El color amber[200] le da un toque de "post-it" clásico muy bueno
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
_shareAsHtml(); // Cambié el nombre para mantener el estándar
},
),
ListTile(
  leading: const Icon(Icons.code_rounded, color: Colors.blue),
  title: Text(AppLocalizations.of(context)!.json_crudo), // Asegúrate de tener este string en l10n
  subtitle: const Text("Texto + JSON"), // Opcional, para aclarar el formato
  onTap: () {
    Navigator.pop(context);
    _shareAsJson(); 
  },
),
ListTile(
  leading: const Icon(Icons.data_object_rounded, color: Colors.teal),
  title: Text(AppLocalizations.of(context)!.json_estructurado), 
  subtitle: const Text("Estructura de datos pura"),
  onTap: () {
    Navigator.pop(context);
    _shareAsStrictJson();
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
SharePlus.instance.share(
ShareParams(text: content),
);
_exitSelectionMode();
}

void _shareAsMarkdown() {
final content = _selectedItems.map((item) {
// 1. Extraemos el Delta del documento actual
final delta = item.document.toDelta();

// 2. Convertimos ese Delta a Markdown conservando el formato
final markdownContent = DeltaToMarkdown().convert(delta);

// 3. Estructuramos el texto final (Título como H1 + contenido)
return "# ${item.title}\n\n$markdownContent";
}).join('\n\n---\n\n');

// 4. Compartimos usando la sintaxis correcta de SharePlus
SharePlus.instance.share(
ShareParams(
text: content,
subject: 'Mis notas en Markdown', // Opcional, útil para correos
),
);

_exitSelectionMode();
}

Future<void> _shareAsPdf() async {
final pdf = pw.Document();

List<pw.Widget> pdfContent = [
pw.Header(level: 0, child: pw.Text("Mis Notas Exportadas")),
];

for (var item in _selectedItems) {
// 1. Convertir el delta del documento a widgets de PDF compatibles
final converter = PDFConverter(
document: item.document.toDelta(),
pageFormat: PDFPageFormat(
width: 595, // Ancho (A4)
height: 841, // Alto
marginTop: 20,
marginBottom: 20,
marginLeft: 20,
marginRight: 20,
),
fallbacks: [],
);

// Obtenemos un solo widget (puede ser null)
final pw.Widget? richTextWidget = await converter.generateWidget();

pdfContent.add(pw.SizedBox(height: 15));
pdfContent.add(
pw.Text(
item.title.isEmpty ? "Sin título" : item.title,
style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
),
);
pdfContent.add(pw.Divider());

// CORRECCIÓN: Validamos que no sea nulo y usamos add() en vez de addAll()
if (richTextWidget != null) {
pdfContent.add(richTextWidget);
}

pdfContent.add(pw.SizedBox(height: 20));
}

pdf.addPage(
pw.MultiPage(
build: (pw.Context context) => pdfContent,
),
);

final output = await getTemporaryDirectory();
final file = File(
"${output.path}/mis_notas_${DateTime.now().millisecondsSinceEpoch}.pdf",
);
await file.writeAsBytes(await pdf.save());

await SharePlus.instance.share(
ShareParams(
text: 'Te comparto mis notas',
files: [XFile(file.path)],
),
);

_exitSelectionMode();
}

Future<void> _shareAsHtml() async {
try {
String combinedHtmlContent = '';

// Iteramos sobre todas las notas seleccionadas
for (var item in _selectedItems) {
// 1. Extraemos el Delta directamente del documento y lo pasamos a JSON
final List<dynamic> deltaOps = item.document.toDelta().toJson();

// 2. Configuramos el convertidor
final converter = QuillDeltaToHtmlConverter(
deltaOps.cast<Map<String, dynamic>>(),
ConverterOptions(
converterOptions: OpConverterOptions(inlineStylesFlag: true),
),
);

final String htmlContent = converter.convert();

// 3. Agregamos el título como H1 y el contenido al string combinado, separando con una línea <hr>
combinedHtmlContent += '<h1>${item.title}</h1>\n$htmlContent\n<hr>\n';
}

// 4. Crear el documento HTML completo
final String fullHtml = '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Notas Exportadas</title>
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

// 5. Obtener el directorio temporal
final directory = await getTemporaryDirectory();

// Generamos un nombre genérico ya que pueden ser varias notas
final File file = File('${directory.path}/notas_${DateTime.now().millisecondsSinceEpoch}.html');

// 6. Escribir el contenido en el archivo
await file.writeAsString(fullHtml);

// 7. Compartir el archivo usando la sintaxis correcta de SharePlus
await SharePlus.instance.share(
ShareParams(
text: 'Te comparto mis notas en formato Web',
files: [XFile(file.path)],
),
);

// 8. Salir del modo de selección
_exitSelectionMode();

} catch (e) {
if (kDebugMode) {
print('Error al generar el archivo HTML: $e');
}
}
}

void _shareAsStrictJson() {
  // Creamos una lista de mapas (objetos)
  final List<Map<String, dynamic>> rawData = _selectedItems.map((item) {
    return {
      "title": item.title,
      // toDelta().toJson() ya devuelve una lista dinámica que jsonEncode entiende
      "content": item.document.toDelta().toJson(), 
    };
  }).toList();

  // Convertimos toda la lista a un solo String de JSON formateado
  final content = jsonEncode(rawData);

  SharePlus.instance.share(
    ShareParams(text: content),
  );
  
  _exitSelectionMode();
}

void _shareAsJson() {
  final content = _selectedItems
      .map((item) {
        // Extraemos el Delta del documento y lo convertimos a un String JSON
        final rawJson = jsonEncode(item.document.toDelta().toJson());
        return "${item.title}\n$rawJson";
      })
      .join('\n\n---\n\n');

  SharePlus.instance.share(
    ShareParams(text: content),
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