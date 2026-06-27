import '../database/database_helper.dart';
import '../models/order.dart';
import 'customer_service.dart';

class DebtEntry {
  final int customerId;
  final String name;
  final String? phone;
  final double totalDebt;
  final int orderCount;
  final int? oldestOrderAt;

  const DebtEntry({
    required this.customerId,
    required this.name,
    this.phone,
    required this.totalDebt,
    required this.orderCount,
    this.oldestOrderAt,
  });
}

class DebtService {
  final DatabaseHelper _db = DatabaseHelper();
  final CustomerService _customers = CustomerService();

  Future<List<DebtEntry>> getDebtList() async {
    final db = await _db.database;
    final orderRows = await db.query('orders');
    final allCustomers = await _customers.getAllCustomers();
    final byId = {for (final c in allCustomers) c.id!: c};

    final agg = <int, ({double debt, int orderCount, int? oldestAt})>{};
    for (final r in orderRows) {
      final o = Order.fromMap(r);
      final d = o.debt;
      if (d <= 0) continue;
      final cur = agg[o.customerId];
      if (cur == null) {
        agg[o.customerId] = (
          debt: d,
          orderCount: 1,
          oldestAt: o.createdAt,
        );
      } else {
        agg[o.customerId] = (
          debt: cur.debt + d,
          orderCount: cur.orderCount + 1,
          oldestAt: cur.oldestAt == null
              ? o.createdAt
              : (o.createdAt < cur.oldestAt! ? o.createdAt : cur.oldestAt),
        );
      }
    }

    final list = <DebtEntry>[];
    for (final e in agg.entries) {
      final c = byId[e.key];
      if (c == null) continue;
      list.add(DebtEntry(
        customerId: e.key,
        name: c.name,
        phone: c.phone,
        totalDebt: e.value.debt,
        orderCount: e.value.orderCount,
        oldestOrderAt: e.value.oldestAt,
      ));
    }
    list.sort((a, b) => b.totalDebt.compareTo(a.totalDebt));
    return list;
  }

  Future<double> getTotalDebt() async {
    final list = await getDebtList();
    return list.fold<double>(0.0, (sum, e) => sum + e.totalDebt);
  }
}
