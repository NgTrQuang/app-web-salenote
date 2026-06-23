import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../utils/constants.dart';
import '../widgets/customer_card.dart';
import 'customer_detail_screen.dart';

class AllCustomersScreen extends StatefulWidget {
  const AllCustomersScreen({super.key});

  @override
  State<AllCustomersScreen> createState() => _AllCustomersScreenState();
}

enum _SortOrder { newest, overdue, nameAz }

class _AllCustomersScreenState extends State<AllCustomersScreen> {
  final _service = CustomerService();
  List<Customer> _all = [];
  List<Customer> _filtered = [];
  String _filterStatus = 'all';
  String _searchQuery = '';
  bool _loading = true;
  _SortOrder _sortOrder = _SortOrder.newest;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await _service.getAllCustomers();
    if (!mounted) return;
    setState(() {
      _all = all;
      _loading = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    var list = _all;
    if (_filterStatus != 'all') {
      list = list.where((c) => c.status == _filterStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) {
        return c.name.toLowerCase().contains(q) ||
            (c.phone?.contains(q) ?? false) ||
            (c.product?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    list = List.of(list);
    switch (_sortOrder) {
      case _SortOrder.newest:
        list.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
        break;
      case _SortOrder.overdue:
        list.sort((a, b) => (a.nextActionAt ?? 0).compareTo(b.nextActionAt ?? 0));
        break;
      case _SortOrder.nameAz:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    _filtered = list;
  }

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
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? theme.colorScheme.primary
                              : null,
                        )),
                    trailing: selected
                        ? Icon(Icons.check_rounded,
                            color: theme.colorScheme.primary, size: 18)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _sortOrder = order;
                        _applyFilter();
                      });
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

  void _onSearch(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilter();
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _searchQuery = '';
      _applyFilter();
    });
  }

  void _onFilter(String status) {
    setState(() {
      _filterStatus = status;
      _applyFilter();
    });
  }

  Future<void> _openDetail(Customer c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: c)),
    );
    _load();
  }

  Map<String, int> _buildCounts() {
    final counts = <String, int>{'all': _all.length};
    for (final s in AppConstants.statuses) {
      counts[s] = _all.where((c) => c.status == s).length;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark
        ? theme.colorScheme.surfaceVariant
        : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── Pinned AppBar + Search + Filter ───────────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: bg,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            titleSpacing: 4,
            toolbarHeight: 56,
            title: Text(
              l.allCustomers,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                onPressed: _showSortSheet,
                tooltip: 'Sắp xếp',
                icon: Badge(
                  isLabelVisible: _sortOrder != _SortOrder.newest,
                  smallSize: 8,
                  child: const Icon(Icons.sort_rounded),
                ),
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(108),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search bar
                  Container(
                    color: bg,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchCtrl,
                      builder: (_, value, __) => SizedBox(
                        height: 44,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: _onSearch,
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
                                    onTap: _clearSearch,
                                    child: Icon(Icons.cancel_rounded,
                                        size: 18, color: Colors.grey.shade400),
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
                  // Filter chips
                  _FilterBar(
                    selected: _filterStatus,
                    counts: _buildCounts(),
                    onSelect: _onFilter,
                    bg: bg,
                  ),
                ],
              ),
            ),
          ),

          // ── List content ────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filtered.isEmpty)
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
          else
            SliverPadding(
              padding: EdgeInsets.only(
                top: 8,
                bottom: 24 + MediaQuery.of(context).padding.bottom,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => CustomerCard(
                    customer: _filtered[i],
                    onTap: () => _openDetail(_filtered[i]),
                  ),
                  childCount: _filtered.length,
                ),
              ),
            ),
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
                  color: isSelected
                      ? statusColor
                      : Colors.grey.shade300,
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
