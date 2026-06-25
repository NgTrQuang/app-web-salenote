import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../models/interaction.dart';
import '../models/order.dart';
import '../services/customer_service.dart';
import '../services/order_service.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../utils/money.dart';
import '../services/insights_service.dart';
import '../widgets/insights_panels.dart';
import '../widgets/order_form_sheet.dart';
import '../widgets/order_payment_sheet.dart';
import '../widgets/bill_preview_sheet.dart';
import '../utils/shipping_utils.dart';
import '../widgets/status_badge.dart';
import 'edit_customer_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late Customer _customer;
  final _service = CustomerService();
  final _orderService = OrderService();
  List<Interaction> _interactions = [];
  List<Order> _orders = [];
  SalesSummary _sales = const SalesSummary();
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadInteractions(), _loadOrders()]);
  }

  Future<void> _loadOrders() async {
    if (_customer.id == null) return;
    final orders = await _orderService.getOrdersByCustomer(_customer.id!);
    final summary = await _orderService.getCustomerSalesSummary(_customer.id!);
    if (mounted) {
      setState(() {
        _orders = orders;
        _sales = summary;
      });
    }
  }

  Future<void> _loadInteractions() async {
    final list = await _service.getInteractions(_customer.id!);
    if (mounted) setState(() => _interactions = list);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
  }

  Future<void> _showMessageDialog() async {
    // Capture scaffoldMessenger before async gap
    final messenger = ScaffoldMessenger.of(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MessageBottomSheet(
        customer: _customer,
        messenger: messenger,
        onConfirmed: _onMessageSent,
      ),
    );
  }

  Future<void> _onMessageSent() async {
    setState(() => _actionLoading = true);
    try {
      await _service.messageSent(_customer);
      final updated = await _service.getCustomer(_customer.id!);
      if (updated != null && mounted) {
        setState(() {
          _customer = updated;
          _actionLoading = false;
        });
        await _loadInteractions();
        _showSnack('Đã ghi nhận liên hệ ✓');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionLoading = false);
        _showSnack('Lỗi: $e');
      }
    }
  }

  Future<void> _recordOrder() async {
    await OrderFormSheet.show(context, _customer);
    final updated = await _service.getCustomer(_customer.id!);
    if (updated != null && mounted) {
      setState(() => _customer = updated);
      await _loadData();
      _showSnack('Đã ghi đơn hàng ✓');
    }
  }

  Future<void> _editCustomer() async {
    final updated = await Navigator.of(context).push<Customer>(
      MaterialPageRoute(
        builder: (_) => EditCustomerScreen(customer: _customer),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _customer = updated);
      await _loadInteractions();
    }
  }

  Future<void> _deleteCustomer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá khách hàng?'),
        content: Text('Xoá ${_customer.name} sẽ không thể khôi phục. Tiếp tục?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await _service.deleteCustomer(_customer.id!);
    if (mounted) Navigator.of(context).pop('deleted');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(_customer.name,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Chỉnh sửa',
            onPressed: _editCustomer,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: Colors.red.shade400),
            tooltip: 'Xoá',
            onPressed: _deleteCustomer,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 32 + MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileCard(customer: _customer),
            const SizedBox(height: 14),
            _TimingCard(customer: _customer),
            const SizedBox(height: 16),
            _ActionBar(
              customer: _customer,
              loading: _actionLoading,
              onMessage: _showMessageDialog,
              onOrder: _recordOrder,
              onEdit: _editCustomer,
            ),
            if (_orders.isNotEmpty) ...[
              const SizedBox(height: 20),
              CustomerIntelligenceCard(
                intel: InsightsService().buildCustomerIntelligence(_customer, _orders),
              ),
              const SizedBox(height: 12),
              Text('Đơn hàng (${_orders.length})',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Doanh thu', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          Text(formatMoney(_sales.revenue), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Lợi nhuận', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          Text(formatMoney(_sales.profit), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                        ],
                      ),
                      const Divider(height: 16),
                      ..._orders.take(5).map((o) => _OrderRow(
                            order: o,
                            customer: _customer,
                            onTap: () => OrderPaymentSheet.show(
                              context,
                              order: o,
                              customer: _customer,
                              onSaved: _loadOrders,
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],
            if (_interactions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Text('Lịch sử liên hệ',
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${_interactions.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _InteractionTimeline(interactions: _interactions),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Profile Card ─────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final Customer customer;
  const _ProfileCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GradientAvatar(name: customer.name, radius: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(customer.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                      StatusBadge(status: customer.status),
                    ],
                  ),
                  if (customer.phone != null &&
                      customer.phone!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Copy button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: customer.phone!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Đã sao chép ${customer.phone}'),
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              );
                            },
                            icon: Icon(Icons.copy_rounded,
                                size: 14,
                                color: theme.colorScheme.primary),
                            label: Text(
                              customer.phone!,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              side: BorderSide(
                                  color: theme.colorScheme.primary
                                      .withAlpha(80)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Call button
                        FilledButton(
                          onPressed: () async {
                            final uri = Uri(
                                scheme: 'tel', path: customer.phone!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Colors.green.shade600,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.phone_rounded,
                                  size: 16, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Gọi',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (customer.address != null && customer.address!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            customer.address!,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Sao chép địa chỉ',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: customer.address!.trim()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép địa chỉ'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: Icon(Icons.copy_rounded,
                              size: 16, color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ],
                  if (customer.source != null &&
                      customer.source!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.campaign_outlined,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          AppConstants.sourceLabel(customer.source),
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ],
                  if (customer.warrantyEndDate != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.verified_outlined,
                            size: 14,
                            color: customer.warrantyExpiringSoon
                                ? Colors.orange.shade700
                                : Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Bảo hành đến ${AppDateUtils.formatDate(customer.warrantyEndDate!)}'
                            '${customer.warrantyDaysLeft != null ? ' (còn ${customer.warrantyDaysLeft} ngày)' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: customer.warrantyExpiringSoon
                                  ? Colors.orange.shade800
                                  : Colors.grey.shade700,
                              fontWeight: customer.warrantyExpiringSoon
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (customer.product != null &&
                      customer.product!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            customer.product!,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (customer.note != null &&
                      customer.note!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade700.withAlpha(80)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes_rounded,
                              size: 14, color: Colors.amber.shade700),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              customer.note!,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final Order order;
  final Customer customer;
  final VoidCallback onTap;

  const _OrderRow({
    required this.order,
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text('${order.productName} × ${order.quantity}'),
          subtitle: Text(AppConstants.paymentLabels[order.paymentStatus] ?? order.paymentStatus),
          trailing: Text(formatMoney(order.revenue)),
          onTap: onTap,
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                    ClipboardData(text: formatShippingInfo(customer, order)));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép thông tin giao hàng')),
                  );
                }
              },
              icon: const Icon(Icons.local_shipping_outlined, size: 16),
              label: const Text('Copy ship', style: TextStyle(fontSize: 12)),
            ),
            TextButton.icon(
              onPressed: () => BillPreviewSheet.show(context, customer: customer, order: order),
              icon: const Icon(Icons.receipt_long_outlined, size: 16),
              label: const Text('Bill', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const Divider(height: 8),
      ],
    );
  }
}

// ── Timing Card ──────────────────────────────────────────────

class _TimingCard extends StatelessWidget {
  final Customer customer;
  const _TimingCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final isUrgent = customer.needsAttention;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isUrgent
            ? BorderSide(color: Colors.red.shade300, width: 1.5)
            : BorderSide.none,
      ),
      color: isUrgent ? Colors.red.shade700.withAlpha(20) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: _TimingItem(
                icon: Icons.calendar_today_outlined,
                label: 'Ngày thêm',
                value: AppDateUtils.formatDate(customer.createdAt),
                iconColor: Colors.grey.shade500,
              ),
            ),
            Container(width: 1, height: 36, color: Theme.of(context).colorScheme.outlineVariant.withAlpha(100)),
            Expanded(
              child: _TimingItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Liên hệ cuối',
                value: AppDateUtils.relativeTime(customer.lastContactAt),
                iconColor: Colors.blue.shade400,
              ),
            ),
            Container(width: 1, height: 36, color: Theme.of(context).colorScheme.outlineVariant.withAlpha(100)),
            Expanded(
              child: _TimingItem(
                icon: Icons.alarm_rounded,
                label: 'Nhắc tiếp',
                value: AppDateUtils.nextActionLabel(customer.nextActionAt),
                iconColor: isUrgent ? Colors.red.shade500 : Colors.green.shade600,
                valueColor: isUrgent ? Colors.red.shade700 : null,
                bold: isUrgent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color? valueColor;
  final bool bold;

  const _TimingItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 4),
          Text(label,
              style:
                  TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Bar ───────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final Customer customer;
  final bool loading;
  final VoidCallback onMessage;
  final VoidCallback onOrder;
  final VoidCallback onEdit;

  const _ActionBar({
    required this.customer,
    required this.loading,
    required this.onMessage,
    required this.onOrder,
    required this.onEdit,
  });

  Future<void> _call() async {
    final phone = customer.phone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone =
        customer.phone != null && customer.phone!.isNotEmpty;
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Row 1: Nhắn tin + Chốt/Sửa
        Row(
          children: [
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: onMessage,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Nhắn tin',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (customer.status != 'closed')
              Expanded(
                child: FilledButton.tonal(
                  onPressed: onOrder,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.green.shade700.withAlpha(30),
                    foregroundColor: Colors.green.shade700,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.receipt_long_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Ghi đơn',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Sửa',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
          ],
        ),
        // Row 2: Gọi điện (chỉ hiện khi có SĐT)
        if (hasPhone) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _call,
            icon: const Icon(Icons.phone_rounded, size: 18),
            label: Text(
              'Gọi điện cho ${customer.name}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              foregroundColor: Colors.green.shade700,
              side: BorderSide(color: Colors.green.shade400),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Interaction Timeline ─────────────────────────────────────

class _InteractionTimeline extends StatelessWidget {
  final List<Interaction> interactions;
  const _InteractionTimeline({required this.interactions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(interactions.length, (index) {
            final item = interactions[index];
            final isLast = index == interactions.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            color: Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.content,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                            AppDateUtils.formatDateTime(item.createdAt),
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Message Bottom Sheet ─────────────────────────────────────

class _MessageBottomSheet extends StatefulWidget {
  final Customer customer;
  final ScaffoldMessengerState messenger;
  final VoidCallback onConfirmed;

  const _MessageBottomSheet({
    required this.customer,
    required this.messenger,
    required this.onConfirmed,
  });

  @override
  State<_MessageBottomSheet> createState() => _MessageBottomSheetState();
}

class _MessageBottomSheetState extends State<_MessageBottomSheet> {
  late final TextEditingController _msgCtrl;
  final _service = CustomerService();

  @override
  void initState() {
    super.initState();
    _msgCtrl = TextEditingController();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final template = await _service.getMessageTemplate();
    final name = widget.customer.name;
    final product = widget.customer.product ?? 'sản phẩm';
    final text = template
        .replaceAll('{tên}', name)
        .replaceAll('{sản_phẩm}', product);
    if (mounted) _msgCtrl.text = text;
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _callPhone() async {
    final phone = widget.customer.phone;
    if (phone == null || phone.isEmpty) return;

    // Kiểm tra và xin quyền CALL_PHONE
    var status = await Permission.phone.status;
    if (status.isDenied) {
      status = await Permission.phone.request();
    }

    if (!mounted) return;

    if (status.isPermanentlyDenied) {
      // Người dùng đã từ chối vĩnh viễn → mở Settings
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cần quyền gọi điện'),
          content: const Text(
              'Bạn đã từ chối quyền gọi điện. Vui lòng vào Cài đặt > Ứng dụng để cấp quyền.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text('Mở Cài đặt'),
            ),
          ],
        ),
      );
      return;
    }

    if (status.isDenied) return; // Người dùng vừa từ chối, không làm gì

    // Có quyền → gọi trực tiếp với ACTION_CALL
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyAndConfirm(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _msgCtrl.text));
    Navigator.of(context).pop();
    widget.onConfirmed();
    widget.messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: const Text('Đã sao chép tin nhắn & ghi nhận liên hệ ✓'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhone = widget.customer.phone != null &&
        widget.customer.phone!.isNotEmpty;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Material(
          color: theme.colorScheme.surface,
          child: SafeArea(
            top: false,
            child: Column(
            children: [
              // ── Drag handle ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // ── Scrollable body ──────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  children: [
                    // Header: avatar + name + phone
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            widget.customer.name.trim().isNotEmpty
                                ? widget.customer.name.trim()[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Liên hệ ${widget.customer.name}',
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              if (hasPhone) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.customer.phone!,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.primary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Quick actions: Gọi điện ──────────────
                    if (hasPhone) ...[
                      _SectionLabel('Gọi điện trực tiếp', theme),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _callPhone,
                          icon: Icon(Icons.phone_rounded,
                              size: 18,
                              color: Colors.green.shade700),
                          label: Text(
                            widget.customer.phone!,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: BorderSide(
                                color: Colors.green.shade700.withAlpha(100)),
                            backgroundColor:
                                Colors.green.shade700.withAlpha(15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Gợi ý template theo ngành ────────────
                    _SectionLabel('Gợi ý nhanh', theme),
                    const SizedBox(height: 8),
                    _QuickTemplates(
                      customer: widget.customer,
                      onSelect: (t) => setState(() => _msgCtrl.text = t),
                    ),
                    const SizedBox(height: 16),

                    // ── Tin nhắn ─────────────────────────────
                    _SectionLabel('Soạn tin nhắn', theme),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _msgCtrl,
                      maxLines: null,
                      minLines: 4,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor:
                            theme.colorScheme.surfaceVariant.withAlpha(100),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: theme.colorScheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: theme.colorScheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: theme.colorScheme.primary, width: 2),
                        ),
                        hintText: 'Soạn tin nhắn...',
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Hint về quy trình
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: theme.colorScheme.primary.withAlpha(40)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nhấn "Sao chép & Đã nhắn" để sao chép tin nhắn vào clipboard, '
                              'sau đó dán vào Zalo/SMS/Messenger. App sẽ tự ghi nhận lần liên hệ này và tính lại lịch nhắc tiếp theo.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.primary,
                                  height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // ── Sticky action buttons ────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                        color: theme.colorScheme.outlineVariant.withAlpha(80)),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Huỷ',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => _copyAndConfirm(context),
                        icon: const Icon(Icons.copy_all_rounded, size: 18),
                        label: const Text('Sao chép & Đã nhắn',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final ThemeData theme;
  const _SectionLabel(this.text, this.theme);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 0.8,
      ),
    );
  }
}

// Gradient avatar — shared across detail screen components
const _kDetailGradients = [
  [Color(0xFF667EEA), Color(0xFF764BA2)],
  [Color(0xFFF093FB), Color(0xFFF5576C)],
  [Color(0xFF4FACFE), Color(0xFF00F2FE)],
  [Color(0xFF43E97B), Color(0xFF38F9D7)],
  [Color(0xFFFA709A), Color(0xFFFEE140)],
  [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
  [Color(0xFFFCCF31), Color(0xFFF55555)],
  [Color(0xFF0BA360), Color(0xFF3CBA92)],
];

class _GradientAvatar extends StatelessWidget {
  final String name;
  final double radius;
  const _GradientAvatar({required this.name, required this.radius});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : '?';
    final idx =
        name.codeUnits.fold(0, (a, b) => a + b) % _kDetailGradients.length;
    final colors = _kDetailGradients[idx];
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.8,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Quick Templates ───────────────────────────────────────────

class _QuickTemplates extends StatelessWidget {
  final Customer customer;
  final ValueChanged<String> onSelect;
  const _QuickTemplates({required this.customer, required this.onSelect});

  static const _templates = [
    (
      label: '👗 Quần áo',
      icon: Icons.checkroom_outlined,
      text: 'Chào {tên}! Shop vừa về mẫu mới cực đẹp, hàng giới hạn. '
          'Anh/chị xem thử không ạ? 😍',
    ),
    (
      label: '💄 Mỹ phẩm',
      icon: Icons.spa_outlined,
      text: 'Chào {tên}! Bên em đang có deal {sản_phẩm} giảm đặc biệt '
          'cho khách cũ. Anh/chị quan tâm không ạ? ✨',
    ),
    (
      label: '🍜 Đồ ăn',
      icon: Icons.restaurant_outlined,
      text: 'Chào {tên}! Hôm nay shop có combo {sản_phẩm} mới, '
          'giao nhanh 30 phút. Anh/chị đặt ngay nhé! 🍱',
    ),
    (
      label: '🔧 Bảo hành',
      icon: Icons.shield_outlined,
      text: 'Chào {tên}! Bảo hành {sản_phẩm} của anh/chị sắp hết. '
          'Liên hệ ngay để được hỗ trợ gia hạn ưu đãi ạ 🛡️',
    ),
    (
      label: '📦 Giao hàng',
      icon: Icons.local_shipping_outlined,
      text: 'Chào {tên}! Đơn hàng {sản_phẩm} của anh/chị đã sẵn sàng. '
          'Anh/chị xác nhận để shop giao nhé! 🚀',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = customer.name;
    final product = customer.product ?? 'sản phẩm';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _templates.map((t) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Icon(t.icon, size: 16,
                  color: theme.colorScheme.primary),
              label: Text(
                t.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              backgroundColor: theme.colorScheme.primary.withAlpha(14),
              side: BorderSide(
                  color: theme.colorScheme.primary.withAlpha(60)),
              onPressed: () {
                final filled = t.text
                    .replaceAll('{tên}', name)
                    .replaceAll('{sản_phẩm}', product);
                onSelect(filled);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
