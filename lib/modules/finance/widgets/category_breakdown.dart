import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/finance_controller.dart';

/// Category breakdown built from the transactions actually loaded from
/// `GET /expenses`.
///
/// No chart package, no backend endpoint and no invented percentages: each
/// bar is `row.total / groupTotal`, where `groupTotal` is the controller's own
/// `totalExpense` / `totalIncome`. Income and expense are kept apart because
/// the backend stores them as separate transaction `type` values, and the
/// toggle lets the user switch without leaving the Finance screen.
class CategoryBreakdown extends StatefulWidget {
  const CategoryBreakdown({
    super.key,
    required this.expenseRows,
    required this.incomeRows,
    required this.totalExpense,
    required this.totalIncome,
  });

  final List<CategoryTotal> expenseRows;
  final List<CategoryTotal> incomeRows;
  final double totalExpense;
  final double totalIncome;

  @override
  State<CategoryBreakdown> createState() => _CategoryBreakdownState();
}

class _CategoryBreakdownState extends State<CategoryBreakdown> {
  /// Which side of the breakdown is visible. Purely presentational, so it is
  /// local view state rather than controller state.
  bool _showIncome = false;

  @override
  Widget build(BuildContext context) {
    final income = _showIncome;
    final rows = income ? widget.incomeRows : widget.expenseRows;
    final groupTotal = income ? widget.totalIncome : widget.totalExpense;
    final accent = income ? AppColors.success : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GroupToggle(
          showIncome: income,
          accent: accent,
          onChanged: (value) => setState(() => _showIncome = value),
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          Text(
            income
                ? 'No income recorded yet'
                : 'No expenses recorded yet',
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondaryColor,
            ),
          )
        else
          ...rows.map((row) => _BreakdownRow(
                row: row,
                groupTotal: groupTotal,
                accent: accent,
              )),
        const SizedBox(height: 8),
        Text(
          '${_money(groupTotal)} total ${income ? 'income' : 'spent'}'
          '${rows.isEmpty ? '' : ' across ${rows.length} ${rows.length == 1 ? 'category' : 'categories'}'}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}

class _GroupToggle extends StatelessWidget {
  const _GroupToggle({
    required this.showIncome,
    required this.accent,
    required this.onChanged,
  });

  final bool showIncome;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleChip(
            label: '💸 Expense',
            selected: !showIncome,
            selectedColor: AppColors.error,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToggleChip(
            label: '💰 Income',
            selected: showIncome,
            selectedColor: AppColors.success,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? selectedColor : context.cardBgAlt,
          borderRadius: BorderRadius.circular(24),
          border: !selected && context.isDark
              ? Border.all(color: context.borderColor)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : context.textSecondaryColor,
          ),
        ),
      ),
    );
  }
}

/// One category row: icon, name, transaction count, real total, and a bar
/// proportional to that category's share of the group total.
class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.row,
    required this.groupTotal,
    required this.accent,
  });

  final CategoryTotal row;
  final double groupTotal;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final share = row.shareOf(groupTotal);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                row.category.icon.isEmpty ? '\u{1F4CB}' : row.category.icon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  row.category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${row.count}x',
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _money(row.total),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 6,
              backgroundColor: context.cardBgAlt,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

String _money(double value) => '\$${NumberFormat('#,##0.00').format(value)}';
