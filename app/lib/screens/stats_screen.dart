import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show localeModeNotifier;
import '../models/order.dart';
import '../services/customer_service.dart';
import '../services/order_service.dart';
import '../widgets/sales_dashboard.dart';
import '../utils/money.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _service = CustomerService();
  final _orderService = OrderService();
  late DateTime _selectedMonth;
  Map<String, dynamic>? _stats;
  SalesSummary? _salesSummary;
  List<Map<String, dynamic>> _revenueBySource = [];
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    final results = await Future.wait([
      _service.getMonthlyStats(_selectedMonth.year, _selectedMonth.month),
      _service.getCurrentStreak(),
      _orderService.getSalesSummaryForMonth(_selectedMonth),
      _orderService.getRevenueBySource(
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ),
    ]);
    if (mounted) {
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _streak = results[1] as int;
        _salesSummary = results[2] as SalesSummary;
        _revenueBySource = List<Map<String, dynamic>>.from(results[3] as List);
        _loading = false;
      });
    }
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _load();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year == now.year &&
        _selectedMonth.month == now.month) return;
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _load();
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final localeCode = localeModeNotifier.value.languageCode;
    final monthLabel =
        DateFormat('MMMM yyyy', localeCode).format(_selectedMonth);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(l.statsTitle,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 32 + MediaQuery.of(context).padding.bottom),
                children: [
                  // ── Streak ──────────────────────────────────
                  if (_streak > 0) ...[
                    _StreakBanner(streak: _streak),
                    const SizedBox(height: 20),
                  ],

                  // ── Month Picker ─────────────────────────────
                  _MonthPicker(
                    label: monthLabel,
                    onPrev: _prevMonth,
                    onNext: _isCurrentMonth ? null : _nextMonth,
                  ),
                  const SizedBox(height: 16),

                  if (_salesSummary != null) ...[
                    SalesDashboard(
                      title: 'Doanh số — $monthLabel',
                      summary: _salesSummary!,
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_revenueBySource.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Doanh thu theo nguồn',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            ..._revenueBySource.map((row) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text('${row['label']}')),
                                      Text(formatMoney((row['revenue'] as num).toDouble()),
                                          style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Big 3 Stats ──────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '${_stats!['contacts']}',
                          label: l.contacts,
                          icon: Icons.chat_bubble_outline_rounded,
                          color: Colors.blue.shade600,
                          bgColor: Colors.blue.shade600.withAlpha(20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: '${_stats!['closed']}',
                          label: l.closedDeals,
                          icon: Icons.check_circle_outline_rounded,
                          color: Colors.green.shade600,
                          bgColor: Colors.green.shade600.withAlpha(20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: '${_stats!['new_customers']}',
                          label: l.newCustomers,
                          icon: Icons.person_add_outlined,
                          color: Colors.purple.shade600,
                          bgColor: Colors.purple.shade600.withAlpha(20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Conversion Rate ──────────────────────────
                  _ConversionCard(
                    contacts: _stats!['contacts'] as int,
                    closed: _stats!['closed'] as int,
                  ),
                  const SizedBox(height: 24),

                  // ── Top Products ─────────────────────────────
                  _TopProductsCard(
                    rows: List<Map<String, dynamic>>.from(
                        _stats!['top_products'] as List),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Streak Banner ─────────────────────────────────────────────

class _StreakBanner extends StatelessWidget {
  final int streak;
  const _StreakBanner({required this.streak});

  String get _label {
    if (streak >= 30) return '🏆 $streak ngày liên tiếp — Xuất sắc!';
    if (streak >= 14) return '🔥 $streak ngày liên tiếp — Tuyệt vời!';
    if (streak >= 7) return '⚡ $streak ngày liên tiếp — Đang vào guồng!';
    return '✨ $streak ngày liên tiếp — Tiếp tục nhé!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Bạn đã liên hệ khách hàng mỗi ngày',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Month Picker ──────────────────────────────────────────────

class _MonthPicker extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _MonthPicker({
    required this.label,
    required this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: onPrev,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withAlpha(120),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: Icon(
            Icons.chevron_right_rounded,
            color: onNext == null ? Colors.grey.shade300 : null,
          ),
          onPressed: onNext,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withAlpha(120),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Conversion Card ───────────────────────────────────────────

class _ConversionCard extends StatelessWidget {
  final int contacts;
  final int closed;

  const _ConversionCard(
      {required this.contacts, required this.closed});

  @override
  Widget build(BuildContext context) {
    final rate =
        contacts > 0 ? (closed / contacts * 100).toStringAsFixed(1) : '—';
    final hasData = contacts > 0;

    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final borderColor = theme.colorScheme.outlineVariant.withAlpha(80);
    final trackColor = theme.colorScheme.surfaceVariant;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📈',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Text('Tỷ lệ chốt đơn',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RateItem(
                  label: 'Lượt liên hệ', value: '$contacts'),
              _RateItem(label: 'Chốt đơn', value: '$closed'),
              _RateItem(
                label: 'Tỷ lệ',
                value: hasData ? '$rate%' : '—',
                highlight: true,
                good: hasData &&
                    double.tryParse(rate)! >= 20,
              ),
            ],
          ),
          if (hasData) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (closed / contacts).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation(
                    closed / contacts >= 0.2
                        ? Colors.green.shade500
                        : Colors.orange.shade400),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RateItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool good;

  const _RateItem({
    required this.label,
    required this.value,
    this.highlight = false,
    this.good = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 24 : 20,
            fontWeight: FontWeight.w800,
            color: highlight
                ? (good ? Colors.green.shade600 : Colors.orange.shade600)
                : Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}

// ── Top Products Card ─────────────────────────────────────────

class _TopProductsCard extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  const _TopProductsCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final borderColor = theme.colorScheme.outlineVariant.withAlpha(80);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🏷️', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('Sản phẩm được hỏi nhiều nhất',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Chưa có dữ liệu sản phẩm',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withAlpha(100),
                        fontSize: 13)),
              ),
            )
          else
            ...rows.asMap().entries.map((entry) {
              final idx = entry.key;
              final row = entry.value;
              final product = row['product'] as String;
              final count = row['cnt'] as int;
              final maxCount = (rows.first['cnt'] as int).toDouble();
              final ratio = count / maxCount;

              final medals = ['🥇', '🥈', '🥉'];
              final medal = idx < 3 ? medals[idx] : '  ${idx + 1}.';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(medal,
                          style: const TextStyle(fontSize: 16)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                product,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                              Text(
                                '$count khách',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 6,
                              backgroundColor: theme.colorScheme.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation(
                                  _barColor(idx)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _barColor(int idx) {
    const colors = [
      Color(0xFFFFD700),
      Color(0xFFC0C0C0),
      Color(0xFFCD7F32),
      Color(0xFF64B5F6),
      Color(0xFF81C784),
    ];
    return idx < colors.length ? colors[idx] : Colors.blue.shade300;
  }
}
