import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';
import '../models/order.dart';
import '../utils/constants.dart';

class BackupService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<String> exportBackup() async {
    final data = await _db.exportAll();
    final json = const JsonEncoder.withIndent('  ').convert(data);

    Directory dir;
    if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectory()) ??
          await getApplicationDocumentsDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
    final file = File('${dir.path}/salenote_backup_$stamp.json');
    await file.writeAsString(json, flush: true);
    return file.path;
  }

  Future<void> shareBackup() async {
    final path = await exportBackup();
    final today = DateFormat('yyyyMMdd').format(DateTime.now());
    await _db.setSetting(AppConstants.keyLastBackupDate, today);
    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/json')],
      text:
          'Salenote – Sao lưu dữ liệu ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
    );
  }

  Future<void> shareCsv() async {
    final data = await _db.exportAll();
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());

    final customerCsv = StringBuffer();
    customerCsv.writeln(
        'Tên,SĐT,Nguồn,Sản phẩm,Trạng thái,Lần liên hệ cuối,Ngày nhắc tiếp,Ghi chú,Hết bảo hành');
    for (final row in (data['customers'] as List)) {
      final r = row as Map<String, dynamic>;
      customerCsv.writeln([
        _csvCell(r['name']?.toString()),
        _csvCell(r['phone']?.toString()),
        _csvCell(AppConstants.sourceLabel(r['source']?.toString())),
        _csvCell(r['product']?.toString()),
        _csvCell(_statusLabel(r['status']?.toString())),
        _csvCell(_msToDate(r['last_contact_at'])),
        _csvCell(_msToDate(r['next_action_at'])),
        _csvCell(r['note']?.toString()),
        _csvCell(_msToDate(r['warranty_end_date'])),
      ].join(','));
    }
    final customerFile = File('${dir.path}/salenote_customers_$stamp.csv');
    await customerFile.writeAsString('\uFEFF${customerCsv.toString()}', flush: true);

    final interactionCsv = StringBuffer();
    interactionCsv.writeln('Khách,Nội dung,Thời gian');
    final customers = data['customers'] as List;
    final idToName = <int, String>{
      for (final r in customers)
        (r as Map)['id'] as int: (r['name'] ?? '') as String,
    };
    for (final row in (data['interactions'] as List)) {
      final r = row as Map<String, dynamic>;
      final cid = r['customer_id'] as int?;
      interactionCsv.writeln([
        _csvCell(idToName[cid] ?? ''),
        _csvCell(r['content']?.toString()),
        _csvCell(_msToDate(r['created_at'])),
      ].join(','));
    }
    final interactionFile =
        File('${dir.path}/salenote_interactions_$stamp.csv');
    await interactionFile.writeAsString(
        '\uFEFF${interactionCsv.toString()}',
        flush: true);

    final files = <XFile>[
      XFile(customerFile.path, mimeType: 'text/csv'),
      XFile(interactionFile.path, mimeType: 'text/csv'),
    ];

    final orders = data['orders'] as List? ?? [];
    if (orders.isNotEmpty) {
      final orderCsv = StringBuffer();
      orderCsv.writeln(
          'Khách,Sản phẩm,SL,Doanh thu,Lợi nhuận,Hoa hồng,Công nợ,TT thanh toán,Ngày');
      for (final row in orders) {
        final r = row as Map<String, dynamic>;
        final o = Order.fromMap(r);
        orderCsv.writeln([
          _csvCell(idToName[o.customerId] ?? ''),
          _csvCell(o.productName),
          _csvCell('${o.quantity}'),
          _csvCell('${o.revenue.round()}'),
          _csvCell('${o.profit.round()}'),
          _csvCell('${o.commission.round()}'),
          _csvCell('${o.debt.round()}'),
          _csvCell(o.paymentStatus),
          _csvCell(_msToDate(o.createdAt)),
        ].join(','));
      }
      final orderFile = File('${dir.path}/salenote_orders_$stamp.csv');
      await orderFile.writeAsString('\uFEFF${orderCsv.toString()}', flush: true);
      files.add(XFile(orderFile.path, mimeType: 'text/csv'));
    }

    await Share.shareXFiles(
      files,
      text: 'Salenote – Xuất CSV ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
    );
  }

  Future<String?> getLastBackupDate() async {
    final raw = await _db.getSetting(AppConstants.keyLastBackupDate);
    if (raw == null || raw.isEmpty) return null;
    try {
      final dt = DateFormat('yyyyMMdd').parse(raw);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return null;
    }
  }

  String _csvCell(String? v) {
    if (v == null || v.isEmpty) return '';
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  String _msToDate(dynamic ms) {
    if (ms == null) return '';
    try {
      return DateFormat('dd/MM/yyyy')
          .format(DateTime.fromMillisecondsSinceEpoch(ms as int));
    } catch (_) {
      return '';
    }
  }

  String _statusLabel(String? status) {
    return AppConstants.statusLabels[status] ?? status ?? '';
  }

  Future<void> autoBackupIfNeeded() async {
    try {
      final today = DateFormat('yyyyMMdd').format(DateTime.now());
      final last = await _db.getSetting(AppConstants.keyLastBackupDate);
      if (last == today) return;

      final data = await _db.exportAll();
      final json = const JsonEncoder.withIndent('  ').convert(data);

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/salenote_backup_$today.json');
      await file.writeAsString(json, flush: true);

      await _db.setSetting(AppConstants.keyLastBackupDate, today);
    } catch (_) {}
  }

  Future<bool> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: Platform.isIOS,
    );
    if (result == null) return false;

    final picked = result.files.single;
    final String content;

    if (picked.path != null) {
      content = await File(picked.path!).readAsString();
    } else if (picked.bytes != null) {
      content = String.fromCharCodes(picked.bytes!);
    } else {
      return false;
    }

    final dynamic decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('File không đúng định dạng sao lưu.');
    }
    if (!decoded.containsKey('customers') ||
        !decoded.containsKey('interactions')) {
      throw const FormatException('File không đúng định dạng sao lưu.');
    }

    await _db.importAll(decoded);
    return true;
  }
}
