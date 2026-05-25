import 'dart:convert';
import 'dart:io';

import 'package:bloc_de_notas/services/backup_service.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
// Solo se usa si !kIsWeb
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
  SortMethod _sortMethod = SortMethod.custom;
  late List<ListItem> _items;

  bool _isSelectionMode = false;
  final List<ListItem> _selectedItems = [];
  bool _isLoading = true;
  // Definimos el canal de comunicación
  //static const platform = MethodChannel('com.estrin217.bloc_de_notas/settings');
  bool _isTrashView =
      false; // Controla si estamos viendo el inicio o la papelera
  late List<ListItem> _trashedItems;
  List<String> _availableTags = [];
  String? _selectedTagFilter;
  //   Variables para Archivo
  late List<ListItem> _archivedItems;
  late List<ListItem> _favoriteItems;
  bool _isArchiveView = false;
  int? _selectedColorFilter;
  bool _isFavoriteView = false;
  List<ListItem> get _currentSourceItems {
  if (_isTrashView) return _trashedItems;
  if (_isArchiveView) return _archivedItems;
  if (_isFavoriteView) return _favoriteItems;
  
  // Filtra dinámicamente por la etiqueta seleccionada en la barra lateral
  if (_selectedTagFilter != null) {
    return _items.where((item) => item.tags.contains(_selectedTagFilter!)).toList();
  }
  
  // Vista por defecto (Inicio)
  return _items;
  }
  
  BackupService get _backupService => BackupService();

  @override
  void initState() {
    super.initState();
    _backupService.isSignedIn();
    WidgetsBinding.instance.addObserver(this);
    _items = [];
    _trashedItems = [];
    _archivedItems = [];
    _favoriteItems = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadAllData();
  });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Llamamos a nuestro nuevo método silencioso
      context.read<UpdaterProvider>().checkUpdateOnStartup();
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

  //  Método unificado para cargar todo
  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();

    // Cargar Etiquetas
    setState(() {
      _availableTags = prefs.getStringList('available_tags') ?? [];
    });

    await _loadItems();
  }

  Future<void> _loadItems() async {
    final String languageCode = Localizations.localeOf(context).languageCode; 
  try {
    // 1. Cargamos la preferencia de la vista (Lista o Cuadrícula)
    final prefs = await SharedPreferences.getInstance();
    final savedView = prefs.getBool('is_list_view');
    if (savedView != null) {
      setState(() {
        _isListView = savedView;
      });
    }

    

    // 2. Cargamos las notas activas
    String? contents;
    if (kIsWeb) {
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
        
      });
    } else {
      // NUEVA CARGA: Si no hay notas guardadas, leemos los assets JSON traducidos
      final defaultNotes = await loadDefaultNotesFromAssets(languageCode);
      setState(() {
        _items = defaultNotes;
        
      });
      _saveItems(); // Guardamos el JSON local inicializado por primera vez
    }

    // --- Cargar Archivados ---
    String? archivedContents;
    if (kIsWeb) {
      archivedContents = prefs.getString('archived_notes');
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/archived_notes.json');
      if (await file.exists()) {
        archivedContents = await file.readAsString();
      }
    }

    if (archivedContents != null && archivedContents.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(archivedContents);
      setState(() {
        _archivedItems = jsonList
            .map((json) => ListItem.fromJson(json))
            .toList();
      });
    }
    String? favoriteContents;
    if (kIsWeb) {
      favoriteContents = prefs.getString('favorite_notes');
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/favorite_notes.json');
      if (await file.exists()) {
        favoriteContents = await file.readAsString();
      }
    }

    if (favoriteContents != null && favoriteContents.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(favoriteContents);
      setState(() {
        _favoriteItems = jsonList
            .map((json) => ListItem.fromJson(json))
            .toList();
      });
    }

    // --- Cargar Papelera ---
    String? trashedContents;
    if (kIsWeb) {
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
        _trashedItems = jsonList
            .map((json) => ListItem.fromJson(json))
            .toList();
      });
    }
    setState(() {
        _isLoading = false;
      });
       
  } catch (e) {
    debugPrint("Error loading items: $e");

    // Manejo de error: Fallback seguro cargando desde los assets JSON
    final defaultNotes = await loadDefaultNotesFromAssets(languageCode);
    setState(() {
      _items = defaultNotes;
      _isLoading = false;
    });
     
    _saveItems();
  }
}
  

