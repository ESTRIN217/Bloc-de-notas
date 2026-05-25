import 'package:flutter/material.dart';
import 'package:bloc_de_notas/l10n/app_localizations.dart';
import 'package:bloc_de_notas/presentation/widgets/list_item.dart';
import 'package:bloc_de_notas/services/search_service.dart';
import 'package:bloc_de_notas/presentation/widgets/note_item_widget.dart'; 

class CustomSearchDelegate extends SearchDelegate<ListItem?> {
  final List<ListItem> allNotes; // Asegúrate de pasarle AQUÍ la unión de todas las notas (normales, archivadas y favoritas) 
  final List<String> availableTags; 
  final List<int> availableColors; 

  // Variables de estado interno para los filtros
  String? selectedTag; 
  int? selectedColor; 
  String? selectedListFilter; // Nueva variable: puede ser 'archived', 'favorite' o null 

  CustomSearchDelegate({
    required this.allNotes,
    required this.availableTags,
    required this.availableColors,
  }); 

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context); 
    return theme.copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    ); 
  } 

  @override
  String get searchFieldLabel => "Buscar..."; 

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_outlined),
          onPressed: () => query = '',
        ),
    ];
  } 

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_outlined),
      onPressed: () => close(context, null),
    );
  } 

  @override
  Widget buildResults(BuildContext context) {
    return _buildBody(context);
  } 

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildBody(context);
  } 

  Widget _buildBody(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setBodyState) {
        
        // 1. Filtrado base por texto, etiquetas y colores
        List<ListItem> results = SearchService.filterNotes(
          sourceList: allNotes,
          query: query,
          selectedTag: selectedTag,
          selectedColor: selectedColor,
        );

        // 2. Filtrado local y secuencial para el comportamiento de Buscador Global
        if (selectedListFilter == 'archived') {
          results = results.where((item) => item.isArchived).toList();
        } else if (selectedListFilter == 'favorite') {
          results = results.where((item) => item.isFavorite).toList();
        }

        return Column(
          children: [
            _buildFilterChips(context, setBodyState), 
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(AppLocalizations.of(context)!.search),
                    ) 
                  : ListView.builder(
                      itemCount: results.length, 
                      itemBuilder: (context, index) {
                        final item = results[index]; 
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
                          child: NoteItemWidget(
                            item: item,
                            isListView: true, 
                            isSelected: false, 
                            isSelectionMode: false, 
                            canReorder: false, 
                            isTrashView: false, 
                            itemIndex: index, 
                            onTap: () {
                              close(context, item); 
                            },
                            onLongPress: () {}, 
                            onMorePressed: () {}, 
                          ),
                        ); 
                      },
                    ), 
            ),
          ],
        );
      },
    ); 
  }

  Widget _buildFilterChips(BuildContext context, StateSetter setBodyState) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
      child: Row(
        children: [
          // Chip para Filtrar por Archivados
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: const Icon(Icons.archive_outlined, size: 18),
              label: Text(AppLocalizations.of(context)!.archivados),
              selected: selectedListFilter == 'archived',
              onSelected: (selected) {
                setBodyState(() {
                  // Si se selecciona, activa 'archived', de lo contrario limpia el filtro
                  selectedListFilter = selected ? 'archived' : null;
                });
              },
            ),
          ),

          // Chip para Filtrar por Favoritos
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: const Icon(Icons.favorite_outline, size: 18),
              label: Text(AppLocalizations.of(context)!.favorites), 
              selected: selectedListFilter == 'favorite',
              onSelected: (selected) {
                setBodyState(() {
                  selectedListFilter = selected ? 'favorite' : null;
                });
              },
            ),
          ),

          // Separador visual implícito o directo si hay más elementos continuos
          // Chips de Etiquetas ya existentes
          ...availableTags.map((tag) => Padding(
                padding: const EdgeInsets.only(right: 8), 
                child: FilterChip(
                  label: Text(tag), 
                  selected: selectedTag == tag, 
                  onSelected: (selected) {
                    setBodyState(() {
                      selectedTag = selected ? tag : null; 
                    });
                  },
                ), 
              )),
              
          // Chips de Colores ya existentes
          ...availableColors.map((colorValue) => Padding(
                padding: const EdgeInsets.only(right: 8), 
                child: FilterChip(
                  avatar: CircleAvatar(
                    backgroundColor: Color(colorValue), 
                    radius: 10,
                  ),
                  label: Text(AppLocalizations.of(context)!.colorFilterLabel),
                  selected: selectedColor == colorValue, 
                  onSelected: (selected) {
                    setBodyState(() {
                      selectedColor = selected ? colorValue : null;
                    });
                  },
                ),
              )), 
        ],
      ),
    );
  }
}