import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/models/expense.dart';
import 'package:spendwise/utils/validators.dart';

void main() {
  group('1. Title Validator Tests', () {
    test('Should return error when title is null', () {
      final result = Validators.validateTitle(null);
      expect(result, 'Title is required');
    });

    test('Should return error when title is empty', () {
      final result = Validators.validateTitle('');
      expect(result, 'Title is required');
    });

    test('Should return error when title contains only whitespace', () {
      final result = Validators.validateTitle('    ');
      expect(result, 'Title is required');
    });

    test('Should return error when title is shorter than 2 characters', () {
      final result = Validators.validateTitle('A');
      expect(result, 'Title must be at least 2 characters long');
    });

    test('Should return null (valid) for a valid title', () {
      final result = Validators.validateTitle('Coffee & Snacks');
      expect(result, isNull);
    });
  });

  group('2. Amount Validator Tests', () {
    test('Should return error when amount is null', () {
      final result = Validators.validateAmount(null);
      expect(result, 'Amount is required');
    });

    test('Should return error when amount is empty', () {
      final result = Validators.validateAmount('');
      expect(result, 'Amount is required');
    });

    test('Should return error when amount is not a valid number', () {
      final result = Validators.validateAmount('abc');
      expect(result, 'Please enter a valid number');
    });

    test('Should return error when amount is 0', () {
      final result = Validators.validateAmount('0');
      expect(result, 'Amount must be greater than 0');
    });

    test('Should return error when amount is negative', () {
      final result = Validators.validateAmount('-45.50');
      expect(result, 'Amount must be greater than 0');
    });

    test('Should return null (valid) for a positive decimal number', () {
      final result = Validators.validateAmount('250.75');
      expect(result, isNull);
    });

    test('Should return null (valid) for an integer string', () {
      final result = Validators.validateAmount('500');
      expect(result, isNull);
    });
  });

  group('3. Expense Model Serialization (toMap / fromMap) Tests', () {
    final testDate = DateTime(2026, 10, 26, 14, 30);
    final expense = Expense(
      id: 1,
      title: 'Groceries',
      amount: 1250.50,
      category: 'Food',
      date: testDate,
      note: 'Weekly essentials',
    );

    test('toMap() correctly converts Expense to Map', () {
      final map = expense.toMap();

      expect(map['id'], 1);
      expect(map['title'], 'Groceries');
      expect(map['amount'], 1250.50);
      expect(map['category'], 'Food');
      expect(map['date'], testDate.toIso8601String());
      expect(map['note'], 'Weekly essentials');
    });

    test('fromMap() correctly constructs Expense from Map', () {
      final map = {
        'id': 2,
        'title': 'Metro Card Recharge',
        'amount': 500.0,
        'category': 'Travel',
        'date': testDate.toIso8601String(),
        'note': 'Monthly pass',
      };

      final parsed = Expense.fromMap(map);

      expect(parsed.id, 2);
      expect(parsed.title, 'Metro Card Recharge');
      expect(parsed.amount, 500.0);
      expect(parsed.category, 'Travel');
      expect(parsed.date, testDate);
      expect(parsed.note, 'Monthly pass');
    });

    test('toMap() and fromMap() round-trip retains exact data', () {
      final original = Expense(
        id: 99,
        title: 'Electricity Bill',
        amount: 3450.0,
        category: 'Bills',
        date: testDate,
        note: null,
      );

      final map = original.toMap();
      final reconstructed = Expense.fromMap(map);

      expect(reconstructed.id, original.id);
      expect(reconstructed.title, original.title);
      expect(reconstructed.amount, original.amount);
      expect(reconstructed.category, original.category);
      expect(reconstructed.date, original.date);
    });

    test('copyWith() returns a modified copy', () {
      final updated = expense.copyWith(
        amount: 1500.0,
        title: 'Supermarket Groceries',
      );

      expect(updated.id, expense.id);
      expect(updated.title, 'Supermarket Groceries');
      expect(updated.amount, 1500.0);
      expect(updated.category, expense.category);
      expect(updated.date, expense.date);
      expect(updated.note, expense.note);
    });

    test('Category icon and color helpers return non-null values', () {
      for (final cat in Expense.categories) {
        final icon = Expense.getCategoryIcon(cat);
        final color = Expense.getCategoryColor(cat);

        expect(icon, isA<IconData>());
        expect(color, isA<Color>());
      }
    });
  });
}
