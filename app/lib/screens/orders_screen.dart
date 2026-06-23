import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../services/customer_service.dart';
import '../services/order_service.dart';
import '../utils/constants.dart';
import '../utils/money.dart';
import '../widgets/order_form_sheet.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _orderService = OrderService();
  final _customerService = CustomerService();
  List<Order> _orders = [];
  Map<int, String> _customerNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await _orderService.getAllOrders();
    final customers = await _customerService.getAllCustomers();
    if (mounted) {
      setState(() {
        _orders = orders;
        _customerNames = {for (final c in customers) c.id!: c.name};
        _loading = false;
      });
    }
  }

  Future<void> _newOrder() async {
    final customers = await _customerService.getAllCustomers();
    if (!mounted) return;
    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm khách trước khi ghi đơn')),
      );
      return;
    }
    Customer? selected = customers.first;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn khách'),
        content: DropdownButtonFormField<Customer>(
          value: selected,
          items: customers
              .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
              .toList(),
          onChanged: (c) => selected = c,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, selected),
            child: const Text('Tiếp'),
          ),
        ],
      ),
    ).then((c) async {
      if (c is Customer && mounted) {
        await OrderFormSheet.show(context, c);
        _load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn hàng')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newOrder,
        icon: const Icon(Icons.receipt_long),
        label: const Text('Ghi đơn'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_outlined, size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('Chưa có đơn hàng'),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _newOrder, child: const Text('Ghi đơn đầu tiên')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final o = _orders[i];
                      return Card(
                        child: ListTile(
                          title: Text(
                            '${o.productName} × ${o.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${_customerNames[o.customerId] ?? 'Khách #${o.customerId}'}\n'
                            '${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(o.createdAt))}',
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formatMoney(o.revenue),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                AppConstants.paymentLabels[o.paymentStatus] ?? o.paymentStatus,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
