import 'package:bloc_de_notas/presentation/widgets/list_item.dart';

class SearchService {
  static List<ListItem> filterNotes({
    required List<ListItem> sourceList,
    required String query,
    String? selectedTag,
    int? selectedColor,
  }) {
    final lowercaseQuery = query.toLowerCase();

    return sourceList.where((item) {
      // Búsqueda por texto [cite: 96]
      final titleMatch = item.title.toLowerCase().contains(lowercaseQuery);
      final summaryMatch = item.document.toPlainText().toLowerCase().contains(lowercaseQuery);
      final matchesSearch = titleMatch || summaryMatch;

      // Búsqueda por filtros [cite: 97]
      final matchesTag = selectedTag == null || item.tags.contains(selectedTag);
      final matchesColor = selectedColor == null || item.backgroundColor == selectedColor;

      return matchesSearch && matchesTag && matchesColor;
    }).toList();
  }
}