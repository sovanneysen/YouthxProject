import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/finance_controller.dart';
import '../models/transaction_model.dart';
import 'add_transaction_page.dart';

/// Detail screen for a single transaction, with edit and delete.
///
/// Holds no copy of the transaction: it receives only [transactionId] and reads
/// the current snapshot out of `FinanceController.transactions` inside an
/// `Obx`. Because `updateTransaction` replaces the list entry and
/// `deleteTransaction` removes it, this screen reflects both without a
/// separate reload.
class TransactionDetailPage extends GetView<FinanceController> {
  const TransactionDetailPage({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimaryColor),
        title: Obx(() {
          final tx = _find();
          return Text(
            tx == null ? 'Transaction' : 'Transaction Details',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          );
        }),
        actions: [
          Obx(() {
            final tx = _find();
            if (tx == null) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Edit transaction',
              onPressed: () => _openEdit(context, tx),
              icon: Icon(Icons.edit, color: context.textPrimaryColor),
            );
          }),
          Obx(() {
            final tx = _find();
            if (tx == null) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Delete transaction',
              onPressed: () => _confirmDelete(context, tx),
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
            );
          }),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final tx = _find();
          // Deleted (or an id that never matched): show a resolvable state
          // instead of a spinner that would never finish.
          if (tx == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: context.textSecondaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This transaction is no longer available.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.textSecondaryColor),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Back to Finance'),
                    ),
                  ],
                ),
              ),
            );
          }
          return _DetailBody(
            tx: tx,
            category: controller.resolveCategory(tx),
            onEdit: () => _openEdit(context, tx),
            onDelete: () => _confirmDelete(context, tx),
          );
        }),
      ),
    );
  }

  /// Current snapshot from the reactive list, or null once removed.
  TransactionModel? _find() =>
      controller.transactions.firstWhereOrNull((t) => t.id == transactionId);

  Future<void> _openEdit(BuildContext context, TransactionModel tx) async {
    final messenger = ScaffoldMessenger.of(context);
    // Reuse the existing transaction form in edit mode (PUT /expenses/{id}).
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddTransactionPage(existing: tx)),
    );
    if (changed == true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Transaction updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TransactionModel tx,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.cardBg,
        title: const Text('Delete this transaction?'),
        content: Text(
          'This removes '
          '${_signedMoney(tx)} from your Finance totals. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // The controller removes it from `transactions`, which this screen observes.
    final ok = await controller.deleteTransaction(tx);
    if (!ok) {
      // Surface the failure once, then clear the shared error so the Finance
      // home is not left in its full-screen error state.
      controller.clearError();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not delete the transaction'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Transaction deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (navigator.canPop()) navigator.pop();
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.tx,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionModel tx;
  final TransactionCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // `type` is the backend's own discriminator; colour follows it and never
    // the other way round.
    final isIncome = tx.type.toLowerCase() == 'income';
    final accent = isIncome ? AppColors.success : AppColors.error;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // * Amount hero + Income/Expense badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isIncome
                  ? const [AppColors.success, AppColors.overviewAccent]
                  : const [AppColors.error, AppColors.coral],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isIncome ? 'INCOME' : 'EXPENSE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _signedMoney(tx),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(tx.date),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // * Detail rows
        Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: context.isDark
                ? Border.all(color: context.borderColor)
                : null,
          ),
          child: Column(
            children: [
              _Row(
                label: 'Category',
                value: category.name,
                leading: Text(
                  category.icon.isEmpty ? '\u{1F4CB}' : category.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              _Divider(),
              _Row(
                label: 'Amount',
                value: _signedMoney(tx),
                valueColor: accent,
              ),
              _Divider(),
              _Row(
                label: 'Date',
                value: DateFormat('d MMM yyyy').format(tx.date),
              ),
              // A transaction with no note renders an explicit "None" rather
              // than a blank row, so the field is never silently missing.
              _Divider(),
              _NoteRow(note: tx.note, accent: accent),
            ],
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit Transaction'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete Transaction'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor, this.leading});

  final String label;
  final String value;
  final Color? valueColor;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondaryColor,
            ),
          ),
          const Spacer(),
          Flexible(
            // Long values wrap instead of overflowing, and always stay
            // right-aligned against the label.
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? context.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note, required this.accent});

  final String? note;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final text = note?.trim();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Note',
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 6),
          if (text == null || text.isEmpty)
            Text(
              'No note added',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: context.textSecondaryColor,
              ),
            )
          else
            // A long note wraps onto as many lines as it needs.
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: accent,
              ),
            ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.borderColor,
    );
  }
}

/// Signed money string, e.g. `-$45.00` / `+$830.00`.
String _signedMoney(TransactionModel tx) {
  final isIncome = tx.type.toLowerCase() == 'income';
  final value = NumberFormat('#,##0.00').format(tx.amount.abs());
  return '${isIncome ? '+' : '-'}\$$value';
}
