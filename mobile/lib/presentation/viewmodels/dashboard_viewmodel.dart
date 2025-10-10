import 'package:flutter/material.dart';
import 'package:expense_tracker_mobile/data/services/dashboard_service.dart';
import 'package:expense_tracker_mobile/data/services/category_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final DashboardService _dashboardService;
  final CategoryService _categoryService;

  Map<String, dynamic>? _statistics;
  Map<String, dynamic>? _budgetStatistics;
  List<Map<String, dynamic>> _monthlyTrend = [];
  List<Map<String, dynamic>> _categoryBreakdown = [];
  bool _isLoading = false;
  bool _isLoadingTrend = false;
  bool _isLoadingBreakdown = false;
  bool _isLoadingBudget = false;
  String? _error;

  DashboardViewModel(this._dashboardService, this._categoryService);

  Map<String, dynamic>? get statistics => _statistics;
  Map<String, dynamic>? get budgetStatistics => _budgetStatistics;
  List<Map<String, dynamic>> get monthlyTrend => _monthlyTrend;
  List<Map<String, dynamic>> get categoryBreakdown => _categoryBreakdown;
  bool get isLoading => _isLoading;
  bool get isLoadingTrend => _isLoadingTrend;
  bool get isLoadingBreakdown => _isLoadingBreakdown;
  bool get isLoadingBudget => _isLoadingBudget;
  String? get error => _error;

  double get totalExpenses {
    return _statistics != null ? double.parse(_statistics!['total_expenses'].toString()) : 0.0;
  }

  int get expenseCount {
    return _statistics != null ? (_statistics!['expense_count'] ?? 0) : 0;
  }

  Future<int> getTotalCategoriesCount() async {
    try {
      final categories = await _categoryService.getCategories();
      return categories.length;
    } catch (e) {
      print('Failed to load categories count: $e');
      return 0;
    }
  }

  Future<void> loadDashboardData() async {
    await Future.wait([
      loadStatistics(),
      loadBudgetStatistics(),
      loadMonthlyTrend(),
      loadCategoryBreakdown(),
    ]);
  }

  Future<void> loadStatistics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _statistics = await _dashboardService.getExpenseStatistics();
      print('Loaded statistics for user: $_statistics');
    } catch (e) {
      _error = e.toString();
      print('Error loading statistics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBudgetStatistics() async {
    _isLoadingBudget = true;
    notifyListeners();

    try {
      _budgetStatistics = await _dashboardService.getBudgetStatistics();
    } catch (e) {
      print('Failed to load budget statistics: $e');
      _budgetStatistics = null;
    } finally {
      _isLoadingBudget = false;
      notifyListeners();
    }
  }

  Future<void> loadMonthlyTrend() async {
    _isLoadingTrend = true;
    notifyListeners();

    try {
      _monthlyTrend = await _dashboardService.getMonthlyTrend();
    } catch (e) {
      print('Failed to load monthly trend: $e');
    } finally {
      _isLoadingTrend = false;
      notifyListeners();
    }
  }

  Future<void> loadCategoryBreakdown() async {
    _isLoadingBreakdown = true;
    notifyListeners();

    try {
      _categoryBreakdown = await _dashboardService.getCategoryBreakdown();
      print('Loaded category breakdown: $_categoryBreakdown');
    } catch (e) {
      print('Failed to load category breakdown: $e');
    } finally {
      _isLoadingBreakdown = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    // Prevent multiple simultaneous refresh calls
    if (_isLoading || _isLoadingTrend || _isLoadingBreakdown || _isLoadingBudget) {
      return;
    }
    await loadDashboardData();
  }

  void clearDashboardData() {
    _statistics = null;
    _budgetStatistics = null;
    _monthlyTrend = [];
    _categoryBreakdown = [];
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}