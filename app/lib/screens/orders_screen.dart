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
import '../widgets/infinite_scroll.dart';
import 'add_order_screen.dart';

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
  bool _loadingMore = false;
  int _page = 1;
  int _total = 0;
  final _scrollCtrl = ScrollController();
  final _loadGate = LoadMoreGate();

  bool get _hasMore => _orders.length < _total;

  @override
  void initState() {
    super.initState();
    bindScrollLoadMore(
      _scrollCtrl,
      hasMore: () => _hasMore && !_loading && !_loadingMore,
      onLoadMore: _loadMore,
      gate: _loadGate,
    );
    _load();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _page = 1;
    setState(() => _loading = true);
    final orders = await _orderService.getOrdersPaged(_page, kDefaultPageSize);
    final total = await _orderService.countOrders();
    final ids = orders.map((o) => o.customerId).toSet().toList();
    final customers = await _customerService.getCustomersByIds(ids);
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _total = total;
      _customers = {for (final c in customers) c.id!: c};
      _loading = false;
    });
    ensureScrollFill(
      controller: _scrollCtrl,
      hasMore: _hasMore,
      onLoadMore: _loadMore,
    );
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loading || _loadingMore) return;
    setState(() => _loadingMore = true);
    final nextPage = _page + 1;
    final orders =
        await _orderService.getOrdersPaged(nextPage, kDefaultPageSize);
    final ids = orders.map((o) => o.customerId).toSet().toList();
    final customers = await _customerService.getCustomersByIds(ids);
    if (!mounted) return;
    setState(() {
      _page = nextPage;
      final existing = _orders.map((o) => o.id).toSet();
      _orders.addAll(orders.where((o) => !existing.contains(o.id)));
      for (final c in customers) {
        _customers[c.id!] = c;
      }
      _loadingMore = false;
    });
    ensureScrollFill(
      controller: _scrollCtrl,
      hasMore: _hasMore,
      onLoadMore: _loadMore,
    );
  }

  Future<void> _newOrder() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddOrderScreen()),
    );
    _load();
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: _orders.length + 1,
                    separatorBuilder: (_, i) => i < _orders.length - 1
                        ? const SizedBox(height: 8)
                        : const SizedBox.shrink(),
                    itemBuilder: (ctx, i) {
                      if (i >= _orders.length) {
                        return LoadMoreFooter(
                          hasMore: _hasMore,
                          loading: _loadingMore,
                          visible: _orders.length,
                          total: _total,
                        );
                      }
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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_customers[o.customerId]?.name ?? 'Khách #${o.customerId}'} · '
                                  '${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(o.createdAt))}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    _Chip('DT', formatMoney(o.revenue)),
                                    _Chip('Lời', formatMoney(o.profit),
                                        Colors.green.shade700),
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
                                  AppConstants.paymentLabels[o.paymentStatus] ??
                                      o.paymentStatus,
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
