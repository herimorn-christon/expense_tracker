import 'package:flutter/material.dart';
import 'package:expense_tracker_mobile/data/models/category.dart';
import 'package:expense_tracker_mobile/data/services/category_service.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryService _categoryService;

  List<Category> _categories = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  CategoryViewModel(this._categoryService);

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;

  // Get active categories only
  List<Category> get activeCategories => _categories.where((category) => category.isActive).toList();

  Future<void> loadCategories({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _error = null;
    if (refresh) notifyListeners();

    try {
      final newCategories = await _categoryService.getCategories();

      if (refresh || _categories.isEmpty) {
        _categories = newCategories;
      } else {
        // Avoid duplicates by checking existing IDs
        final existingIds = _categories.map((c) => c.id).toSet();
        final uniqueNewCategories = newCategories.where((c) => !existingIds.contains(c.id)).toList();
        _categories.addAll(uniqueNewCategories);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory(Category category) async {
    try {
      final newCategory = await _categoryService.createCategory(category);
      _categories.add(newCategory);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(int id, Category category) async {
    try {
      final updatedCategory = await _categoryService.updateCategory(id, category);
      final index = _categories.indexWhere((c) => c.id == id);

      if (index != -1) {
        _categories[index] = updatedCategory;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      await _categoryService.deleteCategory(id);
      _categories.removeWhere((category) => category.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshCategories() async {
    await loadCategories(refresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}