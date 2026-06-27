import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../utils/constants.dart';
import '../widgets/customer_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/infinite_scroll.dart';
import 'customer_detail_screen.dart';

class AllCustomersScreen extends StatefulWidget {
  const AllCustomersScreen({super.key});

  @override
  State<AllCustomersScreen> createState() => _AllCustomersScreenState();
}

enum _SortOrder { newest, overdue, nameAz }

class _AllCustomersScreenState extends State<AllCustomersScreen> {
  final _service = CustomerService();
  List<Customer> _customers = [];
  Map<String, int> _statusCounts = {'all': 0};
  String _filterStatus = 'all';
  String _filterSource = 'all';
  String _searchQuery = '';
  bool _loading = true;
  _SortOrder _sortOrder = _SortOrder.overdue;
  int _page = 1;
  int _totalFiltered = 0;
  int _totalAll = 0;
  bool _loadingMore = false;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _loadGate = LoadMoreGate();

  bool get _hasMore => _customers.length < _totalFiltered;

  @override
  void initState() {
    super.initState();
    bindScrollLoadMore(
      _scrollCtrl,
      hasMore: () => _hasMore && !_loading && !_loadingMore,
      onLoadMore: _loadMore,
      gate: _loadGate,
    );
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _orderBySql() {
    switch (_sortOrder) {
      case _SortOrder.newest:
        return 'created_at DESC';
      case _SortOrder.overdue:
        return 'next_action_at ASC';
      case _SortOrder.nameAz:
        return 'name COLLATE NOCASE ASC';
    }
  }

  Future<void> _load() async {
    _page = 1;
    setState(() => _loading = true);
    final results = await Future.wait([
      _service.getCustomersPaged(
        page: _page,
        pageSize: kDefaultPageSize,
        query: _searchQuery,
        status: _filterStatus,
        source: _filterSource,
        orderBy: _orderBySql(),
      ),
      _service.countCustomers(
        query: _searchQuery,
        status: _filterStatus,
        source: _filterSource,
      ),
      _service.countAllCustomers(),
      _service.getCustomerStatusCounts(),
    ]);
    if (!mounted) return;
    setState(() {
      _customers = results[0] as List<Customer>;
      _totalFiltered = results[1] as int;
      _totalAll = results[2] as int;
      _statusCounts = results[3] as Map<String, int>;
      _loading = false;
    });
    ensureScrollFill(
      controller: _scrollCtrl,
      hasMore: _hasMore,
      onLoadMore: _loadMore,
    );
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loading || _loadingMore) return;
    setState(() => _loadingMore = true);
    final nextPage = _page + 1;
    final list = await _service.getCustomersPaged(
      page: nextPage,
      pageSize: kDefaultPageSize,
      query: _searchQuery,
      status: _filterStatus,
      source: _filterSource,
      orderBy: _orderBySql(),
    );
    if (!mounted) return;
    setState(() {
      _page = nextPage;
      final existing = _customers.map((c) => c.id).toSet();
      _customers.addAll(list.where((c) => !existing.contains(c.id)));
      _loadingMore = false;
    });
    ensureScrollFill(
      controller: _scrollCtrl,
      hasMore: _hasMore,
      onLoadMore: _loadMore,
    );
  }

