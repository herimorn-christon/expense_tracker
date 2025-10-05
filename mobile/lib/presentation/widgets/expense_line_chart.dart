import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ExpenseLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;

  const ExpenseLineChart({
    super.key,
    required this.monthlyData,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No trend data available'),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Expense Trend',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              _buildLineChartData(),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData() {
    // Sort data by month
    final sortedData = List<Map<String, dynamic>>.from(monthlyData);
    sortedData.sort((a, b) => a['month'].compareTo(b['month']));

    final spots = sortedData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return FlSpot(
        index.toDouble(),
        double.parse(data['total'].toString()),
      );
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: _calculateHorizontalInterval(),
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < sortedData.length) {
                final monthData = sortedData[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formatMonth(monthData['month']),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: _calculateHorizontalInterval(),
            getTitlesWidget: (value, meta) {
              return Text(
                _formatAmount(value),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300),
      ),
      minX: 0,
      maxX: (sortedData.length - 1).toDouble(),
      minY: 0,
      maxY: _calculateMaxY(),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: Colors.blue,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  double _calculateHorizontalInterval() {
    if (monthlyData.isEmpty) return 1000;

    final amounts = monthlyData.map((data) => double.parse(data['total'].toString())).toList();
    final maxAmount = amounts.reduce((a, b) => a > b ? a : b);

    if (maxAmount < 1000) return 200;
    if (maxAmount < 10000) return 2000;
    if (maxAmount < 100000) return 20000;
    return 50000;
  }

  double _calculateMaxY() {
    if (monthlyData.isEmpty) return 1000;

    final amounts = monthlyData.map((data) => double.parse(data['total'].toString())).toList();
    final maxAmount = amounts.reduce((a, b) => a > b ? a : b);

    // Add 20% padding to the top
    return maxAmount * 1.2;
  }

  String _formatMonth(String monthStr) {
    try {
      final date = DateTime.parse('$monthStr-01');
      return DateFormat('MMM').format(date);
    } catch (e) {
      return monthStr;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}