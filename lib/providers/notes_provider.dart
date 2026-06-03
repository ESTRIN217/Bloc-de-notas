import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloc_de_notas/presentation/widgets/list_item.dart'; 

class CategoryItem {
  final String id;
  final String name;

  CategoryItem({required this.id, required this.name});
  Map<String, dynamic> toMap() => {'id': id, 'name': name};
  factory CategoryItem.fromMap(Map<String, dynamic> map) => 
      CategoryItem(id: map['id'], name: map['name']);
}

class NotesProvider with ChangeNotifier {
  // Estado de las listas de notas
  List<ListItem> items = [];
  List<ListItem> archivedItems = [];
  List<ListItem> favoriteItems = [];
  List<ListItem> trashedItems = [];
  
  // Estado de metadatos
  List<String> availableTags = [];
  List<CategoryItem> _categories = [];
  List<CategoryItem> get categories => _categories;

  bool isLoading = true;
  List<ListItem> get sortedItems => _applySort(items);
  List<ListItem> get sortedArchivedItems => _applySort(archivedItems);
  List<ListItem> get sortedFavoriteItems => _applySort(favoriteItems);
  List<ListItem> get sortedTrashedItems => _applySort(trashedItems);

/// Tu getter unificado para la búsqueda también se beneficia
  List<ListItem> get allSearchableNotes => [...items, ...archivedItems];

  // --- Helpers DRY para Lectura/Escritura ---
  
  Future<String?> _readJsonData(String fileName) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(fileName);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.json');
      if (await file.exists()) {
        return await file.readAsString();
      }
    }
    return null;
  }

  Future<void> _writeJsonData(String fileName, String content) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(fileName, content);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.json');
      await file.writeAsString(content);
    }
  }

  // --- Lógica de Carga Unificada ---

  Future<void> loadAllData(String languageCode) async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    
    final int? sortMethodIndex = prefs.getInt('selected_sort_method');
  if (sortMethodIndex != null && sortMethodIndex < SortMethod.values.length) {
    _currentSortMethod = SortMethod.values[sortMethodIndex];
  } else {
    _currentSortMethod = SortMethod.custom; // Por defecto si no existe 
  }
    
    // 1. Cargar metadatos (Etiquetas y Categorías)
    availableTags = prefs.getStringList('available_tags') ?? [];
    
    final String? categoriesJson = prefs.getString('custom_categories');
    if (categoriesJson != null) {
      final List<dynamic> decoded = jsonDecode(categoriesJson);
      _categories = decoded.map((item) => CategoryItem.fromMap(item)).toList();
    }

    // 2. Cargar todas las listas de notas usando el Helper
    items = await _loadList('notes') ?? await _loadDefaultNotesFromAssets(languageCode);
    archivedItems = await _loadList('archived_notes') ?? [];
    favoriteItems = await _loadList('favorite_notes') ?? [];
    trashedItems = await _loadList('trashed_notes') ?? [];

    isLoading = false;
    notifyListeners();
  }

  Future<List<ListItem>?> _loadList(String key) async {
    try {
      final content = await _readJsonData(key);
      if (content != null && content.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(content);
        return jsonList.map((json) => ListItem.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error cargando $key: $e");
    }
    return null;
  }

  // --- Lógica de Guardado ---

  Future<void> saveNotesList(String key, List<ListItem> listToSave) async {
    try {
      final List<Map<String, dynamic>> jsonList = listToSave.map((item) => item.toJson()).toList();
      await _writeJsonData(key, jsonEncode(jsonList));
      notifyListeners();
    } catch (e) {
      debugPrint("Error guardando $key: $e");
    }
  }

  Future<void> saveTags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('available_tags', availableTags);
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    final newCategory = CategoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );
    _categories.add(newCategory);
    await _saveCategories();
    notifyListeners();
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_categories.map((c) => c.toMap()).toList());
    await prefs.setString('custom_categories', encoded);
  }

  // --- Carga de Notas por Defecto (Movido desde main.dart) ---
  
  Future<List<ListItem>> _loadDefaultNotesFromAssets(String languageCode) async {
    try {
      String assetPath;
      switch (languageCode) {
        case 'en': assetPath = 'assets/lang/notes_en.json'; break;
        case 'pt': assetPath = 'assets/lang/notes_pt.json'; break;
        case 'es':
        default: assetPath = 'assets/lang/notes_es.json'; break;
      }

      String jsonString = await rootBundle.loadString(assetPath);
      Map<String, dynamic> notesData = jsonDecode(jsonString);
      List<ListItem> defaultNotes = [];

      if (notesData.containsKey('welcome_note')) {
        final welcome = notesData['welcome_note'];
        defaultNotes.add(
          ListItem(
            id: 'welcome_note',
            title: welcome['title'],
            summary: jsonEncode(welcome['summary']),
            lastModified: DateTime.now(),
            backgroundColor: welcome['backgroundColor'] ?? 4294959234,
          ),
        );
      }

      if (notesData.containsKey('exercise_note')) {
        final exercise = notesData['exercise_note'];
        defaultNotes.add(
          ListItem(
            id: 'exercite_note',
            title: exercise['title'],
            summary: jsonEncode(exercise['summary']),
            lastModified: DateTime.now(),
            backgroundColor: exercise['backgroundColor'] ?? 4294967295,
          ),
        );
      }

      // Guardamos la lista por defecto una vez inicializada
      saveNotesList('notes', defaultNotes);
      return defaultNotes;
    } catch (e) {
      if (kDebugMode) print('Error cargando notas por defecto: $e');
      return [];
    }
  }
  
  Future<void> addNote(ListItem note) async {
    items.insert(0, note);
    await saveNotesList('notes', items);
  }

