import '../database/database_helper.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/customer_service.dart';
import '../services/product_service.dart';

class SegmentCustomer {
  final int customerId;
  final String name;
  final String product;
  final int daysSincePurchase;
  final int lastOrderAt;

  const SegmentCustomer({
    required this.customerId,
    required this.name,
    required this.product,
    required this.daysSincePurchase,
    required this.lastOrderAt,
  });
}

class ProductSegment {
  final int productId;
  final String productName;
  final List<SegmentCustomer> customers;

  const ProductSegment({
    required this.productId,
    required this.productName,
    required this.customers,
  });
}

class SegmentService {
  static const segmentMinDays = 30;
  static const segmentMinCount = 3;
  static const recentContactDays = 7;

  final DatabaseHelper _db = DatabaseHelper();
  final CustomerService _customers = CustomerService();
  final ProductService _products = ProductService();

  Future<List<ProductSegment>> getProductReengageSegments([int? nowMs]) async {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final db = await _db.database;
    final orderRows = await db.query('orders');
    final allCustomers = await _customers.getAllCustomers();
    final products = await _products.getAllProducts(activeOnly: false);
    final customerById = {for (final c in allCustomers) c.id!: c};

    final lastByKey = <String, ({
      int orderAt,
      int productId,
      String productName,
      int customerId,
    })>{};

    for (final r in orderRows) {
      final o = Order.fromMap(r);
      if (o.productId == null) continue;
      final key = '${o.customerId}-${o.productId}';
      final existing = lastByKey[key];
      if (existing == null || o.createdAt > existing.orderAt) {
        lastByKey[key] = (
          orderAt: o.createdAt,
          productId: o.productId!,
          productName: o.productName,
          customerId: o.customerId,
        );
      }
    }

    final byProduct = <int, List<SegmentCustomer>>{};
    final contactCutoff = now - recentContactDays * 86400000;

    for (final data in lastByKey.values) {
      final daysSince = ((now - data.orderAt) / 86400000).floor();
      if (daysSince < segmentMinDays) continue;

      final c = customerById[data.customerId];
      if (c == null) continue;
      if (c.lastContactAt >= contactCutoff) continue;

      final entry = SegmentCustomer(
        customerId: data.customerId,
        name: c.name,
        product: data.productName,
        daysSincePurchase: daysSince,
        lastOrderAt: data.orderAt,
      );
      byProduct.putIfAbsent(data.productId, () => []).add(entry);
    }

    final segments = <ProductSegment>[];
    for (final e in byProduct.entries) {
      if (e.value.length < segmentMinCount) continue;
      Product? product;
      for (final p in products) {
        if (p.id == e.key) {
          product = p;
          break;
        }
      }
      e.value.sort((a, b) => b.daysSincePurchase.compareTo(a.daysSincePurchase));
      segments.add(ProductSegment(
        productId: e.key,
        productName: product?.name ?? e.value.first.product,
        customers: e.value,
      ));
    }
    segments.sort((a, b) => b.customers.length.compareTo(a.customers.length));
    return segments;
  }

  Future<ProductSegment?> getProductSegment(int productId, [int? nowMs]) async {
    final segments = await getProductReengageSegments(nowMs);
    for (final s in segments) {
      if (s.productId == productId) return s;
    }
    return null;
  }
}
