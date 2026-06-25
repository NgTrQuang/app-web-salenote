import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../services/customer_service.dart';
import '../services/order_service.dart';
import '../utils/money.dart';

enum ActionType { contactHot, contact, collectDebt, reEngage }

class DailyAction {
  final String id;
  final ActionType type;
  final int customerId;
  final String customerName;
  final String title;
  final String subtitle;
  final int priority;
  final double? amount;

  const DailyAction({
    required this.id,
    required this.type,
    required this.customerId,
    required this.customerName,
    required this.title,
    required this.subtitle,
    required this.priority,
    this.amount,
  });
}

class AtRiskSummary {
  final int hotOverdue;
  final int warmOverdue;
  final int newOverdue;
  final int promoStale;
  final int returningLost;
  final int dueToday;
  final int overdue3Days;
  final int debtCustomers;
  final double totalDebt;

  const AtRiskSummary({
    this.hotOverdue = 0,
    this.warmOverdue = 0,
    this.newOverdue = 0,
    this.promoStale = 0,
    this.returningLost = 0,
    this.dueToday = 0,
    this.overdue3Days = 0,
    this.debtCustomers = 0,
    this.totalDebt = 0,
  });
}

class RevenueInsight {
  final String text;
  const RevenueInsight(this.text);
}

class AchievementStats {
  final int streak;
  final double totalRevenue;
  final int totalOrders;
  final int customersCared;
  final int totalInteractions;
  final double monthRevenue;

  const AchievementStats({
    this.streak = 0,
    this.totalRevenue = 0,
    this.totalOrders = 0,
    this.customersCared = 0,
    this.totalInteractions = 0,
    this.monthRevenue = 0,
  });
}

class CustomerIntelligence {
  final int orderCount;
  final double totalRevenue;
  final double totalProfit;
  final double totalCommission;
  final double totalDebt;
  final int? lastOrderAt;
  final double avgOrderValue;
  final bool isRepeatBuyer;
  final int? daysSinceLastPurchase;
  final String tierLabel;
  final String tierHint;

  const CustomerIntelligence({
    this.orderCount = 0,
    this.totalRevenue = 0,
    this.totalProfit = 0,
    this.totalCommission = 0,
    this.totalDebt = 0,
    this.lastOrderAt,
    this.avgOrderValue = 0,
    this.isRepeatBuyer = false,
    this.daysSinceLastPurchase,
    this.tierLabel = 'Chưa chốt',
    this.tierHint = 'Chưa có đơn hàng — ưu tiên chăm và chốt',
  });
}

class InsightsService {
  static const promoStaleDays = 7;
  static const returningStaleDays = 30;
  static const maxActions = 12;

  final DatabaseHelper _db = DatabaseHelper();
  final CustomerService _customers = CustomerService();
  final OrderService _orders = OrderService();

  int _daysSince(int ms, [int? now]) {
    final n = now ?? DateTime.now().millisecondsSinceEpoch;
    return ((n - ms) / 86400000).floor();
  }

  int _overdueDays(Customer c, [int? now]) {
    return _daysSince(c.nextActionAt, now).clamp(1, 9999);
  }

  Future<Map<int, double>> _debtByCustomer() async {
    final db = await _db.database;
    final rows = await db.query('orders');
    final map = <int, double>{};
    for (final r in rows) {
      final o = Order.fromMap(r);
      final d = o.debt;
      if (d > 0) map[o.customerId] = (map[o.customerId] ?? 0) + d;
    }
    return map;
  }

  Future<Set<int>> _customersWithOrders() async {
    final db = await _db.database;
    final rows = await db.query('orders', columns: ['customer_id']);
    return rows.map((r) => r['customer_id'] as int).toSet();
  }

  Future<AtRiskSummary> getAtRiskSummary() async {
    final due = await _customers.getNeedsAttention();
    final debtMap = await _debtByCustomer();
    var totalDebt = 0.0;
    for (final v in debtMap.values) {
      totalDebt += v;
    }

    final promoStale = await _db.countPromoCandidates(staleDays: promoStaleDays);
    final returningLost = await _db.countLoyaltyCustomers(staleDays: returningStaleDays);
    final overdue3Days = await _db.getOverdueCount();

    return AtRiskSummary(
      hotOverdue: due.where((c) => c.status == 'hot').length,
      warmOverdue: due.where((c) => c.status == 'warm').length,
      newOverdue: due.where((c) => c.status == 'new').length,
      promoStale: promoStale,
      returningLost: returningLost,
      dueToday: due.length,
      overdue3Days: overdue3Days,
      debtCustomers: debtMap.length,
      totalDebt: totalDebt,
    );
  }

  Future<List<DailyAction>> getDailyActions() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final actions = <DailyAction>[];
    final due = await _customers.getNeedsAttention();
    final debtMap = await _debtByCustomer();
    final allCustomers = await _customers.getAllCustomers();
    final withOrders = await _customersWithOrders();
    final byId = {for (final c in allCustomers) c.id!: c};

