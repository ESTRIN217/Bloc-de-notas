import 'dart:convert';
import 'dart:io';

import 'package:bloc_de_notas/audioembedbuilder.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform; // Solo se usa si !kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
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
import 'list_item.dart';
import 'editor_screen.dart';
import 'settings_screen.dart';
import 'theme_provider.dart';
import 'updater_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bloc_de_notas/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'drawing_embed.dart';
import 'update_widget.dart';
import 'theme.dart';

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
          if (themeProvider.useDynamicColors && lightDynamic != null && darkDynamic != null) {
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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  bool _isListView = true;
  SortMethod _sortMethod = SortMethod.custom;
  late List<ListItem> _items;
  late List<ListItem> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  bool _isSelectionMode = false;
  final List<ListItem> _selectedItems = [];
  bool _isLoading = true;
  // Definimos el canal de comunicación
  //static const platform = MethodChannel('com.estrin217.bloc_de_notas/settings');
  bool _isTrashView = false; // Controla si estamos viendo el inicio o la papelera
  late List<ListItem> _trashedItems;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _items = [];
    _filteredItems = [];
    _trashedItems = [];
    _searchController.addListener(_filterItems);
    _loadItems();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Llamamos a nuestro nuevo método silencioso
      context.read<UpdaterProvider>().checkUpdateOnStartup();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Retiramos el observador para evitar fugas de memoria
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose(); // Asumo que ya tienes esto
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

  Future<void> _loadItems() async {
    try {
      // 1. Cargamos la preferencia de la vista (Lista o Cuadrícula)
      final prefs = await SharedPreferences.getInstance();
      final savedView = prefs.getBool('is_list_view');
      if (savedView != null) {
        setState(() {
          _isListView = savedView;
        });
      }

      // 2. Cargamos las notas
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
        // CORRECCIÓN: Asignamos ambas notas a la lista al mismo tiempo
        setState(() {
          _items = [_createWelcomeNote(), _createExerciteNote()];
          _filteredItems = _items;
          _isLoading = false;
        });
        _saveItems(); // Guardamos una sola vez con ambas notas ya en la lista
      }
    } catch (e) {
      debugPrint("Error loading items: $e");

      // Manejo de error: también cargamos ambas notas
      setState(() {
        _items = [_createWelcomeNote(), _createExerciteNote()];
        _filteredItems = _items;
        _isLoading = false;
      });
      _saveItems();
    }
    // --- Cargar Papelera ---
      String? trashedContents;
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        trashedContents = prefs.getString('trashed_notes');
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/trashed_notes.json');
        if (await file.exists()) {
          trashedContents = await file.readAsString();
        }
      }

      if (trashedContents != null && trashedContents.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(trashedContents);
        setState(() {
          _trashedItems = jsonList.map((json) => ListItem.fromJson(json)).toList();
        });
      }
  }

  ListItem _createWelcomeNote() {
    final welcomeNote = ListItem(
      id: 'welcome_note',
      title: '¡Bienvenido a Bloc de notas!', // Este es el título en la lista
      summary: jsonEncode([
        // TÍTULO DENTRO DE LA NOTA
        {"insert": "¡Bienvenido a Bloc de notas!"},
        {
          "insert": "\n",
          "attributes": {"header": 1, "align": "center"},
        },

        {
          "insert":
              "Tu nuevo espacio para organizar ideas, código y tareas.\n\n",
        },

        {
          "insert": "Funciones destacadas:",
          "attributes": {"bold": true},
        },
        {"insert": "\n"},
        {"insert": "Soporte para código"},
        {
          "insert": "\n",
          "attributes": {"list": "bullet"},
        },
        {"insert": "Exportación a PDF y Markdown"},
        {
          "insert": "\n",
          "attributes": {"list": "bullet"},
        },
        {"insert": "\n"},
        {
          "insert":
              "Esta es una nota de ejemplo para ayudarte a explorar las funciones.",
        },
        {
          "insert": "\n",
          "attributes": {"blockquote": true},
        },

        {
          "insert": "\nEstilos de Texto:",
          "attributes": {"bold": true, "underline": true},
        },
        {"insert": "\n"},
        {
          "insert": "Texto en negrita",
          "attributes": {"bold": true},
        },
        {"insert": ", "},
        {
          "insert": "cursiva",
          "attributes": {"italic": true},
        },
        {"insert": " y "},
        {
          "insert": "color de fondo",
          "attributes": {"background": "#FFEB3B"},
        },
        {"insert": ".\n\n"},

        {"insert": "Listas y Organización"},
        {
          "insert": "\n",
          "attributes": {"header": 2},
        },
        {"insert": "Tarea pendiente"},
        {
          "insert": "\n",
          "attributes": {"list": "unchecked"},
        },
        {"insert": "Tarea completada"},
        {
          "insert": "\n",
          "attributes": {"list": "checked"},
        },
        {"insert": "\n\nvoid main() {"},
        {
          "insert": "\n",
          "attributes": {"code-block": true},
        },
        {"insert": "  print('Hola desde Bloc de notas');"},
        {
          "insert": "\n",
          "attributes": {"code-block": true},
        },
        {"insert": "}"},
        {
          "insert": "\n",
          "attributes": {"code-block": true},
        },

        {"insert": "\nEnlace útil: "},
        {
          "insert": "Repositorio Flutter Quill",
          "attributes": {"link": "https://pub.dev/packages/flutter_quill"},
        },
        {"insert": "\n"},
      ]),
      lastModified: DateTime.now(),
      // El color amber[200] le da un toque de "post-it" clásico muy bueno
      backgroundColor: Colors.amber[200]!.toARGB32(),
    );
    return welcomeNote;
  }

  ListItem _createExerciteNote() {
    final exerciteNote = ListItem(
      id: 'exercite_note',
      title: '¡Rutina de ejercicios!', // Este es el título en la lista
      summary: jsonEncode([
        {
          "insert": "Prioridad Fuerza",
          "attributes": {"bold": true},
        },
        {"insert": "\nBloque 1: Fuerza y Potencia (Lo más difícil primero)"},
        {
          "insert": "\n",
          "attributes": {"header": 3},
        },
        {
          "insert": "Dominadas (Barras):",
          "attributes": {"bold": true},
        },
        {
          "insert":
              " 10 repeticiones (o 2 series de 5-7 si quieres subir el volumen). ",
        },
        {
          "insert": "Es el ejercicio que más energía consume.",
          "attributes": {"italic": true},
        },
        {
          "insert": "\n",
          "attributes": {"list": "ordered"},
        },
        {
          "insert": "Flexiones en Pica (Pike Push-ups):",
          "attributes": {"bold": true},
        },
        {"insert": " "},
        {
          "insert": "10 repeticiones",
          "attributes": {"bold": true},
        },
        {"insert": ". Si puedes, pon los pies en la silla para que pesen más."},
        {
          "insert": "\n",
          "attributes": {"list": "ordered"},
        },
        {
          "insert": "Flexiones de Diamante:",
          "attributes": {"bold": true},
        },
        {"insert": " 20 repeticiones. "},
        {
          "insert": "Aíslan el tríceps cuando aún tienes fuerza.",
          "attributes": {"italic": true},
        },
        {
          "insert": "\n",
          "attributes": {"list": "ordered"},
        },
        {"insert": "Bloque 2: Resistencia de Empuje (Pecho y Hombros)"},
        {
          "insert": "\n",
          "attributes": {"header": 3},
        },
        {
          "insert": "Flexiones Inclinadas (Pies en silla):",
          "attributes": {"bold": true},
        },
        {"insert": " 20 repeticiones."},
        {
          "insert": "\n",
          "attributes": {"list": "ordered"},
        },
        {
          "insert": "Flexiones de Puños:",
          "attributes": {"bold": true},
        },
        {"insert": " 20 repeticiones."},
        {
          "insert": "\n",
          "attributes": {"list": "ordered"},
        },
        {
          "insert": "Flexiones Normales:",
          "attributes": {"bold": true},
        },
        {"insert": " 20 repeticiones."},
        {
          "insert": "\n",
          "attributes": {"list": "ordered"},
        },
        {
          "insert": "Deltoides Frontales (Hold o dinámicas):",
          "attributes": {"bold": true},
        },
        {"insert": " "},
        {
          "insert": "15 repeticiones",
          "attributes": {"bold": true},
        },
        {"insert": "."},
        {
          "insert": "\n",
          "attributes": {"list": "ordered"},
        },
        {"insert": "Bloque 3: Tren Inferior (Pierna)"},
        {
          "insert": "\n",
          "attributes": {"header": 3},
        },
        {
          "insert": "Sentadillas (Squats):",
          "attributes": {"bold": true},
        },
        {"insert": " "},
        {
          "insert": "30 repeticiones",
          "attributes": {"bold": true},
        },
        {"insert": ". Busca profundidad."},
        {
          "insert": "\n",
          "attributes": {"list": "ordered"},
        },
        {
          "insert": "Zancadas Frontales:",
          "attributes": {"bold": true},
        },
        {"insert": " "},
        {
          "insert": "40 repeticiones",
          "attributes": {"bold": true},
        },
        {"insert": " (20 por pierna)."},
        {
          "insert": "\n",
          "attributes": {"list": "ordered"},
        },
        {
          "insert": "Butt Bridge (Puente de glúteo):",
          "attributes": {"bold": true},
        },
        {"insert": " "},
        {
          "insert": "30 repeticiones",
          "attributes": {"bold": true},
        },
        {"insert": ". Aprieta 2 segundos arriba."},
        {
          "insert": "\n",
          "attributes": {"list": "ordered"},
        },
        {
          "insert": "Pierna adentro y fuera: 30 repeticiones.",
          "attributes": {"bold": true},
        },
        {
          "insert": "\n",
          "attributes": {"list": "ordered"},
        },
        {"insert": "Bloque 4: Core y Cardio Final"},
        {
          "insert": "\n",
          "attributes": {"header": 3},
        },
        {
          "insert": "Elevaciones de Pierna:",
          "attributes": {"bold": true},
        },
        {"insert": " "},
        {
          "insert": "25 repeticiones",
          "attributes": {"bold": true},
        },
        {"insert": ". No dejes que los pies toquen el suelo."},
        {
          "insert": "\n",
          "attributes": {"list": "ordered"},
        },
        {
          "insert": "Escaladores (Mountain Climbers):",
          "attributes": {"bold": true},
        },
        {"insert": " "},
        {
          "insert": "50 repeticiones",
          "attributes": {"bold": true},
        },
        {"insert": ". Hazlas rápidas para quemar."},
        {
          "insert": "\n",
          "attributes": {"list": "ordered"},
        },
        {
          "insert": "Planchas:",
          "attributes": {"bold": true},
        },
        {
          "insert":
              " 3 series de 1 minuto (Descansa solo 30 segundos entre series).",
        },
        {
          "insert": "\n",
          "attributes": {"list": "ordered"},
        },
        {"insert": "\n¿Cómo progresar con esta lista?"},
        {
          "insert": "\n",
          "attributes": {"header": 3},
        },
        {
          "insert": "Descansos:",
          "attributes": {"bold": true},
        },
        {"insert": " Si buscas "},
        {
          "insert": "condición física (quema de grasa y resistencia)",
          "attributes": {"bold": true},
        },
        {"insert": ", intenta descansar solo 45-60 segundos entre ejercicios."},
        {
          "insert": "\n",
          "attributes": {"list": "bullet"},
        },
        {
          "insert": "Aumento de dificultad:",
          "attributes": {"bold": true},
        },
        {
          "insert":
              " Cuando sientas que las 20 flexiones normales son fáciles, hazlas más lentas (3 segundos para bajar, 1 segundo para subir). Eso se llama \"tiempo bajo tensión\" y es brutal para el músculo.",
        },
        {
          "insert": "\n",
          "attributes": {"list": "bullet"},
        },
        {
          "insert": "Frecuencia:",
          "attributes": {"bold": true},
        },
        {
          "insert":
              " Puedes hacer esto 3 o 4 veces por semana, dejando un día de descanso en medio para que el músculo se recupere y crezca.",
        },
        {
          "insert": "\n",
          "attributes": {"list": "bullet"},
        },
        {
          "insert": "Hidratación",
          "attributes": {"bold": true},
        },
        {
          "insert":
              ": Al subir las repeticiones en pierna y los escaladores, vas a sudar mucho más. Bebe agua a sorbos pequeños durante los descansos.",
        },
        {
          "insert": "\n",
          "attributes": {"list": "bullet"},
        },
        {
          "insert": "Escucha a tus muñecas",
          "attributes": {"bold": true},
        },
        {
          "insert":
              ": Como usas la variante de puños y diamante, si sientes mucha presión, puedes rotar un poco la posición de las manos. La variante de puños es excelente para mantener la muñeca neutra (recta), así que úsala a tu favor si sientes molestias.",
        },
        {
          "insert": "\n",
          "attributes": {"list": "bullet"},
        },
        {
          "insert": "Consistencia",
          "attributes": {"bold": true},
        },
        {
          "insert":
              ": Intenta mantener este orden por al menos 4 semanas antes de volver a subir las repeticiones. El cuerpo necesita tiempo para adaptarse mecánicamente a los nuevos ángulos.",
        },
        {
          "insert": "\n",
          "attributes": {"list": "bullet"},
        },
      ]),
      lastModified: DateTime.now(),
    );
    return exerciteNote;
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
    // Elegimos la fuente de datos según la vista
    final sourceList = _isTrashView ? _trashedItems : _items; 
    
    setState(() {
      _filteredItems = sourceList.where((item) {
        final titleMatch = item.title.toLowerCase().contains(query);
        final summaryMatch = item.document.toPlainText().toLowerCase().contains(query);
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
      final itemToDelete = _items.firstWhere((i) => i.id == originalItem.id);
      setState(() {
        _items.removeWhere((i) => i.id == originalItem.id);
        _trashedItems.add(itemToDelete); // Movemos a papelera
        _filterItems();
        _saveItems();
        _saveTrashedItems();
      });
      _showUndoSnackbar([itemToDelete]); // Mostramos SnackBar
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

  void _showUndoSnackbar(List<ListItem> deletedItems) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: const Text('Movido a la papelera'),
        behavior: SnackBarBehavior.floating, // Estilo flotante de Material 3
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () {
            setState(() {
              _trashedItems.removeWhere((item) => deletedItems.contains(item));
              _items.addAll(deletedItems);
              _saveItems();
              _saveTrashedItems();
              _filterItems();
            });
          },
        ),
      ),
    );
  }

  // Modifica _deleteSelectedItems para que maneje la papelera
  void _deleteSelectedItems() async {
    final itemsToDelete = List<ListItem>.from(_selectedItems);
    
    setState(() {
      if (_isTrashView) {
        // Eliminación definitiva desde la papelera
        _cleanupImagesForItems(itemsToDelete);
        _trashedItems.removeWhere((item) => itemsToDelete.contains(item));
        _saveTrashedItems();
      } else {
        // Enviar a la papelera desde el inicio
        _items.removeWhere((item) => itemsToDelete.contains(item));
        _trashedItems.addAll(itemsToDelete);
        _saveItems();
        _saveTrashedItems();
        _showUndoSnackbar(itemsToDelete);
      }
      _exitSelectionMode();
      _filterItems();
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
                  _shareAsHtml(); // Cambié el nombre para mantener el estándar
                },
              ),
              ListTile(
                leading: const Icon(Icons.code_rounded, color: Colors.blue),
                title: Text(AppLocalizations.of(context)!.json_crudo),
                subtitle: const Text(
                  "Formato crudo para respaldo",
                ), // Opcional, para aclarar el formato
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

    pdf.addPage(pw.MultiPage(build: (pw.Context context) => pdfContent));

    final output = await getTemporaryDirectory();
    final file = File(
      "${output.path}/mis_notas_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(text: 'Te comparto mis notas', files: [XFile(file.path)]),
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
      final String fullHtml =
          '''
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
      final File file = File(
        '${directory.path}/notas_${DateTime.now().millisecondsSinceEpoch}.html',
      );

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

  void _shareAsJson() {
    final content = _selectedItems
        .map((item) {
          // Extraemos el Delta del documento y lo convertimos a un String JSON
          final rawJson = jsonEncode(item.document.toDelta().toJson());
          return "${item.title}\n$rawJson";
        })
        .join('\n\n---\n\n');

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: _exitSelectionMode,
        ),
        title: Text('${_selectedItems.length} seleccionados'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.share,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => _showShareMenu(context),
            tooltip: AppLocalizations.of(context)!.share,
          ),
          IconButton(
            icon: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _deleteSelectedItems,
            tooltip: AppLocalizations.of(context)!.delete,
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Container(
        height: 48, // Altura estándar de la barra de búsqueda en Google
        decoration: BoxDecoration(
          // surfaceContainerHigh es el color oficial de Google para cajas de búsqueda
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.search,
            prefixIcon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            border: InputBorder
                .none, // Quitamos el borde para usar el del Container
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12, // Centra el texto verticalmente
              horizontal: 20,
            ),
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isListView ? Icons.grid_view : Icons.view_list,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: _toggleView,
          tooltip: AppLocalizations.of(context)!.toggleView,
        ),
        IconButton(
          icon: Icon(
            Icons.import_export,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: _showSortOptions,
          tooltip: AppLocalizations.of(context)!.sort,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      drawer: Drawer(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerLow, // Color MD3
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
              selected: !_isTrashView,
              onTap: () {
                setState(() => _isTrashView = false);
                _filterItems();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Papelera'),
              selected: _isTrashView,
              onTap: () {
                setState(() => _isTrashView = true);
                _filterItems();
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: Badge(
                isLabelVisible: context.watch<UpdaterProvider>().hasUpdate,
                backgroundColor: Colors.red,
                smallSize: 10,
                child: const Icon(Icons.settings),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
                // }
              },
            ),
            const Divider(),
            const UpdateAvailableWidget(isDrawerTile: true),
            ListTile(
  enabled: false,
  leading: const Icon(Icons.info_outline, size: 20),
  title: FutureBuilder<List<dynamic>>(
    future: Future.wait([
      PackageInfo.fromPlatform(),
      DeviceInfoPlugin().deviceInfo, // Usamos .deviceInfo para que sea genérico
    ]),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        final PackageInfo packageInfo = snapshot.data![0];
        final deviceData = snapshot.data![1];
        
        String platformDetail = "";

        if (kIsWeb) {
          // Extraemos el nombre del navegador y la versión (ej. Chrome 124)
          final webInfo = deviceData as WebBrowserInfo;
          platformDetail = "${webInfo.browserName.name.toUpperCase()} ${webInfo.appVersion.split(' ').first}";
        } else if (Platform.isAndroid) {
          final androidInfo = deviceData as AndroidDeviceInfo;
          platformDetail = androidInfo.supportedAbis.first.toUpperCase();
        } else {
          platformDetail = "NATIVE";
        }

        return Text(
          'Versión ${packageInfo.version} (${packageInfo.buildNumber}) • $platformDetail',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
        );
      }
      
      return const Text('Cargando...', style: TextStyle(fontSize: 12));
    },
  ),
),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_isListView ? _buildListView() : _buildGridView()),
      floatingActionButton: (_isSelectionMode || _isTrashView)
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

    // Determinamos si el fondo actual es oscuro
    final isDarkBackground = _isColorDark(item.backgroundColor);

    // Si el fondo es oscuro -> texto blanco. Si es claro -> texto negro.
    final dynamicTextColor = isDarkBackground ? Colors.white : Colors.black87;
    final dynamicIconColor = isDarkBackground ? Colors.white : Colors.black87;

    // 1. Creamos un controlador temporal solo para renderizar el documento actual
    final previewController = quill.QuillController(
      document: item.document,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );

    // 2. Configuramos el editor en modo lectura
    final richTextPreview = IgnorePointer(
      // IgnorePointer asegura que el toque pase al InkWell de la tarjeta
      child: quill.QuillEditor.basic(
        controller: previewController,
        config: quill.QuillEditorConfig(
          showCursor: false,
          padding: EdgeInsets.zero,
          scrollable: false,

          // AQUÍ ESTÁ EL CAMBIO CLAVE:
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
            // Estilo para el texto pequeño
            small: TextStyle(color: dynamicTextColor, fontSize: 12),
            // 1. Citas (Blockquotes) - La línea con la barra lateral
            quote: quill.DefaultTextBlockStyle(
              TextStyle(
                color: dynamicTextColor,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
              const quill.HorizontalSpacing(16, 0), // Espacio para la barra
              const quill.VerticalSpacing(8, 8),
              const quill.VerticalSpacing(0, 0),
              // Esto es para que la barra lateral no sea blanca si no quieres
              BoxDecoration(
                border: Border(
                  left: BorderSide(
                    width: 4,
                    color: dynamicTextColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),

            // 2. Enlaces (Links)
            link: TextStyle(
              color: isDarkBackground
                  ? Colors.blue[300]
                  : Colors.blue[700], // Azul legible según fondo
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
          ),

          embedBuilders: [
            // 1. Builders personalizados primero
            AudioEmbedBuilder(),
            DrawingEmbedBuilder(),

            // 2. Builders de la librería según la plataforma
            if (kIsWeb)
              ...FlutterQuillEmbeds.editorWebBuilders()
            else
              ...FlutterQuillEmbeds.editorBuilders(),
          ],
        ),
      ),
    );

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
              color: dynamicTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (item.title.isNotEmpty && item.document.length > 1)
          const SizedBox(height: 8),
        if (item.document.length > 1)
          isListView
              ? ClipRect(
                  // Corta el texto que sobrepase el alto máximo
                  child: ConstrainedBox(
                    // Limitamos la altura en la vista de lista (aprox. 9-10 líneas)
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: richTextPreview,
                  ),
                )
              : Expanded(
                  // En GridView, el Expanded tomará el espacio restante
                  child: ClipRect(child: richTextPreview),
                ),
      ],
    );
    final Widget dragIcon = Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 12, 0),
      child: Icon(Icons.drag_handle, color: dynamicIconColor),
    );

    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : (item.backgroundColor != null
                ? Color(item.backgroundColor!)
                : Theme.of(context)
                      .colorScheme
                      .surfaceContainerLow), // Fondo sutil MD3 para tarjetas
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          // Usamos outlineVariant para un borde suave y elegante
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () =>
            _isSelectionMode ? _toggleSelection(item) : _navigateToEditor(item),
        onLongPress: () => !_isSelectionMode ? _startSelectionMode(item) : null,
        child: Ink(
          // Usar Ink para que la decoración no tape el efecto visual
          decoration: item.backgroundImagePath != null && !kIsWeb
              ? BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(item.backgroundImagePath!)),
                    fit: BoxFit.cover,
                    // ColorFilter opcional para asegurar legibilidad del texto
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.1),
                      BlendMode.darken,
                    ),
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
             if (!_isSelectionMode) ...[
                if (isListView) ...[
                  // En LISTA: Mostramos el icono de arrastre si el orden es personalizado
                  if (canReorder)
                    ReorderableDragStartListener(
                      index: _filteredItems.indexOf(item),
                      child: dragIcon,
                    ),
                ] else ...[
                  // En GRIDVIEW: Ocultamos el arrastre y mostramos los tres puntos para selección
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: IconButton(
                      icon: Icon(Icons.more_vert, color: dynamicIconColor),
                      onPressed: () => _startSelectionMode(item),
                      tooltip: AppLocalizations.of(context)!.select,
                    ),
                  ),
                ],
              ],
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
  final scrollController = ScrollController(); // Sincronización obligatoria

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
      onReorder: (ReorderedListFunction<ListItem> reorderCallback) {
        setState(() {
          _items = reorderCallback(_items);
          _filteredItems = List.from(_items);
          _saveItems();
        });
      },
      
      // Se generan las llaves únicas obligatorias para cada hijo
      builder: (children) {
        return GridView(
          controller: scrollController, // El controlador debe ser el mismo
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          children: children,
        );
      },
      children: _filteredItems.map((item) {
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
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 200,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.75,
    ),
    itemCount: _filteredItems.length,
    itemBuilder: (context, index) =>
        _buildItem(_filteredItems[index], isListView: false),
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
  Future<void> _saveTrashedItems() async {
    try {
      final List<Map<String, dynamic>> jsonList = _trashedItems
          .map((item) => item.toJson())
          .toList();
      final contents = jsonEncode(jsonList);
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('trashed_notes', contents);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/trashed_notes.json');
        await file.writeAsString(contents);
      }
    } catch (e) {
      debugPrint("Error guardando papelera: $e");
    }
  }
}
