import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../utils/constants.dart';
import '../utils/money.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _service = ProductService();
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.getAllProducts();
    if (mounted) setState(() {
      _products = list;
      _loading = false;
    });
  }

  Future<void> _openForm([Product? product]) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _ProductForm(
        product: product,
        onSave: (p) async {
          if (product?.id != null) {
            await _service.updateProduct(p.copyWith(id: product!.id, createdAt: product.createdAt));
          } else {
            await _service.addProduct(
              name: p.name,
              costPrice: p.costPrice,
              defaultSellPrice: p.defaultSellPrice,
              defaultCommission: p.defaultCommission,
              note: p.note,
              trackInventory: p.trackInventory,
              stockQuantity: p.stockQuantity,
              lowStockThreshold: p.lowStockThreshold,
            );
          }
          if (ctx.mounted) Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('Chưa có sản phẩm'),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: () => _openForm(), child: const Text('Thêm sản phẩm')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: _products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final p = _products[i];
                      return Card(
                        child: ListTile(
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            'Bán ${formatMoney(p.defaultSellPrice)} · Lời ${formatMoney(p.defaultSellPrice - p.costPrice)}'
                            '${p.trackInventory ? '\nKho: ${p.stockQuantity} (${AppConstants.stockStatusLabel(p.stockStatus)})' : ''}',
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(p.active ? 'Ẩn' : 'Kích hoạt'),
                              ),
                              const PopupMenuItem(value: 'delete', child: Text('Xoá', style: TextStyle(color: Colors.red))),
                            ],
                            onSelected: (v) async {
                              if (v == 'edit') _openForm(p);
                              if (v == 'toggle') {
                                await _service.toggleActive(p);
                                _load();
                              }
                              if (v == 'delete' && p.id != null) {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Xoá sản phẩm?'),
                                    content: Text('Xoá "${p.name}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Huỷ')),
                                      FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xoá')),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  await _service.deleteProduct(p.id!);
                                  _load();
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _ProductForm extends StatefulWidget {
  final Product? product;
  final ValueChanged<Product> onSave;

  const _ProductForm({this.product, required this.onSave});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  late final TextEditingController _name;
  late final TextEditingController _cost;
  late final TextEditingController _sell;
  late final TextEditingController _comm;
  late final TextEditingController _stock;
  late final TextEditingController _threshold;
  late bool _trackInventory;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _cost = TextEditingController(text: p != null ? formatMoneyInput(p.costPrice) : '');
    _sell = TextEditingController(text: p != null ? formatMoneyInput(p.defaultSellPrice) : '');
    _comm = TextEditingController(text: p != null ? formatMoneyInput(p.defaultCommission) : '');
    _stock = TextEditingController(text: '${p?.stockQuantity ?? 0}');
    _threshold = TextEditingController(text: '${p?.lowStockThreshold ?? 5}');
    _trackInventory = p?.trackInventory ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _cost.dispose();
    _sell.dispose();
    _comm.dispose();
    _stock.dispose();
    _threshold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Tên *')),
            const SizedBox(height: 12),
            TextField(controller: _cost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Giá vốn')),
            const SizedBox(height: 12),
            TextField(controller: _sell, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Giá bán')),
            const SizedBox(height: 12),
            TextField(controller: _comm, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Hoa hồng')),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Theo dõi tồn kho'),
              subtitle: const Text('Tắt cho dịch vụ / không quản kho', style: TextStyle(fontSize: 12)),
              value: _trackInventory,
              onChanged: (v) => setState(() => _trackInventory = v),
            ),
            if (_trackInventory) ...[
              TextField(controller: _stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tồn hiện tại')),
              const SizedBox(height: 12),
              TextField(controller: _threshold, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cảnh báo khi còn ≤')),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (_name.text.trim().isEmpty) return;
                widget.onSave(Product(
                  name: _name.text.trim(),
                  costPrice: parseMoneyInput(_cost.text),
                  defaultSellPrice: parseMoneyInput(_sell.text),
                  defaultCommission: parseMoneyInput(_comm.text),
                  trackInventory: _trackInventory,
                  stockQuantity: int.tryParse(_stock.text) ?? 0,
                  lowStockThreshold: int.tryParse(_threshold.text) ?? 5,
                  active: widget.product?.active ?? true,
                  createdAt: widget.product?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
                ));
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}
