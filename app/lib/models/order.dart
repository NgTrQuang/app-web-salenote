class Order {
  final int? id;
  final int customerId;
  final int? productId;
  final String productName;
  final int quantity;
  final double unitSellPrice;
  final double unitCost;
  final double unitCommission;
  final String paymentStatus;
  final double paidAmount;
  final String? note;
  final String? shippingName;
  final String? shippingPhone;
  final String? shippingAddress;
  final int createdAt;

  Order({
    this.id,
    required this.customerId,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unitSellPrice,
    required this.unitCost,
    required this.unitCommission,
    required this.paymentStatus,
    required this.paidAmount,
    this.note,
    this.shippingName,
    this.shippingPhone,
    this.shippingAddress,
    required this.createdAt,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      productId: map['product_id'] as int?,
      productName: map['product_name'] as String,
      quantity: (map['quantity'] as num).toInt(),
      unitSellPrice: (map['unit_sell_price'] as num).toDouble(),
      unitCost: (map['unit_cost'] as num).toDouble(),
      unitCommission: (map['unit_commission'] as num).toDouble(),
      paymentStatus: map['payment_status'] as String,
      paidAmount: (map['paid_amount'] as num).toDouble(),
      note: map['note'] as String?,
      shippingName: map['shipping_name'] as String?,
      shippingPhone: map['shipping_phone'] as String?,
      shippingAddress: map['shipping_address'] as String?,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_sell_price': unitSellPrice,
      'unit_cost': unitCost,
      'unit_commission': unitCommission,
      'payment_status': paymentStatus,
      'paid_amount': paidAmount,
      'note': note,
      'shipping_name': shippingName,
      'shipping_phone': shippingPhone,
      'shipping_address': shippingAddress,
      'created_at': createdAt,
    };
  }

  double get revenue => quantity * unitSellPrice;
  double get cost => quantity * unitCost;
  double get profit => revenue - cost;
  double get commission => quantity * unitCommission;
  double get debt => (revenue - paidAmount).clamp(0, double.infinity);
}

class SalesSummary {
  final double revenue;
  final double cost;
  final double profit;
  final double commission;
  final double debt;
  final int orderCount;

  const SalesSummary({
    this.revenue = 0,
    this.cost = 0,
    this.profit = 0,
    this.commission = 0,
    this.debt = 0,
    this.orderCount = 0,
  });

  static SalesSummary fromOrders(List<Order> orders) {
    var revenue = 0.0;
    var cost = 0.0;
    var profit = 0.0;
    var commission = 0.0;
    var debt = 0.0;
    for (final o in orders) {
      revenue += o.revenue;
      cost += o.cost;
      profit += o.profit;
      commission += o.commission;
      debt += o.debt;
    }
    return SalesSummary(
      revenue: revenue,
      cost: cost,
      profit: profit,
      commission: commission,
      debt: debt,
      orderCount: orders.length,
    );
  }
}
