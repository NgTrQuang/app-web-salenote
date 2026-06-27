import '../database/database_helper.dart';
import '../utils/constants.dart';
import 'order_service.dart';

class GoalProgress {
  final double goal;
  final double current;
  final double remaining;
  final int orderCount;
  final int? ordersNeeded;
  final int percent;

  const GoalProgress({
    required this.goal,
    required this.current,
    required this.remaining,
    required this.orderCount,
    this.ordersNeeded,
    required this.percent,
  });
}

class GoalService {
  final DatabaseHelper _db = DatabaseHelper();
  final OrderService _orders = OrderService();

  Future<double?> getMonthlyGoal() async {
    final v = await _db.getSetting(AppConstants.keyMonthlyRevenueGoal);
    if (v == null || v.isEmpty) return null;
    final n = double.tryParse(v);
    return (n != null && n > 0) ? n : null;
  }

  Future<void> setMonthlyGoal(double amount) async {
    if (amount <= 0) {
      await _db.setSetting(AppConstants.keyMonthlyRevenueGoal, '');
      return;
    }
    await _db.setSetting(
      AppConstants.keyMonthlyRevenueGoal,
      amount.round().toString(),
    );
  }

  Future<GoalProgress?> getGoalProgress([DateTime? now]) async {
    final goal = await getMonthlyGoal();
    if (goal == null) return null;

    final d = now ?? DateTime.now();
    final summary = await _orders.getSalesSummaryForMonth(d);
    final current = summary.revenue;
    final remaining = (goal - current).clamp(0.0, double.infinity).toDouble();
    final avg = summary.orderCount > 0 ? current / summary.orderCount : 0.0;
    final int? ordersNeeded = remaining > 0 && avg > 0
        ? (remaining / avg).ceil()
        : remaining > 0
            ? null
            : 0;

    return GoalProgress(
      goal: goal,
      current: current,
      remaining: remaining,
      orderCount: summary.orderCount,
      ordersNeeded: ordersNeeded,
      percent: (current / goal * 100).round().clamp(0, 100),
    );
  }
}