Future<void> updateNoteInList(String listKey, ListItem updatedNote) async {
  List<ListItem> targetList = _getListByKey(listKey);
  int index = targetList.indexWhere((element) => element.id == updatedNote.id);
  if (index != -1) {
    targetList[index] = updatedNote;
    await saveNotesList(listKey, targetList);
  }
}

Future<void> moveNote({
  required ListItem note,
  required String fromKey,
  required String toKey,
}) async {
  List<ListItem> fromList = _getListByKey(fromKey);
  List<ListItem> toList = _getListByKey(toKey);

  fromList.removeWhere((item) => item.id == note.id);
  toList.insert(0, note);

  await saveNotesList(fromKey, fromList);
  await saveNotesList(toKey, toList);
}

Future<void> deleteNotePermanently(ListItem note) async {
  trashedItems.removeWhere((item) => item.id == note.id);
  await saveNotesList('trashed_notes', trashedItems);
}

// Helper interno para simplificar la lógica DRY
List<ListItem> _getListByKey(String key) {
  switch (key) {
    case 'notes': return items;
    case 'archived_notes': return archivedItems;
    case 'favorite_notes': return favoriteItems;
    case 'trashed_notes': return trashedItems;
    default: return items;
  }
}

// --- Gestión de Etiquetas ---
Future<void> addTag(String tag) async {
  if (!availableTags.contains(tag)) {
    availableTags.add(tag);
    await saveTags();
  }
}

Future<void> removeTag(String tag) async {
  availableTags.remove(tag);
  await saveTags();
}

