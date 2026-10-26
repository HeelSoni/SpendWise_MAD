import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/expense.dart';
import '../widgets/expense_tile.dart';
import 'add_edit_screen.dart';

/// The main Home screen of SpendWise.
///
/// Features:
/// - Budget Overview Card showing total spent, budget, and remaining balance
/// - Red Warning Banner when monthly budget is exceeded
/// - Filter controls for Category (chips) and Month (selector)
/// - List of expenses (newest first) using [ExpenseTile]
/// - Empty state illustration and message
/// - Floating Action Button to quickly add a new expense
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> _allMonthExpenses = [];
  List<Expense> _filteredExpenses = [];
  double _totalSpent = 0.0;
  double _monthlyBudget = 15000.0;
  bool _isLoading = true;

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Reloads all data for the selected month from SQLite.
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final year = _selectedDate.year;
      final month = _selectedDate.month;

      final expenses = await DBHelper.instance.getExpensesByMonth(year, month);
      final budget = await DBHelper.instance.getBudget(year, month);
      final totalSpent = await DBHelper.instance.getTotalSpentForMonth(year, month);

      setState(() {
        _allMonthExpenses = expenses;
        _monthlyBudget = budget;
        _totalSpent = totalSpent;
        _applyCategoryFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load expenses: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  /// Filters the expenses list in memory by category.
  void _applyCategoryFilter() {
    if (_selectedCategory == 'All') {
      _filteredExpenses = List.from(_allMonthExpenses);
    } else {
      _filteredExpenses = _allMonthExpenses
          .where((exp) => exp.category == _selectedCategory)
          .toList();
    }
  }

  /// Changes the active month and reloads data.
  void _changeMonth(int delta) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + delta,
        1,
      );
    });
    _loadData();
  }

  /// Deletes an expense with undo capability and feedback.
  Future<void> _deleteExpense(Expense expense) async {
    if (expense.id == null) return;
    try {
      await DBHelper.instance.deleteExpense(expense.id!);
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${expense.title}"'),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.amberAccent,
              onPressed: () async {
                await DBHelper.instance.insertExpense(expense);
                _loadData();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting expense: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  /// Navigates to Add/Edit screen and refreshes on return.
  Future<void> _navigateToAddEdit([Expense? expense]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEditScreen(expense: expense),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currencyFormat = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    );
    final monthFormat = DateFormat('MMMM yyyy');

    final remainingBudget = _monthlyBudget - _totalSpent;
    final isBudgetExceeded = _monthlyBudget > 0 && _totalSpent > _monthlyBudget;
    final budgetProgress = _monthlyBudget > 0
        ? (_totalSpent / _monthlyBudget).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SpendWise',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh data',
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEdit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // 1. Month Navigation Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            tooltip: 'Previous month',
                            onPressed: () => _changeMonth(-1),
                          ),
                          Text(
                            monthFormat.format(_selectedDate),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            tooltip: 'Next month',
                            onPressed: () => _changeMonth(1),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Monthly Budget Summary Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                                : [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primaryContainer,
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Monthly Overview',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[300] : Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Budget: ${currencyFormat.format(_monthlyBudget)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currencyFormat.format(_totalSpent),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total spent in ${DateFormat('MMMM').format(_selectedDate)}',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: budgetProgress,
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isBudgetExceeded
                                      ? Colors.redAccent
                                      : (budgetProgress > 0.8
                                          ? Colors.amberAccent
                                          : Colors.greenAccent),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isBudgetExceeded
                                      ? 'Over budget'
                                      : 'Remaining Balance',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[300] : Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(remainingBudget.abs()),
                                  style: TextStyle(
                                    color: isBudgetExceeded
                                        ? Colors.redAccent
                                        : Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Warning Banner (if Budget is Exceeded)
                  if (isBudgetExceeded)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Budget Exceeded!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'You have exceeded your monthly limit by ${currencyFormat.format((_totalSpent - _monthlyBudget).abs())}.',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 4. Category Filter Chips
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: 42,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: const Text('All'),
                                selected: _selectedCategory == 'All',
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedCategory = 'All';
                                      _applyCategoryFilter();
                                    });
                                  }
                                },
                              ),
                            ),
                            ...Expense.categories.map((category) {
                              final isSelected = _selectedCategory == category;
                              final catColor = Expense.getCategoryColor(category);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  avatar: Icon(
                                    Expense.getCategoryIcon(category),
                                    size: 16,
                                    color: isSelected ? Colors.white : catColor,
                                  ),
                                  label: Text(category),
                                  selected: isSelected,
                                  selectedColor: catColor,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : null,
                                    fontWeight: isSelected ? FontWeight.bold : null,
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = selected ? category : 'All';
                                      _applyCategoryFilter();
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 5. Section Title & Item Count
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Expenses',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_filteredExpenses.length} ${_filteredExpenses.length == 1 ? 'record' : 'records'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 6. Expense List or Empty State
                  if (_filteredExpenses.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                _selectedCategory == 'All'
                                    ? 'No expenses recorded yet'
                                    : 'No expenses under "$_selectedCategory"',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap the "+ Add Expense" button to add your spending.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final expense = _filteredExpenses[index];
                          return ExpenseTile(
                            expense: expense,
                            onTap: () => _navigateToAddEdit(expense),
                            onDelete: () => _deleteExpense(expense),
                          );
                        },
                        childCount: _filteredExpenses.length,
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 90), // Bottom padding for FAB
                  ),
                ],
              ),
            ),
    );
  }
}
