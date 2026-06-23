import 'package:intl/intl.dart';

String formatMoney(num amount) {
  final s = NumberFormat('#,###', 'vi_VN').format(amount.round());
  return '${s.replaceAll(',', '.')}đ';
}

String formatMoneyInput(num amount) {
  if (amount == 0) return '';
  return NumberFormat('#,###', 'vi_VN').format(amount.round()).replaceAll(',', '.');
}

double parseMoneyInput(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty) return 0;
  return double.tryParse(digits) ?? 0;
}
