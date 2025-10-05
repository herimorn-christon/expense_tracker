import 'package:flutter/material.dart';
import 'package:expense_tracker_mobile/data/models/expense.dart';
import 'package:expense_tracker_mobile/data/models/category.dart';
import 'package:expense_tracker_mobile/data/services/expense_service.dart';
import 'package:expense_tracker_mobile/data/services/category_service.dart';

class ExpenseFormViewModel extends ChangeNotifier {
  final ExpenseService _expenseService;
  final CategoryService _categoryService;

  List<Category> _categories = [];
  bool _isLoading = false;
  bool _isLoadingCategories = false;
  String? _error;

  ExpenseFormViewModel(this._expenseService, this._categoryService);

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingCategories => _isLoadingCategories;
  String? get error => _error;

  Future<void> loadCategories() async {
    _isLoadingCategories = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _categoryService.getCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  Future<bool> createExpense(Expense expense, {String? receiptPath}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _expenseService.createExpense(expense, receiptPath: receiptPath);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExpense(int expenseId, Expense expense, {String? receiptPath}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _expenseService.updateExpense(expenseId, expense);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}