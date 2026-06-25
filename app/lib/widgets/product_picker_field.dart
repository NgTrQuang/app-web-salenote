import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/money.dart';

const _pageSize = 20;

/// Chọn sản phẩm có tìm kiếm và phân trang — tránh dropdown dài và tràn chuỗi.
class ProductPickerField extends StatelessWidget {
  final List<Product> products;
  final int? value;
  final ValueChanged<int?> onChanged;

  const ProductPickerField({
    super.key,
    required this.products,
    required this.value,
    required this.onChanged,
  });

  Product? get _selected {
    if (value == null) return null;
    try {
      return products.firstWhere((p) => p.id == value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _ProductPickerSheet(
        products: products,
        selectedId: value,
      ),
    );
    if (!context.mounted || picked == null) return;
    onChanged(picked < 0 ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final label = selected == null
        ? '— Nhập tay —'
        : '${selected.name} (${formatMoney(selected.defaultSellPrice)})';

    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Chọn từ danh mục',
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  final List<Product> products;
  final int? selectedId;

  const _ProductPickerSheet({required this.products, this.selectedId});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final _searchCtrl = TextEditingController();
  int _page = 1;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.products;
    return widget.products.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 999999);
    final safePage = _page.clamp(1, totalPages);
    final start = (safePage - 1) * _pageSize;
    final slice = filtered.skip(start).take(_pageSize).toList();
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Chọn sản phẩm',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Tìm tên sản phẩm...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() {
              _query = v;
              _page = 1;
            }),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: const Text('— Nhập tay —'),
                  selected: widget.selectedId == null,
                  onTap: () => Navigator.pop(context, -1),
                ),
                ...slice.map((p) {
                  final subtitle = p.trackInventory
                      ? '${formatMoney(p.defaultSellPrice)} · kho: ${p.stockQuantity}'
                      : formatMoney(p.defaultSellPrice);
                  return ListTile(
                    title: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(p.name),
                    ),
                    subtitle: Text(subtitle),
                    selected: widget.selectedId == p.id,
                    onTap: () => Navigator.pop(context, p.id),
                  );
                }),
                if (slice.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Không tìm thấy')),
                  ),
              ],
            ),
          ),
          if (totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: safePage > 1 ? () => setState(() => _page = safePage - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('$safePage / $totalPages'),
                IconButton(
                  onPressed: safePage < totalPages ? () => setState(() => _page = safePage + 1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
