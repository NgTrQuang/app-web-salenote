import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/segment_service.dart';
import '../services/customer_service.dart';
import '../utils/constants.dart';
import '../screens/customer_detail_screen.dart';

class SegmentActionSheet extends StatefulWidget {
  final ProductSegment segment;

  const SegmentActionSheet({super.key, required this.segment});

  static Future<void> show(BuildContext context, ProductSegment segment) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SegmentActionSheet(segment: segment),
    );
  }

  @override
  State<SegmentActionSheet> createState() => _SegmentActionSheetState();
}

class _SegmentActionSheetState extends State<SegmentActionSheet> {
  String _template = AppConstants.defaultMessage;
  static const _pageSize = 20;
  int _visible = 20;

  @override
  void initState() {
    super.initState();
    CustomerService().getMessageTemplate().then((t) {
      if (mounted) setState(() => _template = t);
    });
  }

  List<SegmentCustomer> get _slice =>
      widget.segment.customers.take(_visible).toList();

  bool get _hasMore => _visible < widget.segment.customers.length;

  void _loadMore() {
    setState(() {
      _visible = (_visible + _pageSize).clamp(0, widget.segment.customers.length);
    });
  }

  String _message(String name, String product) {
    final svc = CustomerService();
    return svc.applyMessageTemplate(_template, name, product);
  }

  Future<void> _copyOne(String name, String product) async {
    await Clipboard.setData(ClipboardData(text: _message(name, product)));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã copy tin cho $name')),
      );
    }
  }

  Future<void> _copyAll() async {
    final lines = widget.segment.customers
        .map((c) => _message(c.name, c.product))
        .join('\n\n');
    await Clipboard.setData(ClipboardData(text: lines));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Đã copy ${widget.segment.customers.length} tin nhắn')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.75;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nhắn ${widget.segment.customers.length} khách',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'Mua ${widget.segment.productName} cách đây 30+ ngày — copy tin dán Zalo',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH * 0.55),
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollEndNotification && _hasMore) {
                    final m = n.metrics;
                    if (m.pixels >= m.maxScrollExtent - 80) _loadMore();
                  }
                  return false;
                },
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _slice.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    if (i >= _slice.length) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: Text(
                            'Cuộn để xem thêm (${_slice.length}/${widget.segment.customers.length})',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ),
                      );
                    }
                    final c = _slice[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Mua ${c.daysSincePurchase} ngày trước'),
                      trailing: TextButton.icon(
                        onPressed: () => _copyOne(c.name, c.product),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy'),
                      ),
                      onTap: () async {
                        final customer = await CustomerService()
                            .getCustomer(c.customerId);
                        if (customer != null && context.mounted) {
                          Navigator.pop(context);
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustomerDetailScreen(customer: customer),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _copyAll,
              icon: const Icon(Icons.copy_all),
              label: Text('Copy tất cả (${widget.segment.customers.length})'),
            ),
          ],
        ),
      ),
    );
  }
}
