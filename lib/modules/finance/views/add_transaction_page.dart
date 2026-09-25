import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youthx/modules/finance/models/transaction_model.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/finance_controller.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  // Todo: STEP 1: Variables store"state" Can change Data
  final amountController = TextEditingController();

  bool isExpense = true;

  int selectedIndex = -1;

  DateTime selectedDate = DateTime.now();

  final noteController = TextEditingController();

  // Todo: STEP 2: build() — build UI On screen
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<FinanceController>();

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ! PART A: Header (Close, Title, Save)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.close, color: context.textPrimaryColor),
                    ),
                    Text(
                      'Add Transaction',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enter a valid amount'),
                            ),
                          );
                          return;
                        }
                        if (selectedIndex == -1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Select a category')),
                          );
                          return;
                        }

                        // Compute from the reactive backend list at save-time
                        // so the categoryId sent to POST matches the DB FK.
                        final saveList = isExpense
                            ? ctrl.expenseCategories.toList()
                            : ctrl.incomeCategories.toList();
                        final category = saveList[selectedIndex];
                        final tx = TransactionModel(
                          id: '', // backend assigns real id on create
                          type: isExpense ? 'expense' : 'income',
                          category: category,
                          amount: amount,
                          note: noteController.text.isEmpty
                              ? null
                              : noteController.text,
                          date: selectedDate,
                        );

                        final controller = Get.find<FinanceController>();
                        controller.addTransaction(tx).then((success) {
                          if (success) Navigator.pop(context);
                        });
                      },

                      child: const Text('Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ! PART B: Expense / Income Toggle
                Row(
                  children: [
                    // Todo: Expense button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isExpense = true;
                            selectedIndex = -1;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isExpense ? Colors.red : context.cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: !isExpense && context.isDark
                                ? Border.all(color: context.borderColor)
                                : null,
                          ),
                          child: Text(
                            '💸 Expense',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isExpense
                                  ? Colors.white
                                  : context.textSecondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Todo:Income button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isExpense = false;
                            selectedIndex = -1;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isExpense ? Colors.green : context.cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: isExpense && context.isDark
                                ? Border.all(color: context.borderColor)
                                : null,
                          ),
                          child: Text(
                            '💰 Income',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !isExpense
                                  ? Colors.white
                                  : context.textSecondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: context.isDark
                        ? Border.all(color: context.borderColor)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'AMOUNT',
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              '\$',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IntrinsicWidth(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 60),
                              child: TextField(
                                controller: amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  hintStyle: TextStyle(
                                    color: context.textSecondaryColor.withValues(alpha: 0.5),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ! PART D: Category Grid View . Builder
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),

                Obx(() {
                  // Compute inside Obx so backend-loaded categories are
                  // reflected dynamically when ctrl.expenseCategories loads.
                  final categoryList = isExpense
                      ? ctrl.expenseCategories.toList()
                      : ctrl.incomeCategories.toList();

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categoryList.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemBuilder: (context, index) {
                      final category = categoryList[index];
                      final isSelected = selectedIndex == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (context.isDark
                                    ? Colors.blue.withValues(alpha: 0.25)
                                    : Colors.blue[50])
                                : context.cardBg,
                            border: isSelected
                                ? Border.all(color: Colors.blue, width: 2)
                                : (context.isDark
                                    ? Border.all(color: context.borderColor)
                                    : null),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                category.icon,
                                style: const TextStyle(fontSize: 22),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                category.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(height: 16),

                // ! PART E: Note field
                Text(
                  'Note (optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: 'What was this for?',
                    filled: true,
                    fillColor: context.cardBgAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ! PART F: Date row
                Text(
                  'Date',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: context.isDark
                          ? Border.all(color: context.borderColor)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: context.textSecondaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: TextStyle(color: context.textPrimaryColor),
                        ),
                      ],
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
