import 'package:flutter/material.dart';
import 'package:expense_tracker_mobile/data/models/expense.dart';
import 'package:expense_tracker_mobile/data/models/category.dart';
import 'package:expense_tracker_mobile/data/services/expense_service.dart';
import 'package:expense_tracker_mobile/data/services/category_service.dart';

class ExpenseListViewModel extends ChangeNotifier {
  final ExpenseService _expenseService;
  final CategoryService _categoryService;

  List<Expense> _expenses = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _searchQuery = '';
  Category? _selectedCategory;
  String? _selectedPaymentMethod;
  DateTimeRange? _dateRange;

  ExpenseListViewModel(this._expenseService, this._categoryService);

  List<Expense> get expenses => _expenses;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  Category? get selectedCategory => _selectedCategory;
  String? get selectedPaymentMethod => _selectedPaymentMethod;
  DateTimeRange? get dateRange => _dateRange;

  // Filtered expenses based on search and filters
  List<Expense> get filteredExpenses {
    return _expenses.where((expense) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!expense.title.toLowerCase().contains(query) &&
            !expense.description.toString().toLowerCase().contains(query)) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != null) {
        if (expense.categoryId != _selectedCategory!.id) {
          return false;
        }
      }

      // Payment method filter
      if (_selectedPaymentMethod != null) {
        if (expense.paymentMethod != _selectedPaymentMethod) {
          return false;
        }
      }

      // Date range filter
      if (_dateRange != null) {
        if (expense.expenseDate.isBefore(_dateRange!.start) ||
            expense.expenseDate.isAfter(_dateRange!.end)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> loadExpenses({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _error = null;
    if (refresh) notifyListeners();

    try {
      final filters = <String, dynamic>{};

      if (_selectedCategory != null) {
        filters['category_id'] = _selectedCategory!.id.toString();
      }

      if (_selectedPaymentMethod != null) {
        filters['payment_method'] = _selectedPaymentMethod!;
      }

      if (_dateRange != null) {
        filters['start_date'] = _dateRange!.start.toIso8601String().split('T')[0];
        filters['end_date'] = _dateRange!.end.toIso8601String().split('T')[0];
      }

      final newExpenses = await _expenseService.getExpenses(filters: filters.isNotEmpty ? filters : null);

      // Always replace the list to avoid duplicates
      _expenses = newExpenses;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _categoryService.getCategories();
      notifyListeners();
    } catch (e) {
      print('Failed to load categories: $e');
    }
  }

  Future<void> refreshExpenses() async {
    _expenses = []; // Clear list to prevent duplicates
    await loadExpenses(refresh: true);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(Category? category) {
    _selectedCategory = category;
    _expenses = []; // Clear list to prevent duplicates
    notifyListeners();
    loadExpenses(refresh: true); // Reload with new filter
  }

  void setPaymentMethodFilter(String? paymentMethod) {
    _selectedPaymentMethod = paymentMethod;
    _expenses = []; // Clear list to prevent duplicates
    notifyListeners();
    loadExpenses(refresh: true); // Reload with new filter
  }

  void setDateRangeFilter(DateTimeRange? dateRange) {
    _dateRange = dateRange;
    if (dateRange != null) {
      _expenses = []; // Clear list to prevent duplicates
    }
    notifyListeners();
    loadExpenses(refresh: true); // Reload with new filter
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedPaymentMethod = null;
    _dateRange = null;
    _expenses = []; // Clear the list
    notifyListeners();
    loadExpenses(refresh: true);
  }

  Future<bool> updateExpense(int expenseId, Expense expense) async {
    try {
      final updatedExpense = await _expenseService.updateExpense(expenseId, expense);
      final index = _expenses.indexWhere((e) => e.id == expenseId);

      if (index != -1) {
        _expenses[index] = updatedExpense;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteExpense(int expenseId) async {
    try {
      await _expenseService.deleteExpense(expenseId);
      _expenses.removeWhere((expense) => expense.id == expenseId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}