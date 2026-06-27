import 'package:flutter/material.dart';
import '../models/order.dart';
import '../utils/money.dart';
import '../screens/debts_screen.dart';

class TodaySummaryBar extends StatelessWidget {
  final SalesSummary today;
  final SalesSummary month;
  final int actionCount;
  final double totalDebt;

  const TodaySummaryBar({
    super.key,
    required this.today,
    required this.month,
    required this.actionCount,
    required this.totalDebt,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <Widget>[];

    if (today.profit > 0 || today.orderCount > 0) {
      parts.add(Text.rich(TextSpan(
        text: 'Lời hôm nay ',
        children: [
          TextSpan(
            text: formatMoney(today.profit),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      )));
    }

    if (month.profit > 0) {
      parts.add(Text.rich(TextSpan(
        text: 'Tháng lời ',
        children: [
          TextSpan(
            text: formatMoney(month.profit),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      )));
    }

    if (today.orderCount > 0) {
      parts.add(Text.rich(TextSpan(
        children: [
          TextSpan(
            text: '${today.orderCount}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: ' đơn hôm nay'),
        ],
      )));
    }

    if (actionCount > 0) {
      parts.add(Text.rich(TextSpan(
        children: [
          TextSpan(
            text: '$actionCount',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: ' việc cần làm'),
        ],
      )));
    }

    if (totalDebt > 0) {
      parts.add(GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DebtsScreen()),
        ),
        child: Text.rich(TextSpan(
          text: 'Còn ',
          style: TextStyle(
            color: Colors.amber.shade800,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(
              text: formatMoney(totalDebt),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: ' nợ'),
          ],
        )),
      ));
    }

    if (parts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'Chưa có đơn hôm nay — thêm khách hoặc ghi đơn khi chốt.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            for (var i = 0; i < parts.length; i++) ...[
              if (i > 0)
                Text(' · ',
                    style: TextStyle(color: Colors.grey.shade400)),
              parts[i],
            ],
          ],
        ),
      ),
    );
  }
}
