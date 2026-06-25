import '../models/customer.dart';
import '../models/order.dart';
import 'money.dart';

class ShippingSnapshot {
  final String shippingName;
  final String? shippingPhone;
  final String? shippingAddress;

  const ShippingSnapshot({
    required this.shippingName,
    this.shippingPhone,
    this.shippingAddress,
  });
}

String resolveShippingName(Order order, Customer customer) {
  final v = order.shippingName?.trim();
  if (v != null && v.isNotEmpty) return v;
  return customer.name.trim();
}

String resolveShippingPhone(Order order, Customer customer) {
  final v = order.shippingPhone?.trim();
  if (v != null && v.isNotEmpty) return v;
  return customer.phone?.trim() ?? '';
}

String resolveShippingAddress(Order order, Customer customer) {
  final v = order.shippingAddress?.trim();
  if (v != null && v.isNotEmpty) return v;
  return customer.address?.trim() ?? '';
}

ShippingSnapshot snapshotShipping(
  Customer customer, {
  String? shippingName,
  String? shippingPhone,
  String? shippingAddress,
}) {
  return ShippingSnapshot(
    shippingName: shippingName?.trim().isNotEmpty == true
        ? shippingName!.trim()
        : customer.name.trim(),
    shippingPhone: shippingPhone?.trim().isNotEmpty == true
        ? shippingPhone!.trim()
        : customer.phone?.trim(),
    shippingAddress: shippingAddress?.trim().isNotEmpty == true
        ? shippingAddress!.trim()
        : customer.address?.trim(),
  );
}

bool shippingDiffersFromCustomer(Order order, Customer customer) {
  return resolveShippingName(order, customer) != customer.name.trim() ||
      resolveShippingPhone(order, customer) != (customer.phone?.trim() ?? '') ||
      resolveShippingAddress(order, customer) != (customer.address?.trim() ?? '');
}

String formatShippingInfo(Customer customer, Order order) {
  final name = resolveShippingName(order, customer);
  final phone = resolveShippingPhone(order, customer);
  final address = resolveShippingAddress(order, customer);
  final lines = <String>[
    'Người nhận: $name',
    if (phone.isNotEmpty) 'SĐT: $phone',
    if (address.isNotEmpty) 'Địa chỉ: $address',
    'Sản phẩm: ${order.productName} × ${order.quantity}',
    'Thành tiền: ${formatMoney(order.revenue)}',
    if (order.note != null && order.note!.isNotEmpty) 'Ghi chú đơn: ${order.note}',
  ];
  return lines.join('\n');
}

String formatAddressOnly(Customer customer, [Order? order]) {
  if (order != null) return resolveShippingAddress(order, customer);
  return customer.address?.trim() ?? '';
}
