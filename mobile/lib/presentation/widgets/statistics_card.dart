import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatisticsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatisticsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StatisticsGrid extends StatelessWidget {
  final Map<String, dynamic> statistics;
  final Map<String, dynamic>? budgetStatistics;

  const StatisticsGrid({
    super.key,
    required this.statistics,
    this.budgetStatistics,
  });

  @override
  Widget build(BuildContext context) {
    final totalExpenses = double.parse(statistics['total_expenses'].toString());
    final expenseCount = statistics['expense_count'] ?? 0;

    // Budget information
    final totalBudgets = budgetStatistics?['total_budgets'] ?? 0;
    final activeBudgets = budgetStatistics?['active_budgets'] ?? 0;
    final avgBudgetUtilization = budgetStatistics?['avg_utilization_percentage'] ?? 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatisticsCard(
                title: 'Total Expenses',
                value: 'Tsh ${NumberFormat('#,###').format(totalExpenses)}',
                subtitle: 'This month',
                icon: Icons.account_balance_wallet,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatisticsCard(
                title: 'Budget Utilization',
                value: '${avgBudgetUtilization.toStringAsFixed(1)}%',
                subtitle: 'Average usage',
                icon: Icons.pie_chart,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatisticsCard(
                title: 'Active Budgets',
                value: NumberFormat('#,###').format(activeBudgets),
                subtitle: 'Total budgets',
                icon: Icons.account_balance_wallet,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatisticsCard(
                title: 'Categories',
                value: _getCategoryCount().toString(),
                subtitle: 'Active categories',
                icon: Icons.category,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _getCategoryCount() {
    final expensesByCategory = statistics['expenses_by_category'] as List<dynamic>? ?? [];
    return expensesByCategory.length;
  }
}