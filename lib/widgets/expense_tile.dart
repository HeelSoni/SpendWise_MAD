import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

/// A custom, interactive list tile widget representing a single [Expense].
///
/// Features:
/// - Category icon inside a colored avatar container
/// - Clean formatted date and expense title
/// - Currency formatted amount (₹) with bold typography
/// - Tap to trigger the edit callback
/// - Swipe-to-delete with red background and confirmation dialog
class ExpenseTile extends StatelessWidget {
  /// The expense data to display.
  final Expense expense;

  /// Callback invoked when the user taps the tile to edit.
  final VoidCallback onTap;

  /// Callback invoked when the user confirms deletion after swiping.
  final VoidCallback onDelete;

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categoryColor = Expense.getCategoryColor(expense.category);
    final categoryIcon = Expense.getCategoryIcon(expense.category);

    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(expense.date);

    final currencyFormat = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    );
    final formattedAmount = currencyFormat.format(expense.amount);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Dismissible(
        key: Key('expense_${expense.id ?? expense.hashCode}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          // Show confirmation dialog before deleting
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              icon: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade600,
                size: 40,
              ),
              title: const Text('Delete Expense?'),
              content: Text(
                'Are you sure you want to delete "${expense.title}" of $formattedAmount? This action cannot be undone.',
                textAlign: TextAlign.center,
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) {
          onDelete();
        },
        child: Material(
          color: isDark ? const Color(0xFF1E222B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: isDark ? 0 : 1.5,
          shadowColor: Colors.black12,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Category Icon Container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: categoryColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title, Category & Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                expense.category,
                                style: TextStyle(
                                  color: categoryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formattedDate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (expense.note != null && expense.note!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            expense.note!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Expense Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formattedAmount,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