/// Procesa las acciones de borrado, actualización o inserción desde el Editor
Future<void> handleEditorResult({
  required dynamic result,
  required ListItem originalItem,
}) async {
  // Caso 1: Eliminación explícita
  if (result == "DELETE") {
    // Buscamos en qué lista está para moverlo a la papelera
    ListItem? itemToDelete = 
        items.cast<ListItem?>().firstWhere((i) => i?.id == originalItem.id, orElse: () => null) ??
        archivedItems.cast<ListItem?>().firstWhere((i) => i?.id == originalItem.id, orElse: () => null) ??
        favoriteItems.cast<ListItem?>().firstWhere((i) => i?.id == originalItem.id, orElse: () => null);

    items.removeWhere((i) => i.id == originalItem.id);
    archivedItems.removeWhere((i) => i.id == originalItem.id);
    favoriteItems.removeWhere((i) => i.id == originalItem.id);

    if (itemToDelete != null) {
      trashedItems.insert(0, itemToDelete);
    }

    await _saveAllLists();
    notifyListeners();
    return;
  }

  // Caso 2: Se recibió una nota (Nueva o Editada)
  if (result is ListItem) {
    final int indexInItems = items.indexWhere((i) => i.id == result.id);
    final int indexInArchived = archivedItems.indexWhere((i) => i.id == result.id);
    final int indexInFavorites = favoriteItems.indexWhere((i) => i.id == result.id);

    // ¿La nota quedó vacía? (Ajusta 'result.summary' si necesitas evaluar otra propiedad de texto)
    if (result.title.trim().isEmpty && (result.summary.trim().isEmpty || result.summary.length <= 1)) {
      if (indexInItems != -1) items.removeAt(indexInItems);
      if (indexInArchived != -1) archivedItems.removeAt(indexInArchived);
      if (indexInFavorites != -1) favoriteItems.removeAt(indexInFavorites);
      
      await _saveAllLists();
      notifyListeners();
      return;
    }

    // Manejo de flujo Principal vs Archivado
    if (result.isArchived) {
      if (indexInItems != -1) items.removeAt(indexInItems);
      if (indexInArchived != -1) {
        archivedItems[indexInArchived] = result;
      } else {
        archivedItems.insert(0, result);
      }
    } else {
      if (indexInArchived != -1) archivedItems.removeAt(indexInArchived);
      if (indexInItems != -1) {
        items[indexInItems] = result; // Mantiene el orden personalizado
      } else {
        items.insert(0, result);
      }
    }

    // Manejo de Favoritos
    if (result.isFavorite) {
      if (indexInFavorites != -1) {
        favoriteItems[indexInFavorites] = result;
      } else {
        favoriteItems.insert(0, result);
      }
    } else {
      if (indexInFavorites != -1) {
        favoriteItems.removeAt(indexInFavorites);
      }
    }

    await _saveAllLists();
    notifyListeners();
  }
}

/// Helper privado DRY para disparar los guardados en lote de forma limpia
Future<void> _saveAllLists() async {
  await Future.wait([
    saveNotesList('notes', items),
    saveNotesList('archived_notes', archivedItems),
    saveNotesList('favorite_notes', favoriteItems),
    saveNotesList('trashed_notes', trashedItems),
  ]);
}

