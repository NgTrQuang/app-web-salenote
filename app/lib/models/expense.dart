class Expense {
  final int? id;
  final String category;
  final double amount;
  final String? note;
  final int createdAt;

  const Expense({
    this.id,
    required this.category,
    required this.amount,
    this.note,
    required this.createdAt,
  });

  factory Expense.fromMap(Map<String, dynamic> m) {
    return Expense(
      id: m['id'] as int?,
      category: m['category'] as String,
      amount: (m['amount'] as num).toDouble(),
      note: m['note'] as String?,
      createdAt: m['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap({bool forDb = true}) {
    final m = <String, dynamic>{
      'category': category,
      'amount': amount,
      'note': note,
      'created_at': createdAt,
    };
    if (forDb && id != null) m['id'] = id;
    return m;
  }
}
