import 'package:flutter/material.dart';
import 'package:bloc_de_notas/l10n/app_localizations.dart';
import 'package:bloc_de_notas/presentation/widgets/list_item.dart';
import 'package:bloc_de_notas/services/search_service.dart';
import 'package:bloc_de_notas/presentation/widgets/note_item_widget.dart'; // Tu widget actual para mostrar notas 

class CustomSearchDelegate extends SearchDelegate<ListItem?> {
  final List<ListItem> allNotes;
  final List<String> availableTags;
  final List<int> availableColors;

  // Variables de estado interno para los filtros
  String? selectedTag;
  int? selectedColor;

  CustomSearchDelegate({
    required this.allNotes,
    required this.availableTags,
    required this.availableColors,
  });

  // Forzamos el input para que respete Material Design 3 sin líneas molestas
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
  String get searchFieldLabel => "Buscar..."; // Aquí puedes usar AppLocalizations si puedes inyectar el context previamente

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
      onPressed: () => close(context, null), // Cierra la búsqueda
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
    // 1. Envolvemos TODA la pantalla en el StatefulBuilder
    return StatefulBuilder(
      builder: (context, setBodyState) {
        
        // 2. Ahora results se calcula CADA VEZ que haces tap en un chip
        final results = SearchService.filterNotes(
          sourceList: allNotes,
          query: query,
          selectedTag: selectedTag,
          selectedColor: selectedColor,
        );

        return Column(
          children: [
            // 3. Le pasamos el setBodyState a los chips para que puedan actualizar toda la vista
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

  // Actualizamos el widget de chips para recibir la función de estado principal
  Widget _buildFilterChips(BuildContext context, StateSetter setBodyState) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Chips de Etiquetas
          ...availableTags.map((tag) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(tag),
                  selected: selectedTag == tag,
                  onSelected: (selected) {
                    // Usamos el estado del body para redibujar toda la pantalla
                    setBodyState(() {
                      selectedTag = selected ? tag : null;
                    });
                  },
                ),
              )),
          // Chips de Colores
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