/// Alterna el estado de favoritos para una lista de ítems seleccionados
  Future<void> toggleFavoriteMultiple(List<ListItem> selectedItems) async {
  if (selectedItems.isEmpty) return;

  for (var selectedItem in selectedItems) {
    final int indexInItems = items.indexWhere((i) => i.id == selectedItem.id);
    final int indexInArchived = archivedItems.indexWhere((i) => i.id == selectedItem.id);
    
    final bool newFavoriteStatus = !selectedItem.isFavorite;

    // Crear la nueva instancia mapeando todos los campos actuales
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
      categoryId: selectedItem.categoryId, // <-- Preservar categoría
    );

    // Reemplazar en las listas de origen correspondientes
    if (indexInItems != -1) items[indexInItems] = updatedItem;
    if (indexInArchived != -1) archivedItems[indexInArchived] = updatedItem;

    // Sincronizar la lista global de favoritos
    if (newFavoriteStatus) {
      if (!favoriteItems.any((i) => i.id == selectedItem.id)) {
        favoriteItems.insert(0, updatedItem);
      }
    } else {
      favoriteItems.removeWhere((i) => i.id == selectedItem.id);
    }
  }

  // Guardamos todo en lote usando el helper que unifica la carga y escritura
  await _saveAllLists();
  notifyListeners();
  }

  /// Alterna el estado de archivado en bloque (Archivar o Desarchivar)
  Future<void> toggleArchiveMultiple({
  required List<ListItem> selectedItems,
  required bool toArchive,
}) async {
  if (selectedItems.isEmpty) return;

  final List<String> selectedIds = selectedItems.map((e) => e.id).toList();

  if (toArchive) {
    // Archivar: Quitar de principal, mutar bandera e insertar en archivados
    items.removeWhere((item) => selectedIds.contains(item.id));
    
    for (var item in selectedItems) {
      final updated = ListItem(
        id: item.id,
        title: item.title,
        summary: item.summary,
        lastModified: item.lastModified,
        backgroundColor: item.backgroundColor,
        backgroundImagePath: item.backgroundImagePath,
        tags: item.tags,
        isArchived: true, // Forzamos destino
        isFavorite: item.isFavorite,
        categoryId: item.categoryId, // <-- Preservar categoría
      );
      // Evitar duplicados por si acaso
      if (!archivedItems.any((a) => a.id == item.id)) {
        archivedItems.insert(0, updated);
      }
    }
  } else {
    // Desarchivar: Quitar de archivados, mutar bandera e insertar en principal
    archivedItems.removeWhere((item) => selectedIds.contains(item.id));

    for (var item in selectedItems) {
      final updated = ListItem(
        id: item.id,
        title: item.title,
        summary: item.summary,
        lastModified: item.lastModified,
        backgroundColor: item.backgroundColor,
        backgroundImagePath: item.backgroundImagePath,
        tags: item.tags,
        isArchived: false, // Forzamos destino
        isFavorite: item.isFavorite,
      );
      if (!items.any((i) => i.id == item.id)) {
        items.insert(0, updated);
      }
    }
  }

  // Persistir cambios usando el helper centralizado
  await _saveAllLists();
  notifyListeners();
  }

  /// Realiza un toggle de una etiqueta específica en un bloque de notas seleccionadas
  Future<void> toggleTagMultiple({
  required List<ListItem> selectedItems,
  required String tag,
}) async {
  if (selectedItems.isEmpty) return;

  final List<String> selectedIds = selectedItems.map((e) => e.id).toList();

  // 1. Actualizar en la lista principal si existe
  for (int i = 0; i < items.length; i++) {
    if (selectedIds.contains(items[i].id)) {
      final updatedTags = List<String>.from(items[i].tags);
      if (updatedTags.contains(tag)) {
        updatedTags.remove(tag);
      } else {
        updatedTags.add(tag);
      }

      items[i] = ListItem(
        id: items[i].id,
        title: items[i].title,
        summary: items[i].summary,
        lastModified: DateTime.now(), // Marcamos la nueva modificación
        backgroundColor: items[i].backgroundColor,
        backgroundImagePath: items[i].backgroundImagePath,
        tags: updatedTags,
        isArchived: items[i].isArchived,
        isFavorite: items[i].isFavorite,
      );
    }
  }

  // 2. Actualizar en la lista de archivados si existe
  for (int i = 0; i < archivedItems.length; i++) {
    if (selectedIds.contains(archivedItems[i].id)) {
      final updatedTags = List<String>.from(archivedItems[i].tags);
      if (updatedTags.contains(tag)) {
        updatedTags.remove(tag);
      } else {
        updatedTags.add(tag);
      }

      archivedItems[i] = ListItem(
        id: archivedItems[i].id,
        title: archivedItems[i].title,
        summary: archivedItems[i].summary,
        lastModified: DateTime.now(),
        backgroundColor: archivedItems[i].backgroundColor,
        backgroundImagePath: archivedItems[i].backgroundImagePath,
        tags: updatedTags,
        isArchived: archivedItems[i].isArchived,
        isFavorite: archivedItems[i].isFavorite, // Corregido el índice cruzado
      );
    }
  }

  // 3. Sincronizar también la lista de favoritos si alguna de las notas editadas es favorita
  for (int i = 0; i < favoriteItems.length; i++) {
    if (selectedIds.contains(favoriteItems[i].id)) {
      final updatedTags = List<String>.from(favoriteItems[i].tags);
      if (updatedTags.contains(tag)) {
        updatedTags.remove(tag);
      } else {
        updatedTags.add(tag);
      }

      favoriteItems[i] = ListItem(
        id: favoriteItems[i].id,
        title: favoriteItems[i].title,
        summary: favoriteItems[i].summary,
        lastModified: DateTime.now(),
        backgroundColor: favoriteItems[i].backgroundColor,
        backgroundImagePath: favoriteItems[i].backgroundImagePath,
        tags: updatedTags,
        isArchived: favoriteItems[i].isArchived,
        isFavorite: favoriteItems[i].isFavorite,
      );
    }
  }

  // Guardado en lote optimizado
  await _saveAllLists();
  notifyListeners();
  }

