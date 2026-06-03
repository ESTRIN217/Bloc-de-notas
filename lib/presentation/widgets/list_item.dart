import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';

enum SortMethod { custom, alphabetical, byDate }

class ListItem {
  final String id;
  final String title;
  final String summary;
  final DateTime lastModified;
  final int? backgroundColor;
  final String? backgroundImagePath;
  final List<String> tags;
  final bool isArchived;
  final bool isFavorite;
  final String? categoryId; 
  final bool isPinned;

  ListItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.lastModified,
    this.backgroundColor,
    this.backgroundImagePath,
    this.tags = const [],
    this.isArchived = false,
    this.isFavorite = false,
    this.categoryId,
    this.isPinned = false,
  });

  ListItem copyWith({
    String? id,
    String? title,
    String? summary,
    DateTime? lastModified,
    int? backgroundColor,
    String? backgroundImagePath,
    List<String>? tags,
    bool? isArchived,
    bool? isFavorite,
    String? categoryId,
    bool overrideCategory = false,
    bool? isPinned,
  }) {
    return ListItem(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      lastModified: lastModified ?? this.lastModified,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      tags: tags ?? this.tags,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      categoryId: overrideCategory ? categoryId : (categoryId ?? this.categoryId),
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'lastModified': lastModified.toIso8601String(),
      'backgroundColor': backgroundColor,
      'backgroundImagePath': backgroundImagePath,
      'tags': tags,
      'isArchived': isArchived,
      'isFavorite': isFavorite,
      'categoryId': categoryId, 
      'isPinned': isPinned,
    };
  }

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
      id: json['id'],
      title: json['title'],
      summary: json['summary'],
      lastModified: DateTime.parse(json['lastModified']),
      backgroundColor: json['backgroundColor'],
      backgroundImagePath: json['backgroundImagePath'],
      tags: List<String>.from(json['tags'] ?? []),
      isArchived: json['isArchived'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      categoryId: json['categoryId'], 
      isPinned: json['isPinned'] ?? false,
    );
  }

  // Helper to get a Quill Document from the summary string
  Document get document {
    try {
      if (summary.trim().startsWith('[') && summary.trim().endsWith(']')) {
        final decoded = jsonDecode(summary);
        if (decoded is List) {
            // The delta is already a list of maps, so we can pass it directly
            return Document.fromJson(decoded);
        } 
      }
    } catch (e) {
      // Not a valid JSON, so treat it as plain text.
    } 
    // For plain text summaries or errors in JSON parsing, create a simple delta.
    return Document()..insert(0, summary);
  }
}
