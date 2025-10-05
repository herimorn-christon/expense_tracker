import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final int id;
  final int userId;
  final int categoryId;
  final String title;
  final String? description;
  final double amount;
  final DateTime expenseDate;
  final String? receiptPath;
  final String paymentMethod;
  final String? location;
  final List<String>? tags;
  final bool isRecurring;
  final String? recurrenceType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Related data
  final String? categoryName;
  final String? categoryColor;

  const Expense({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    this.description,
    required this.amount,
    required this.expenseDate,
    this.receiptPath,
    required this.paymentMethod,
    this.location,
    this.tags,
    this.isRecurring = false,
    this.recurrenceType,
    this.createdAt,
    this.updatedAt,
    this.categoryName,
    this.categoryColor,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      title: json['title'],
      description: json['description'],
      amount: double.parse(json['amount'].toString()),
      expenseDate: DateTime.parse(json['expense_date']),
      receiptPath: json['receipt_path'],
      paymentMethod: json['payment_method'] ?? 'cash',
      location: json['location'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isRecurring: json['is_recurring'] ?? false,
      recurrenceType: json['recurrence_type'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      categoryName: json['category']?['name'],
      categoryColor: json['category']?['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String(),
      'receipt_path': receiptPath,
      'payment_method': paymentMethod,
      'location': location,
      'tags': tags,
      'is_recurring': isRecurring,
      'recurrence_type': recurrenceType,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Expense copyWith({
    int? id,
    int? userId,
    int? categoryId,
    String? title,
    String? description,
    double? amount,
    DateTime? expenseDate,
    String? receiptPath,
    String? paymentMethod,
    String? location,
    List<String>? tags,
    bool? isRecurring,
    String? recurrenceType,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? categoryColor,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      receiptPath: receiptPath ?? this.receiptPath,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }

  @override
  List<Object?> get props => [
    id, userId, categoryId, title, description, amount, expenseDate,
    receiptPath, paymentMethod, location, tags, isRecurring,
    recurrenceType, createdAt, updatedAt, categoryName, categoryColor
  ];
}