/// Maneja la eliminación lógica (enviar a papelera) o definitiva de múltiples notas
  Future<void> deleteMultiple({
  required List<ListItem> selectedItems,
  required bool isTrashView,
  required Function(List<ListItem>) onPermanentDeleteCleanup,
}) async {
  if (selectedItems.isEmpty) return;

  final Set<String> idsToDelete = selectedItems.map((item) => item.id).toSet();

  if (isTrashView) {
    // 1. Eliminación definitiva desde la papelera
    // Ejecutamos el callback para limpiar imágenes u otros archivos locales
    onPermanentDeleteCleanup(selectedItems);
    
    trashedItems.removeWhere((item) => idsToDelete.contains(item.id));
  } else {
    // 2. Enviar a la papelera (Eliminación lógica)
    items.removeWhere((item) => idsToDelete.contains(item.id));
    archivedItems.removeWhere((item) => idsToDelete.contains(item.id));
    favoriteItems.removeWhere((item) => idsToDelete.contains(item.id));
    
    // Evitamos duplicados al insertar en la papelera
    for (var item in selectedItems) {
      if (!trashedItems.any((t) => t.id == item.id)) {
        trashedItems.add(item);
      }
    }
  }

  // Guardamos todo el lote modificado en disco de una sola vez
  await _saveAllLists();
  notifyListeners();
  }

/// Método auxiliar para el SnackBar de "Deshacer" (para restaurar los ítems si el usuario se arrepiente)
  Future<void> restoreFromTrash(List<ListItem> itemsToRestore) async {
  if (itemsToRestore.isEmpty) return;

  final Set<String> idsToRestore = itemsToRestore.map((item) => item.id).toSet();
  
  // Quitamos de la papelera
  trashedItems.removeWhere((item) => idsToRestore.contains(item.id));

  // Devolvemos a sus respectivas listas basándonos en sus banderas de estado
  for (var item in itemsToRestore) {
    if (item.isArchived) {
      if (!archivedItems.any((a) => a.id == item.id)) archivedItems.insert(0, item);
    } else {
      if (!items.any((i) => i.id == item.id)) items.insert(0, item);
    }

    if (item.isFavorite) {
      if (!favoriteItems.any((f) => f.id == item.id)) favoriteItems.insert(0, item);
    }
  }

  await _saveAllLists();
  notifyListeners();
  }

/// Vacía por completo la papelera de reciclaje y ejecuta la limpieza de recursos
  Future<void> clearTrash({
  required Function(List<ListItem>) onPermanentDeleteCleanup,
}) async {
  if (trashedItems.isEmpty) return;

  // 1. Ejecutamos el callback para limpiar imágenes del almacenamiento local
  onPermanentDeleteCleanup(List<ListItem>.from(trashedItems));

  // 2. Limpiamos la lista en memoria
  trashedItems.clear();

  // 3. Persistimos el cambio en el archivo JSON correspondiente
  await saveNotesList('trashed_notes', trashedItems);
  
  notifyListeners();
  }

