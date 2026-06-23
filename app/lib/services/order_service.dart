import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../utils/constants.dart';

class OrderService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<Order> createOrder({
    required int customerId,
    int? productId,
    required String productName,
    required int quantity,
    required double unitSellPrice,
    required double unitCost,
    required double unitCommission,
    required String paymentStatus,
    required double paidAmount,
    String? note,
    bool markCustomerClosed = true,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final revenue = quantity * unitSellPrice;
    var paid = paidAmount;
    if (paymentStatus == 'paid') paid = revenue;
    if (paymentStatus == 'unpaid') paid = 0;

    final order = Order(
      customerId: customerId,
      productId: productId,
      productName: productName.trim(),
      quantity: quantity,
      unitSellPrice: unitSellPrice,
      unitCost: unitCost,
      unitCommission: unitCommission,
      paymentStatus: paymentStatus,
      paidAmount: paid,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      createdAt: now,
    );

    final db = await _db.database;
    final id = await db.transaction((txn) async {
      final orderId = await txn.insert('orders', order.toMap());

      if (productId != null) {
        final rows = await txn.query('products', where: 'id = ?', whereArgs: [productId]);
        if (rows.isNotEmpty) {
          final p = rows.first;
          final track = (p['track_inventory'] as int? ?? 0) == 1;
          if (track) {
            final stock = (p['stock_quantity'] as num?)?.toInt() ?? 0;
            await txn.update(
              'products',
              {'stock_quantity': stock - quantity},
              where: 'id = ?',
              whereArgs: [productId],
            );
          }
        }
      }

      final summary =
          'Ghi đơn: ${order.productName} × $quantity — ${_formatMoney(revenue)}';
      await txn.insert('interactions', {
        'customer_id': customerId,
        'content': summary,
        'created_at': now,
      });

      final customerRows =
          await txn.query('customers', where: 'id = ?', whereArgs: [customerId]);
      if (customerRows.isNotEmpty) {
        final c = Customer.fromMap(customerRows.first);
        final patch = <String, dynamic>{
          'product_id': productId ?? c.productId,
          'product': productName.trim().isNotEmpty ? productName.trim() : c.product,
        };
        if (markCustomerClosed) {
          patch['status'] = 'closed';
          patch['last_contact_at'] = now;
          patch['next_action_at'] = now + Customer.followUpDelayMs('closed');
        }
        await txn.update('customers', patch,
            where: 'id = ?', whereArgs: [customerId]);
      }

      return orderId;
    });

    return Order(
      id: id,
      customerId: order.customerId,
      productId: order.productId,
      productName: order.productName,
      quantity: order.quantity,
      unitSellPrice: order.unitSellPrice,
      unitCost: order.unitCost,
      unitCommission: order.unitCommission,
      paymentStatus: order.paymentStatus,
      paidAmount: order.paidAmount,
      note: order.note,
      createdAt: order.createdAt,
    );
  }

  String _formatMoney(double n) {
    return '${n.round()}đ';
  }

  Future<List<Order>> getAllOrders() => _db.getAllOrders();

  Future<List<Order>> getOrdersByCustomer(int customerId) =>
      _db.getOrdersByCustomer(customerId);

  Future<void> deleteOrder(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final rows = await txn.query('orders', where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) return;
      final order = Order.fromMap(rows.first);
      if (order.productId != null) {
        final pRows = await txn.query('products',
            where: 'id = ?', whereArgs: [order.productId]);
        if (pRows.isNotEmpty) {
          final p = pRows.first;
          if ((p['track_inventory'] as int? ?? 0) == 1) {
            final stock = (p['stock_quantity'] as num?)?.toInt() ?? 0;
            await txn.update(
              'products',
              {'stock_quantity': stock + order.quantity},
              where: 'id = ?',
              whereArgs: [order.productId],
            );
          }
        }
      }
      await txn.delete('orders', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<SalesSummary> getSalesSummaryForDay([DateTime? date]) {
    final d = date ?? DateTime.now();
    final start = DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;
    final end = start + 86400000;
    return _summaryInRange(start, end);
  }

  Future<SalesSummary> getSalesSummaryForMonth([DateTime? date]) {
    final d = date ?? DateTime.now();
    final start = DateTime(d.year, d.month, 1).millisecondsSinceEpoch;
    final end = DateTime(d.year, d.month + 1, 1).millisecondsSinceEpoch;
    return _summaryInRange(start, end);
  }

  Future<SalesSummary> getCustomerSalesSummary(int customerId) async {
    final orders = await getOrdersByCustomer(customerId);
    return SalesSummary.fromOrders(orders);
  }

  Future<SalesSummary> _summaryInRange(int start, int end) async {
    final orders = await _db.getOrdersInRange(start, end);
    return SalesSummary.fromOrders(orders);
  }

  Future<List<Map<String, dynamic>>> getRevenueBySource(int start, int end) async {
    final orders = await _db.getOrdersInRange(start, end);
    if (orders.isEmpty) return [];

    final db = await _db.database;
    final customerIds = orders.map((o) => o.customerId).toSet().toList();
    final placeholders = List.filled(customerIds.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT id, source FROM customers WHERE id IN ($placeholders)',
      customerIds,
    );
    final sourceByCustomer = {
      for (final r in rows) r['id'] as int: r['source'] as String?,
    };

    final agg = <String, Map<String, num>>{};
    for (final o in orders) {
      final src = sourceByCustomer[o.customerId] ?? '_none';
      final cur = agg.putIfAbsent(src, () => {'revenue': 0, 'order_count': 0});
      cur['revenue'] = (cur['revenue'] ?? 0) + o.revenue;
      cur['order_count'] = (cur['order_count'] ?? 0) + 1;
    }

    return agg.entries
        .map((e) => {
              'source': e.key,
              'label': e.key == '_none'
                  ? 'Chưa ghi nguồn'
                  : AppConstants.sourceLabel(e.key),
              'revenue': e.value['revenue']!,
              'order_count': e.value['order_count']!,
            })
        .toList()
      ..sort((a, b) => (b['revenue'] as num).compareTo(a['revenue'] as num));
  }
}
