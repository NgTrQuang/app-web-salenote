import 'package:flutter/material.dart';
import '../models/order.dart';
import '../utils/money.dart';

class SalesDashboard extends StatelessWidget {
  final String title;
  final SalesSummary summary;

  const SalesDashboard({
    super.key,
    required this.title,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.2,
          children: [
            _MetricCard(
              label: 'Doanh thu',
              value: formatMoney(summary.revenue),
              color: theme.colorScheme.onSurface,
            ),
            _MetricCard(
              label: 'Lợi nhuận',
              value: formatMoney(summary.profit),
              color: Colors.green.shade700,
            ),
            _MetricCard(
              label: 'Hoa hồng',
              value: formatMoney(summary.commission),
              color: theme.colorScheme.primary,
            ),
            _MetricCard(
              label: 'Công nợ',
              value: formatMoney(summary.debt),
              color: summary.debt > 0 ? Colors.red.shade700 : Colors.grey,
            ),
          ],
        ),
        if (summary.orderCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${summary.orderCount} đơn hàng',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
