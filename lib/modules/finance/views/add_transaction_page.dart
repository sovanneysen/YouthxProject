import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youthx/modules/finance/models/transaction_model.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/finance_controller.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key, this.existing});

  /// When set the page edits this transaction through `PUT /expenses/{id}`
  /// instead of creating a new one with `POST /expenses`. Passing the existing
  /// transaction is what lets the same form serve both flows.
  final TransactionModel? existing;

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  // Todo: STEP 1: Variables store"state" Can change Data
  final amountController = TextEditingController();

  // * True while editing: seeded from the transaction being edited.
  bool get isEditing => widget.existing != null;

  bool isExpense = true;

  /// The chosen category. Held as the object rather than a list index so the
  /// selection survives the category list loading asynchronously and stays
  /// correct when the income/expense toggle swaps the visible list.
  TransactionCategory? selectedCategory;

  DateTime selectedDate = DateTime.now();

  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing == null) return;

    // Prefill every field from the transaction being edited. The backend
    // stores a positive `amount` with the direction carried by `type`, so the
    // absolute value is what belongs in the amount field.
    isExpense = existing.type.toLowerCase() != 'income';
    selectedCategory = existing.category;
    selectedDate = existing.date;
    amountController.text = existing.amount.abs().toStringAsFixed(2);
    noteController.text = existing.note ?? '';
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  /// The category to send: prefer the copy from the loaded backend list so
  /// `categoryId` always points at a real row, then fall back to name matching
  /// and finally to whatever the transaction carried.
  TransactionCategory _resolveCategory(List<TransactionCategory> list) {
    final selected = selectedCategory;
    if (selected == null) {
      throw StateError('no category selected');
    }
    return list.firstWhereOrNull((c) => c.id != null && c.id == selected.id) ??
        list.firstWhereOrNull((c) => c.name == selected.name) ??
        selected;
  }

  void _toast(String message) {
    // Guarded here rather than at each call site because the call sites sit
    // after an `await`, and `context` is a State field.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Validates the form, then either creates (`POST /expenses`) or updates
  /// (`PUT /expenses/{id}`) through the controller. Pops with `true` on
  /// success so the caller can react.
  Future<bool> _submit(FinanceController ctrl) async {
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      _toast('Enter a valid amount');
      return false;
    }
    if (selectedCategory == null) {
      _toast('Select a category');
      return false;
    }

    // Compute from the reactive backend list at save-time so the categoryId
    // sent to the backend matches the DB FK.
    final saveList =
        isExpense ? ctrl.expenseCategories.toList() : ctrl.incomeCategories.toList();
    final category = _resolveCategory(saveList);
    final note = noteController.text.trim();

    final existing = widget.existing;
    final tx = TransactionModel(
      // On edit the id must be preserved so the controller can replace the
      // right list entry; on create the backend assigns the id.
      id: existing?.id ?? '',
      type: isExpense ? 'expense' : 'income',
      category: category,
      amount: amount,
      note: note.isEmpty ? null : note,
      date: selectedDate,
    );

    final success = isEditing
        ? await ctrl.updateTransaction(tx)
        : await ctrl.addTransaction(tx);
    if (!success) {
      // The controller writes the message into `error` on failure. Show our own
      // toast and clear it so the Finance home is not left in its
      // full-screen error state behind this sheet.
      ctrl.clearError();
      _toast(isEditing
          ? 'Could not update the transaction'
          : 'Could not save the transaction');
    }
    return success;
  }

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
                      isEditing ? 'Edit Transaction' : 'Add Transaction',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final success = await _submit(ctrl);
                        // `context` here is build()'s parameter, so the guard
                        // belongs on the context, not on the State.
                        if (success && context.mounted) {
                          Navigator.pop(context, true);
                        }
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
                            selectedCategory = null;
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
                            selectedCategory = null;
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
                      // Match on the backend id; fall back to the name for a
                      // category that has no id at all.
                      final selected = selectedCategory;
                      final isSelected = selected != null &&
                          ((selected.id != null && category.id == selected.id) ||
                              (selected.id == null &&
                                  category.name == selected.name));

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = category;
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
