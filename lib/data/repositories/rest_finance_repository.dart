import '../../modules/finance/models/saving_goal_model.dart';
import '../../modules/finance/models/transaction_model.dart';
import '../providers/api_provider.dart';
import 'finance_repository.dart';

/// REST-backed Finance repository, wired to the real Draft Backend, mirroring
/// the exact Growth Center wiring (`RestGrowthRepository`). Contract verified
/// from the Draft Backend source (this draft):
///
///   GET  /expense-categories       -> `List<ExpenseCategoryResponse>`
///   GET  /expenses?page=&size=     -> `PageResponse<ExpenseResponse>`
///   POST /expenses                 -> 201 ExpenseResponse
///   PUT  /expenses/{id}            -> 200 ExpenseResponse
///   DELETE /expenses/{id}          -> 204
///
///   GET  /saving-goals             -> `List<SavingGoalResponse>`
///   POST /saving-goals             -> 201 SavingGoalResponse
///   POST /saving-goals/{id}/deposit-> 200 SavingGoalResponse
///   PUT  /saving-goals/{id}        -> 200 SavingGoalResponse
///   DELETE /saving-goals/{id}      -> 204
///
/// All finance endpoints are user-scoped by the JWT (ownership enforced in
/// the backend service layer — cross-user access returns 403, verified by the
/// Draft Backend's ExpenseService/ExpenseController tests).
class RestFinanceRepository implements FinanceRepository {
  RestFinanceRepository({ApiProvider? apiProvider})
    : _api = apiProvider ?? ApiProvider();

  final ApiProvider _api;

  // ── Categories ────────────────────────────────────────────

  @override
  Future<List<TransactionCategory>> fetchCategories() async {
    final data = await _api.get('/expense-categories');
    final list = data is List ? data : const <dynamic>[];
    return list
        .map((e) => TransactionCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Transactions (paged) ─────────────────────────────────

  /// Fetches EVERY page of `/expenses` and merges them into a single list so
  /// the home screen can compute a complete balance (income − expense) from
  /// the real data instead of a truncated first page.
  @override
  Future<List<TransactionModel>> fetchTransactions() async {
    final all = <TransactionModel>[];
    var page = 0;
    var totalElements = -1;
    var fetched = 0;

    do {
      final data = await _api.get('/expenses?page=$page&size=100');
      final pageMap = data is Map ? data : const <String, dynamic>{};
      final content = pageMap['content'];
      final items = content is List ? content : const <dynamic>[];
      final total = (pageMap['totalElements'] as num?)?.toInt() ?? 0;

      for (final e in items) {
        all.add(_toTransaction(e as Map<String, dynamic>));
      }

      fetched = all.length;
      totalElements = total;
      page++;

      final last = (pageMap['last'] as bool?) ?? true;
      if (last || fetched >= totalElements) break;
    } while (true);

    return all;
  }

  @override
  Future<TransactionModel> createTransaction(TransactionModel t) async {
    final data = await _api.post('/expenses', _transactionBody(t));
    final parsed = _toTransaction(data as Map<String, dynamic>);
    // `_toTransaction` substitutes 'Unknown' when the response carries no
    // category details, so testing only for an empty name never fires and the
    // category the user just chose would be dropped. Treat that placeholder as
    // "category details absent" and keep the category we sent.
    if ((parsed.category.name.isEmpty || parsed.category.name == 'Unknown') &&
        t.category.name.isNotEmpty) {
      return TransactionModel(
        id: parsed.id,
        type: parsed.type,
        category: t.category,
        amount: parsed.amount,
        note: parsed.note,
        date: parsed.date,
      );
    }
    return parsed;
  }

  @override
  Future<TransactionModel> updateTransaction(TransactionModel t) async {
    final data = await _api.put('/expenses/${t.id}', _transactionBody(t));
    final parsed = _toTransaction(data as Map<String, dynamic>);
    // `_toTransaction` substitutes 'Unknown' when the response carries no
    // category details, so testing only for an empty name never fires and the
    // category the user just chose would be dropped. Treat that placeholder as
    // "category details absent" and keep the category we sent.
    if ((parsed.category.name.isEmpty || parsed.category.name == 'Unknown') &&
        t.category.name.isNotEmpty) {
      return TransactionModel(
        id: parsed.id,
        type: parsed.type,
        category: t.category,
        amount: parsed.amount,
        note: parsed.note,
        date: parsed.date,
      );
    }
    return parsed;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _api.delete('/expenses/$id');
  }

  // ── Saving Goals ─────────────────────────────────────────

  @override
  Future<List<SavingGoalModel>> fetchSavingGoals() async {
    final data = await _api.get('/saving-goals');
    final list = data is List ? data : const <dynamic>[];
    return list
        .map((e) => SavingGoalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SavingGoalModel> createSavingGoal(SavingGoalModel goal) async {
    final data = await _api.post('/saving-goals', goal.toCreateBody());
    return SavingGoalModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<SavingGoalModel> depositToSavingGoal(
    SavingGoalModel goal,
    double amount,
  ) async {
    final data = await _api.post(
      '/saving-goals/${goal.id}/deposit',
      goal.toDepositBody(amount),
    );
    return SavingGoalModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<SavingGoalModel> updateSavingGoal(SavingGoalModel goal) async {
    final data = await _api.put('/saving-goals/${goal.id}', {
      'name': goal.name,
      'targetAmount': goal.targetAmount,
    });
    return SavingGoalModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteSavingGoal(String id) async {
    await _api.delete('/saving-goals/$id');
  }

  // ── Mapping ──────────────────────────────────────────────

  Map<String, dynamic> _transactionBody(TransactionModel t) {
    return {
      'categoryId': t.category.id,
      'type': t.type, // * 'expense' | 'income'
      'amount': t.amount,
      'note': t.note,
      'transactionDate':
          '${t.date.year.toString().padLeft(4, '0')}-${_pad(t.date.month)}-${_pad(t.date.day)}',
    };
  }

  TransactionModel _toTransaction(Map<String, dynamic> json) {
    final rawCatId = json['categoryId'] ?? json['category']?['id'];
    final categoryId = rawCatId is num
        ? rawCatId.toInt()
        : int.tryParse(rawCatId?.toString() ?? '');
    final category = TransactionCategory.fromJson(
      (json['category'] as Map<String, dynamic>?) ??
          {
            'id': categoryId,
            'name': json['categoryName'] ?? 'Unknown',
            'icon': json['categoryIcon'] ?? '❓',
          },
    );
    return TransactionModel(
      id: json['id'].toString(),
      type: (json['type'] as String?)?.toLowerCase() ?? 'expense',
      category: category,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      note: json['note'] as String?,
      date:
          DateTime.tryParse(json['transactionDate'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
