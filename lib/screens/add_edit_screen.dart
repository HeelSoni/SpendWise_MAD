import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/expense.dart';
import '../utils/validators.dart';

/// Form screen for creating a new [Expense] or editing an existing one.
///
/// Features:
/// - Pre-populates fields if editing an existing expense
/// - Form validation with custom [Validators]
/// - Interactive date picker with formatted display
/// - Category dropdown with category icons and color badges
/// - Try/catch error handling around DB operations with user-friendly SnackBars
class AddEditScreen extends StatefulWidget {
  /// Existing expense to edit, or null if creating a new one.
  final Expense? expense;

  const AddEditScreen({super.key, this.expense});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late String _selectedCategory;
  late DateTime _selectedDate;
  bool _isLoading = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;

    _titleController = TextEditingController(text: expense?.title ?? '');
    _amountController = TextEditingController(
      text: expense != null ? expense.amount.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: expense?.note ?? '');

    _selectedCategory = expense?.category ?? Expense.categories.first;
    _selectedDate = expense?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Opens the native Material DatePicker.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'SELECT EXPENSE DATE',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Validates and saves the expense to SQLite.
  Future<void> _saveExpense() async {
    // 1. Trigger form validation
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Validate date explicitly
    final dateError = Validators.validateDate(_selectedDate);
    if (dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dateError),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final parsedAmount = double.parse(_amountController.text.trim());
      final title = _titleController.text.trim();
      final note = _noteController.text.trim();

      if (_isEditing) {
        // Update existing expense
        final updatedExpense = widget.expense!.copyWith(
          title: title,
          amount: parsedAmount,
          category: _selectedCategory,
          date: _selectedDate,
          note: note.isNotEmpty ? note : null,
        );

        await DBHelper.instance.updateExpense(updatedExpense);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Expense updated successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // Insert new expense
        final newExpense = Expense(
          title: title,
          amount: parsedAmount,
          category: _selectedCategory,
          date: _selectedDate,
          note: note.isNotEmpty ? note : null,
        );

        await DBHelper.instance.insertExpense(newExpense);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Expense added successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Expense' : 'Add Expense',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Hint
                Text(
                  _isEditing
                      ? 'Modify the details below to update your record.'
                      : 'Fill in the information below to record your expense.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),

                // Title Field
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Expense Title *',
                    hintText: 'e.g. Dinner with friends',
                    prefixIcon: const Icon(Icons.edit_note_rounded),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E222B) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                    ),
                  ),
                  validator: Validators.validateTitle,
                ),
                const SizedBox(height: 16),

                // Amount Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount (₹) *',
                    hintText: '0.00',
                    prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E222B) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                    ),
                  ),
                  validator: Validators.validateAmount,
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category *',
                    prefixIcon: Icon(
                      Expense.getCategoryIcon(_selectedCategory),
                      color: Expense.getCategoryColor(_selectedCategory),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E222B) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                    ),
                  ),
                  items: Expense.categories.map((category) {
                    final color = Expense.getCategoryColor(category);
                    final icon = Expense.getCategoryIcon(category);
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Row(
                        children: [
                          Icon(icon, color: color, size: 20),
                          const SizedBox(width: 10),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                  validator: Validators.validateCategory,
                ),
                const SizedBox(height: 16),

                // Date Picker Tile
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E222B) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date of Expense *',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formattedDate,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _pickDate,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Note Field (Optional)
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Note (Optional)',
                    hintText: 'Add extra details or reminders...',
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.notes_rounded),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E222B) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Action Button
                FilledButton(
                  onPressed: _isLoading ? null : _saveExpense,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Expense' : 'Save Expense',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
