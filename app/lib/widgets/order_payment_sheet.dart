import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/customer.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../utils/constants.dart';
import '../utils/money.dart';
import '../utils/shipping_utils.dart';
import 'bill_preview_sheet.dart';

class OrderPaymentSheet extends StatefulWidget {
  final Order order;
  final Customer customer;
  final VoidCallback onSaved;

  const OrderPaymentSheet({
    super.key,
    required this.order,
    required this.customer,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required Order order,
    required Customer customer,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => OrderPaymentSheet(
        order: order,
        customer: customer,
        onSaved: () {
          Navigator.pop(ctx);
          onSaved();
        },
      ),
    );
  }

  @override
  State<OrderPaymentSheet> createState() => _OrderPaymentSheetState();
}

class _OrderPaymentSheetState extends State<OrderPaymentSheet> {
  final _orderService = OrderService();
  late String _paymentStatus;
  late final TextEditingController _paidCtrl;
  late final TextEditingController _shipNameCtrl;
  late final TextEditingController _shipPhoneCtrl;
  late final TextEditingController _shipAddressCtrl;
  bool _saving = false;

  bool get _readOnlyPayment => widget.order.paymentStatus == 'paid';

  Order get _previewOrder => Order(
        id: widget.order.id,
        customerId: widget.order.customerId,
        productId: widget.order.productId,
        productName: widget.order.productName,
        quantity: widget.order.quantity,
        unitSellPrice: widget.order.unitSellPrice,
        unitCost: widget.order.unitCost,
        unitCommission: widget.order.unitCommission,
        paymentStatus: _paymentStatus,
        paidAmount: _previewPaid,
        note: widget.order.note,
        shippingName: _shipNameCtrl.text.trim(),
        shippingPhone: _shipPhoneCtrl.text.trim().isEmpty ? null : _shipPhoneCtrl.text.trim(),
        shippingAddress: _shipAddressCtrl.text.trim().isEmpty ? null : _shipAddressCtrl.text.trim(),
        createdAt: widget.order.createdAt,
      );

  @override
  void initState() {
    super.initState();
    _paymentStatus = widget.order.paymentStatus;
    _paidCtrl = TextEditingController(text: formatMoneyInput(widget.order.paidAmount));
    _shipNameCtrl = TextEditingController(text: resolveShippingName(widget.order, widget.customer));
    _shipPhoneCtrl = TextEditingController(text: resolveShippingPhone(widget.order, widget.customer));
    _shipAddressCtrl = TextEditingController(text: resolveShippingAddress(widget.order, widget.customer));
  }

  double get _revenue => widget.order.revenue;

  double get _previewPaid {
    if (_paymentStatus == 'paid') return _revenue;
    if (_paymentStatus == 'unpaid') return 0;
    return parseMoneyInput(_paidCtrl.text);
  }

  double get _previewDebt => (_revenue - _previewPaid).clamp(0, double.infinity);

  Future<void> _copyShipping() async {
    await Clipboard.setData(
      ClipboardData(text: formatShippingInfo(widget.customer, _previewOrder)),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã sao chép thông tin giao hàng')),
      );
    }
  }

  void _openBill() {
    BillPreviewSheet.show(
      context,
      customer: widget.customer,
      order: _previewOrder,
    );
  }

  Future<void> _save() async {
    if (_shipNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập tên người nhận')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _orderService.updateOrderShipping(
        orderId: widget.order.id!,
        shippingName: _shipNameCtrl.text.trim(),
        shippingPhone: _shipPhoneCtrl.text.trim(),
        shippingAddress: _shipAddressCtrl.text.trim(),
      );
      if (!_readOnlyPayment) {
        await _orderService.updateOrderPayment(
          orderId: widget.order.id!,
          paymentStatus: _paymentStatus,
          paidAmount: _previewPaid,
        );
      }
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
    _paidCtrl.dispose();
    _shipNameCtrl.dispose();
    _shipPhoneCtrl.dispose();
    _shipAddressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final differs = shippingDiffersFromCustomer(_previewOrder, widget.customer);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _readOnlyPayment ? 'Chi tiết đơn' : 'Cập nhật đơn',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text('${o.productName} × ${o.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyShipping,
                    icon: const Icon(Icons.content_copy, size: 16),
                    label: const Text('Copy ship', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openBill,
                    icon: const Icon(Icons.receipt_long_outlined, size: 16),
                    label: const Text('Xem bill', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Giao hàng trên đơn',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                        if (differs)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('Khác hồ sơ',
                                style: TextStyle(fontSize: 10, color: Colors.amber.shade900)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _shipNameCtrl,
                      decoration: const InputDecoration(labelText: 'Người nhận', isDense: true),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _shipPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'SĐT', isDense: true),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _shipAddressCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ',
                        alignLabelWithHint: true,
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SummaryGrid(
              revenue: o.revenue,
              profit: o.profit,
              commission: o.commission,
              debt: o.debt,
            ),
            if (!_readOnlyPayment) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _paymentStatus,
                decoration: const InputDecoration(labelText: 'Trạng thái thanh toán'),
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
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Công nợ sau cập nhật: ${formatMoney(_previewDebt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _previewDebt > 0 ? Colors.red : Colors.grey,
                    fontWeight: _previewDebt > 0 ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ] else
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Đã thu đủ — có thể sửa thông tin giao hàng trên đơn.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            if (o.note != null && o.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Ghi chú: ${o.note}', style: const TextStyle(fontSize: 13)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final double revenue;
  final double profit;
  final double commission;
  final double debt;

  const _SummaryGrid({
    required this.revenue,
    required this.profit,
    required this.commission,
    required this.debt,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceVariant.withAlpha(120),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _Metric('Doanh thu', formatMoney(revenue), cs.primary)),
                Expanded(
                  child: _Metric('Lợi nhuận', formatMoney(profit), Colors.green.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _Metric('Hoa hồng', formatMoney(commission), cs.primary)),
                Expanded(
                  child: _Metric(
                    'Công nợ',
                    formatMoney(debt),
                    debt > 0 ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }
}
