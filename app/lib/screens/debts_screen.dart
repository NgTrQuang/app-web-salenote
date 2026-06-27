import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/debt_service.dart';
import '../utils/money.dart';
import '../widgets/app_drawer.dart';
import '../widgets/infinite_scroll.dart';
import 'customer_detail_screen.dart';
import '../services/customer_service.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final _service = DebtService();
  List<DebtEntry> _debts = [];
  bool _loading = true;
  final _visible = ClientVisibleList();
  final _scrollCtrl = ScrollController();
  final _loadGate = LoadMoreGate();

  List<DebtEntry> get _visibleItems => _visible.slice(_debts);

  @override
  void initState() {
    super.initState();
    bindScrollLoadMore(
      _scrollCtrl,
      hasMore: () => _visible.hasMore(_debts),
      onLoadMore: () {
        setState(() => _visible.loadMore(_debts));
        ensureScrollFill(
          controller: _scrollCtrl,
          hasMore: _visible.hasMore(_debts),
          onLoadMore: () => setState(() => _visible.loadMore(_debts)),
        );
      },
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
    setState(() => _loading = true);
    final list = await _service.getDebtList();
    if (!mounted) return;
    setState(() {
      _debts = list;
      _visible.reset();
      _loading = false;
    });
    ensureScrollFill(
      controller: _scrollCtrl,
      hasMore: _visible.hasMore(_debts),
      onLoadMore: () => setState(() => _visible.loadMore(_debts)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _debts.fold(0.0, (s, e) => s + e.totalDebt);

    return Scaffold(
      drawer: const AppDrawer(current: 'debts'),
      appBar: AppBar(
        title: const Text('Ai nợ tôi',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _debts.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text('Không có công nợ — tuyệt vời!'),
                        ),
                      ],
                    )
                  : ListView(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        Card(
                          color: Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tổng công nợ',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red.shade700)),
                                Text(formatMoney(total),
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade800)),
                                Text('${_debts.length} khách còn nợ',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red.shade600)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._visibleItems.map((d) => Card(
                              child: ListTile(
                                title: Text(d.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text([
                                  if (d.phone != null) d.phone!,
                                  '${d.orderCount} đơn còn nợ',
                                ].join(' · ')),
                                trailing: Text(
                                  formatMoney(d.totalDebt),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                onTap: () async {
                                  final c = await CustomerService()
                                      .getCustomer(d.customerId);
                                  if (c != null && context.mounted) {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CustomerDetailScreen(customer: c),
                                      ),
                                    );
                                    _load();
                                  }
                                },
                                onLongPress: () async {
                                  final text =
                                      '${d.name}${d.phone != null ? ' (${d.phone})' : ''}: còn nợ ${formatMoney(d.totalDebt)}';
                                  await Clipboard.setData(
                                      ClipboardData(text: text));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Đã copy: $text')),
                                    );
                                  }
                                },
                              ),
                            )),
                        LoadMoreFooter(
                          hasMore: _visible.hasMore(_debts),
                          loading: false,
                          visible: _visibleItems.length,
                          total: _debts.length,
                        ),
                      ],
                    ),
            ),
    );
  }
}
