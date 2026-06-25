import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/order_form_sheet.dart';

const _pageSize = 20;

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
  String _query = '';
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCustomer;
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await _customerService.getAllCustomers();
    if (!mounted) return;
    setState(() {
      _customers = list;
      _loading = false;
      if (_selected == null && list.isNotEmpty) {
        _selected = list.first;
      }
    });
  }

  List<Customer> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _customers;
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            (c.phone?.toLowerCase().contains(q) ?? false) ||
            (c.product?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  int get _totalPages => (_filtered.length / _pageSize).ceil().clamp(1, 999999);

  List<Customer> get _pageItems {
    final safePage = _page.clamp(1, _totalPages);
    final start = (safePage - 1) * _pageSize;
    return _filtered.skip(start).take(_pageSize).toList();
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
    final pageItems = _pageItems;
    final totalPages = _totalPages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi đơn mới', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      drawer: const AppDrawer(current: 'orders'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _customers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 56, color: Colors.grey.shade300),
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
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Tìm tên, SĐT, sản phẩm...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (v) => setState(() {
                              _query = v;
                              _page = 1;
                            }),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ...pageItems.map((c) {
                            final sel = _selected?.id == c.id;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: sel
                                  ? Theme.of(context).colorScheme.primaryContainer.withAlpha(80)
                                  : null,
                              child: ListTile(
                                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  [c.phone, c.product]
                                      .where((x) => x != null && x!.isNotEmpty)
                                      .join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: sel ? const Icon(Icons.check_circle, color: Colors.green) : null,
                                onTap: () => setState(() => _selected = c),
                              ),
                            );
                          }),
                          if (totalPages > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: _page > 1 ? () => setState(() => _page--) : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Text('$_page / $totalPages'),
                                IconButton(
                                  onPressed: _page < totalPages ? () => setState(() => _page++) : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
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
