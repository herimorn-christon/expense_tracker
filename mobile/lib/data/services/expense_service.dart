import 'package:expense_tracker_mobile/core/network/api_client.dart';
import 'package:expense_tracker_mobile/data/models/expense.dart';

class ExpenseService {
  final ApiClient _apiClient;

  ExpenseService(this._apiClient);

  Future<List<Expense>> getExpenses({
    Map<String, dynamic>? filters,
  }) async {
    try {
      final response = await _apiClient.get('/expenses', queryParameters: filters);

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle Laravel paginated response structure
        List<dynamic> expensesData;
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is Map<String, dynamic> && data.containsKey('data')) {
            // Paginated response: {"data": {"data": [...], "current_page": 1, ...}}
            expensesData = data['data'] ?? [];
          } else if (data is List<dynamic>) {
            // Direct array response
            expensesData = data;
          } else {
            expensesData = [];
          }
        } else if (responseData is List<dynamic>) {
          // Direct array response
          expensesData = responseData;
        } else {
          expensesData = [];
        }

        return expensesData.map((json) => Expense.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch expenses: $e');
    }
  }

  Future<Expense> getExpenseById(int id) async {
    try {
      final response = await _apiClient.get('/expenses/$id');

      if (response.statusCode == 200) {
        return Expense.fromJson(response.data['data'] ?? response.data);
      }
      throw Exception('Expense not found');
    } catch (e) {
      throw Exception('Failed to fetch expense: $e');
    }
  }

  Future<Expense> createExpense(Expense expense, {String? receiptPath}) async {
    try {
      Map<String, dynamic> expenseData = expense.toJson();
      expenseData.remove('id'); // Remove ID for creation
      expenseData.remove('created_at');
      expenseData.remove('updated_at');

      if (receiptPath != null) {
        // If there's a receipt image, use multipart upload
        return await _createExpenseWithReceipt(expenseData, receiptPath);
      } else {
        // Regular JSON creation
        final response = await _apiClient.post('/expenses', data: expenseData);

        if (response.statusCode == 201) {
          return Expense.fromJson(response.data['data'] ?? response.data);
        }
      }

      throw Exception('Failed to create expense');
    } catch (e) {
      throw Exception('Failed to create expense: $e');
    }
  }

  Future<Expense> _createExpenseWithReceipt(Map<String, dynamic> expenseData, String receiptPath) async {
    try {
      // This would require implementing file upload in the API client
      // For now, create without receipt and log the path
      print('Receipt upload not yet implemented: $receiptPath');

      final response = await _apiClient.post('/expenses', data: expenseData);

      if (response.statusCode == 201) {
        return Expense.fromJson(response.data['data'] ?? response.data);
      }

      throw Exception('Failed to create expense');
    } catch (e) {
      throw Exception('Failed to create expense with receipt: $e');
    }
  }

  Future<Expense> updateExpense(int id, Expense expense) async {
    try {
      Map<String, dynamic> expenseData = expense.toJson();
      expenseData.remove('id');
      expenseData.remove('created_at');
      expenseData.remove('updated_at');

      final response = await _apiClient.put('/expenses/$id', data: expenseData);

      if (response.statusCode == 200) {
        return Expense.fromJson(response.data['data'] ?? response.data);
      }

      throw Exception('Failed to update expense');
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _apiClient.delete('/expenses/$id');
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  Future<Map<String, dynamic>> getExpenseStatistics({
    String? period,
    List<int>? categoryIds,
  }) async {
    try {
      Map<String, dynamic> params = {};

      if (period != null) params['period'] = period;
      if (categoryIds != null && categoryIds.isNotEmpty) {
        params['categories'] = categoryIds.join(',');
      }

      final response = await _apiClient.get('/expenses/statistics/dashboard', queryParameters: params);

      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      }

      throw Exception('Failed to fetch statistics');
    } catch (e) {
      throw Exception('Failed to fetch expense statistics: $e');
    }
  }
}