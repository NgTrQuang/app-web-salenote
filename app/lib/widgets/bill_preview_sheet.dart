import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/customer.dart';
import '../models/order.dart';
import '../services/bill_service.dart';
import '../utils/constants.dart';
import '../utils/money.dart';

class BillPreviewSheet extends StatefulWidget {
  final Customer customer;
  final Order order;

  const BillPreviewSheet({
    super.key,
    required this.customer,
    required this.order,
  });

  static Future<void> show(
    BuildContext context, {
    required Customer customer,
    required Order order,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => BillPreviewSheet(customer: customer, order: order),
      ),
    );
  }

  @override
  State<BillPreviewSheet> createState() => _BillPreviewSheetState();
}

class _BillPreviewSheetState extends State<BillPreviewSheet> {
  final _billService = BillService();
  BillData? _data;
  bool _loading = true;
  bool _busy = false;
  String? _msg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _billService.buildBillData(widget.customer, widget.order);
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _msg = 'Không tải được dữ liệu bill';
        });
      }
    }
  }

  Future<Uint8List> _buildPdfBytes() async {
    if (_data == null) throw StateError('Bill chưa sẵn sàng');
    return _billService.generatePdf(_data!);
  }

  Future<void> _share() async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      final bytes = await _buildPdfBytes();
      final filename = _billService.billFilename(widget.order);
      await Printing.sharePdf(bytes: bytes, filename: filename);
      if (mounted) setState(() => _msg = 'Đã mở chia sẻ');
    } catch (e) {
      if (mounted) setState(() => _msg = 'Không thể chia sẻ PDF');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _savePdf() async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      final bytes = await _buildPdfBytes();
      final filename = _billService.billFilename(widget.order);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(file.path)], subject: filename, text: 'Phiếu bán hàng');
      if (mounted) setState(() => _msg = 'Chọn Lưu vào Files / Drive để tải PDF');
    } catch (e) {
      if (mounted) setState(() => _msg = 'Không thể tạo PDF');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Xem trước bill',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _data == null
                    ? Center(child: Text(_msg ?? 'Không có dữ liệu bill'))
                    : SingleChildScrollView(
                        child: _BillPreviewContent(data: _data!),
                      ),
          ),
          if (_msg != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _msg!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy || _data == null ? null : _share,
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Chia sẻ'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy || _data == null ? null : _savePdf,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Tải PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillPreviewContent extends StatelessWidget {
  final BillData data;

  const _BillPreviewContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final order = data.order;
    final shop = data.shop;
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final createdLabel = dateFmt.format(DateTime.fromMillisecondsSinceEpoch(order.createdAt));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            shop.shopName.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          if (shop.shopPhone.isNotEmpty)
            Text('SĐT: ${shop.shopPhone}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('PHIẾU BÁN HÀNG', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
          Text('Mã đơn #${order.id} · $createdLabel', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const Divider(height: 24),
          _line('Khách hàng', data.shippingName, bold: true),
          if (data.shippingPhone.isNotEmpty) _line('SĐT', data.shippingPhone),
          if (data.shippingAddress.isNotEmpty) _line('Địa chỉ', data.shippingAddress),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: const [
                  _Th('Sản phẩm'),
                  _Th('SL', align: TextAlign.right),
                  _Th('Đơn giá', align: TextAlign.right),
                  _Th('Thành tiền', align: TextAlign.right),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: const EdgeInsets.all(6), child: Text(order.productName, style: const TextStyle(fontSize: 12, color: Colors.black87))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${order.quantity}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: Colors.black87))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(formatMoney(order.unitSellPrice), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: Colors.black87))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(formatMoney(data.revenue), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          _total('Tổng cộng', formatMoney(data.revenue), bold: true),
          _total('Đã thu', formatMoney(order.paidAmount)),
          if (data.debt > 0) _total('Còn nợ', formatMoney(data.debt), color: Colors.red.shade700, bold: true),
          _total('Thanh toán', AppConstants.paymentLabels[order.paymentStatus] ?? order.paymentStatus),
          if (order.note != null && order.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Ghi chú: ${order.note}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
          const SizedBox(height: 16),
          const Text(
            'Phiếu bán hàng — không phải hóa đơn GTGT. Cảm ơn quý khách!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(color: Colors.grey)),
            TextSpan(text: value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _total(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color ?? Colors.black87)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}

class _Th extends StatelessWidget {
  final String text;
  final TextAlign align;

  const _Th(this.text, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(text, textAlign: align, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }
}
