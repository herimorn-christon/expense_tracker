import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker_mobile/data/models/expense.dart';
import 'package:expense_tracker_mobile/data/models/category.dart';
import 'package:expense_tracker_mobile/presentation/viewmodels/expense_list_viewmodel.dart';
import 'package:expense_tracker_mobile/presentation/screens/expense_form_screen.dart';

class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  State<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends State<ExpensesListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseListViewModel>().loadExpenses();
      context.read<ExpenseListViewModel>().loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ExpenseFormScreen(),
            ),
          ).then((_) {
            // Refresh expenses list when returning from add screen
            context.read<ExpenseListViewModel>().refreshExpenses();
          });
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<ExpenseListViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search expenses...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              viewModel.setSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                      fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    viewModel.setSearchQuery(value);
                  },
                ),
              ),

              // Filter Summary
              if (viewModel.selectedCategory != null ||
                  viewModel.selectedPaymentMethod != null ||
                  viewModel.dateRange != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getFilterSummary(viewModel),
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          viewModel.clearFilters();
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),

              // Loading State
              if (viewModel.isLoading && viewModel.expenses.isEmpty)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )

              // Error State
              else if (viewModel.error != null && viewModel.expenses.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading expenses',
                          style: Theme.of(context).textTheme.titleLarge,
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
                            viewModel.refreshExpenses();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )

              // Empty State
              else if (viewModel.filteredExpenses.isEmpty && !viewModel.isLoading)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No expenses found',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getEmptyStateMessage(viewModel),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ExpenseFormScreen(),
                              ),
                            ).then((_) {
                              // Refresh expenses list when returning from add screen
                              context.read<ExpenseListViewModel>().refreshExpenses();
                            });
                          },
                          child: const Text('Add Expense'),
                        ),
                      ],
                    ),
                  ),
                )

              // Expense List
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => viewModel.refreshExpenses(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: viewModel.filteredExpenses.length + (viewModel.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == viewModel.filteredExpenses.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final expense = viewModel.filteredExpenses[index];
                        return ExpenseCard(
                          expense: expense,
                          onTap: () {
                            _navigateToExpenseEdit(expense);
                          },
                          onEdit: () {
                            _navigateToExpenseEdit(expense);
                          },
                          onDelete: () {
                            _showDeleteConfirmation(expense);
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _getFilterSummary(ExpenseListViewModel viewModel) {
    final filters = <String>[];

    if (viewModel.selectedCategory != null) {
      filters.add('Category: ${viewModel.selectedCategory!.name}');
    }

    if (viewModel.selectedPaymentMethod != null) {
      filters.add('Payment: ${_formatPaymentMethod(viewModel.selectedPaymentMethod!)}');
    }

    if (viewModel.dateRange != null) {
      filters.add('Date: ${_formatDateRange(viewModel.dateRange!)}');
    }

    return filters.isNotEmpty ? filters.join(', ') : 'Filters applied';
  }

  String _getEmptyStateMessage(ExpenseListViewModel viewModel) {
    if (viewModel.searchQuery.isNotEmpty) {
      return 'No expenses match your search "${viewModel.searchQuery}"';
    }

    if (viewModel.selectedCategory != null ||
        viewModel.selectedPaymentMethod != null ||
        viewModel.dateRange != null) {
      return 'No expenses match the selected filters';
    }

    return 'Start by adding your first expense';
  }

  String _formatPaymentMethod(String method) {
    return method.replaceAll('_', ' ').toUpperCase();
  }

  String _formatDateRange(DateTimeRange range) {
    final formatter = DateFormat('MMM dd');
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => const ExpenseFilterDialog(),
    );
  }

  void _navigateToExpenseEdit(Expense expense) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExpenseFormScreen(expense: expense),
      ),
    ).then((_) {
      // Refresh expenses list when returning from edit screen
      context.read<ExpenseListViewModel>().refreshExpenses();
    });
  }

  void _showDeleteConfirmation(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ExpenseListViewModel>().deleteExpense(expense.id);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expense.categoryName ?? 'Unknown Category',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Tsh ${NumberFormat('#,###').format(expense.amount)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(expense.expenseDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (expense.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  expense.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPaymentMethodColor(expense.paymentMethod).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getPaymentMethodColor(expense.paymentMethod),
                      ),
                    ),
                    child: Text(
                      _formatPaymentMethod(expense.paymentMethod),
                      style: TextStyle(
                        color: _getPaymentMethodColor(expense.paymentMethod),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPaymentMethodColor(String method) {
    switch (method) {
      case 'cash':
        return Colors.green;
      case 'card':
        return Colors.blue;
      case 'bank_transfer':
        return Colors.purple;
      case 'mobile_money':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatPaymentMethod(String method) {
    return method.replaceAll('_', ' ').toUpperCase();
  }
}

class ExpenseFilterDialog extends StatefulWidget {
  const ExpenseFilterDialog({super.key});

  @override
  State<ExpenseFilterDialog> createState() => _ExpenseFilterDialogState();
}

class _ExpenseFilterDialogState extends State<ExpenseFilterDialog> {
  Category? _tempSelectedCategory;
  String? _tempSelectedPaymentMethod;
  DateTimeRange? _tempDateRange;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<ExpenseListViewModel>();
    _tempSelectedCategory = viewModel.selectedCategory;
    _tempSelectedPaymentMethod = viewModel.selectedPaymentMethod;
    _tempDateRange = viewModel.dateRange;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExpenseListViewModel>();

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filter Expenses',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Category Filter
            DropdownButtonFormField<Category>(
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              value: _tempSelectedCategory,
              items: [
                const DropdownMenuItem<Category>(
                  value: null,
                  child: Text('All Categories'),
                ),
                ...viewModel.categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _tempSelectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Payment Method Filter
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              value: _tempSelectedPaymentMethod,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Payment Methods'),
                ),
                ...['cash', 'card', 'bank_transfer', 'mobile_money'].map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(_formatPaymentMethod(method)),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _tempSelectedPaymentMethod = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Date Range Filter
            InkWell(
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );

                if (picked != null) {
                  setState(() {
                    _tempDateRange = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range),
                    const SizedBox(width: 12),
                    Text(
                      _tempDateRange != null
                          ? '${DateFormat('MMM dd').format(_tempDateRange!.start)} - ${DateFormat('MMM dd').format(_tempDateRange!.end)}'
                          : 'Select Date Range',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      viewModel.clearFilters();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      viewModel.setCategoryFilter(_tempSelectedCategory);
                      viewModel.setPaymentMethodFilter(_tempSelectedPaymentMethod);
                      viewModel.setDateRangeFilter(_tempDateRange);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPaymentMethod(String method) {
    return method.replaceAll('_', ' ').toUpperCase();
  }
}