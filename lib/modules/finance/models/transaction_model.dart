// * STEP 1: Class for Category (Food, Transport, Salary...)
class TransactionCategory {
  String name;
  String icon;

  // *Constructor
  TransactionCategory({required this.name, required this.icon});
}

// * STEP 2: Class for Transaction
class TransactionModel {
  String id;
  String type;
  TransactionCategory category;
  double amount;
  String? note;
  DateTime date;

  // * Constructor
  TransactionModel({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    this.note,
    required this.date,
  });
}

//* STEP 3: Sample Data — List categories exist

// Todo: Category for Expense
List<TransactionCategory> expenseCategories = [
  TransactionCategory(name: 'Food', icon: '🍔'),
  TransactionCategory(name: 'Transport', icon: '🚌'),
  TransactionCategory(name: 'Shopping', icon: '🛍️'),
  TransactionCategory(name: 'Education', icon: '📚'),
  TransactionCategory(name: 'Health', icon: '💊'),
  TransactionCategory(name: 'Fun', icon: '🎮'),
  TransactionCategory(name: 'Bills', icon: '🏠'),
  TransactionCategory(name: 'Other', icon: '📦'),
];

// Todo: Category for Income
List<TransactionCategory> incomeCategories = [
  TransactionCategory(name: 'Salary', icon: '🏢'),
  TransactionCategory(name: 'Freelance', icon: '💻'),
  TransactionCategory(name: 'Gift', icon: '🎁'),
  TransactionCategory(name: 'Investment', icon: '📈'),
  TransactionCategory(name: 'Rental', icon: '🏠'),
  TransactionCategory(name: 'Other', icon: '📦'),
];
