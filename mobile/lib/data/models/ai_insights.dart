import 'package:equatable/equatable.dart';

class AIInsights extends Equatable {
  final String timeframe;
  final DateTimeRange dateRange;
  final double totalExpenses;
  final int expenseCount;
  final String insights;
  final List<String> suggestions;
  final TrendData trends;

  const AIInsights({
    required this.timeframe,
    required this.dateRange,
    required this.totalExpenses,
    required this.expenseCount,
    required this.insights,
    required this.suggestions,
    required this.trends,
  });

  factory AIInsights.fromJson(Map<String, dynamic> json) {
    return AIInsights(
      timeframe: json['timeframe'] ?? 'month',
      dateRange: DateTimeRange(
        start: DateTime.parse(json['date_range']['start']),
        end: DateTime.parse(json['date_range']['end']),
      ),
      totalExpenses: double.parse(json['total_expenses'].toString()),
      expenseCount: json['expense_count'] ?? 0,
      insights: json['insights'] ?? '',
      suggestions: json['suggestions'] != null
          ? List<String>.from(json['suggestions'])
          : [],
      trends: TrendData.fromJson(json['trends'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeframe': timeframe,
      'date_range': {
        'start': dateRange.start.toIso8601String(),
        'end': dateRange.end.toIso8601String(),
      },
      'total_expenses': totalExpenses,
      'expense_count': expenseCount,
      'insights': insights,
      'suggestions': suggestions,
      'trends': trends.toJson(),
    };
  }

  @override
  List<Object?> get props => [timeframe, dateRange, totalExpenses, expenseCount, insights, suggestions, trends];
}

class TrendData extends Equatable {
  final String direction;
  final String consistency;

  const TrendData({
    required this.direction,
    required this.consistency,
  });

  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      direction: json['direction'] ?? 'stable',
      consistency: json['consistency'] ?? 'moderate',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'direction': direction,
      'consistency': consistency,
    };
  }

  @override
  List<Object?> get props => [direction, consistency];
}

class DateTimeRange extends Equatable {
  final DateTime start;
  final DateTime end;

  const DateTimeRange({
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [start, end];
}