/// Actualiza el orden de las notas principales tras una acción de arrastrar y soltar
  Future<void> reorderNotes(List<ListItem> reorderedList) async {
  items = reorderedList;
  
  // Guardamos únicamente la lista de notas principales usando tu método existente
  await saveNotesList('notes', items);
  
  // Notificamos para que cualquier Grid u otro widget se entere del nuevo orden
  notifyListeners();
  }

/// Reordena un elemento mediante índices tradicionales (ReorderableListView)
Future<void> reorderItemByIndex(int oldIndex, int newIndex) async {
  // Ajuste nativo de Flutter: si el elemento se mueve hacia abajo, el índice cambia
  if (oldIndex < newIndex) {
    newIndex -= 1;
  }

  // Removemos el ítem de su posición vieja e insertamos en la nueva
  final item = items.removeAt(oldIndex);
  items.insert(newIndex, item);

  // Persistimos los cambios de forma asíncrona en el almacenamiento
  await saveNotesList('notes', items);
  
  // Notificamos a todos los widgets que escuchan las notas
  notifyListeners();
  }

/// Filtra y devuelve la lista de colores únicos presentes en las notas
  List<int> get uniqueNotesColors {
  return allSearchableNotes
      .where((item) => item.backgroundColor != null)
      .map((item) => item.backgroundColor!)
      .toSet()
      .toList();
  }

  SortMethod _currentSortMethod = SortMethod.custom;
  SortMethod get currentSortMethod => _currentSortMethod;

/// Cambia el método de ordenamiento global, lo persiste y notifica a la UI
  Future<void> changeSortMethod(SortMethod method) async {
  _currentSortMethod = method;
  notifyListeners(); // Notifica de inmediato a la UI para mejorar la respuesta visual 
  
  try {
    final prefs = await SharedPreferences.getInstance();
    // Guardamos el índice del enum (0: alphabetical, 1: byDate, 2: custom)
    await prefs.setInt('selected_sort_method', method.index);
  } catch (e) {
    debugPrint("Error guardando el método de ordenamiento: $e");
  }
  }

  /// Helper privado para ordenar cualquier lista dinámicamente sin destruirla.
  /// Prioriza los elementos fijados arriba en la lista, los cuales permanecen inmóviles.
  List<ListItem> _applySort(List<ListItem> originalList) {
  if (originalList.isEmpty) return originalList;

  // 1. Separar los elementos en fijados y no fijados
  final pinnedNotes = originalList.where((item) => item.isPinned).toList();
  final normalNotes = originalList.where((item) => !item.isPinned).toList();

  // 2. Aplicar el ordenamiento elegido ÚNICAMENTE a las notas normales
  switch (_currentSortMethod) {
    case SortMethod.alphabetical:
      normalNotes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      break;
    case SortMethod.byDate:
      normalNotes.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      break;
    case SortMethod.custom:
      // Mantiene el orden de inserción/arrastre del JSON original
      break;
  }

  // 3. Unificar las listas. Los fijados siempre se quedan arriba en su orden original.
  return [...pinnedNotes, ...normalNotes];
  }

/// Renombra una etiqueta a nivel global y actualiza todas las notas que la contengan
  Future<void> deleteTagGlobal(String tag) async {
  availableTags.remove(tag);

  items = _batchUpdateItemTags(targetList: items, oldTag: tag, newTag: null);
  archivedItems = _batchUpdateItemTags(targetList: archivedItems, oldTag: tag, newTag: null);
  trashedItems = _batchUpdateItemTags(targetList: trashedItems, oldTag: tag, newTag: null);
  favoriteItems = _batchUpdateItemTags(targetList: favoriteItems, oldTag: tag, newTag: null);

  await Future.wait([saveTags(), _saveAllLists()]);
  notifyListeners();
}

