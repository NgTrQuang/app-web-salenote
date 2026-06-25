import '../database/database_helper.dart';
import '../models/product.dart';

class ProductService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<List<Product>> getAllProducts({bool activeOnly = false}) =>
      _db.getAllProducts(activeOnly: activeOnly);

  Future<Product?> getProduct(int id) => _db.getProduct(id);

  Future<Product> addProduct({
    required String name,
    required double costPrice,
    required double defaultSellPrice,
    required double defaultCommission,
    String? note,
    bool trackInventory = false,
    int stockQuantity = 0,
    int lowStockThreshold = 5,
  }) async {
    final product = Product(
      name: name.trim(),
      costPrice: costPrice,
      defaultSellPrice: defaultSellPrice,
      defaultCommission: defaultCommission,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      trackInventory: trackInventory,
      stockQuantity: trackInventory ? stockQuantity : 0,
      lowStockThreshold: lowStockThreshold,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    final id = await _db.insertProduct(product);
    return product.copyWith(id: id);
  }

  Future<void> updateProduct(Product product) async {
    var p = product;
    if (!p.trackInventory) p = p.copyWith(stockQuantity: 0);
    await _db.updateProduct(p);
  }

  Future<void> deleteProduct(int id) => _db.deleteProduct(id);

  Future<void> toggleActive(Product product) async {
    final nextActive = !product.active;
    await updateProduct(product.copyWith(active: nextActive));
    if (!nextActive && product.id != null) {
      final db = await _db.database;
      await db.update(
        'customers',
        {'product_id': null},
        where: 'product_id = ?',
        whereArgs: [product.id],
      );
    }
  }

  Future<List<Product>> getLowStockProducts() async {
    final list = await getAllProducts(activeOnly: true);
    return list
        .where((p) => p.stockStatus == 'low' || p.stockStatus == 'out')
        .toList();
  }

  Future<void> deductStock(int productId, int quantity) async {
    final product = await _db.getProduct(productId);
    if (product == null || !product.trackInventory) return;
    await _db.updateProduct(
      product.copyWith(stockQuantity: product.stockQuantity - quantity),
    );
  }

  Future<void> restoreStock(int productId, int quantity) async {
    final product = await _db.getProduct(productId);
    if (product == null || !product.trackInventory) return;
    await _db.updateProduct(
      product.copyWith(stockQuantity: product.stockQuantity + quantity),
    );
  }

  Map<String, dynamic> applyDefaults(Product product, {int quantity = 1}) {
    return {
      'product_id': product.id,
      'product_name': product.name,
      'quantity': quantity,
      'unit_sell_price': product.defaultSellPrice,
      'unit_cost': product.costPrice,
      'unit_commission': product.defaultCommission,
    };
  }
}
