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
        onNavigateToExpenses: () => _navigateToTab(1),
        onNavigateToAIInsights: () => _navigateToTab(2),
        onNavigateToCategories: () => _navigateToTab(3),
        onNavigateToBudgets: () => _navigateToTab(4),
      ),
      const ExpensesListScreen(),
      const AIInsightsScreen(),
      const CategoriesScreen(),
      const BudgetsScreen(),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for auth changes and refresh dashboard data
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.user != null) {
      // User is logged in, ensure dashboard data is loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final dashboardViewModel = context.read<DashboardViewModel>();
        if (dashboardViewModel.statistics == null && !dashboardViewModel.isLoading) {
          dashboardViewModel.loadDashboardData();
        }
      });
    }
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Refresh dashboard data when navigating to dashboard tab (with throttling)
    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final dashboardViewModel = context.read<DashboardViewModel>();
        // Only refresh if not already loading (ViewModel handles throttling)
        if (!dashboardViewModel.isLoading && !dashboardViewModel.isLoadingTrend && !dashboardViewModel.isLoadingBreakdown) {
          dashboardViewModel.refreshDashboard();
        }
      });
    }
  }

  void _refreshDashboardData() {
    final dashboardViewModel = context.read<DashboardViewModel>();
    dashboardViewModel.refreshDashboard();
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
        onTap: _onTabChanged,
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

class HomeTab extends StatefulWidget {
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
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int? _currentUserId;
  bool _isRefreshing = false;

  void _checkUserChange(AuthProvider authProvider, DashboardViewModel dashboardViewModel) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = authProvider.user?.id;

      if (authProvider.user == null) {
        // User is not logged in, clear dashboard data
        dashboardViewModel.clearDashboardData();
        _currentUserId = null;
      } else if (_currentUserId != currentUserId && !_isRefreshing) {
        // User has changed, clear old data and load new data (with throttling)
        print('User changed from $_currentUserId to $currentUserId, refreshing dashboard data');
        setState(() {
          _isRefreshing = true;
        });
        dashboardViewModel.clearDashboardData();
        dashboardViewModel.loadDashboardData().then((_) {
          setState(() {
            _isRefreshing = false;
          });
        });
        _currentUserId = currentUserId;
      } else if (!_isRefreshing && !dashboardViewModel.isLoading && dashboardViewModel.statistics == null) {
        // Same user but no data loaded, load dashboard data
        dashboardViewModel.loadDashboardData();
      }
    });
  }

  Future<void> _refreshDashboardData() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes

    setState(() {
      _isRefreshing = true;
    });

    try {
      final dashboardViewModel = context.read<DashboardViewModel>();
      await dashboardViewModel.refreshDashboard();

      // Small delay to ensure data is loaded
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dashboardViewModel = context.watch<DashboardViewModel>();

    // Check if user has changed and refresh data accordingly
    _checkUserChange(authProvider, dashboardViewModel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        elevation: 0,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : () {
              _refreshDashboardData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshDashboardData();
        },
        child: SingleChildScrollView(
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
                    onTap: widget.onNavigateToExpenses,
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
                    onTap: widget.onNavigateToAIInsights,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.category,
                    title: 'Categories',
                    color: Colors.orange,
                    onTap: widget.onNavigateToCategories,
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
                    onTap: widget.onNavigateToBudgets,
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