import 'package:flutter/material.dart';
import '../services/insights_service.dart';
import '../utils/money.dart';
import '../services/customer_service.dart';
import '../screens/customer_detail_screen.dart';

class DailyActionCenter extends StatelessWidget {
  final List<DailyAction> actions;

  const DailyActionCenter({super.key, required this.actions});

  IconData _icon(ActionType t) {
    switch (t) {
      case ActionType.contactHot:
        return Icons.local_fire_department;
      case ActionType.contact:
        return Icons.phone_outlined;
      case ActionType.collectDebt:
        return Icons.payments_outlined;
      case ActionType.reEngage:
        return Icons.replay;
    }
  }

  Color _color(ActionType t) {
    switch (t) {
      case ActionType.contactHot:
        return Colors.red;
      case ActionType.contact:
        return Colors.orange;
      case ActionType.collectDebt:
        return Colors.teal;
      case ActionType.reEngage:
        return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Việc hôm nay',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Làm theo thứ tự ưu tiên',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            if (actions.isEmpty)
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Không có việc gấp — bạn đang theo kịp khách!',
                        style: TextStyle(fontSize: 13)),
                  ),
                ],
              )
            else
              ...actions.asMap().entries.map((e) {
                final i = e.key;
                final a = e.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: _color(a.type).withAlpha(30),
                    child: Icon(_icon(a.type), size: 18, color: _color(a.type)),
                  ),
                  title: Text('${i + 1}. ${a.title}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(a.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () async {
                    final c = await CustomerService().getCustomer(a.customerId);
                    if (c != null && context.mounted) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CustomerDetailScreen(customer: c),
                        ),
                      );
                    }
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}

class AtRiskAlertsPanel extends StatelessWidget {
  final AtRiskSummary summary;

  const AtRiskAlertsPanel({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = <({String label, String value, IconData icon, Color color})>[];
    if (summary.hotOverdue > 0) {
      items.add((
        label: 'Khách Nóng quá hạn',
        value: '${summary.hotOverdue}',
        icon: Icons.local_fire_department,
        color: Colors.red,
      ));
    }
    if (summary.warmOverdue + summary.newOverdue > 0) {
      items.add((
        label: 'Tiềm năng / Mới chưa chăm',
        value: '${summary.warmOverdue + summary.newOverdue}',
        icon: Icons.people_outline,
        color: Colors.orange,
      ));
    }
    if (summary.promoStale > 0) {
      items.add((
        label: 'Lâu chưa liên hệ',
        value: '${summary.promoStale}',
        icon: Icons.warning_amber_outlined,
        color: Colors.amber.shade800,
      ));
    }
    if (summary.returningLost > 0) {
      items.add((
        label: 'Khách từng mua chưa quay lại',
        value: '${summary.returningLost}',
        icon: Icons.replay,
        color: Colors.deepPurple,
      ));
    }
    if (summary.debtCustomers > 0) {
      items.add((
        label: 'Khách còn công nợ',
        value: '${summary.debtCustomers} · ${formatMoney(summary.totalDebt)}',
        icon: Icons.payments_outlined,
        color: Colors.red,
      ));
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cảnh báo rủi ro',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map((item) => Container(
                        width: (MediaQuery.of(context).size.width - 64) / 2,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: item.color.withAlpha(80)),
                          borderRadius: BorderRadius.circular(10),
                          color: item.color.withAlpha(15),
                        ),
                        child: Row(
                          children: [
                            Icon(item.icon, size: 18, color: item.color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.label,
                                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  Text(item.value,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: item.color)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class AchievementBanner extends StatelessWidget {
  final AchievementStats stats;

  const AchievementBanner({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.streak == 0 &&
        stats.customersCared == 0 &&
        stats.totalRevenue == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withAlpha(120),
            Theme.of(context).colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Salenote đang giúp bạn',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (stats.streak > 0)
                _chip('🔥 ${stats.streak} ngày', 'Không bỏ sót khách'),
              if (stats.customersCared > 0)
                _chip('${stats.customersCared}', 'Khách đã chăm'),
              if (stats.totalRevenue > 0)
                _chip(formatMoney(stats.totalRevenue), 'Doanh thu tích luỹ'),
              if (stats.totalOrders > 0) _chip('${stats.totalOrders}', 'Đơn đã ghi'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class RevenueInsightPanel extends StatelessWidget {
  final List<RevenueInsight> insights;

  const RevenueInsightPanel({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Insight doanh thu',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ...insights.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Expanded(child: Text(i.text, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class CustomerIntelligenceCard extends StatelessWidget {
  final CustomerIntelligence intel;

  const CustomerIntelligenceCard({super.key, required this.intel});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Giá trị khách hàng',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(intel.tierLabel,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(intel.tierHint,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _stat('Tổng đơn', '${intel.orderCount}'),
                _stat('Doanh thu', formatMoney(intel.totalRevenue)),
                _stat('Lợi nhuận', formatMoney(intel.totalProfit)),
                _stat('Hoa hồng', formatMoney(intel.totalCommission)),
                _stat('Công nợ', formatMoney(intel.totalDebt),
                    danger: intel.totalDebt > 0),
                _stat('TB/đơn',
                    intel.orderCount > 0 ? formatMoney(intel.avgOrderValue) : '—'),
                _stat('Mua lặp', intel.isRepeatBuyer ? 'Có' : 'Chưa'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, {bool danger = false}) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: danger ? Colors.red : null)),
        ],
      ),
    );
  }
}