  void _resetFiltersAndLoad() => _load();

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final options = [
          (_SortOrder.newest, Icons.schedule_rounded, 'Mới nhất trước'),
          (_SortOrder.overdue, Icons.priority_high_rounded, 'Quá hạn trước'),
          (_SortOrder.nameAz, Icons.sort_by_alpha_rounded, 'Tên A → Z'),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sắp xếp theo',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface)),
                const SizedBox(height: 12),
                ...options.map((opt) {
                  final (order, icon, label) = opt;
                  final selected = _sortOrder == order;
                  return ListTile(
                    dense: true,
                    leading: Icon(icon,
                        color: selected
                            ? theme.colorScheme.primary
                            : Colors.grey.shade500),
                    title: Text(label,
                        style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? theme.colorScheme.primary : null,
                        )),
                    trailing: selected
                        ? Icon(Icons.check_rounded,
                            color: theme.colorScheme.primary, size: 18)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _sortOrder = order);
                      _resetFiltersAndLoad();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openDetail(Customer c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: c)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;
    final fillColor =
        isDark ? theme.colorScheme.surfaceVariant : Colors.grey.shade100;

    final subtitle = _totalFiltered == _totalAll
        ? '$_totalAll khách'
        : '$_totalFiltered / $_totalAll khách';

    return Scaffold(
      backgroundColor: bg,
      drawer: const AppDrawer(current: 'customers'),
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: bg,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            titleSpacing: 4,
            toolbarHeight: 56,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.allCustomers,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
            actions: [
              IconButton(
                onPressed: _showSortSheet,
                tooltip: 'Sắp xếp',
                icon: Badge(
                  isLabelVisible: _sortOrder != _SortOrder.overdue,
                  smallSize: 8,
                  child: const Icon(Icons.sort_rounded),
                ),
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(152),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: bg,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchCtrl,
                      builder: (_, value, __) => SizedBox(
                        height: 44,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) {
                            _searchQuery = v;
                            _resetFiltersAndLoad();
                          },
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: l.searchHint,
                            hintStyle: TextStyle(
                                fontSize: 14, color: Colors.grey.shade400),
                            filled: true,
                            fillColor: fillColor,
                            contentPadding: EdgeInsets.zero,
                            prefixIcon: Icon(Icons.search_rounded,
                                size: 20, color: Colors.grey.shade400),
                            suffixIcon: value.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchCtrl.clear();
                                      _searchQuery = '';
                                      _resetFiltersAndLoad();
                                    },
                                    child: Icon(Icons.cancel_rounded,
                                        size: 18,
                                        color: Colors.grey.shade400),
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
                  ),
                  _FilterBar(
                    selected: _filterStatus,
                    counts: _statusCounts,
                    onSelect: (s) {
                      _filterStatus = s;
                      _resetFiltersAndLoad();
                    },
                    bg: bg,
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      children: [
                        _SourceChip(
                          label: 'Nguồn: Tất cả',
                          selected: _filterSource == 'all',
                          onTap: () {
                            _filterSource = 'all';
                            _resetFiltersAndLoad();
                          },
                        ),
                        _SourceChip(
                          label: 'Chưa ghi',
                          selected: _filterSource == '_none',
                          onTap: () {
                            _filterSource = '_none';
                            _resetFiltersAndLoad();
                          },
                        ),
                        ...AppConstants.customerSources.map((s) => _SourceChip(
                              label: s['label']!,
                              selected: _filterSource == s['key'],
                              onTap: () {
                                _filterSource = s['key']!;
                                _resetFiltersAndLoad();
                              },
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_totalFiltered == 0)
            SliverFillRemaining(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 24),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? l.noSearchResults
                            : l.noCustomers,
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.only(top: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => CustomerCard(
                    customer: _customers[i],
                    onTap: () => _openDetail(_customers[i]),
                  ),
                  childCount: _customers.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: LoadMoreFooter(
                hasMore: _hasMore,
                loading: _loadingMore,
                visible: _customers.length,
                total: _totalFiltered,
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 24 + MediaQuery.of(context).padding.bottom,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String selected;
  final Map<String, int> counts;
  final ValueChanged<String> onSelect;
  final Color bg;

  const _FilterBar({
    required this.selected,
    required this.counts,
    required this.onSelect,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final filters = [
      ('all', l.allCustomers),
      ...AppConstants.statuses.map((s) => (s, l.statusLabel(s))),
    ];

    return Container(
      height: 44,
      color: bg,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final (key, label) = filters[i];
          final isSelected = selected == key;
          final count = counts[key] ?? 0;
          final statusColor = key == 'all'
              ? theme.colorScheme.primary
              : Color(AppConstants.statusColors[key]!);

          return GestureDetector(
            onTap: () => onSelect(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? statusColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? statusColor : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withAlpha(60)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SourceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: theme.colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
