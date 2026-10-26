import 'package:flutter/material.dart';

/// Represents a single expense record in the SpendWise application.
///
/// This model class encapsulates all attributes of an expense, handles
/// serialization to/from SQLite database maps, and provides category metadata
/// such as icons and distinct theme colors.
class Expense {
  /// Unique identifier generated automatically by SQLite (primary key).
  /// Nullable when creating a new expense before inserting into DB.
  final int? id;

  /// Short descriptive title of the expense (e.g., "Grocery shopping").
  final String title;

  /// Numerical cost/amount spent. Must be positive (> 0).
  final double amount;

  /// Selected spending category (e.g., 'Food', 'Travel', etc.).
  final String category;

  /// The date and time when the expense occurred.
  final DateTime date;

  /// Optional extra notes or remarks about this expense.
  final String? note;

  /// Standard constructor for Expense model.
  const Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });

  /// Master list of supported categories in SpendWise.
  static const List<String> categories = [
    'Food',
    'Travel',
    'Shopping',
    'Bills',
    'Education',
    'Entertainment',
    'Health',
    'Other',
  ];

  /// Converts this [Expense] object into a Map for SQLite database insertion/updating.
  /// Note: The date is serialized as an ISO 8601 string for reliable storage in SQLite TEXT.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'note': note ?? '',
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Constructs an [Expense] instance from a SQLite row Map.
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
    );
  }

  /// Creates a copy of this Expense with optional updated fields.
  Expense copyWith({
    int? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  /// Returns a designated Material Icon corresponding to the given category name.
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Travel':
        return Icons.directions_car_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Bills':
        return Icons.receipt_long_rounded;
      case 'Education':
        return Icons.school_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      case 'Health':
        return Icons.local_hospital_rounded;
      case 'Other':
      default:
        return Icons.category_rounded;
    }
  }

  /// Returns a harmonious accent color corresponding to the given category.
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xFFF57C00); // Amber/Orange
      case 'Travel':
        return const Color(0xFF1976D2); // Primary Blue
      case 'Shopping':
        return const Color(0xFF7B1FA2); // Purple
      case 'Bills':
        return const Color(0xFFD32F2F); // Red
      case 'Education':
        return const Color(0xFF0097A7); // Cyan
      case 'Entertainment':
        return const Color(0xFFE91E63); // Pink
      case 'Health':
        return const Color(0xFF388E3C); // Forest Green
      case 'Other':
      default:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }
}