/// Carga el JSON traducido basándose en el Locale actual y devuelve las notas por defecto.
Future<List<ListItem>> loadDefaultNotesFromAssets(String languageCode) async {
  try {
    
    String assetPath;
    switch (languageCode) {
      case 'en':
        assetPath = 'assets/lang/notes_en.json';
        break;
      case 'pt':
        assetPath = 'assets/lang/notes_pt.json';
        break;
      case 'es':
      default:
        assetPath = 'assets/lang/notes_es.json'; // Respaldo nativo si es cualquier otro idioma
        break;
    }

    // 2. Leer el string crudo del archivo de assets
    String jsonString = await rootBundle.loadString(assetPath);

    // 3. Decodificar a un mapa nativo de Dart
    Map<String, dynamic> notesData = jsonDecode(jsonString);
    List<ListItem> defaultNotes = [];

    // 4. Mapear y procesar la Nota de Bienvenida (welcome_note)
    if (notesData.containsKey('welcome_note')) {
      final welcome = notesData['welcome_note'];
      defaultNotes.add(
        ListItem(
          id: 'welcome_note',
          title: welcome['title'],
          // Convertimos la lista estructurada del Delta de vuelta a un String JSON plano
          summary: jsonEncode(welcome['summary']),
          lastModified: DateTime.now(),
          backgroundColor: welcome['backgroundColor'] ?? 4294959234, // Amber/Amarillo suave
        ),
      );
    }

    // 5. Mapear y procesar la Nota de Ejercicios (exercise_note)
    if (notesData.containsKey('exercise_note')) {
      final exercise = notesData['exercise_note'];
      defaultNotes.add(
        ListItem(
          id: 'exercite_note', // Mantiene el ID que ya usabas
          title: exercise['title'],
          summary: jsonEncode(exercise['summary']),
          lastModified: DateTime.now(),
          backgroundColor: exercise['backgroundColor'] ?? 4294967295, // Blanco
        ),
      );
    }

    return defaultNotes;
  } catch (e) {
    if (kDebugMode) print('Error cargando notas por defecto: $e');
    return []; // Retorna lista vacía ante cualquier error de lectura
  }
}

  //   Guardar Etiquetas
  Future<void> _saveTags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('available_tags', _availableTags);
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

  //   Guardar Archivados
  Future<void> _saveArchivedItems() async {
    try {
      final List<Map<String, dynamic>> jsonList = _archivedItems
          .map((item) => item.toJson())
          .toList();
      final contents = jsonEncode(jsonList);
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('archived_notes', contents);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/archived_notes.json');
        await file.writeAsString(contents);
      }
    } catch (e) {
      debugPrint("Error saving archived items: $e");
    }
  }
  Future<void> _saveFavoriteItems() async {
    try {
      final List<Map<String, dynamic>> jsonList = _favoriteItems
          .map((item) => item.toJson())
          .toList();
      final contents = jsonEncode(jsonList);
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('favorite_notes', contents);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/favorite_notes.json');
        await file.writeAsString(contents);
      }
    } catch (e) {
      debugPrint("Error saving favoritos items: $e");
    }
  }

  void _archiveSelectedItems() async {
    // 1. Guardamos una copia de los elementos y el estado de la vista para el "Deshacer"
    final itemsToMove = List<ListItem>.from(_selectedItems);
    final wasInArchiveView = _isArchiveView;

    // Función auxiliar para generar copias de los items con el estado isArchived actualizado
    List<ListItem> getUpdatedItems(bool targetStatus) {
      return itemsToMove
          .map(
            (item) => ListItem(
              id: item.id,
              title: item.title,
              summary: item.summary,
              lastModified: item.lastModified,
              backgroundColor: item.backgroundColor,
              backgroundImagePath: item.backgroundImagePath,
              tags: item.tags,
              isArchived:
                  targetStatus, // Actualizamos la variable según el destino
              isFavorite: item.isFavorite,
            ),
          )
          .toList();
    }

    setState(() {
      if (wasInArchiveView) {
        // Desarchivar: Quitar de archivados y mover a principal con isArchived = false
        final restoredItems = getUpdatedItems(false);
        _archivedItems.removeWhere(
          (item) => itemsToMove.any((m) => m.id == item.id),
        );
        _items.addAll(restoredItems);
      } else {
        // Archivar: Quitar de principal y mover a archivados con isArchived = true
        final archivedItems = getUpdatedItems(true);
        _items.removeWhere((item) => itemsToMove.any((m) => m.id == item.id));
        _archivedItems.addAll(archivedItems);
      }
      _saveItems();
      _saveArchivedItems();
      _exitSelectionMode();
       
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasInArchiveView
              ? AppLocalizations.of(context)!.notesRestored
              : AppLocalizations.of(context)!.notesArchived,
        ),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.undo,
          onPressed: () {
            setState(() {
              if (wasInArchiveView) {
                // Revertir restauración: de vuelta al archivo (isArchived = true)
                final reverted = getUpdatedItems(true);
                _items.removeWhere(
                  (item) => itemsToMove.any((m) => m.id == item.id),
                );
                _archivedItems.addAll(reverted);
              } else {
                // Revertir archivado: de vuelta a la lista principal (isArchived = false)
                final reverted = getUpdatedItems(false);
                _archivedItems.removeWhere(
                  (item) => itemsToMove.any((m) => m.id == item.id),
                );
                _items.addAll(reverted);
              }
              _saveItems();
              _saveArchivedItems();
               
            });
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

    final originalItem =
        item ??
        ListItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '',
          summary: '',
          lastModified: DateTime.now(),
          tags: _selectedTagFilter != null
              ? [_selectedTagFilter!]
              : [], // Asigna la etiqueta actual si hay filtro
        );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditorScreen(item: originalItem)),
    );

    if (result == null) {
      _loadAllData(); // Recargamos por si editó etiquetas dentro del editor
      return;
    }

    if (result == "DELETE") {
      final itemToDelete =
          _items.cast<ListItem?>().firstWhere(
            (i) => i?.id == originalItem.id,
            orElse: () => null,
          ) ??
          _archivedItems.cast<ListItem?>().firstWhere(
            (i) => i?.id == originalItem.id,
            orElse: () => null,
          ) ??
          _favoriteItems.cast<ListItem?>().firstWhere((i) => i?.id == originalItem.id,
          orElse: () => null);
          
      setState(() {
        _items.removeWhere((i) => i.id == originalItem.id);
        _archivedItems.removeWhere((i) => i.id == originalItem.id);
        _favoriteItems.removeWhere((i) => i.id == originalItem.id);
        _trashedItems.add(itemToDelete!); // Movemos a papelera
         
        _saveItems();
        _saveArchivedItems();
        _saveFavoriteItems();
        _saveTrashedItems();
      });
      if (itemToDelete != null) {
        _showUndoSnackbar([itemToDelete]); // Mostramos SnackBar
      }
    } else if (result is ListItem) {
      setState(() {
        // 1. Buscamos la posición original en ambas listas
        final int indexInItems = _items.indexWhere((i) => i.id == result.id);
        final int indexInArchived = _archivedItems.indexWhere(
          (i) => i.id == result.id,
        );
        final int indexInFavorites = _favoriteItems.indexWhere((i) => i.id == result.id);

        // 2. Si la nota quedó vacía, la eliminamos y salimos
        if (result.title.trim().isEmpty && result.document.length <= 1) {
          if (indexInItems != -1) _items.removeAt(indexInItems);
          if (indexInArchived != -1) _archivedItems.removeAt(indexInArchived);
          if (indexInFavorites != -1) _favoriteItems.removeAt(indexInFavorites);
           
          _saveItems();
          _saveArchivedItems();
          _saveFavoriteItems();
          return;
        }

        // 3. Manejamos la actualización o inserción respetando la posición
        if (result.isArchived) {
          // Si se movió de Principal a Archivado o es nueva en archivados
          if (indexInItems != -1) _items.removeAt(indexInItems);

          if (indexInArchived != -1) {
            _archivedItems[indexInArchived] = result; // Actualiza en su lugar
          } else {
            _archivedItems.insert(0, result); // Nueva nota archivada va arriba
          }
        } else {
          // Si se movió de Archivado a Principal o es nueva en principal
          if (indexInArchived != -1) _archivedItems.removeAt(indexInArchived);

          if (indexInItems != -1) {
            _items[indexInItems] =
                result; // Actualiza en su lugar (mantiene orden personalizado)
          } else {
            _items.insert(0, result); // Nueva nota va al principio
          }
        }
    
    if (result.isFavorite) {
      if (indexInFavorites != -1) {
        // Si ya era favorito, actualizamos sus datos modificados (título, texto, etc.)
        _favoriteItems[indexInFavorites] = result;
      } else {
        // Si se marcó como favorito dentro del editor por primera vez
        _favoriteItems.insert(0, result);
      }
    } else {
      // Si se desmarcó como favorito dentro del editor
      if (indexInFavorites != -1) {
        _favoriteItems.removeAt(indexInFavorites);
      }
    }
    
        
         
        _saveItems();
        _saveArchivedItems();
        _saveFavoriteItems();
      });
      _loadAllData();
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.tagNotesTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: _availableTags.isEmpty
                ? Text(AppLocalizations.of(context)!.noTagsCreated)
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _availableTags.length,
                    itemBuilder: (context, index) {
                      final tag = _availableTags[index];
                      return ListTile(
                        leading: const Icon(Icons.label_outline),
                        title: Text(tag),
                        // Cambié un poco el ícono para que tenga más sentido visual de "etiquetar/modificar"
                        trailing: const Icon(Icons.sell_outlined), 
                        onTap: () {
                          setState(() {
                            for (var item in _selectedItems) {
                              
                              // 1. Buscar y actualizar en la lista principal (_items)
                              final indexInItems = _items.indexWhere((i) => i.id == item.id);
                              if (indexInItems != -1) {
                                final updatedTags = List<String>.from(_items[indexInItems].tags);
                                
                                // Lógica de Toggle: Si la tiene, la quita. Si no la tiene, la pone.
                                if (updatedTags.contains(tag)) {
                                  updatedTags.remove(tag);
                                } else {
                                  updatedTags.add(tag);
                                }
                                
                                _items[indexInItems] = ListItem(
                                  id: _items[indexInItems].id,
                                  title: _items[indexInItems].title,
                                  summary: _items[indexInItems].summary,
                                  lastModified: DateTime.now(), // Actualizamos la fecha de modificación
                                  backgroundColor: _items[indexInItems].backgroundColor,
                                  backgroundImagePath: _items[indexInItems].backgroundImagePath,
                                  tags: updatedTags,
                                  isArchived: _items[indexInItems].isArchived,
                                  isFavorite: _items[indexInItems].isFavorite,
                                );
                              }

                              // 2. Buscar y actualizar en la lista de archivados (_archivedItems)
                              final indexInArchived = _archivedItems.indexWhere((i) => i.id == item.id);
                              if (indexInArchived != -1) {
                                final updatedTags = List<String>.from(_archivedItems[indexInArchived].tags);
                                
                                if (updatedTags.contains(tag)) {
                                  updatedTags.remove(tag);
                                } else {
                                  updatedTags.add(tag);
                                }
                                
                                _archivedItems[indexInArchived] = ListItem(
                                  id: _archivedItems[indexInArchived].id,
                                  title: _archivedItems[indexInArchived].title,
                                  summary: _archivedItems[indexInArchived].summary,
                                  lastModified: DateTime.now(),
                                  backgroundColor: _archivedItems[indexInArchived].backgroundColor,
                                  backgroundImagePath: _archivedItems[indexInArchived].backgroundImagePath,
                                  tags: updatedTags,
                                  isArchived: _archivedItems[indexInArchived].isArchived,
                                  isFavorite: _archivedItems[indexInItems].isFavorite,
                                );
                              }
                            }
                            
                            // Guardamos ambas listas por si modificamos notas archivadas
                            _saveItems();
                            _saveArchivedItems(); 
                             
                          });
                          
                          Navigator.pop(context);
                          _exitSelectionMode();
                          
                          // Hacemos el mensaje del SnackBar más genérico ya que ahora quita y pone etiquetas
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.updatesTag(_selectedItems.length as String),
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

                            if (_availableTags.any(
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
                              _availableTags.add(newTag);
                              _saveTags();
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
                        itemCount: _availableTags.length,
                        itemBuilder: (context, index) {
                          final tag = _availableTags[index];
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
    final TextEditingController renameController = TextEditingController(
      text: oldTag,
    );
    // Agregamos una variable para manejar el error localmente en el diálogo
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // Necesario para mostrar el error dinámicamente
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.renameTag),
              content: TextField(
                controller: renameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.renameTagLabel,
                  errorText: errorText, // Muestra el mensaje de error aquí
                  prefixIcon: const Icon(Icons.edit_outlined),
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
                  onPressed: () {
                    final newTag = renameController.text.trim();

                    // 1. Si no cambió nada, solo cerramos
                    if (newTag == oldTag) {
                      Navigator.pop(context);
                      return;
                    }

                    // 2. Validación de duplicados
                    bool exists = _availableTags.any(
                      (t) =>
                          t.toLowerCase() == newTag.toLowerCase() &&
                          t != oldTag,
                    );

                    if (exists) {
                      setDialogState(
                        () => errorText = AppLocalizations.of(
                          context,
                        )!.tagExistsError,
                      );
                      return;
                    }

                    if (newTag.isNotEmpty) {
                      setState(() {
                        // Actualizar lista global
                        int index = _availableTags.indexOf(oldTag);
                        if (index != -1) _availableTags[index] = newTag;

                        // Actualizar filtro activo
                        if (_selectedTagFilter == oldTag) {
                          _selectedTagFilter = newTag;
                        }

                        // Actualizar notas (Uso de map para mayor limpieza)
                        void updateTags(List<ListItem> list) {
                          for (var item in list) {
                            if (item.tags.contains(oldTag)) {
                              item.tags.remove(oldTag);
                              item.tags.add(newTag);
                            }
                          }
                        }

                        updateTags(_items);
                        updateTags(_trashedItems);

                        _saveTags();
                         
                      });
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

  void _showUndoSnackbar(List<ListItem> deletedItems) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.movedToTrash),
        behavior: SnackBarBehavior.floating, // Estilo flotante de Material 3
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.undo,
          onPressed: () {
            setState(() {
              for (var item in deletedItems) {
                _trashedItems.removeWhere((i) => i.id == item.id);
                
                if (item.isArchived) {
                  _archivedItems.add(item); // Si era archivada, vuelve a archivados
                } else {
                  _items.add(item); // Si no, va al inicio
                }

                // Sincronización al restaurar: Si era favorita, la devolvemos a favoritos
                if (item.isFavorite) {
                  if (!_favoriteItems.any((i) => i.id == item.id)) {
                    _favoriteItems.add(item);
                  }
                }
              }
              _saveItems();
              _saveArchivedItems(); 
              _saveFavoriteItems(); // Guardamos los cambios en favoritos
              _saveTrashedItems();
            });
          },
        ),
      ),
    );
  }

  void _deleteSelectedItems() async {
    final itemsToDelete = List<ListItem>.from(_selectedItems);
    final idsToDelete = itemsToDelete.map((item) => item.id).toSet();

    setState(() {
      if (_isTrashView) {
        // Eliminación definitiva desde la papelera
        _cleanupImagesForItems(itemsToDelete);
        _trashedItems.removeWhere((item) => idsToDelete.contains(item.id));
        _saveTrashedItems();
      } else {
        // Enviar a la papelera comparando por ID para mantener la sincronización
        _items.removeWhere((item) => idsToDelete.contains(item.id));
        _archivedItems.removeWhere((item) => idsToDelete.contains(item.id));
        _favoriteItems.removeWhere((item) => idsToDelete.contains(item.id));
        
        _trashedItems.addAll(itemsToDelete);
        
        _saveItems();
        _saveArchivedItems();
        _saveFavoriteItems(); // Guardamos el estado de favoritos actualizado
        _saveTrashedItems();
        _showUndoSnackbar(itemsToDelete);
      }
      _exitSelectionMode();
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

  void _setCustomSort() {
    setState(() {
      _sortMethod = SortMethod.custom;
       
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
       
    });
  }

  void _sortByDate({bool preserveState = true}) {
    if (preserveState) Navigator.pop(context);
    setState(() {
      _sortMethod = SortMethod.byDate;
      _items.sort((a, b) => b.lastModified.compareTo(a.lastModified));
       
    });
  }

  void _onReorderItem(int oldIndex, int newIndex) {
    if (!_isTrashView) return;
    setState(() {
      
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);

       
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
        title: Text('${_selectedItems.length}'),
        actions: [
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
    // Obtenemos los colores únicos para enviarlos al Delegate [cite: 314]
    final uniqueColors = [..._items, ..._archivedItems]
        .where((item) => item.backgroundColor != null)
        .map((item) => item.backgroundColor!)
        .toSet()
        .toList();

    final ListItem? selectedNote = await showSearch<ListItem?>(
      context: context,
      delegate: CustomSearchDelegate(
        allNotes: [
      ..._items, 
      ..._archivedItems
    ],
        availableTags: _availableTags,
        availableColors: uniqueColors,
      ),
    );

    // Si el usuario seleccionó una nota desde la búsqueda, la abrimos
    if (selectedNote != null) {
      _navigateToEditor(selectedNote);
    }
  },
  child: SearchBar(
    enabled: false, // Lo desactivamos para que actúe solo como un botón visual
    hintText: AppLocalizations.of(context)!.search,
    leading: const Icon(Icons.search_outlined),
    elevation: WidgetStateProperty.all(0),
    backgroundColor: WidgetStateProperty.all(
      Theme.of(context).colorScheme.surfaceContainerHigh,
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
                            !_isSelectionMode;

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
                  !_isTrashView && _selectedTagFilter == null && !_isArchiveView && !_isFavoriteView
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
                    !_isArchiveView && !_isFavoriteView,

                onTap: () {
                  setState(() {
                    _isTrashView = false;
                    _isArchiveView = false;
                    _isFavoriteView = false;
                    _selectedTagFilter = null;
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
            ..._availableTags.map(
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
                        null; // Opcional: quitar filtro al ir a papelera
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
                  _loadAllData();
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
      body: _isLoading
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
    index: _currentSourceItems.indexOf(item),
    child: NoteItemWidget(
    item: item,
    isListView: isListView,
    isSelected: _selectedItems.contains(item),
    isSelectionMode: _isSelectionMode,
    canReorder: _sortMethod == SortMethod.custom,
    isTrashView: _isTrashView,
    itemIndex: _currentSourceItems.indexOf(item),
    moreButtonTooltip: AppLocalizations.of(context)!.select,
    onTap: () {
      if (_isSelectionMode) {
        _toggleSelection(item);
      } else if (_isTrashView) {
        // MOSTRAR DIÁLOGO EN PAPELERA
        showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: Text(AppLocalizations.of(context)!.restoreNote),
                  onTap: () {
                    setState(() {
                      _trashedItems.removeWhere((i) => i.id == item.id);
                      if (item.isArchived) {
                        if (!_archivedItems.any((i) => i.id == item.id)) {
                             _archivedItems.add(item);
                          }
                      } else {
                        if (!_Items.any((i) => i.id == item.id)) {
                             _Items.add(item);
                          }
                      }
                      if (item.isFavorite) {
                          // Insertamos para evitar duplicados por seguridad
                          if (!_favoriteItems.any((i) => i.id == item.id)) {
                             _favoriteItems.add(item);
                          }
                       }
                      _saveItems();
                      _saveArchivedItems();
                      _saveFavoriteItems();
                      _saveTrashedItems();
                       
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever_outlined,
                    color: Colors.red,
                  ),
                  title: Text(AppLocalizations.of(context)!.deleteForever),
                  onTap: () {
                    setState(() {
                      _cleanupImagesForItems([item]);
                      _trashedItems.removeWhere((i) => i.id == item.id);
                      _saveTrashedItems();
                       
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
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
        _sortMethod == SortMethod.custom ;
    if (canReorder) {
      return ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemCount: _currentSourceItems.length,
        itemBuilder: (context, index) {
          final item = _currentSourceItems[index];
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
      itemCount: _currentSourceItems.length,
      itemBuilder: (context, index) {
        final item = _currentSourceItems[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildItem(item, isListView: true),
        );
      },
    );
  }

  Widget _buildGridView() {
    final bool canReorder =
        _sortMethod == SortMethod.custom ;
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
        children: _currentSourceItems.map((item) {
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
      itemCount: _currentSourceItems.length,
      itemBuilder: (context, index) =>
          _buildItem(_currentSourceItems[index], isListView: false),
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
            onPressed: () {
              setState(() {
                _cleanupImagesForItems(_trashedItems);
                _trashedItems.clear();
                _saveTrashedItems();
                 
              });
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.emptyTrashAction),
          ),
        ],
      ),
    );
  }

  // Ejemplo de la función que maneja el cambio de filtro
  void _onTagSelected(String? tag) {
    setState(() {
      _isTrashView = false;
      _isArchiveView = false;
      _isFavoriteView = false;
      // Si se toca la misma etiqueta, se deselecciona (vuelve el icono import)
      // Si se toca una nueva, se activa el filtro (aparecen los tres puntos)
      _selectedTagFilter = (_selectedTagFilter == tag) ? null : tag;
       
    });
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
            onPressed: () {
              setState(() {
                // 1. Eliminar de la lista global de etiquetas
                _availableTags.remove(tag);
                _selectedTagFilter = null; // Volvemos a la vista general

                // 2. Función interna para limpiar la etiqueta de cualquier lista de notas
                void removeTagFromList(List<ListItem> list) {
                  for (var item in list) {
                    // Si el ítem contiene la etiqueta, la removemos
                    if (item.tags.contains(tag)) {
                      item.tags.remove(tag);
                    }
                  }
                }

                // 3. Aplicar la limpieza a todas tus fuentes de datos[cite: 1]
                removeTagFromList(_items);
                removeTagFromList(_archivedItems);
                removeTagFromList(_trashedItems);

                // 4. Persistir todos los cambios en SharedPreferences y archivos JSON[cite: 1]
                _saveTags();
                _saveItems();
                _saveArchivedItems();
                _saveTrashedItems();

                  // Refrescar la UI[cite: 1]
              });
              Navigator.pop(context);
            },
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  void _toggleFavoriteSelectedItems() async {
  if (_selectedItems.isEmpty) return;

  setState(() {
    for (var selectedItem in _selectedItems) {
      // 1. Localizar el ítem en la lista de notas activas o archivadas
      final int indexInItems = _items.indexWhere((i) => i.id == selectedItem.id);
      final int indexInArchived = _archivedItems.indexWhere((i) => i.id == selectedItem.id);
      
      final bool newFavoriteStatus = !selectedItem.isFavorite;

      // 2. Crear una nueva instancia con el estado de favorito invertido
      final updatedItem = ListItem(
        id: selectedItem.id,
        title: selectedItem.title,
        summary: selectedItem.summary,
        lastModified: selectedItem.lastModified,
        backgroundColor: selectedItem.backgroundColor,
        backgroundImagePath: selectedItem.backgroundImagePath,
        tags: selectedItem.tags,
        isArchived: selectedItem.isArchived,
        isFavorite: newFavoriteStatus,
      );

      // 3. Reemplazar en la lista de origen
      if (indexInItems != -1) _items[indexInItems] = updatedItem;
      if (indexInArchived != -1) _archivedItems[indexInArchived] = updatedItem;

      // 4. Sincronizar la lista/categoría especial de favoritos
      if (newFavoriteStatus) {
        // Evitamos duplicados
        if (!_favoriteItems.any((i) => i.id == selectedItem.id)) {
          _favoriteItems.insert(0, updatedItem);
        }
      } else {
        _favoriteItems.removeWhere((i) => i.id == selectedItem.id);
      }
    }

    // 5. Persistir todos los cambios en los archivos correspondientes
    _saveItems();
    _saveArchivedItems();
    _saveFavoriteItems();
    
    // Limpiar selección y refrescar UI
    _exitSelectionMode();
     
  });
}
}