    for (final c in due.where((x) => x.status == 'hot')) {
      actions.add(DailyAction(
        id: 'hot-${c.id}',
        type: ActionType.contactHot,
        customerId: c.id!,
        customerName: c.name,
        title: 'Chăm khách Nóng: ${c.name}',
        subtitle:
            'Quá hạn ${_overdueDays(c, now)} ngày${c.product != null ? ' · ${c.product}' : ''}',
        priority: 1,
      ));
    }

    for (final e in debtMap.entries) {
      final c = byId[e.key];
      if (c == null) continue;
      actions.add(DailyAction(
        id: 'debt-${e.key}',
        type: ActionType.collectDebt,
        customerId: e.key,
        customerName: c.name,
        title: 'Thu nợ: ${c.name}',
        subtitle: 'Còn ${formatMoney(e.value)} chưa thu',
        priority: 2,
        amount: e.value,
      ));
    }

    for (final c in due.where((x) => x.status == 'warm' || x.status == 'new')) {
      actions.add(DailyAction(
        id: 'contact-${c.id}',
        type: ActionType.contact,
        customerId: c.id!,
        customerName: c.name,
        title: 'Liên hệ: ${c.name}',
        subtitle:
            '${c.status == 'warm' ? 'Tiềm năng' : 'Mới'} · quá hạn ${_overdueDays(c, now)} ngày',
        priority: c.status == 'warm' ? 3 : 4,
      ));
    }

    final promoCutoff = now - promoStaleDays * 86400000;
    final dueIds = due.map((d) => d.id).toSet();
    for (final c in allCustomers) {
      if (c.status != 'warm' && c.status != 'hot') continue;
      if (c.lastContactAt >= promoCutoff) continue;
      if (dueIds.contains(c.id)) continue;
      actions.add(DailyAction(
        id: 'promo-${c.id}',
        type: ActionType.contact,
        customerId: c.id!,
        customerName: c.name,
        title: 'Chăm lại: ${c.name}',
        subtitle:
            '${c.status == 'hot' ? 'Nóng' : 'Tiềm năng'} · ${_daysSince(c.lastContactAt, now)} ngày chưa liên hệ',
        priority: 5,
      ));
    }

    final returnCutoff = now - returningStaleDays * 86400000;
    for (final c in allCustomers) {
      if (c.status != 'closed') continue;
      if (!withOrders.contains(c.id)) continue;
      if (c.lastContactAt >= returnCutoff) continue;
      actions.add(DailyAction(
        id: 'return-${c.id}',
        type: ActionType.reEngage,
        customerId: c.id!,
        customerName: c.name,
        title: 'Mời mua lại: ${c.name}',
        subtitle:
            'Đã từng mua · ${_daysSince(c.lastContactAt, now)} ngày chưa chăm',
        priority: 6,
      ));
    }

