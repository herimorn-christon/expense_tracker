import 'package:expense_tracker_mobile/core/network/api_client.dart';
import 'package:expense_tracker_mobile/data/models/budget.dart';

class BudgetService {
  final ApiClient _apiClient;

  BudgetService(this._apiClient);

  Future<List<Budget>> getBudgets({String? period}) async {
    try {
      print('BudgetService: Fetching budgets...'); // Debug log
      final Map<String, dynamic> queryParams = {};
      if (period != null) {
        queryParams['period'] = period;
      }

      final response = await _apiClient.get('/budgets', queryParameters: queryParams);
      print('BudgetService: Response status: ${response.statusCode}'); // Debug log
      print('BudgetService: Full response: ${response.data}'); // Debug log

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        print('BudgetService: Raw data length: ${data.length}'); // Debug log
        print('BudgetService: First item: ${data.isNotEmpty ? data[0] : 'No data'}'); // Debug log

        final budgets = data.map((json) {
          print('BudgetService: Processing item: $json'); // Debug log
          try {
            return Budget.fromJson(json);
          } catch (e) {
            print('BudgetService: Error parsing budget: $e'); // Debug log
            print('BudgetService: Problematic JSON: $json'); // Debug log
            rethrow;
          }
        }).toList();

        print('BudgetService: Successfully parsed ${budgets.length} budgets'); // Debug log
        return budgets;
      }
      print('BudgetService: Invalid status code: ${response.statusCode}'); // Debug log
      return [];
    } catch (e) {
      print('BudgetService: Error: $e'); // Debug log
      throw Exception('Failed to fetch budgets: $e');
    }
  }

  Future<Budget> getBudgetById(int id) async {
    try {
      final response = await _apiClient.get('/budgets/$id');

      if (response.statusCode == 200) {
        return Budget.fromJson(response.data['data'] ?? response.data);
      }
      throw Exception('Budget not found');
    } catch (e) {
      throw Exception('Failed to fetch budget: $e');
    }
  }

  Future<Budget> createBudget(Budget budget) async {
    try {
      Map<String, dynamic> budgetData = budget.toJson();
      // Remove fields that shouldn't be sent during creation
      budgetData.remove('id');
      budgetData.remove('created_at');
      budgetData.remove('updated_at');
      budgetData.remove('spent');
      budgetData.remove('remaining');
      budgetData.remove('utilization_percentage');
      budgetData.remove('status');
      budgetData.remove('should_alert');

      final response = await _apiClient.post('/budgets', data: budgetData);

      if (response.statusCode == 201) {
        return Budget.fromJson(response.data['data'] ?? response.data);
      }

      throw Exception('Failed to create budget');
    } catch (e) {
      throw Exception('Failed to create budget: $e');
    }
  }

  Future<Budget> updateBudget(int id, Budget budget) async {
    try {
      Map<String, dynamic> budgetData = budget.toJson();
      // Remove fields that shouldn't be sent during update
      budgetData.remove('id');
      budgetData.remove('created_at');
      budgetData.remove('updated_at');
      budgetData.remove('spent');
      budgetData.remove('remaining');
      budgetData.remove('utilization_percentage');
      budgetData.remove('status');
      budgetData.remove('should_alert');

      final response = await _apiClient.put('/budgets/$id', data: budgetData);

      if (response.statusCode == 200) {
        return Budget.fromJson(response.data['data'] ?? response.data);
      }

      throw Exception('Failed to update budget');
    } catch (e) {
      throw Exception('Failed to update budget: $e');
    }
  }

  Future<void> deleteBudget(int id) async {
    try {
      await _apiClient.delete('/budgets/$id');
    } catch (e) {
      throw Exception('Failed to delete budget: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAISuggestions({int months = 6}) async {
    try {
      final response = await _apiClient.get('/budgets/ai-suggestions', queryParameters: {
        'months': months.toString(),
      });

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch AI suggestions: $e');
    }
  }

  Future<Map<String, dynamic>> autoAdjustBudgets() async {
    try {
      final response = await _apiClient.post('/budgets/auto-adjust');

      if (response.statusCode == 200) {
        return response.data;
      }

      throw Exception('Failed to auto-adjust budgets');
    } catch (e) {
      throw Exception('Failed to auto-adjust budgets: $e');
    }
  }

  Future<Map<String, dynamic>> getBudgetAnalytics({int months = 6}) async {
    try {
      final response = await _apiClient.get('/budgets/analytics', queryParameters: {
        'months': months.toString(),
      });

      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      }

      throw Exception('Failed to fetch budget analytics');
    } catch (e) {
      throw Exception('Failed to fetch budget analytics: $e');
    }
  }
}