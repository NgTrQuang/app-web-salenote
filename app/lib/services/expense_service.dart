import '../database/database_helper.dart';
import '../models/expense.dart';

class ExpenseService {
  final DatabaseHelper _db = DatabaseHelper();

  ({int start, int end}) _monthRange(DateTime date) {
    final start = DateTime(date.year, date.month, 1).millisecondsSinceEpoch;
    final end = DateTime(date.year, date.month + 1, 1).millisecondsSinceEpoch;
    return (start: start, end: end);
  }

  Future<List<Expense>> getExpensesForMonth([DateTime? date]) async {
    final d = date ?? DateTime.now();
    final range = _monthRange(d);
    final db = await _db.database;
    final rows = await db.query(
      'expenses',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [range.start, range.end],
      orderBy: 'created_at DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<double> getExpensesTotalForMonth([DateTime? date]) async {
    final list = await getExpensesForMonth(date);
    return list.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  Future<double> getTrueProfit(double grossProfit, [DateTime? date]) async {
    final expenses = await getExpensesTotalForMonth(date);
    return grossProfit - expenses;
  }

  Future<Expense> addExpense({
    required String category,
    required double amount,
    String? note,
    int? createdAt,
  }) async {
    final db = await _db.database;
    final expense = Expense(
      category: category,
      amount: amount,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );
    final id = await db.insert('expenses', expense.toMap());
    return Expense(
      id: id,
      category: expense.category,
      amount: expense.amount,
      note: expense.note,
      createdAt: expense.createdAt,
    );
  }

  Future<void> deleteExpense(int id) async {
    final db = await _db.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
