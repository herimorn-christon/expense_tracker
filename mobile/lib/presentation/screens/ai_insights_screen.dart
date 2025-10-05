import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_mobile/presentation/viewmodels/ai_insights_viewmodel.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load only basic insights initially for faster loading
      context.read<AIInsightsViewModel>().loadAIInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AIInsightsViewModel>().refreshAllInsights();
            },
          ),
        ],
      ),
      body: Consumer<AIInsightsViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Insights Section
                Text(
                  'Smart Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Loading State
                if (viewModel.isLoading)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Analyzing your expenses...'),
                          ],
                        ),
                      ),
                    ),
                  )

                // Error State
                else if (viewModel.error != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.error, color: Colors.red[600]),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load AI insights',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.red[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            viewModel.error!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              viewModel.loadAIInsights();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )

                // AI Insights Content
                else if (viewModel.insights != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.psychology, color: Colors.purple[600]),
                              const SizedBox(width: 8),
                              Text(
                                'AI Analysis',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            viewModel.insights!.insights,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 20),

                          // Suggestions
                          Text(
                            'Recommendations',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...viewModel.insights!.suggestions.map((suggestion) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      suggestion,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),

                          const SizedBox(height: 20),

                          // Trend Information
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getTrendColor(viewModel.insights!.trends.direction).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getTrendColor(viewModel.insights!.trends.direction),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getTrendIcon(viewModel.insights!.trends.direction),
                                  color: _getTrendColor(viewModel.insights!.trends.direction),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Trend: ${_formatTrendDirection(viewModel.insights!.trends.direction)}',
                                  style: TextStyle(
                                    color: _getTrendColor(viewModel.insights!.trends.direction),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Predictive Analysis Section
                const SizedBox(height: 24),
                Text(
                  'Predictive Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                if (viewModel.predictiveAnalysis == null && !viewModel.isLoadingPredictive) ...[
                  // Load predictive analysis on demand
                  ElevatedButton(
                    onPressed: () {
                      context.read<AIInsightsViewModel>().loadPredictiveAnalysis();
                    },
                    child: const Text('Load Predictions'),
                  ),
                  const SizedBox(height: 16),
                ] else if (viewModel.isLoadingPredictive)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (viewModel.predictiveAnalysis != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.trending_up, color: Colors.blue[600]),
                                const SizedBox(width: 8),
                                Text(
                                  'Future Predictions',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Based on your spending patterns, here are the predicted amounts for the next few months:',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            ..._buildPredictionsList(viewModel.predictiveAnalysis!),
                          ],
                        ),
                      ),
                    ),
                ],

                // Anomaly Detection Section
                const SizedBox(height: 24),
                Text(
                  'Anomaly Detection',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                if (viewModel.anomalyDetection == null && !viewModel.isLoadingAnomalies) ...[
                  // Load anomaly detection on demand
                  ElevatedButton(
                    onPressed: () {
                      context.read<AIInsightsViewModel>().loadAnomalyDetection();
                    },
                    child: const Text('Load Anomaly Detection'),
                  ),
                  const SizedBox(height: 16),
                ] else if (viewModel.isLoadingAnomalies)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (viewModel.anomalyDetection != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange[600]),
                                const SizedBox(width: 8),
                                Text(
                                  'Unusual Patterns',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._buildAnomaliesList(viewModel.anomalyDetection!),
                          ],
                        ),
                      ),
                    ),
                ],

                // Comparative Analysis Section
                const SizedBox(height: 24),
                Text(
                  'Comparative Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                if (viewModel.comparativeAnalysis == null && !viewModel.isLoadingComparative) ...[
                  // Load comparative analysis on demand
                  ElevatedButton(
                    onPressed: () {
                      context.read<AIInsightsViewModel>().loadComparativeAnalysis();
                    },
                    child: const Text('Load Comparison'),
                  ),
                  const SizedBox(height: 16),
                ] else if (viewModel.isLoadingComparative)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (viewModel.comparativeAnalysis != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.compare_arrows, color: Colors.teal[600]),
                                const SizedBox(width: 8),
                                Text(
                                  'Period Comparison',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._buildComparativeList(viewModel.comparativeAnalysis!),
                          ],
                        ),
                      ),
                    ),
                ],

                // Empty State
                if (!viewModel.isLoading && viewModel.insights == null && viewModel.error == null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.psychology, color: Colors.grey[600], size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'No AI Insights Available',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add some expenses to get AI-powered insights and recommendations',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildPredictionsList(Map<String, dynamic> predictions) {
    final predictionsList = predictions['predictions'] as List<dynamic>? ?? [];

    if (predictionsList.isEmpty) {
      return [
        Text(
          'No predictions available yet. Add more expense data for better predictions.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ];
    }

    return predictionsList.take(3).map((prediction) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.blue[600], size: 20),
            const SizedBox(width: 8),
            Text(
              '${prediction['month']}: Tsh ${prediction['predicted_amount']}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildAnomaliesList(Map<String, dynamic> anomalies) {
    final anomaliesList = anomalies['anomalies'] as List<dynamic>? ?? [];

    if (anomaliesList.isEmpty) {
      return [
        Text(
          'No unusual spending patterns detected. Your expenses look normal!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ];
    }

    return anomaliesList.take(3).map((anomaly) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning, color: Colors.orange[600], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${anomaly['category']} - ${anomaly['date']}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Unusual amount: Tsh ${anomaly['amount']} (${anomaly['deviation_percentage']}% deviation)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildComparativeList(Map<String, dynamic> comparison) {
    final categoryComparison = comparison['category_comparison'] as List<dynamic>? ?? [];

    if (categoryComparison.isEmpty) {
      return [
        Text(
          'No comparison data available. Add expenses in different time periods to see comparisons.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ];
    }

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          'Comparing ${comparison['period1']} vs ${comparison['period2']}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      ...categoryComparison.take(3).map((category) {
        final change = category['change_percentage'];
        final isPositive = change > 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.category, color: Colors.teal[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category['category_name'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isPositive ? Colors.red[600] : Colors.green[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ];
  }

  Color _getTrendColor(String direction) {
    switch (direction) {
      case 'increasing':
        return Colors.red;
      case 'decreasing':
        return Colors.green;
      case 'stable':
      default:
        return Colors.blue;
    }
  }

  IconData _getTrendIcon(String direction) {
    switch (direction) {
      case 'increasing':
        return Icons.trending_up;
      case 'decreasing':
        return Icons.trending_down;
      case 'stable':
      default:
        return Icons.trending_flat;
    }
  }

  String _formatTrendDirection(String direction) {
    return direction.replaceAll('_', ' ').toUpperCase();
  }
}