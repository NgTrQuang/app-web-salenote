import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../services/order_service.dart';
import '../utils/constants.dart';
import '../utils/money.dart';
import '../widgets/app_drawer.dart';
import '../widgets/order_payment_sheet.dart';
import 'add_order_screen.dart';

const _pageSize = 20;

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _orderService = OrderService();
  final _customerService = CustomerService();
  List<Order> _orders = [];
  Map<int, Customer> _customers = {};
  bool _loading = true;
  int _page = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int? page}) async {
    if (page != null) _page = page;
    setState(() => _loading = true);
    final orders = await _orderService.getOrdersPaged(_page, _pageSize);
    final total = await _orderService.countOrders();
    final customers = await _customerService.getAllCustomers();
    if (mounted) {
      setState(() {
        _orders = orders;
        _total = total;
        _customers = {for (final c in customers) c.id!: c};
        _loading = false;
      });
    }
  }

  int get _totalPages => (_total / _pageSize).ceil().clamp(1, 999999);

  Future<void> _newOrder() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddOrderScreen()),
    );
    _load(page: 1);
  }

  void _openOrder(Order o) {
    final customer = _customers[o.customerId];
    if (customer == null) return;
    OrderPaymentSheet.show(
      context,
      order: o,
      customer: customer,
      onSaved: () => _load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(current: 'orders'),
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
                      Icon(Icons.receipt_outlined,
                          size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('Chưa có đơn hàng'),
                      const SizedBox(height: 16),
                      FilledButton(
                          onPressed: _newOrder,
                          child: const Text('Ghi đơn đầu tiên')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _load(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          itemCount: _orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final o = _orders[i];
                            return Card(
                              child: InkWell(
                                onTap: () => _openOrder(o),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${o.productName} × ${o.quantity}',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_customers[o.customerId]?.name ?? 'Khách #${o.customerId}'} · '
                                        '${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(o.createdAt))}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 4,
                                        children: [
                                          _Chip('DT', formatMoney(o.revenue)),
                                          _Chip('Lời', formatMoney(o.profit), Colors.green.shade700),
                                          _Chip('HH', formatMoney(o.commission)),
                                          _Chip(
                                            'Nợ',
                                            formatMoney(o.debt),
                                            o.debt > 0 ? Colors.red : Colors.grey,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppConstants.paymentLabels[o.paymentStatus] ?? o.paymentStatus,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: o.paymentStatus == 'paid'
                                              ? Colors.green
                                              : o.paymentStatus == 'partial'
                                                  ? Colors.orange
                                                  : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (_totalPages > 1)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_page * _pageSize - _pageSize + 1}–${(_page * _pageSize).clamp(0, _total)} / $_total'),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _page > 1 ? () => _load(page: _page - 1) : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Text('$_page / $_totalPages'),
                                IconButton(
                                  onPressed: _page < _totalPages ? () => _load(page: _page + 1) : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _Chip(this.label, this.value, [this.color]);

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
    );
  }
}
