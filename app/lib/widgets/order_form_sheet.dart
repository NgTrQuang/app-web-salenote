import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../utils/constants.dart';
import '../utils/money.dart';
import 'product_picker_field.dart';

class OrderFormSheet extends StatefulWidget {
  final Customer customer;
  final VoidCallback onSaved;

  const OrderFormSheet({
    super.key,
    required this.customer,
    required this.onSaved,
  });

  static Future<void> show(BuildContext context, Customer customer) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => OrderFormSheet(
        customer: customer,
        onSaved: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  State<OrderFormSheet> createState() => _OrderFormSheetState();
}

class _OrderFormSheetState extends State<OrderFormSheet> {
  final _orderService = OrderService();
  final _productService = ProductService();
  List<Product> _products = [];
  int? _productId;
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _sellCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _commCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _shipNameCtrl = TextEditingController();
  final _shipPhoneCtrl = TextEditingController();
  final _shipAddressCtrl = TextEditingController();
  String _paymentStatus = 'paid';
  bool _markClosed = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _shipNameCtrl.text = widget.customer.name;
    _shipPhoneCtrl.text = widget.customer.phone ?? '';
    _shipAddressCtrl.text = widget.customer.address ?? '';
    _loadProducts();
    if (widget.customer.product != null) {
      _nameCtrl.text = widget.customer.product!;
    }
  }

  Future<void> _loadProducts() async {
    final list = await _productService.getAllProducts(activeOnly: true);
    if (!mounted) return;
    setState(() => _products = list);
    if (widget.customer.productId != null) {
      _selectProduct(widget.customer.productId);
    }
  }

  void _selectProduct(int? id) {
    if (id == null) {
      setState(() => _productId = null);
      return;
    }
    final p = _products.firstWhere((x) => x.id == id);
    final d = _productService.applyDefaults(p);
    setState(() {
      _productId = id;
      _nameCtrl.text = d['product_name'] as String;
      _sellCtrl.text = formatMoneyInput(d['unit_sell_price'] as double);
      _costCtrl.text = formatMoneyInput(d['unit_cost'] as double);
      _commCtrl.text = formatMoneyInput(d['unit_commission'] as double);
    });
  }

  int get _qty => int.tryParse(_qtyCtrl.text) ?? 1;
  double get _sell => parseMoneyInput(_sellCtrl.text);
  double get _cost => parseMoneyInput(_costCtrl.text);
  double get _comm => parseMoneyInput(_commCtrl.text);
  double get _revenue => _qty * _sell;
  double get _profit => _qty * (_sell - _cost);
  double get _commission => _qty * _comm;
  double get _paid =>
      _paymentStatus == 'paid'
          ? _revenue
          : _paymentStatus == 'unpaid'
              ? 0
              : parseMoneyInput(_paidCtrl.text);
  double get _debt => (_revenue - _paid).clamp(0, double.infinity);

  Product? get _selectedProduct {
    if (_productId == null) return null;
    try {
      return _products.firstWhere((p) => p.id == _productId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập tên sản phẩm')),
      );
      return;
    }
    if (_sell <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giá bán phải lớn hơn 0')),
      );
      return;
    }
    final p = _selectedProduct;
    if (p != null && p.trackInventory && _qty > p.stockQuantity) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Vượt tồn kho'),
          content: Text(
            'Tồn "${p.name}" còn ${p.stockQuantity}, bạn ghi $_qty. Vẫn lưu?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _saving = true);
    try {
      await _orderService.createOrder(
        customerId: widget.customer.id!,
        productId: _productId,
        productName: _nameCtrl.text.trim(),
        quantity: _qty,
        unitSellPrice: _sell,
        unitCost: _cost,
        unitCommission: _comm,
        paymentStatus: _paymentStatus,
        paidAmount: _paymentStatus == 'partial'
            ? parseMoneyInput(_paidCtrl.text)
            : _paymentStatus == 'unpaid'
                ? 0
                : _revenue,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        shippingName: _shipNameCtrl.text.trim(),
        shippingPhone: _shipPhoneCtrl.text.trim().isEmpty ? null : _shipPhoneCtrl.text.trim(),
        shippingAddress: _shipAddressCtrl.text.trim().isEmpty ? null : _shipAddressCtrl.text.trim(),
        markCustomerClosed: _markClosed,
      );
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _sellCtrl.dispose();
    _costCtrl.dispose();
    _commCtrl.dispose();
    _paidCtrl.dispose();
    _noteCtrl.dispose();
    _shipNameCtrl.dispose();
    _shipPhoneCtrl.dispose();
    _shipAddressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final p = _selectedProduct;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ghi đơn — ${widget.customer.name}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Thông tin giao hàng',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      'Mặc định từ hồ sơ khách — sửa nếu giao địa chỉ khác. Lưu cố định trên đơn.',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _shipNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Người nhận',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _shipPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'SĐT giao hàng', isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _shipAddressCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ giao hàng',
                        alignLabelWithHint: true,
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_products.isNotEmpty) ...[
              ProductPickerField(
                products: _products,
                value: _productId,
                onChanged: _selectProduct,
              ),
              if (p != null && p.trackInventory)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Tồn: ${p.stockQuantity} — ${AppConstants.stockStatusLabel(p.stockStatus)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: p.stockStatus == 'out' || _qty > p.stockQuantity
                          ? Colors.red
                          : p.stockStatus == 'low'
                              ? Colors.orange
                              : Colors.grey,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên sản phẩm *'),
              onChanged: (_) => setState(() => _productId = null),
              scrollPadding: const EdgeInsets.all(20),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'SL'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _sellCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Giá bán'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _costCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Giá vốn'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Hoa hồng'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _paymentStatus,
              decoration: const InputDecoration(labelText: 'Thanh toán'),
              items: AppConstants.paymentLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _paymentStatus = v ?? 'paid'),
            ),
            if (_paymentStatus == 'partial') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _paidCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Đã thu'),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Ghi chú đơn'),
              maxLines: 2,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _markClosed,
              onChanged: (v) => setState(() => _markClosed = v ?? true),
              title: const Text('Đánh dấu khách "Đã chốt"', style: TextStyle(fontSize: 14)),
            ),
            Card(
              color: Theme.of(context).colorScheme.surfaceVariant.withAlpha(120),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _SumItem('Doanh thu', formatMoney(_revenue))),
                        Expanded(child: _SumItem('Lợi nhuận', formatMoney(_profit), Colors.green.shade700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _SumItem('Hoa hồng', formatMoney(_commission))),
                        Expanded(
                          child: _SumItem(
                            'Công nợ',
                            formatMoney(_debt),
                            _debt > 0 ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu đơn hàng'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SumItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _SumItem(this.label, this.value, [this.color]);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
