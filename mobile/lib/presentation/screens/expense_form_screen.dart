import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker_mobile/data/models/expense.dart';
import 'package:expense_tracker_mobile/data/models/category.dart';
import 'package:expense_tracker_mobile/presentation/viewmodels/expense_form_viewmodel.dart';
import 'package:expense_tracker_mobile/presentation/providers/auth_provider.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;

  const ExpenseFormScreen({
    super.key,
    this.expense,
  });

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _locationController = TextEditingController();

  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = 'cash';
  String? _receiptImagePath;
  bool _isRecurring = false;
  String _recurrenceType = 'monthly';

  final List<String> _paymentMethods = ['cash', 'card', 'bank_transfer', 'mobile_money'];
  final List<String> _recurrenceTypes = ['daily', 'weekly', 'monthly', 'yearly'];

  @override
  void initState() {
    super.initState();

    // If editing existing expense, populate form fields
    if (widget.expense != null) {
      _titleController.text = widget.expense!.title;
      _descriptionController.text = widget.expense!.description ?? '';
      _amountController.text = widget.expense!.amount.toStringAsFixed(0);
      _locationController.text = widget.expense!.location ?? '';
      _selectedDate = widget.expense!.expenseDate;
      _paymentMethod = widget.expense!.paymentMethod;
      _isRecurring = widget.expense!.isRecurring;
      _recurrenceType = widget.expense!.recurrenceType ?? 'monthly';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseFormViewModel>().loadCategories();
      // Set selected category after categories are loaded
      _loadSelectedCategory();
    });
  }

  Future<void> _loadSelectedCategory() async {
    if (widget.expense != null) {
      final viewModel = context.read<ExpenseFormViewModel>();
      await viewModel.loadCategories();

      // Find the category that matches the expense's categoryId
      for (var category in viewModel.categories) {
        if (category.id == widget.expense!.categoryId) {
          setState(() {
            _selectedCategory = category;
          });
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense != null ? 'Edit Expense' : 'Add Expense'),
        elevation: 0,
      ),
      body: Consumer<ExpenseFormViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoadingCategories) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title Field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Expense Title *',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter expense title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (Tsh) *',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _AmountInputFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        final amount = double.tryParse(value.replaceAll(',', ''));
                        if (amount == null || amount <= 0) {
                          return 'Please enter valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<Category>(
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCategory,
                      items: viewModel.categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Method
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        prefixIcon: Icon(Icons.payment),
                        border: OutlineInputBorder(),
                      ),
                      value: _paymentMethod,
                      items: _paymentMethods.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(_formatPaymentMethod(method)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Location Field
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location (Optional)',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Receipt Upload
                    InkWell(
                      onTap: _pickReceiptImage,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.camera_alt),
                            const SizedBox(width: 12),
                            Text(
                              _receiptImagePath != null
                                  ? 'Receipt Selected'
                                  : 'Add Receipt (Optional)',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            if (_receiptImagePath != null)
                              const Icon(Icons.check_circle, color: Colors.green),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recurring Expense Toggle
                    SwitchListTile(
                      title: const Text('Recurring Expense'),
                      subtitle: const Text('Automatically repeat this expense'),
                      value: _isRecurring,
                      onChanged: (value) {
                        setState(() {
                          _isRecurring = value;
                        });
                      },
                    ),

                    // Recurrence Type (if recurring)
                    if (_isRecurring) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Recurrence Frequency',
                          prefixIcon: Icon(Icons.repeat),
                          border: OutlineInputBorder(),
                        ),
                        value: _recurrenceType,
                        items: _recurrenceTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_formatRecurrenceType(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _recurrenceType = value!;
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Error Message
                    if (viewModel.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          viewModel.error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),

                    // Submit Button
                    ElevatedButton(
                      onPressed: viewModel.isLoading ? null : _submitExpense,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: viewModel.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Expense',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickReceiptImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _receiptImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final viewModel = context.read<ExpenseFormViewModel>();

    final amount = double.parse(_amountController.text.replaceAll(',', ''));

    final expense = Expense(
      id: widget.expense?.id ?? 0, // Use existing ID if editing
      userId: authProvider.user!.id,
      categoryId: _selectedCategory!.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      amount: amount,
      expenseDate: _selectedDate,
      paymentMethod: _paymentMethod,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      isRecurring: _isRecurring,
      recurrenceType: _isRecurring ? _recurrenceType : null,
    );

    bool success;
    if (widget.expense != null) {
      // Update existing expense
      success = await viewModel.updateExpense(widget.expense!.id, expense, receiptPath: _receiptImagePath);
    } else {
      // Create new expense
      success = await viewModel.createExpense(expense, receiptPath: _receiptImagePath);
    }

    if (success && mounted) {
      Navigator.of(context).pop(); // Go back to previous screen
    }
  }

  String _formatPaymentMethod(String method) {
    return method.replaceAll('_', ' ').toUpperCase();
  }

  String _formatRecurrenceType(String type) {
    switch (type) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      default:
        return type;
    }
  }
}

// Custom formatter for amount input
class _AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final numericValue = newValue.text.replaceAll(',', '');
    if (numericValue.length > 10) {
      return oldValue;
    }

    final formatter = NumberFormat('#,###');
    final formattedValue = formatter.format(int.tryParse(numericValue) ?? 0);

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}