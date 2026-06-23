/// Sentinel object used to distinguish "pass null explicitly" from "not provided".
const _absent = Object();

class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? note;
  final String? product;
  final int? productId;
  final String? source;
  final String status;
  final int createdAt;
  final int lastContactAt;
  final int nextActionAt;
  final int? warrantyEndDate;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.note,
    this.product,
    this.productId,
    this.source,
    this.status = 'new',
    required this.createdAt,
    required this.lastContactAt,
    required this.nextActionAt,
    this.warrantyEndDate,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      note: map['note'] as String?,
      product: map['product'] as String?,
      productId: map['product_id'] as int?,
      source: map['source'] as String?,
      status: map['status'] as String? ?? 'new',
      createdAt: map['created_at'] as int,
      lastContactAt: map['last_contact_at'] as int,
      nextActionAt: map['next_action_at'] as int,
      warrantyEndDate: map['warranty_end_date'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'note': note,
      'product': product,
      'product_id': productId,
      'source': source,
      'status': status,
      'created_at': createdAt,
      'last_contact_at': lastContactAt,
      'next_action_at': nextActionAt,
      'warranty_end_date': warrantyEndDate,
    };
  }

  Customer copyWith({
    int? id,
    String? name,
    Object? phone = _absent,
    Object? note = _absent,
    Object? product = _absent,
    Object? productId = _absent,
    Object? source = _absent,
    String? status,
    int? createdAt,
    int? lastContactAt,
    int? nextActionAt,
    Object? warrantyEndDate = _absent,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone == _absent ? this.phone : phone as String?,
      note: note == _absent ? this.note : note as String?,
      product: product == _absent ? this.product : product as String?,
      productId: productId == _absent ? this.productId : productId as int?,
      source: source == _absent ? this.source : source as String?,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastContactAt: lastContactAt ?? this.lastContactAt,
      nextActionAt: nextActionAt ?? this.nextActionAt,
      warrantyEndDate: warrantyEndDate == _absent
          ? this.warrantyEndDate
          : warrantyEndDate as int?,
    );
  }

  bool get needsAttention {
    final now = DateTime.now().millisecondsSinceEpoch;
    return nextActionAt <= now;
  }

  int? get warrantyDaysLeft {
    if (warrantyEndDate == null) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = warrantyEndDate! - now;
    if (diff <= 0) return null;
    return (diff / 86400000).ceil();
  }

  bool get warrantyExpiringSoon {
    final days = warrantyDaysLeft;
    return days != null && days <= 30;
  }

  static int followUpDelayMs(String status) {
    switch (status) {
      case 'new':
        return const Duration(days: 1).inMilliseconds;
      case 'warm':
        return const Duration(days: 2).inMilliseconds;
      case 'hot':
        return const Duration(days: 1).inMilliseconds;
      case 'closed':
        return const Duration(days: 7).inMilliseconds;
      default:
        return const Duration(days: 1).inMilliseconds;
    }
  }
}