    actions.sort((a, b) {
      final p = a.priority.compareTo(b.priority);
      if (p != 0) return p;
      return (b.amount ?? 0).compareTo(a.amount ?? 0);
    });
    return actions.take(maxActions).toList();
  }

  Future<List<RevenueInsight>> getRevenueInsights([DateTime? date]) async {
    final d = date ?? DateTime.now();
    final start = DateTime(d.year, d.month, 1).millisecondsSinceEpoch;
    final end = DateTime(d.year, d.month + 1, 1).millisecondsSinceEpoch;
    final insights = <RevenueInsight>[];

    final summary = await _orders.getSalesSummaryForMonth(d);
    final bySource = await _orders.getRevenueBySource(start, end);
    final topProducts = await _orders.getTopSalesProductsByRevenue(start, end);

    if (summary.debt > 0) {
      insights.add(RevenueInsight(
        'Còn ${formatMoney(summary.debt)} công nợ tháng này — ưu tiên thu trước khi chốt đơn mới',
      ));
    }

    if (bySource.isNotEmpty && summary.revenue > 0) {
      final top = bySource.first;
      final pct = ((top['revenue'] as num) / summary.revenue * 100).round();
      if (pct >= 20) {
        insights.add(RevenueInsight(
          '${top['label']} tạo $pct% doanh thu tháng này',
        ));
      }
      if (bySource.length >= 2) {
        final second = bySource[1];
        final pct2 = ((second['revenue'] as num) / summary.revenue * 100).round();
        if (pct2 >= 10) {
          insights.add(RevenueInsight(
            '${second['label']} đóng góp $pct2% — cân nhắc đầu tư thêm nguồn này',
          ));
        }
      }
    }

    if (topProducts.isNotEmpty && summary.revenue > 0) {
      final top = topProducts.first;
      final pct =
          ((top['revenue'] as num) / summary.revenue * 100).round();
      insights.add(RevenueInsight(
        '"${top['product']}" đang bán chạy nhất ($pct% doanh thu tháng)',
      ));
    }

    if (insights.isEmpty && summary.revenue == 0) {
      insights.add(const RevenueInsight(
        'Chưa có doanh thu tháng này — tập trung chăm khách Nóng và Tiềm năng trước',
      ));
    }

    return insights.take(3).toList();
  }

  Future<AchievementStats> getAchievementStats() async {
    final db = await _db.database;
    final streak = await _customers.getCurrentStreak();
    final orderRows = await db.query('orders');
    final interactionRows = await db.query('interactions');
    final monthSummary = await _orders.getSalesSummaryForMonth();

    final caredIds = interactionRows.map((r) => r['customer_id'] as int).toSet();
    var totalRevenue = 0.0;
    for (final r in orderRows) {
      totalRevenue += Order.fromMap(r).revenue;
    }

    return AchievementStats(
      streak: streak,
      totalRevenue: totalRevenue,
      totalOrders: orderRows.length,
      customersCared: caredIds.length,
      totalInteractions: interactionRows.length,
      monthRevenue: monthSummary.revenue,
    );
  }

  CustomerIntelligence buildCustomerIntelligence(
    Customer customer,
    List<Order> orders,
  ) {
    final summary = SalesSummary.fromOrders(orders);
    final orderCount = orders.length;
    int? lastOrderAt;
    if (orderCount > 0) {
      lastOrderAt = orders.map((o) => o.createdAt).reduce((a, b) => a > b ? a : b);
    }
    final daysSinceLast =
        lastOrderAt != null ? _daysSince(lastOrderAt) : null;
    final avg = orderCount > 0 ? summary.revenue / orderCount : 0.0;

    var tierLabel = 'Chưa chốt';
    var tierHint = 'Chưa có đơn hàng — ưu tiên chăm và chốt';
    if (orderCount >= 5 || summary.revenue >= 10000000) {
      tierLabel = 'VIP';
      tierHint = 'Khách mang giá trị cao — giữ liên hệ định kỳ';
    } else if (orderCount >= 2) {
      tierLabel = 'Khách quen';
      tierHint = 'Mua lặp lại — cơ hội upsell và giới thiệu';
    } else if (orderCount == 1) {
      tierLabel = 'Đã mua 1 lần';
      tierHint = 'Theo dõi sau bán để mời mua lại';
    }

    return CustomerIntelligence(
      orderCount: orderCount,
      totalRevenue: summary.revenue,
      totalProfit: summary.profit,
      totalCommission: summary.commission,
      totalDebt: summary.debt,
      lastOrderAt: lastOrderAt,
      avgOrderValue: avg,
      isRepeatBuyer: orderCount >= 2,
      daysSinceLastPurchase: daysSinceLast,
      tierLabel: tierLabel,
      tierHint: tierHint,
    );
  }

  Future<({String title, String body})> buildActionDailyNotification() async {
    final due = await _customers.getNeedsAttention();
    final actions = await getDailyActions();
    final atRisk = await getAtRiskSummary();

    if (due.isEmpty && actions.isEmpty) {
      return (
        title: 'Salenote — Ngày êm ả',
        body:
            'Không có việc gấp hôm nay. Xem insight doanh thu & khách cũ cần chăm lại.',
      );
    }

    Customer? firstHot;
    for (final c in due) {
      if (c.status == 'hot') {
        firstHot = c;
        break;
      }
    }
    final firstAction = actions.isNotEmpty ? actions.first : null;
    DailyAction? debtAction;
    for (final a in actions) {
      if (a.type == ActionType.collectDebt) {
        debtAction = a;
        break;
      }
    }

    if (firstHot != null) {
      final days = _overdueDays(firstHot);
      final more = due.length - 1;
      return (
        title: '🔥 ${firstHot.name} cần chăm gấp',
        body: more > 0
            ? 'Khách Nóng · quá hạn $days ngày. Còn $more khách khác cần liên hệ hôm nay.'
            : 'Khách Nóng · quá hạn $days ngày. Mở app để xem việc cần làm.',
      );
    }

    if (debtAction != null && debtAction.amount != null) {
      return (
        title: '💰 Thu nợ: ${debtAction.customerName}',
        body:
            'Còn ${formatMoney(debtAction.amount!)}. Tổng ${atRisk.debtCustomers} khách còn nợ.',
      );
    }

    if (firstAction != null) {
      final more = actions.length - 1;
      return (
        title: 'Việc hôm nay: ${firstAction.customerName}',
        body: more > 0
            ? '${firstAction.subtitle}. Còn $more việc khác trong danh sách.'
            : firstAction.subtitle,
      );
    }

    return (
      title: 'Salenote — Việc hôm nay',
      body: 'Bạn có ${due.length} khách cần liên hệ hôm nay',
    );
  }
}
