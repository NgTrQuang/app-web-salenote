import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/order_form_sheet.dart';
import '../widgets/infinite_scroll.dart';

/// Tương đương web /orders/new
class AddOrderScreen extends StatefulWidget {
  final Customer? initialCustomer;

  const AddOrderScreen({super.key, this.initialCustomer});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _customerService = CustomerService();
  final _searchCtrl = TextEditingController();
  List<Customer> _customers = [];
  Customer? _selected;
  bool _loading = true;
  bool _loadingMore = false;
  String _query = '';
  int _page = 1;
  int _total = 0;
  final _scrollCtrl = ScrollController();
  final _loadGate = LoadMoreGate();

  bool get _hasMore => _customers.length < _total;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCustomer;
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
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _page = 1;
    setState(() => _loading = true);
    final list = await _customerService.getCustomersPaged(
      page: _page,
      pageSize: kDefaultPageSize,
      query: _query,
    );
    final total = await _customerService.countCustomers(query: _query);
    if (!mounted) return;
    setState(() {
      _customers = list;
      _total = total;
      _loading = false;
      if (_selected == null && _customers.isNotEmpty) {
        _selected = _customers.first;
      }
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
    final list = await _customerService.getCustomersPaged(
      page: nextPage,
      pageSize: kDefaultPageSize,
      query: _query,
    );
    if (!mounted) return;
    setState(() {
      _page = nextPage;
      final existing = _customers.map((c) => c.id).toSet();
      _customers.addAll(list.where((c) => !existing.contains(c.id)));
      _loadingMore = false;
    });
    ensureScrollFill(
      controller: _scrollCtrl,
      hasMore: _hasMore,
      onLoadMore: _loadMore,
    );
  }

  Future<void> _openForm() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm khách trước khi ghi đơn')),
      );
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => OrderFormSheet(
        customer: _selected!,
        onSaved: () {
          Navigator.pop(ctx);
          Navigator.pop(context, true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi đơn mới',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      drawer: const AppDrawer(current: 'orders'),
      body: _loading && _customers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _total == 0 && !_loading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('Chưa có khách hàng'),
                        const SizedBox(height: 8),
                        const Text('Thêm khách trước khi ghi đơn',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Chọn khách hàng',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Tìm tên, SĐT, sản phẩm...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (v) {
                              _query = v;
                              _load();
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        children: [
                          ..._customers.map((c) {
                            final sel = _selected?.id == c.id;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: sel
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withAlpha(80)
                                  : null,
                              child: ListTile(
                                title: Text(c.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  [c.phone, c.product]
                                      .where((x) =>
                                          x != null && x.isNotEmpty)
                                      .join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: sel
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : null,
                                onTap: () => setState(() => _selected = c),
                              ),
                            );
                          }),
                          LoadMoreFooter(
                            hasMore: _hasMore,
                            loading: _loadingMore,
                            visible: _customers.length,
                            total: _total,
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: _openForm,
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('Tiếp tục — nhập đơn'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
