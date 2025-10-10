import 'package:expense_tracker_mobile/core/network/api_client.dart';

class DashboardService {
  final ApiClient _apiClient;

  DashboardService(this._apiClient);

  Future<Map<String, dynamic>> getExpenseStatistics({
    String? startDate,
    String? endDate,
  }) async {
    try {
      Map<String, dynamic> params = {};

      if (startDate != null) params['start_date'] = startDate;
      if (endDate != null) params['end_date'] = endDate;

      // Add user_id parameter to ensure user-specific filtering
      final response = await _apiClient.get('/expenses/statistics/dashboard', queryParameters: params);

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle Laravel API response structure
        final data = responseData is Map<String, dynamic> && responseData.containsKey('data')
            ? responseData['data'] as Map<String, dynamic>
            : responseData as Map<String, dynamic>;

        return data;
      }

      throw Exception('Failed to fetch dashboard statistics');
    } catch (e) {
      throw Exception('Failed to fetch dashboard statistics: $e');
    }
  }

  Future<Map<String, dynamic>> getBudgetStatistics() async {
    try {
      final response = await _apiClient.get('/budgets/statistics/dashboard');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle Laravel API response structure
        final data = responseData is Map<String, dynamic> && responseData.containsKey('data')
            ? responseData['data'] as Map<String, dynamic>
            : responseData as Map<String, dynamic>;

        return data;
      }

      throw Exception('Failed to fetch budget statistics');
    } catch (e) {
      throw Exception('Failed to fetch budget statistics: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyTrend() async {
    try {
      final response = await _apiClient.get('/cash-flow/monthly-trend');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle Laravel API response structure
        final data = responseData is Map<String, dynamic> && responseData.containsKey('data')
            ? responseData['data'] as List<dynamic>
            : responseData as List<dynamic>;

        return data.map((item) => item as Map<String, dynamic>).toList();
      }

      throw Exception('Failed to fetch monthly trend');
    } catch (e) {
      throw Exception('Failed to fetch monthly trend: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCategoryBreakdown() async {
    try {
      final response = await _apiClient.get('/expenses/statistics/dashboard');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle Laravel API response structure
        final data = responseData is Map<String, dynamic> && responseData.containsKey('data')
            ? responseData['data'] as Map<String, dynamic>
            : responseData as Map<String, dynamic>;

        final expensesByCategory = data['expenses_by_category'] as List<dynamic>? ?? [];

        return expensesByCategory.map((item) {
          final category = item['category'] as Map<String, dynamic>? ?? {};
          return {
            'category_name': category['name'] ?? 'Unknown',
            'category_color': category['color'] ?? '#6B7280',
            'total': double.parse(item['total'].toString()),
          };
        }).toList();
      }

      throw Exception('Failed to fetch category breakdown');
    } catch (e) {
      throw Exception('Failed to fetch category breakdown: $e');
    }
  }
}