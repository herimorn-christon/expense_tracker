import 'package:equatable/equatable.dart';

class Budget extends Equatable {
  final int id;
  final int userId;
  final int? categoryId;
  final double amount;
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final bool isActive;
  final bool autoAdjust;
  final double alertThreshold;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Category? category;
  final double spent;
  final double remaining;
  final double utilizationPercentage;
  final String status;
  final bool shouldAlert;

  const Budget({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.amount,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.description,
    required this.isActive,
    required this.autoAdjust,
    required this.alertThreshold,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    required this.spent,
    required this.remaining,
    required this.utilizationPercentage,
    required this.status,
    required this.shouldAlert,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      amount: double.parse(json['amount'].toString()),
      period: json['period'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      description: json['description'],
      isActive: json['is_active'] ?? true,
      autoAdjust: json['auto_adjust'] ?? false,
      alertThreshold: double.parse(json['alert_threshold'].toString()),
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      spent: double.parse(json['spent'].toString()),
      remaining: double.parse(json['remaining'].toString()),
      utilizationPercentage: json['utilization_percentage'] is int
          ? (json['utilization_percentage'] as int).toDouble()
          : double.parse(json['utilization_percentage'].toString()),
      status: json['status'] ?? 'unused',
      shouldAlert: json['should_alert'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'period': period,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'description': description,
      'is_active': isActive,
      'auto_adjust': autoAdjust,
      'alert_threshold': alertThreshold,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'category': category?.toJson(),
      'spent': spent,
      'remaining': remaining,
      'utilization_percentage': utilizationPercentage,
      'status': status,
      'should_alert': shouldAlert,
    };
  }

  Budget copyWith({
    int? id,
    int? userId,
    int? categoryId,
    double? amount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    bool? isActive,
    bool? autoAdjust,
    double? alertThreshold,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    Category? category,
    double? spent,
    double? remaining,
    double? utilizationPercentage,
    String? status,
    bool? shouldAlert,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      autoAdjust: autoAdjust ?? this.autoAdjust,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      spent: spent ?? this.spent,
      remaining: remaining ?? this.remaining,
      utilizationPercentage: utilizationPercentage ?? this.utilizationPercentage,
      status: status ?? this.status,
      shouldAlert: shouldAlert ?? this.shouldAlert,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        amount,
        period,
        startDate,
        endDate,
        description,
        isActive,
        autoAdjust,
        alertThreshold,
        metadata,
        createdAt,
        updatedAt,
        category,
        spent,
        remaining,
        utilizationPercentage,
        status,
        shouldAlert,
      ];
}

class Category {
  final int id;
  final String name;
  final String color;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      color: json['color'] ?? '#6B7280',
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}