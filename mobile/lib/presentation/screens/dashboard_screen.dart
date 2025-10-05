import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_mobile/presentation/screens/expense_form_screen.dart';
import 'package:expense_tracker_mobile/presentation/screens/expenses_list_screen.dart';
import 'package:expense_tracker_mobile/presentation/screens/ai_insights_screen.dart';
import 'package:expense_tracker_mobile/presentation/screens/categories_screen.dart';
import 'package:expense_tracker_mobile/presentation/screens/budgets_screen.dart';
import 'package:expense_tracker_mobile/presentation/providers/auth_provider.dart';
import 'package:expense_tracker_mobile/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:expense_tracker_mobile/presentation/widgets/statistics_card.dart';
import 'package:expense_tracker_mobile/presentation/widgets/expense_pie_chart.dart';
import 'package:expense_tracker_mobile/presentation/widgets/expense_line_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeTab(
        onNavigateToExpenses: () => setState(() => _currentIndex = 1),
        onNavigateToAIInsights: () => setState(() => _currentIndex = 2),
        onNavigateToCategories: () => setState(() => _currentIndex = 3),
        onNavigateToBudgets: () => setState(() => _currentIndex = 4),
      ),
      const ExpensesListScreen(),
      const AIInsightsScreen(),
      const CategoriesScreen(),
      const BudgetsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ExpenseFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ) : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'AI Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budgets',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  final VoidCallback onNavigateToExpenses;
  final VoidCallback onNavigateToAIInsights;
  final VoidCallback onNavigateToCategories;
  final VoidCallback onNavigateToBudgets;

  const HomeTab({
    super.key,
    required this.onNavigateToExpenses,
    required this.onNavigateToAIInsights,
    required this.onNavigateToCategories,
    required this.onNavigateToBudgets,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dashboardViewModel = context.watch<DashboardViewModel>();

    // Load dashboard data when widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!dashboardViewModel.isLoading && dashboardViewModel.statistics == null) {
        dashboardViewModel.loadDashboardData();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            authProvider.user?.name.substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back!',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                authProvider.user?.name ?? 'User',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.add,
                    title: 'Add Expense',
                    color: Colors.green,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ExpenseFormScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.list,
                    title: 'View Expenses',
                    color: Colors.blue,
                    onTap: onNavigateToExpenses,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.insights,
                    title: 'AI Insights',
                    color: Colors.purple,
                    onTap: onNavigateToAIInsights,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.category,
                    title: 'Categories',
                    color: Colors.orange,
                    onTap: onNavigateToCategories,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.account_balance_wallet,
                    title: 'Budgets',
                    color: Colors.purple,
                    onTap: onNavigateToBudgets,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: SizedBox.shrink(), // Empty space for layout
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Statistics Cards
            if (dashboardViewModel.statistics != null) ...[
              StatisticsGrid(
                statistics: dashboardViewModel.statistics!,
                budgetStatistics: dashboardViewModel.budgetStatistics,
              ),
              const SizedBox(height: 24),
            ],

            // Charts Section
            Text(
              'Analytics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Category Breakdown Chart
            if (dashboardViewModel.categoryBreakdown.isNotEmpty) ...[
              ExpensePieChart(
                categoryData: dashboardViewModel.categoryBreakdown,
                totalAmount: dashboardViewModel.totalExpenses,
              ),
              const SizedBox(height: 24),
            ],

            // Monthly Trend Chart
            if (dashboardViewModel.monthlyTrend.isNotEmpty) ...[
              ExpenseLineChart(
                monthlyData: dashboardViewModel.monthlyTrend,
              ),
              const SizedBox(height: 24),
            ],

            // Loading State for Charts
            if (dashboardViewModel.isLoadingBreakdown || dashboardViewModel.isLoadingTrend)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            // Error State
            if (dashboardViewModel.error != null && dashboardViewModel.statistics == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.error, color: Colors.red[600]),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load dashboard data',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.red[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dashboardViewModel.error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          dashboardViewModel.refreshDashboard();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),

            // Empty State
            if (!dashboardViewModel.isLoading &&
                dashboardViewModel.statistics == null &&
                dashboardViewModel.error == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.analytics, color: Colors.grey[600], size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'No Data Available',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add some expenses to see your analytics and insights',
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
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}