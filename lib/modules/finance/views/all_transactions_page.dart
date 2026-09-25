import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/finance_controller.dart';

class AllTransactionsPage extends StatelessWidget {
  const AllTransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FinanceController>();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        title: Text(
          'All Transactions',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: context.textPrimaryColor),
      ),
      body: Obx(() {
        final txs = controller.transactions;

        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (txs.isEmpty) {
          return Center(
            child: Text(
              'No transactions yet',
              style: TextStyle(color: context.textSecondaryColor),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: txs.length,
          itemBuilder: (context, index) {
            final tx = txs[index];
            final category = controller.resolveCategory(tx);
            final isIncome = tx.type.toLowerCase() == 'income';
            final sign = isIncome ? '+' : '-';
            final amountStr =
                '$sign\$${NumberFormat('#,##0.00').format(tx.amount.abs())}';
            final dateStr =
                '${tx.date.day}/${tx.date.month}/${tx.date.year}';
            final subtitle = '${category.name} · $dateStr';
            final title =
                tx.note?.isNotEmpty == true ? tx.note! : category.name;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: context.isDark
                    ? Border.all(color: context.borderColor)
                    : null,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: context.cardBgAlt,
                  child: Text(category.icon),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                subtitle: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondaryColor,
                  ),
                ),
                trailing: Text(
                  amountStr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isIncome ? Colors.green : context.textPrimaryColor,
                  ),
                ),
                onTap: () {
                  // TODO: open pre-filled edit screen when edit flow is ready
                },
              ),
            );
          },
        );
      }),
    );
  }
}

