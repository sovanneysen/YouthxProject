// * STEP 1: Class for Category (Food, Transport, Salary...)
class TransactionCategory {
  final int? id;
  final String name;
  final String icon;
  final bool isIncome;

  const TransactionCategory({
    this.id,
    required this.name,
    required this.icon,
    this.isIncome = false,
  });

  /// Backend `ExpenseCategoryResponse` JSON -> category. The Draft Backend
  /// stores ONE shared category list (`/expense-categories`) used for both
  /// income and expense; the transaction's `type` column distinguishes them.
  factory TransactionCategory.fromJson(Map<String, dynamic> json) {
    return TransactionCategory(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      isIncome: json['isIncome'] as bool? ?? false,
    );
  }
}

// * STEP 2: Class for Transaction
class TransactionModel {
  final String id;
  final String type; // * 'income' | 'expense'
  final TransactionCategory category;
  final double amount;
  final String? note;
  final DateTime date;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    this.note,
    required this.date,
  });
}

// * STEP 3: Sample Data — List categories exist

// * Todo: Category for Expense
List<TransactionCategory> expenseCategories = [
  TransactionCategory(id: 1, name: 'Food', icon: '🍔'),
  TransactionCategory(id: 2, name: 'Transport', icon: '🚌'),
  TransactionCategory(id: 3, name: 'Shopping', icon: '🛍️'),
  TransactionCategory(id: 4, name: 'Education', icon: '📚'),
  TransactionCategory(id: 5, name: 'Health', icon: '💊'),
  TransactionCategory(id: 6, name: 'Fun', icon: '🎮'),
  TransactionCategory(id: 7, name: 'Bills', icon: '🏠'),
  TransactionCategory(id: 8, name: 'Other', icon: '📦'),
];

// * Todo: Category for Income (uses the same shared category ids as the
// * Draft Backend — income is a transaction `type`, not a separate list).
List<TransactionCategory> incomeCategories = [
  TransactionCategory(id: 1, name: 'Salary', icon: '🏢'),
  TransactionCategory(id: 2, name: 'Freelance', icon: '💻'),
  TransactionCategory(id: 3, name: 'Gift', icon: '🎁'),
  TransactionCategory(id: 4, name: 'Investment', icon: '📈'),
  TransactionCategory(id: 5, name: 'Rental', icon: '🏠'),
  TransactionCategory(id: 6, name: 'Other', icon: '📦'),
];