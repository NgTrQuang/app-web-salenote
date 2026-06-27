import 'package:flutter/material.dart';
import '../services/goal_service.dart';
import '../utils/money.dart';
import '../screens/stats_screen.dart';

class GoalProgressCard extends StatelessWidget {
  final GoalProgress progress;

  const GoalProgressCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final achieved = progress.remaining <= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mục tiêu tháng này',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              achieved
                  ? 'Bạn đã đạt mục tiêu — có thể đặt mục tiêu mới trong Cài đặt'
                  : 'Theo dõi tiến độ doanh thu cá nhân',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formatMoney(progress.current),
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('/ ${formatMoney(progress.goal)}',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Text(
                  achieved ? 'Đã đạt!' : '${progress.percent}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.percent / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: achieved ? Colors.green : Theme.of(context).colorScheme.primary,
              ),
            ),
            if (!achieved) ...[
              const SizedBox(height: 10),
              Text.rich(TextSpan(
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                children: [
                  const TextSpan(text: 'Còn '),
                  TextSpan(
                    text: formatMoney(progress.remaining),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (progress.ordersNeeded != null && progress.ordersNeeded! > 0)
                    TextSpan(
                      text:
                          ' — cần thêm khoảng ${progress.ordersNeeded} đơn',
                    ),
                ],
              )),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              ),
              child: const Text('Xem tiền của tôi →'),
            ),
          ],
        ),
      ),
    );
  }
}
