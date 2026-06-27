import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../database/database_helper.dart';
import '../services/customer_service.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../utils/constants.dart';
import '../utils/money.dart';
import '../widgets/customer_card.dart';
import '../services/insights_service.dart';
import '../services/goal_service.dart';
import '../services/segment_service.dart';
import '../widgets/insights_panels.dart';
import '../widgets/sales_dashboard.dart';
import '../widgets/today_summary_bar.dart';
import '../widgets/goal_progress_card.dart';
import '../widgets/segment_action_sheet.dart';
import '../widgets/infinite_scroll.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_logo.dart';
import 'add_customer_screen.dart';
import 'add_order_screen.dart';
import 'all_customers_screen.dart';
import 'customer_detail_screen.dart';
import 'products_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'debts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = CustomerService();
  List<Customer> _needsAttention = [];
  List<Customer> _upcoming = [];
  bool _loading = true;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  int _streak = 0;
  int _overdueCount = 0;
  SalesSummary _todaySales = const SalesSummary();
  SalesSummary _monthSales = const SalesSummary();
  List<Product> _lowStock = [];
  List<DailyAction> _dailyActions = [];
  AtRiskSummary _atRisk = const AtRiskSummary();
  AchievementStats _achievements = const AchievementStats();
  List<RevenueInsight> _revenueInsights = [];
  GoalProgress? _goalProgress;
  bool _showSalesDetail = false;
  bool _showCustomers = false;
  final _needsVisible = ClientVisibleList();
  final _upcomingVisible = ClientVisibleList();
  final _insights = InsightsService();
  int _navIndex = 0;
  bool _showSwipeHint = false;
  bool _fabExtended = true;
  String? _dailyTip;
  String? _pendingMilestone;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldExtend = _scrollCtrl.offset < 60;
    if (shouldExtend != _fabExtended) {
      setState(() => _fabExtended = shouldExtend);
    }
    if (!_scrollCtrl.hasClients) return;
    if (!scrollNearBottom(_scrollCtrl.position)) return;
    var changed = false;
    if (_needsVisible.hasMore(_filteredAttention)) {
      _needsVisible.loadMore(_filteredAttention);
      changed = true;
    } else if (_upcomingVisible.hasMore(_filteredUpcoming)) {
      _upcomingVisible.loadMore(_filteredUpcoming);
      changed = true;
    }
    if (changed) setState(() {});
  }

  void _resetListVisible() {
    _needsVisible.reset();
    _upcomingVisible.reset();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _searchQuery = '';
    });
    _resetListVisible();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = DatabaseHelper();
    final orderService = OrderService();
    final productService = ProductService();
    final results = await Future.wait([
      _service.getNeedsAttention(),
      _service.getUpcoming(),
      _service.getCurrentStreak(),
      db.getOverdueCount(),
      db.getSetting(AppConstants.keySwipeHintShown),
      db.getSetting(AppConstants.keyDailyTipDate),
      orderService.getSalesSummaryForDay(),
      orderService.getSalesSummaryForMonth(),
      productService.getLowStockProducts(),
      _insights.getDailyActions(),
      _insights.getAtRiskSummary(),
      _insights.getAchievementStats(),
      _insights.getRevenueInsights(),
      GoalService().getGoalProgress(),
    ]);
    if (mounted) {
      _needsAttention = results[0] as List<Customer>;
      _upcoming = results[1] as List<Customer>;
      _streak = results[2] as int;
      _overdueCount = results[3] as int;
      final hintShown = (results[4] as String?) == 'true';
      final tipDate = results[5] as String?;
      _todaySales = results[6] as SalesSummary;
      _monthSales = results[7] as SalesSummary;
      _lowStock = results[8] as List<Product>;
      _dailyActions = results[9] as List<DailyAction>;
      _atRisk = results[10] as AtRiskSummary;
      _achievements = results[11] as AchievementStats;
      _revenueInsights = results[12] as List<RevenueInsight>;
      _goalProgress = results[13] as GoalProgress?;
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';
      final tip = tipDate != todayStr ? _pickTip(todayStr) : null;
      _needsVisible.reset();
      _upcomingVisible.reset();
      setState(() {
        _loading = false;
        _showSwipeHint = !hintShown &&
            (_needsAttention.isNotEmpty || _upcoming.isNotEmpty);
        _dailyTip = tip;
      });
      if (tip != null) {
        db.setSetting(AppConstants.keyDailyTipDate, todayStr);
      }
      await _checkMilestone();
    }
  }

  String _pickTip(String seed) {
    final tips = [
      '💡 Vuốt phải thẻ khách = đánh dấu đã nhắn ngay, không cần vào chi tiết',
      '💡 Nhấn chip SĐT trên thẻ khách để gọi điện 1 chạm',
      '💡 Dùng chip gợi ý ngành khi soạn tin — tên & sản phẩm tự điền',
      '💡 Nhập ngày bảo hành khi bán để nhận badge nhắc nhở tự động',
      '💡 Sao lưu dữ liệu mỗi tuần trong Cài đặt → Sao lưu dữ liệu',
      '💡 Đặt trạng thái Nóng 🔴 cho khách đang hỏi nhiều — app nhắc sau 1 ngày',
      '💡 Sau chốt đơn đừng xoá khách — app tự nhắc chăm sóc sau 7 ngày',
    ];
    final idx = seed.hashCode.abs() % tips.length;
    return tips[idx];
  }

  Future<void> _checkMilestone() async {
    final db = DatabaseHelper();
    final shown = await db.getSetting(AppConstants.keyMilestoneShown);
    final shownSet = shown?.split(',').toSet() ?? {};
    final all = await _service.getAllCustomers();
    final total = all.length;
    final closed = all.where((c) => c.status == 'closed').length;
    String? milestone;
    String? milestoneKey;
    if (total >= 10 && !shownSet.contains('c10')) {
      milestone = '🎉 Tuyệt vời! Bạn đã có 10 khách hàng đầu tiên!';
      milestoneKey = 'c10';
    } else if (total >= 50 && !shownSet.contains('c50')) {
      milestone = '🚀 Ấn tượng! 50 khách hàng trong sổ rồi!';
      milestoneKey = 'c50';
    } else if (closed >= 5 && !shownSet.contains('s5')) {
      milestone = '💰 5 đơn hàng đã chốt — kỹ năng sales của bạn đang lên!';
      milestoneKey = 's5';
    } else if (_streak >= 7 && !shownSet.contains('str7')) {
      milestone = '🔥 7 ngày streak! Bạn đang duy trì thói quen tốt!';
      milestoneKey = 'str7';
    }
    if (milestone != null && milestoneKey != null && mounted) {
      shownSet.add(milestoneKey);
      await db.setSetting(AppConstants.keyMilestoneShown, shownSet.join(','));
      setState(() => _pendingMilestone = milestone);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pendingMilestone != null) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(
              content: Text(
                _pendingMilestone!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              backgroundColor: const Color(0xFF1A73E8),
            ));
          setState(() => _pendingMilestone = null);
        }
      });
    }
  }

  Future<void> _addDemoCustomer() async {
    await _service.addCustomer(
      name: 'Nguyễn Thị Mai (mẫu)',
      phone: '0912345678',
      product: 'Áo khoác',
      note: 'Khách quan tâm áo khoác mùa đông, hỏi giá hôm qua',
      status: 'hot',
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: const Text('Đã thêm khách mẫu — thử vuốt phải/trái nhé!'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
    }
    _load();
  }

  Future<void> _openSegment(int productId) async {
    final seg = await SegmentService().getProductSegment(productId);
    if (seg != null && mounted) {
      await SegmentActionSheet.show(context, seg);
    }
  }

  void _handleInsightAction(RevenueInsightRoute route) {
    switch (route) {
      case RevenueInsightRoute.stats:
      case RevenueInsightRoute.statsSource:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StatsScreen()),
        );
        break;
      case RevenueInsightRoute.debts:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DebtsScreen()),
        );
        break;
      case RevenueInsightRoute.customers:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AllCustomersScreen()),
        );
        break;
      case RevenueInsightRoute.homeActions:
        _scrollCtrl.animateTo(
          280,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
        break;
    }
  }

  Future<void> _addCustomer() async {
    await Navigator.of(context).push<Customer>(
      MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
    );
    _load();
  }

  Future<void> _openDetail(Customer customer) async {
    await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
          builder: (_) => CustomerDetailScreen(customer: customer)),
    );
    _load();
  }

  Future<void> _swipeMessaged(Customer customer) async {
    HapticFeedback.mediumImpact();
    await _service.messageSent(customer);
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(l.messageSentConfirm.replaceAll('{name}', customer.name)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(label: l.undo, onPressed: () {}),
      ));
    _load();
  }

  Future<void> _swipeDelete(Customer customer) async {
    HapticFeedback.mediumImpact();
    final l = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteCustomerTitle),
        content: Text(
            l.deleteCustomerConfirm.replaceAll('{name}', customer.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirm != true) {
      _load();
      return;
    }
    await _service.deleteCustomer(customer.id!);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Đã xoá ${customer.name}'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
    }
    _load();
  }

  List<Customer> get _filteredAttention {
    if (_searchQuery.isEmpty) return _needsAttention;
    final q = _searchQuery.toLowerCase();
    return _needsAttention
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            (c.phone?.contains(q) ?? false) ||
            (c.product?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  List<Customer> get _filteredUpcoming {
    if (_searchQuery.isEmpty) return _upcoming;
    final q = _searchQuery.toLowerCase();
    return _upcoming
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            (c.phone?.contains(q) ?? false) ||
            (c.product?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  void _onNavTap(int index) async {
    if (index == _navIndex && index == 0) return;
    switch (index) {
      case 0:
        setState(() => _navIndex = 0);
        break;
      case 1:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AllCustomersScreen()),
        );
        _load();
        break;
      case 2:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StatsScreen()),
        );
        _load();
        break;
      case 3:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        _load();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _needsAttention.length + _upcoming.length;
    final urgentCount = _needsAttention.length;
    final fa = _needsVisible.slice(_filteredAttention);
    final fu = _upcomingVisible.slice(_filteredUpcoming);
    final faTotal = _filteredAttention.length;
    final fuTotal = _filteredUpcoming.length;
    final filteredTotal = fa.length + fu.length;
    final l = AppLocalizations.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: theme.colorScheme.surface,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bg,
        drawer: const AppDrawer(current: 'home'),
        // ── Bottom Navigation Bar ────────────────────────────
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withAlpha(80),
                width: 0.5,
              ),
            ),
          ),
          child: NavigationBar(
          selectedIndex: _navIndex,
          onDestinationSelected: _onNavTap,
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          indicatorColor: theme.colorScheme.primary.withAlpha(26),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Badge(
                isLabelVisible: urgentCount > 0,
                label: Text('$urgentCount'),
                child: const Icon(Icons.home_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: urgentCount > 0,
                label: Text('$urgentCount'),
                child: const Icon(Icons.home_rounded),
              ),
              label: 'Hôm nay',
            ),
            const NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Sổ khách',
            ),
            const NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Tiền',
            ),
            const NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Cài đặt',
            ),
          ],
        ),
        ),
        ),
        // ── FAB ─────────────────────────────────────────────
        floatingActionButton: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: _fabExtended
              ? FloatingActionButton.extended(
                  key: const ValueKey('fab_ext'),
                  onPressed: _addCustomer,
                  icon: const Icon(Icons.person_add_rounded),
                  label: Text(l.addCustomer,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  elevation: 3,
                )
              : FloatingActionButton(
                  key: const ValueKey('fab_small'),
                  onPressed: _addCustomer,
                  elevation: 3,
                  child: const Icon(Icons.person_add_rounded),
                ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        // ── Body ─────────────────────────────────────────────
        body: RefreshIndicator(
                onRefresh: _load,
                edgeOffset: MediaQuery.of(context).padding.top + 110,
                child: CustomScrollView(
                  controller: _scrollCtrl,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ── Pinned AppBar + Search ───────────────
                    SliverAppBar(
                      pinned: true,
                      floating: false,
                      backgroundColor: bg,
                      surfaceTintColor: Colors.transparent,
                      scrolledUnderElevation: 0,
                      automaticallyImplyLeading: false,
                      titleSpacing: 16,
                      toolbarHeight: 56,
                      title: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu_rounded),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            tooltip: 'Menu',
                          ),
                          const AppLogo(size: 30, borderRadius: 8),
                          const SizedBox(width: 10),
                          Text(l.appName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 19)),
                          if (_streak > 1) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _onNavTap(2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🔥',
                                        style: TextStyle(fontSize: 11)),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$_streak ngày',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.receipt_long_outlined),
                            tooltip: 'Ghi đơn mới',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const AddOrderScreen()),
                            ),
                          ),
                        ],
                      ),
                      // ── Pinned Search Bar ──────────────────
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(56),
                        child: _HomeSearchBar(
                          controller: _searchCtrl,
                          hint: l.searchHint,
                          onChanged: (v) => setState(() {
                            _searchQuery = v;
                            _resetListVisible();
                          }),
                          onClear: _clearSearch,
                          bg: bg,
                        ),
                      ),
                    ),

                    // ── Content ─────────────────────────────
                    if (_loading)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (total == 0)
                      SliverFillRemaining(
                        child: _EmptyState(
                        onAdd: _addCustomer,
                        onAddDemo: _addDemoCustomer),
                      )
                    else if (_searchQuery.isNotEmpty && filteredTotal == 0)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 56, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(l.noSearchResults,
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 15)),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      if (_searchQuery.isEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: TodaySummaryBar(
                              today: _todaySales,
                              month: _monthSales,
                              actionCount: _dailyActions.length,
                              totalDebt: _atRisk.totalDebt,
                            ),
                          ),
                        ),
                        if (_goalProgress != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: GoalProgressCard(progress: _goalProgress!),
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: DailyActionCenter(
                              actions: _dailyActions,
                              onSegmentAction: _openSegment,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: AchievementBanner(stats: _achievements),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: AtRiskAlertsPanel(summary: _atRisk),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: RevenueInsightPanel(
                              insights: _revenueInsights,
                              onAction: _handleInsightAction,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Card(
                              child: Column(
                                children: [
                                  ListTile(
                                    title: const Text('Doanh số',
                                        style: TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      'Hôm nay ${formatMoney(_todaySales.revenue)} · Tháng ${formatMoney(_monthSales.revenue)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Icon(
                                      _showSalesDetail
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                    ),
                                    onTap: () =>
                                        setState(() => _showSalesDetail = !_showSalesDetail),
                                  ),
                                  if (_showSalesDetail) ...[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                      child: SalesDashboard(
                                          title: 'Hôm nay', summary: _todaySales),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                      child: SalesDashboard(
                                          title: 'Tháng này', summary: _monthSales),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_lowStock.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: Card(
                                child: InkWell(
                                  onTap: () => Navigator.of(context)
                                      .push(MaterialPageRoute(
                                          builder: (_) => const ProductsScreen()))
                                      .then((_) => _load()),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Cảnh báo tồn kho (${_lowStock.length})',
                                            style: const TextStyle(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 8),
                                        ..._lowStock.take(4).map((p) => Padding(
                                              padding: const EdgeInsets.only(bottom: 6),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                      child: Text(p.name,
                                                          overflow: TextOverflow.ellipsis)),
                                                  Text(
                                                    '${p.stockQuantity} · ${AppConstants.stockStatusLabel(p.stockStatus)}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: p.stockStatus == 'out'
                                                          ? Colors.red
                                                          : Colors.orange,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )),
                                        const SizedBox(height: 4),
                                        Text('Quản lý tồn kho →',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.primary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                      // ── Swipe Hint ───────────────────────────
                      if (_showSwipeHint && _searchQuery.isEmpty)
                        _SwipeHintBanner(
                          onDismiss: () async {
                            await DatabaseHelper().setSetting(
                                AppConstants.keySwipeHintShown, 'true');
                            setState(() => _showSwipeHint = false);
                          },
                        ),
                      // ── Daily Tip ────────────────────────────
                      if (_dailyTip != null && _searchQuery.isEmpty)
                        _DailyTipBanner(
                          tip: _dailyTip!,
                          onDismiss: () => setState(() => _dailyTip = null),
                        ),
                      // ── Insight Banner ───────────────────────
                      if (_overdueCount > 0 && _searchQuery.isEmpty)
                        _InsightBanner(
                          overdueCount: _overdueCount,
                          onTap: () => _onNavTap(1),
                        ),
                      if (_searchQuery.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Card(
                              child: ListTile(
                                title: Text(
                                  'Sổ khách hôm nay ($total)',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'Cần liên hệ $urgentCount · Sắp tới ${_upcoming.length}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Icon(
                                  _showCustomers
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                ),
                                onTap: () =>
                                    setState(() => _showCustomers = !_showCustomers),
                              ),
                            ),
                          ),
                        ),
                      if (_showCustomers || _searchQuery.isNotEmpty) ...[
                      if (faTotal > 0) ...[
                        _SectionHeader(
                          icon: Icons.local_fire_department_rounded,
                          title: l.needsAttention,
                          count: faTotal,
                          color: Colors.red.shade600,
                          bgColor: Colors.red.shade50,
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _SwipeableCard(
                              customer: fa[i],
                              onTap: () => _openDetail(fa[i]),
                              onMessaged: () => _swipeMessaged(fa[i]),
                              onDelete: () => _swipeDelete(fa[i]),
                            ),
                            childCount: fa.length,
                          ),
                        ),
                        if (faTotal > kDefaultPageSize)
                          SliverToBoxAdapter(
                            child: LoadMoreFooter(
                              hasMore: _needsVisible.hasMore(_filteredAttention),
                              loading: false,
                              visible: fa.length,
                              total: faTotal,
                            ),
                          ),
                      ],
                      if (fuTotal > 0) ...[
                        _SectionHeader(
                          icon: Icons.schedule_rounded,
                          title: l.upcoming,
                          count: fuTotal,
                          color: Colors.blue.shade700,
                          bgColor: Colors.blue.shade50,
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _SwipeableCard(
                              customer: fu[i],
                              onTap: () => _openDetail(fu[i]),
                              onMessaged: () => _swipeMessaged(fu[i]),
                              onDelete: () => _swipeDelete(fu[i]),
                            ),
                            childCount: fu.length,
                          ),
                        ),
                        if (fuTotal > kDefaultPageSize)
                          SliverToBoxAdapter(
                            child: LoadMoreFooter(
                              hasMore:
                                  _upcomingVisible.hasMore(_filteredUpcoming),
                              loading: false,
                              visible: fu.length,
                              total: fuTotal,
                            ),
                          ),
                      ],
                      ],
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 96 + MediaQuery.of(context).padding.bottom,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _SwipeableCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onMessaged;
  final VoidCallback onDelete;

  const _SwipeableCard({
    required this.customer,
    required this.onTap,
    required this.onMessaged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(customer.id),
      background: _SwipeBg(
        alignment: Alignment.centerLeft,
        color: Colors.green.shade500,
        icon: Icons.check_circle_outline_rounded,
        label: 'Đã nhắn',
      ),
      secondaryBackground: _SwipeBg(
        alignment: Alignment.centerRight,
        color: Colors.red.shade500,
        icon: Icons.delete_outline_rounded,
        label: 'Xoá',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onMessaged();
          return false;
        } else {
          onDelete();
          return false;
        }
      },
      child: CustomerCard(customer: customer, onTap: onTap),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  const _SwipeBg({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment:
              isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (!isLeft) ...[
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(width: 8),
            ],
            Icon(icon, color: Colors.white, size: 26),
            if (isLeft) ...[
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color color;
  final Color bgColor;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Always-visible pinned search bar ─────────────────────────────────────────
class _HomeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final Color bg;

  const _HomeSearchBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark
        ? theme.colorScheme.surfaceVariant
        : Colors.grey.shade100;

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (_, value, __) => SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
              filled: true,
              fillColor: fillColor,
              contentPadding: EdgeInsets.zero,
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: Colors.grey.shade400,
              ),
              suffixIcon: value.text.isNotEmpty
                  ? GestureDetector(
                      onTap: onClear,
                      child: Icon(
                        Icons.cancel_rounded,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.withAlpha(120),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightBanner extends StatelessWidget {
  final int overdueCount;
  final VoidCallback onTap;
  const _InsightBanner({required this.overdueCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.red.shade900.withAlpha(60)
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.red.shade300.withAlpha(isDark ? 80 : 160),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.red.shade600.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.notification_important_rounded,
                      color: Colors.red.shade600, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Có $overdueCount khách quá hạn liên hệ!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nhắn sớm để không mất đơn hàng.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade600.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.red.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onAddDemo;
  const _EmptyState({required this.onAdd, required this.onAddDemo});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withAlpha(30),
                    theme.colorScheme.primary.withAlpha(10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_alt_outlined,
                  size: 48, color: theme.colorScheme.primary.withAlpha(160)),
            ),
            const SizedBox(height: 20),
            Text(
              l.noCustomers,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              l.noCustomersHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade500, height: 1.5),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_rounded),
              label: Text(l.addCustomerTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onAddDemo,
              icon: const Icon(Icons.science_outlined, size: 18),
              label: const Text('Thêm khách mẫu để thử',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(30)),
              ),
              child: Row(
                children: [
                  Icon(Icons.swipe_rounded,
                      size: 20,
                      color: theme.colorScheme.primary.withAlpha(180)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sau khi thêm: vuốt phải = Đã nhắn, vuốt trái = Xoá',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary.withAlpha(200),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Swipe Hint Banner ─────────────────────────────────────────────────────────
class _SwipeHintBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _SwipeHintBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.primary.withAlpha(25)
                : theme.colorScheme.primary.withAlpha(12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.primary.withAlpha(isDark ? 60 : 40),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.swipe_rounded,
                    color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mẹo thao tác nhanh',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '👉 Vuốt phải = Đã nhắn  •  👈 Vuốt trái = Xoá',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close_rounded,
                    size: 16, color: Colors.grey.shade400),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Daily Tip Banner ──────────────────────────────────────────────────────────
class _DailyTipBanner extends StatelessWidget {
  final String tip;
  final VoidCallback onDismiss;
  const _DailyTipBanner({required this.tip, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.amber.shade900.withAlpha(40)
                : Colors.amber.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.amber.shade300.withAlpha(isDark ? 80 : 140),
            ),
          ),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tip.replaceFirst('💡 ', ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.amber.shade200
                        : Colors.amber.shade900,
                    height: 1.4,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close_rounded,
                    size: 16, color: Colors.grey.shade400),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
