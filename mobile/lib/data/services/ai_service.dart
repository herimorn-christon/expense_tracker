import 'package:expense_tracker_mobile/core/network/api_client.dart';
import 'package:expense_tracker_mobile/data/models/ai_insights.dart';

class AIService {
  final ApiClient _apiClient;

  AIService(this._apiClient);

  Future<AIInsights> getInsights({
    String? timeframe,
    List<int>? categoryIds,
  }) async {
    try {
      Map<String, dynamic> data = {};

      if (timeframe != null) data['timeframe'] = timeframe;
      if (categoryIds != null && categoryIds.isNotEmpty) {
        data['categories'] = categoryIds;
      }

      final response = await _apiClient.post('/ai/insights', data: data);

      if (response.statusCode == 200) {
        return AIInsights.fromJson(response.data['data']);
      }

      throw Exception('Failed to fetch AI insights');
    } catch (e) {
      throw Exception('Failed to fetch AI insights: $e');
    }
  }

  Future<Map<String, dynamic>> getPredictiveAnalysis({
    int? monthsAhead,
    List<int>? categoryIds,
  }) async {
    try {
      Map<String, dynamic> data = {};

      if (monthsAhead != null) data['months_ahead'] = monthsAhead;
      if (categoryIds != null && categoryIds.isNotEmpty) {
        data['categories'] = categoryIds;
      }

      final response = await _apiClient.post('/ai/predictive-analysis', data: data);

      if (response.statusCode == 200) {
        return response.data['data'];
      }

      throw Exception('Failed to fetch predictive analysis');
    } catch (e) {
      throw Exception('Failed to fetch predictive analysis: $e');
    }
  }

  Future<Map<String, dynamic>> detectAnomalies({
    int? months,
    String? sensitivity,
  }) async {
    try {
      Map<String, dynamic> data = {};

      if (months != null) data['months'] = months;
      if (sensitivity != null) data['sensitivity'] = sensitivity;

      final response = await _apiClient.post('/ai/anomaly-detection', data: data);

      if (response.statusCode == 200) {
        return response.data['data'];
      }

      throw Exception('Failed to detect anomalies');
    } catch (e) {
      throw Exception('Failed to detect anomalies: $e');
    }
  }

  Future<Map<String, dynamic>> getComparativeAnalysis({
    String? period1,
    String? period2,
  }) async {
    try {
      Map<String, dynamic> params = {};

      if (period1 != null) params['period1'] = period1;
      if (period2 != null) params['period2'] = period2;

      final response = await _apiClient.get('/ai/comparative-analysis', queryParameters: params);

      if (response.statusCode == 200) {
        return response.data['data'];
      }

      throw Exception('Failed to fetch comparative analysis');
    } catch (e) {
      throw Exception('Failed to fetch comparative analysis: $e');
    }
  }
}