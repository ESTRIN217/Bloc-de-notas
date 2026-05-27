import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryItem {
  final String id;
  final String name;

  CategoryItem({required this.id, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'name': name};
  factory CategoryItem.fromMap(Map<String, dynamic> map) => CategoryItem(id: map['id'], name: map['name']);
}

class CategoryProvider with ChangeNotifier {
  List<CategoryItem> _categories = [];
  List<CategoryItem> get categories => _categories;

  CategoryProvider() {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final String? categoriesJson = prefs.getString('custom_categories');
    if (categoriesJson != null) {
      final List<dynamic> decoded = jsonDecode(categoriesJson);
      _categories = decoded.map((item) => CategoryItem.fromMap(item)).toList();
      notifyListeners();
    }
  }

  Future<void> addCategory(String name) async {
    final newCategory = CategoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );
    _categories.add(newCategory);
    notifyListeners();
    await _saveCategories();
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_categories.map((c) => c.toMap()).toList());
    await prefs.setString('custom_categories', encoded);
  }
}