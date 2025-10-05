import 'package:flutter/material.dart';
import 'package:expense_tracker_mobile/data/models/ai_insights.dart';
import 'package:expense_tracker_mobile/data/services/ai_service.dart';

class AIInsightsViewModel extends ChangeNotifier {
  final AIService _aiService;

  AIInsights? _insights;
  Map<String, dynamic>? _predictiveAnalysis;
  Map<String, dynamic>? _anomalyDetection;
  Map<String, dynamic>? _comparativeAnalysis;
  bool _isLoading = false;
  bool _isLoadingPredictive = false;
  bool _isLoadingAnomalies = false;
  bool _isLoadingComparative = false;
  String? _error;

  // Caching timestamps to avoid repeated API calls
  DateTime? _lastInsightsLoad;
  DateTime? _lastPredictiveLoad;
  DateTime? _lastAnomaliesLoad;
  DateTime? _lastComparativeLoad;

  // Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  AIInsightsViewModel(this._aiService);

  AIInsights? get insights => _insights;
  Map<String, dynamic>? get predictiveAnalysis => _predictiveAnalysis;
  Map<String, dynamic>? get anomalyDetection => _anomalyDetection;
  Map<String, dynamic>? get comparativeAnalysis => _comparativeAnalysis;
  bool get isLoading => _isLoading;
  bool get isLoadingPredictive => _isLoadingPredictive;
  bool get isLoadingAnomalies => _isLoadingAnomalies;
  bool get isLoadingComparative => _isLoadingComparative;
  String? get error => _error;

  Future<void> loadAIInsights({
    String? timeframe,
    List<int>? categoryIds,
    bool forceRefresh = false,
  }) async {
    // Check cache first
    if (!forceRefresh && _insights != null && _lastInsightsLoad != null) {
      final timeSinceLastLoad = DateTime.now().difference(_lastInsightsLoad!);
      if (timeSinceLastLoad < _cacheDuration) {
        return; // Use cached data
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _insights = await _aiService.getInsights(
        timeframe: timeframe,
        categoryIds: categoryIds,
      );
      _lastInsightsLoad = DateTime.now();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPredictiveAnalysis({
    int? monthsAhead,
    List<int>? categoryIds,
    bool forceRefresh = false,
  }) async {
    // Check cache first
    if (!forceRefresh && _predictiveAnalysis != null && _lastPredictiveLoad != null) {
      final timeSinceLastLoad = DateTime.now().difference(_lastPredictiveLoad!);
      if (timeSinceLastLoad < _cacheDuration) {
        return; // Use cached data
      }
    }

    _isLoadingPredictive = true;
    notifyListeners();

    try {
      _predictiveAnalysis = await _aiService.getPredictiveAnalysis(
        monthsAhead: monthsAhead,
        categoryIds: categoryIds,
      );
      _lastPredictiveLoad = DateTime.now();
    } catch (e) {
      _error = 'Failed to load predictive analysis: $e';
      print('Failed to load predictive analysis: $e');
    } finally {
      _isLoadingPredictive = false;
      notifyListeners();
    }
  }

  Future<void> loadAnomalyDetection({
    int? months,
    String? sensitivity,
    bool forceRefresh = false,
  }) async {
    // Check cache first
    if (!forceRefresh && _anomalyDetection != null && _lastAnomaliesLoad != null) {
      final timeSinceLastLoad = DateTime.now().difference(_lastAnomaliesLoad!);
      if (timeSinceLastLoad < _cacheDuration) {
        return; // Use cached data
      }
    }

    _isLoadingAnomalies = true;
    notifyListeners();

    try {
      _anomalyDetection = await _aiService.detectAnomalies(
        months: months,
        sensitivity: sensitivity,
      );
      _lastAnomaliesLoad = DateTime.now();
    } catch (e) {
      _error = 'Failed to load anomaly detection: $e';
      print('Failed to load anomaly detection: $e');
    } finally {
      _isLoadingAnomalies = false;
      notifyListeners();
    }
  }

  Future<void> loadComparativeAnalysis({
    String? period1,
    String? period2,
    bool forceRefresh = false,
  }) async {
    // Check cache first
    if (!forceRefresh && _comparativeAnalysis != null && _lastComparativeLoad != null) {
      final timeSinceLastLoad = DateTime.now().difference(_lastComparativeLoad!);
      if (timeSinceLastLoad < _cacheDuration) {
        return; // Use cached data
      }
    }

    _isLoadingComparative = true;
    notifyListeners();

    try {
      _comparativeAnalysis = await _aiService.getComparativeAnalysis(
        period1: period1,
        period2: period2,
      );
      _lastComparativeLoad = DateTime.now();
    } catch (e) {
      _error = 'Failed to load comparative analysis: $e';
      print('Failed to load comparative analysis: $e');
    } finally {
      _isLoadingComparative = false;
      notifyListeners();
    }
  }

  Future<void> refreshAllInsights() async {
    // Force refresh all insights (bypass cache)
    await Future.wait([
      loadAIInsights(forceRefresh: true),
      loadPredictiveAnalysis(forceRefresh: true),
      loadAnomalyDetection(forceRefresh: true),
      loadComparativeAnalysis(forceRefresh: true),
    ]);
  }

  // Clear all cached data
  void clearCache() {
    _insights = null;
    _predictiveAnalysis = null;
    _anomalyDetection = null;
    _comparativeAnalysis = null;
    _lastInsightsLoad = null;
    _lastPredictiveLoad = null;
    _lastAnomaliesLoad = null;
    _lastComparativeLoad = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}