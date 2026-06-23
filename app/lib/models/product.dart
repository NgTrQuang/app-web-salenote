class Product {
  final int? id;
  final String name;
  final double costPrice;
  final double defaultSellPrice;
  final double defaultCommission;
  final String? note;
  final bool active;
  final bool trackInventory;
  final int stockQuantity;
  final int lowStockThreshold;
  final int createdAt;

  Product({
    this.id,
    required this.name,
    required this.costPrice,
    required this.defaultSellPrice,
    required this.defaultCommission,
    this.note,
    this.active = true,
    this.trackInventory = false,
    this.stockQuantity = 0,
    this.lowStockThreshold = 5,
    required this.createdAt,
  });

  static bool _bool(dynamic v, {bool def = false}) {
    if (v == null) return def;
    if (v is bool) return v;
    if (v is int) return v != 0;
    return def;
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0,
      defaultSellPrice: (map['default_sell_price'] as num?)?.toDouble() ?? 0,
      defaultCommission: (map['default_commission'] as num?)?.toDouble() ?? 0,
      note: map['note'] as String?,
      active: _bool(map['active'], def: true),
      trackInventory: _bool(map['track_inventory']),
      stockQuantity: (map['stock_quantity'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (map['low_stock_threshold'] as num?)?.toInt() ?? 5,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap({bool forDb = false}) {
    return {
      if (id != null) 'id': id,
      'name': name,
      'cost_price': costPrice,
      'default_sell_price': defaultSellPrice,
      'default_commission': defaultCommission,
      'note': note,
      'active': forDb ? (active ? 1 : 0) : active,
      'track_inventory': forDb ? (trackInventory ? 1 : 0) : trackInventory,
      'stock_quantity': trackInventory ? stockQuantity : 0,
      'low_stock_threshold': lowStockThreshold,
      'created_at': createdAt,
    };
  }

  Product copyWith({
    int? id,
    String? name,
    double? costPrice,
    double? defaultSellPrice,
    double? defaultCommission,
    String? note,
    bool? active,
    bool? trackInventory,
    int? stockQuantity,
    int? lowStockThreshold,
    int? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      costPrice: costPrice ?? this.costPrice,
      defaultSellPrice: defaultSellPrice ?? this.defaultSellPrice,
      defaultCommission: defaultCommission ?? this.defaultCommission,
      note: note ?? this.note,
      active: active ?? this.active,
      trackInventory: trackInventory ?? this.trackInventory,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get stockStatus {
    if (!trackInventory) return 'none';
    if (stockQuantity <= 0) return 'out';
    if (stockQuantity <= lowStockThreshold) return 'low';
    return 'ok';
  }
}