Future<void> renameTagGlobal({required String oldTag, required String newTag}) async {
  final int tagIndex = availableTags.indexOf(oldTag);
  if (tagIndex != -1) availableTags[tagIndex] = newTag;

  items = _batchUpdateItemTags(targetList: items, oldTag: oldTag, newTag: newTag);
  archivedItems = _batchUpdateItemTags(targetList: archivedItems, oldTag: oldTag, newTag: newTag);
  trashedItems = _batchUpdateItemTags(targetList: trashedItems, oldTag: oldTag, newTag: newTag);
  favoriteItems = _batchUpdateItemTags(targetList: favoriteItems, oldTag: oldTag, newTag: newTag);

  await Future.wait([saveTags(), _saveAllLists()]);
  notifyListeners();
  }
  /// Helper privado DRY para modificar etiquetas de notas en cascada
  List<ListItem> _batchUpdateItemTags({
  required List<ListItem> targetList,
  required String oldTag,
  required String? newTag, // Si es nulo, significa que estamos eliminando la etiqueta
}) {
  return targetList.map((item) {
    if (item.tags.contains(oldTag)) {
      final updatedTags = List<String>.from(item.tags)..remove(oldTag);
      if (newTag != null) {
        updatedTags.add(newTag);
      }
      return ListItem(
        id: item.id,
        title: item.title,
        summary: item.summary,
        lastModified: DateTime.now(), // Sincroniza la modificación
        backgroundColor: item.backgroundColor,
        backgroundImagePath: item.backgroundImagePath,
        tags: updatedTags,
        isArchived: item.isArchived,
        isFavorite: item.isFavorite,
        categoryId: item.categoryId, // <-- Preservar categoría
      );
    }
    return item;
  }).toList();
  }
  /// Asigna una categoría a múltiples notas en lote (DRY)
  Future<void> assignCategoryMultiple(List<ListItem> itemsToUpdate, String? categoryId) async {
    if (itemsToUpdate.isEmpty) return;
    
    final folderIds = itemsToUpdate.map((e) => e.id).toSet();
    
    List<ListItem> updateList(List<ListItem> targetList) { 
      return targetList.map((item) {
        if (folderIds.contains(item.id)) {
          return item.copyWith(
            categoryId: categoryId, 
            overrideCategory: true, // Forzar el cambio, incluso si se limpia a null
            lastModified: DateTime.now(),
          );
        }
        return item;
      }).toList();
    } 

    items = updateList(items);
    archivedItems = updateList(archivedItems);
    favoriteItems = updateList(favoriteItems);
    trashedItems = updateList(trashedItems);

    await _saveAllLists();
    notifyListeners();
  }
  List<ListItem> getFilteredList({
    required List<ListItem> sortedList,
    required String? selectedTag,
    required CategoryItem? selectedCategory,
  }) {
    Iterable<ListItem> filtered = sortedList;
    
    if (selectedTag != null) {
      filtered = filtered.where((item) => item.tags.contains(selectedTag));
    }
    
    if (selectedCategory != null) {
      filtered = filtered.where((item) => item.categoryId == selectedCategory.id);
    }
    
    return filtered.toList();
  }
  /// Alterna el estado de fijado (pin) para un bloque de notas seleccionadas
  Future<void> togglePinMultiple(List<ListItem> selectedItems) async {
  if (selectedItems.isEmpty) return;

  final Set<String> selectedIds = selectedItems.map((e) => e.id).toSet();

  List<ListItem> updatePinStatus(List<ListItem> targetList) {
    return targetList.map((item) {
      if (selectedIds.contains(item.id)) {
        return item.copyWith(
          isPinned: !item.isPinned,
          lastModified: DateTime.now(),
        );
      }
      return item;
    }).toList();
  }

  items = updatePinStatus(items);
  archivedItems = updatePinStatus(archivedItems);
  favoriteItems = updatePinStatus(favoriteItems);

  await _saveAllLists();
  notifyListeners();
  }
}