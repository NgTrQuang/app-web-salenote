import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/customer.dart';
import '../models/order.dart';
import '../utils/constants.dart';
import '../utils/money.dart';
import '../utils/shipping_utils.dart';
import 'shop_settings_service.dart';

class BillData {
  final ShopSettings shop;
  final Order order;
  final Customer customer;
  final int issuedAt;
  final String shippingName;
  final String shippingPhone;
  final String shippingAddress;

  BillData({
    required this.shop,
    required this.order,
    required this.customer,
    required this.issuedAt,
    required this.shippingName,
    required this.shippingPhone,
    required this.shippingAddress,
  });

  double get revenue => order.revenue;
  double get debt => order.debt;
}

class BillService {
  final ShopSettingsService _shopSettings = ShopSettingsService();
  pw.Font? _fontRegular;
  pw.Font? _fontBold;

  Future<void> _ensureFonts() async {
    if (_fontRegular != null && _fontBold != null) return;
    final regularData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    _fontRegular = pw.Font.ttf(regularData);
    _fontBold = pw.Font.ttf(boldData);
  }

  Future<BillData> buildBillData(Customer customer, Order order) async {
    final shop = await _shopSettings.getSettings();
    return BillData(
      shop: shop,
      order: order,
      customer: customer,
      issuedAt: DateTime.now().millisecondsSinceEpoch,
      shippingName: resolveShippingName(order, customer),
      shippingPhone: resolveShippingPhone(order, customer),
      shippingAddress: resolveShippingAddress(order, customer),
    );
  }

  String billFilename(Order order) {
    final d = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
    final date = DateFormat('yyyyMMdd').format(d);
    return 'bill-${order.id ?? 'new'}-$date.pdf';
  }

  Future<Uint8List> generatePdf(BillData data) async {
    await _ensureFonts();
    final font = _fontRegular!;
    final fontBold = _fontBold!;
    final order = data.order;
    final shop = data.shop;
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final createdLabel = dateFmt.format(DateTime.fromMillisecondsSinceEpoch(order.createdAt));

    pw.Widget labelValue(String label, String value, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(text: '$label ', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
              pw.TextSpan(
                text: value,
                style: pw.TextStyle(font: bold ? fontBold : font, fontSize: 10),
              ),
            ],
          ),
        ),
      );
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      shop.shopName.toUpperCase(),
                      style: pw.TextStyle(font: fontBold, fontSize: 16),
                      textAlign: pw.TextAlign.center,
                    ),
                    if (shop.shopPhone.isNotEmpty)
                      pw.Text('SĐT: ${shop.shopPhone}', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.SizedBox(height: 8),
                    pw.Text('PHIẾU BÁN HÀNG', style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.grey700)),
                    pw.Text(
                      'Mã đơn #${order.id} · $createdLabel',
                      style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              labelValue('Khách hàng:', data.shippingName, bold: true),
              if (data.shippingPhone.isNotEmpty) labelValue('SĐT:', data.shippingPhone),
              if (data.shippingAddress.isNotEmpty) labelValue('Địa chỉ:', data.shippingAddress),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _cell('Sản phẩm', fontBold),
                      _cell('SL', fontBold, align: pw.TextAlign.right),
                      _cell('Đơn giá', fontBold, align: pw.TextAlign.right),
                      _cell('Thành tiền', fontBold, align: pw.TextAlign.right),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _cell(order.productName, font),
                      _cell('${order.quantity}', font, align: pw.TextAlign.right),
                      _cell(formatMoney(order.unitSellPrice), font, align: pw.TextAlign.right),
                      _cell(formatMoney(data.revenue), fontBold, align: pw.TextAlign.right),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColors.grey400),
              _totalRow('Tổng cộng', formatMoney(data.revenue), fontBold),
              _totalRow('Đã thu', formatMoney(order.paidAmount), font),
              if (data.debt > 0)
                _totalRow('Còn nợ', formatMoney(data.debt), fontBold, color: PdfColors.red700),
              _totalRow(
                'Thanh toán',
                AppConstants.paymentLabels[order.paymentStatus] ?? order.paymentStatus,
                font,
              ),
              if (order.note != null && order.note!.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text('Ghi chú: ${order.note}', style: pw.TextStyle(font: font, fontSize: 10)),
              ],
              pw.Spacer(),
              pw.Text(
                'Phiếu bán hàng — không phải hóa đơn GTGT. Cảm ơn quý khách!',
                style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  pw.Widget _cell(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 10), textAlign: align),
    );
  }

  pw.Widget _totalRow(String label, String value, pw.Font font, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10, color: color)),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: 10, color: color)),
        ],
      ),
    );
  }
}
