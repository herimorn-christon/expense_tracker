import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker_mobile/data/models/category.dart';

class ExpensePieChart extends StatelessWidget {
  final List<Map<String, dynamic>> categoryData;
  final double totalAmount;

  const ExpensePieChart({
    super.key,
    required this.categoryData,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No expense data available'),
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
            'Expenses by Category',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: _buildPieSections(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                centerSpaceColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    return categoryData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final percentage = totalAmount > 0 ? (data['total'] / totalAmount) * 100 : 0;

      return PieChartSectionData(
        value: data['total'],
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        color: _colorFromHex(data['category_color'] ?? '#6B7280'),
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: categoryData.take(4).map((data) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _colorFromHex(data['category_color'] ?? '#6B7280'),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              data['category_name'] ?? 'Unknown',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _colorFromHex(String hexColor) {
    hexColor = hexColor.replaceFirst('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor'; // Add alpha if not present
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}