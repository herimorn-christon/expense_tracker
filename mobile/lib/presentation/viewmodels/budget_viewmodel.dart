import 'package:flutter/material.dart';
import 'package:expense_tracker_mobile/data/models/budget.dart';
import 'package:expense_tracker_mobile/data/services/budget_service.dart';

class BudgetViewModel extends ChangeNotifier {
  final BudgetService _budgetService;

  List<Budget> _budgets = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _aiSuggestions;
  Map<String, dynamic>? _analytics;

  BudgetViewModel(this._budgetService);

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get aiSuggestions => _aiSuggestions;
  Map<String, dynamic>? get analytics => _analytics;

  // Get active budgets only
  List<Budget> get activeBudgets => _budgets.where((budget) => budget.isActive).toList();

  // Get budgets by status
  List<Budget> getBudgetsByStatus(String status) {
    return _budgets.where((budget) => budget.status == status).toList();
  }

  // Get budgets that need attention (warning or exceeded)
  List<Budget> get budgetsNeedingAttention {
    return _budgets.where((budget) => budget.shouldAlert || budget.status == 'exceeded').toList();
  }

  Future<void> loadBudgets({String? period, bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _error = null;
    if (refresh) notifyListeners();

    try {
      print('BudgetViewModel: Loading budgets...'); // Debug log
      final newBudgets = await _budgetService.getBudgets(period: period);
      print('BudgetViewModel: Received ${newBudgets.length} budgets from service'); // Debug log

      if (refresh || _budgets.isEmpty) {
        _budgets = newBudgets;
        print('BudgetViewModel: Set budgets list to ${newBudgets.length} items'); // Debug log
      } else {
        // Avoid duplicates by checking existing IDs
        final existingIds = _budgets.map((b) => b.id).toSet();
        final uniqueNewBudgets = newBudgets.where((b) => !existingIds.contains(b.id)).toList();
        _budgets.addAll(uniqueNewBudgets);
        print('BudgetViewModel: Added ${uniqueNewBudgets.length} unique items, total: ${_budgets.length}'); // Debug log
      }
    } catch (e) {
      print('BudgetViewModel: Error loading budgets: $e'); // Debug log
      _error = e.toString();
    } finally {
      _isLoading = false;
      print('BudgetViewModel: Finished loading, isLoading: $_isLoading, error: $_error'); // Debug log
      notifyListeners();
    }
  }

  Future<bool> createBudget(Budget budget) async {
    try {
      final newBudget = await _budgetService.createBudget(budget);
      _budgets.add(newBudget);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBudget(int id, Budget budget) async {
    try {
      final updatedBudget = await _budgetService.updateBudget(id, budget);
      final index = _budgets.indexWhere((b) => b.id == id);

      if (index != -1) {
        _budgets[index] = updatedBudget;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBudget(int id) async {
    try {
      await _budgetService.deleteBudget(id);
      _budgets.removeWhere((budget) => budget.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadAISuggestions({int months = 6}) async {
    try {
      _aiSuggestions = null;
      notifyListeners();

      final suggestions = await _budgetService.getAISuggestions(months: months);
      _aiSuggestions = {'suggestions': suggestions};
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> autoAdjustBudgets() async {
    try {
      final result = await _budgetService.autoAdjustBudgets();
      // Refresh budgets after auto-adjustment
      await loadBudgets(refresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadBudgetAnalytics({int months = 6}) async {
    try {
      _analytics = null;
      notifyListeners();

      final analyticsData = await _budgetService.getBudgetAnalytics(months: months);
      _analytics = analyticsData;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshBudgets() async {
    await loadBudgets(refresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper method to get budget progress color
  Color getBudgetProgressColor(Budget budget) {
    if (budget.status == 'exceeded') return Colors.red;
    if (budget.status == 'warning') return Colors.orange;
    return Colors.green;
  }

  // Helper method to get budget status text
  String getBudgetStatusText(Budget budget) {
    switch (budget.status) {
      case 'exceeded':
        return 'Over Budget';
      case 'warning':
        return 'Warning';
      case 'active':
        return 'On Track';
      case 'unused':
        return 'Unused';
      default:
        return 'Unknown';
    }
  }
}