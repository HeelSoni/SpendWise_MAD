import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/expense.dart';
import '../utils/validators.dart';

/// Summary and Analytics screen for SpendWise.
///
/// Features:
/// - Category-wise spending breakdown with interactive `fl_chart` PieChart
/// - Monthly budget manager card with "Edit Budget" dialog
/// - Detailed category list showing spent amount, transaction count, and % of total
/// - Month navigation to inspect historical trends
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, double> _categoryTotals = {};
  double _totalSpent = 0.0;
  double _monthlyBudget = 15000.0;
  bool _isLoading = true;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadSummaryData();
  }

  /// Fetches summary aggregations and budget for the active month.
  Future<void> _loadSummaryData() async {
    setState(() => _isLoading = true);
    try {
      final year = _selectedDate.year;
      final month = _selectedDate.month;

      final totals = await DBHelper.instance.getCategoryTotals(year, month);
      final budget = await DBHelper.instance.getBudget(year, month);
      final total = await DBHelper.instance.getTotalSpentForMonth(year, month);

      setState(() {
        _categoryTotals = totals;
        _monthlyBudget = budget;
        _totalSpent = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load summary: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
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
      _touchedIndex = -1;
    });
    _loadSummaryData();
  }

  /// Opens a Material Dialog to edit and persist the monthly budget.
  Future<void> _showEditBudgetDialog() async {
    final controller = TextEditingController(
      text: _monthlyBudget.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: Colors.indigo),
            SizedBox(width: 10),
            Text('Set Monthly Budget'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter budget for ${DateFormat('MMMM yyyy').format(_selectedDate)}:',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Budget (₹)',
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: Validators.validateBudget,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newBudget = double.parse(controller.text.trim());
                await DBHelper.instance.setBudget(
                  _selectedDate.year,
                  _selectedDate.month,
                  newBudget,
                );
                if (ctx.mounted) {
                  Navigator.of(ctx).pop(true);
                }
              }
            },
            child: const Text('Save Budget'),
          ),
        ],
      ),
    );

    if (updated == true) {
      _loadSummaryData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monthly budget updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final monthFormat = DateFormat('MMMM yyyy');

    final remaining = _monthlyBudget - _totalSpent;
    final hasExpenses = _categoryTotals.isNotEmpty && _totalSpent > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics & Summary',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSummaryData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Month Navigation Header
                    Row(
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
                    const SizedBox(height: 10),

                    // 2. Budget Control Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E222B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isDark
                            ? null
                            : const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly Budget',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currencyFormat.format(_monthlyBudget),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  remaining >= 0
                                      ? 'Remaining: ${currencyFormat.format(remaining)}'
                                      : 'Exceeded by: ${currencyFormat.format(remaining.abs())}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: remaining >= 0
                                        ? Colors.green
                                        : Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _showEditBudgetDialog,
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. Category Spending Breakdown Title
                    Text(
                      'Spending by Category',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 4. Pie Chart or Empty State
                    if (!hasExpenses)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E222B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.pie_chart_outline_rounded,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No spending recorded for this month.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add some expenses from the Home tab to see visual chart analytics.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // Pie Chart Card
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E222B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isDark
                              ? null
                              : const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 220,
                              child: PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection == null) {
                                          _touchedIndex = -1;
                                          return;
                                        }
                                        _touchedIndex = pieTouchResponse
                                            .touchedSection!.touchedSectionIndex;
                                      });
                                    },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 42,
                                  sections: _buildPieSections(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Total: ${currencyFormat.format(_totalSpent)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 5. Category Breakdown Detailed List
                      Text(
                        'Category Breakdown',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ..._categoryTotals.entries.map((entry) {
                        final category = entry.key;
                        final amount = entry.value;
                        final percentage = _totalSpent > 0
                            ? (amount / _totalSpent) * 100
                            : 0.0;
                        final color = Expense.getCategoryColor(category);
                        final icon = Expense.getCategoryIcon(category);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E222B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isDark
                                ? null
                                : const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(icon, color: color, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          '${percentage.toStringAsFixed(1)}% of total',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(amount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  minHeight: 6,
                                  backgroundColor: color.withValues(alpha: 0.15),
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  /// Generates the pie chart sections with distinct colors and sizing for touched state.
  List<PieChartSectionData> _buildPieSections() {
    final entries = _categoryTotals.entries.toList();
    return List.generate(entries.length, (i) {
      final isTouched = i == _touchedIndex;
      final entry = entries[i];
      final category = entry.key;
      final amount = entry.value;
      final percentage = _totalSpent > 0 ? (amount / _totalSpent) * 100 : 0.0;
      final color = Expense.getCategoryColor(category);

      final radius = isTouched ? 65.0 : 55.0;
      final fontSize = isTouched ? 14.0 : 12.0;

      return PieChartSectionData(
        color: color,
        value: amount,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(color: Colors.black45, blurRadius: 4),
          ],
        ),
      );
    });
  }
}
