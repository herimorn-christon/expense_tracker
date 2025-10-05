import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_mobile/data/models/budget.dart';
import 'package:expense_tracker_mobile/presentation/providers/auth_provider.dart';
import 'package:expense_tracker_mobile/presentation/viewmodels/budget_viewmodel.dart';
import 'package:expense_tracker_mobile/presentation/viewmodels/category_viewmodel.dart';

// Use the Category class from budget.dart to avoid conflicts
typedef BudgetCategory = Category;

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetViewModel>().loadBudgets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Management'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              _showAnalyticsDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showBudgetDialog();
            },
          ),
        ],
      ),
      body: Consumer<BudgetViewModel>(
        builder: (context, viewModel, child) {
          return RefreshIndicator(
            onRefresh: () => viewModel.refreshBudgets(),
            child: viewModel.budgets.isEmpty && viewModel.isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : viewModel.budgets.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: viewModel.budgets.length,
                        itemBuilder: (context, index) {
                          final budget = viewModel.budgets[index];
                          return BudgetCard(
                            budget: budget,
                            onDelete: () {
                              _showDeleteConfirmation(budget);
                            },
                          );
                        },
                      ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Budgets',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first budget to start tracking your expenses',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _showBudgetDialog();
            },
            child: const Text('Create Budget'),
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => const BudgetDialog(),
    );
  }

  void _showDeleteConfirmation(Budget budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('Are you sure you want to delete the budget for "${budget.category?.name ?? 'All Categories'}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteBudget(budget);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => const BudgetAnalyticsDialog(),
    );
  }

  Future<void> _deleteBudget(Budget budget) async {
    final viewModel = context.read<BudgetViewModel>();
    final success = await viewModel.deleteBudget(budget.id);

    if (success && mounted) {
      // Refresh the budgets list to remove the deleted budget
      context.read<BudgetViewModel>().refreshBudgets();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Budget for "${budget.category?.name ?? 'All Categories'}" deleted successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete budget. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

class BudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback onDelete;

  const BudgetCard({
    super.key,
    required this.budget,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final budgetViewModel = context.watch<BudgetViewModel>();
    final progressColor = budgetViewModel.getBudgetProgressColor(budget);
    final statusText = budgetViewModel.getBudgetStatusText(budget);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.category?.name ?? 'All Categories',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${budget.period[0].toUpperCase()}${budget.period.substring(1)} Budget',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(budget.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(budget.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: _getStatusColor(budget.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tsh ${budget.spent.toStringAsFixed(0)} / Tsh ${budget.amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${budget.utilizationPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: progressColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (budget.utilizationPercentage / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Tsh ${budget.remaining.toStringAsFixed(0)} remaining',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'exceeded':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'active':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class BudgetDialog extends StatefulWidget {
  const BudgetDialog({super.key});

  @override
  State<BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<BudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _alertThresholdController = TextEditingController();
  String _selectedPeriod = 'monthly';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  BudgetCategory? _selectedCategory; // Use Category object like in ExpenseFormScreen
  bool _autoAdjust = false;

  @override
  void initState() {
    super.initState();
    // Set default values for new budget creation
    _alertThresholdController.text = '80';
  }



  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _alertThresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Budget',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Amount
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Budget Amount (Tsh) *',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter budget amount';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Category Selection - Using same pattern as ExpenseFormScreen
                Consumer<CategoryViewModel>(
                  builder: (context, categoryViewModel, child) {
                    // Load categories if not already loaded
                    if (categoryViewModel.categories.isEmpty && !categoryViewModel.isLoading) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        categoryViewModel.loadCategories();
                      });
                    }

                    if (categoryViewModel.isLoading) {
                      return const TextField(
                        decoration: InputDecoration(
                          labelText: 'Category (Optional)',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        enabled: false,
                      );
                    }

                    // Convert to BudgetCategory objects for consistency
                    final budgetCategories = categoryViewModel.categories.map((category) => BudgetCategory(
                      id: category.id,
                      name: category.name,
                      color: category.color ?? '#6B7280',
                      userId: category.userId,
                      createdAt: category.createdAt ?? DateTime.now(),
                      updatedAt: category.updatedAt ?? DateTime.now(),
                    )).toList();

                    // Find the selected category from the loaded categories
                    BudgetCategory? selectedCategoryValue;
                    if (_selectedCategory != null) {
                      try {
                        selectedCategoryValue = budgetCategories.firstWhere(
                          (cat) => cat.id == _selectedCategory!.id,
                        );
                      } catch (e) {
                        selectedCategoryValue = null; // Category not found in loaded list
                      }
                    }

                    return DropdownButtonFormField<BudgetCategory?>(
                      value: selectedCategoryValue,
                      decoration: const InputDecoration(
                        labelText: 'Category (Optional)',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<BudgetCategory?>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...budgetCategories.map((category) {
                          return DropdownMenuItem<BudgetCategory?>(
                            value: category,
                            child: Text(category.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Period
                DropdownButtonFormField<String>(
                  value: _selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Budget Period *',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriod = value!;
                      _calculateEndDate();
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select budget period';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Start Date
                InkWell(
                  onTap: () => _selectDate(context, true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date *',
                      prefixIcon: Icon(Icons.date_range),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _startDate.toString().split(' ')[0],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // End Date
                InkWell(
                  onTap: () => _selectDate(context, false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date *',
                      prefixIcon: Icon(Icons.date_range),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _endDate.toString().split(' ')[0],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Alert Threshold
                TextFormField(
                  controller: _alertThresholdController,
                  decoration: const InputDecoration(
                    labelText: 'Alert Threshold (%) *',
                    prefixIcon: Icon(Icons.warning),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter alert threshold';
                    }
                    final threshold = double.tryParse(value);
                    if (threshold == null || threshold < 0 || threshold > 100) {
                      return 'Please enter a valid percentage (0-100)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 16),

                // Auto Adjust
                SwitchListTile(
                  title: const Text('Enable AI Auto-Adjustment'),
                  subtitle: const Text('Automatically adjust budget based on spending patterns'),
                  value: _autoAdjust,
                  onChanged: (value) {
                    setState(() {
                      _autoAdjust = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Consumer<BudgetViewModel>(
                        builder: (context, viewModel, child) {
                          return ElevatedButton(
                            onPressed: viewModel.isLoading ? null : _submitBudget,
                            child: viewModel.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Create'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _calculateEndDate() {
    switch (_selectedPeriod) {
      case 'weekly':
        _endDate = _startDate.add(const Duration(days: 7));
        break;
      case 'monthly':
        _endDate = DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
        break;
      case 'quarterly':
        _endDate = DateTime(_startDate.year, _startDate.month + 3, _startDate.day);
        break;
      case 'yearly':
        _endDate = DateTime(_startDate.year + 1, _startDate.month, _startDate.day);
        break;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _calculateEndDate();
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final viewModel = context.read<BudgetViewModel>();
    final authProvider = context.read<AuthProvider>();

    final budget = Budget(
      id: 0, // Will be set by the API
      userId: authProvider.user!.id,
      categoryId: _selectedCategory?.id,
      amount: double.parse(_amountController.text),
      period: _selectedPeriod,
      startDate: _startDate,
      endDate: _endDate,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isActive: true,
      autoAdjust: _autoAdjust,
      alertThreshold: double.parse(_alertThresholdController.text),
      metadata: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      spent: 0.0,
      remaining: 0.0,
      utilizationPercentage: 0.0,
      status: 'unused',
      shouldAlert: false,
    );

    final success = await viewModel.createBudget(budget);

    if (success && mounted) {
      Navigator.of(context).pop();
      // Refresh the budgets list to show the new budget
      context.read<BudgetViewModel>().refreshBudgets();
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget created successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create budget. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

class BudgetAnalyticsDialog extends StatelessWidget {
  const BudgetAnalyticsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Budget Analytics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Consumer<BudgetViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.analytics == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final analytics = viewModel.analytics!;
                return Column(
                  children: [
                    _AnalyticsCard(
                      title: 'Total Budgets',
                      value: analytics['total_budgets']?.toString() ?? '0',
                      icon: Icons.account_balance_wallet,
                    ),
                    const SizedBox(height: 12),
                    _AnalyticsCard(
                      title: 'Active Budgets',
                      value: analytics['active_budgets']?.toString() ?? '0',
                      icon: Icons.check_circle,
                    ),
                    const SizedBox(height: 12),
                    _AnalyticsCard(
                      title: 'Over Budget',
                      value: analytics['over_budget']?.toString() ?? '0',
                      icon: Icons.warning,
                      color: Colors.red,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: color ?? Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}