import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import 'status_badge.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = customer.needsAttention;
    final theme = Theme.of(context);
    final statusColor =
        Color(AppConstants.statusColors[customer.status] ?? 0xFF9E9E9E);
    final hasPhone =
        customer.phone != null && customer.phone!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: isUrgent ? 2 : 0.5,
        shadowColor: isUrgent
            ? Colors.red.withAlpha(50)
            : Colors.black.withAlpha(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isUrgent
                  ? Border.all(color: Colors.red.shade300, width: 1)
                  : Border(
                      left: BorderSide(color: statusColor, width: 3.5),
                    ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
            child: Row(
              children: [
                _Avatar(name: customer.name, statusColor: statusColor),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              customer.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          StatusBadge(status: customer.status),
                        ],
                      ),
                      if (customer.product != null &&
                          customer.product!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          customer.product!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (customer.source != null &&
                          customer.source!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          AppConstants.sourceLabel(customer.source),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.primary.withAlpha(180),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isUrgent
                                  ? Colors.red.shade600.withAlpha(22)
                                  : theme.colorScheme.surfaceVariant
                                      .withAlpha(100),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUrgent
                                      ? Icons.notification_important_rounded
                                      : Icons.schedule_rounded,
                                  size: 11,
                                  color: isUrgent
                                      ? Colors.red.shade600
                                      : Colors.grey.shade500,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  AppDateUtils.nextActionLabel(
                                      customer.nextActionAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isUrgent
                                        ? Colors.red.shade700
                                        : Colors.grey.shade600,
                                    fontWeight: isUrgent
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasPhone) ...[  
                            const SizedBox(width: 6),
                            _PhoneChip(phone: customer.phone!),
                          ],
                          if (customer.warrantyExpiringSoon) ...[
                            const SizedBox(width: 6),
                            _WarrantyChip(days: customer.warrantyDaysLeft!),
                          ],
                        ],
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

// Palette of gradient pairs indexed by name hash
const _kGradients = [
  [Color(0xFF667EEA), Color(0xFF764BA2)],
  [Color(0xFFF093FB), Color(0xFFF5576C)],
  [Color(0xFF4FACFE), Color(0xFF00F2FE)],
  [Color(0xFF43E97B), Color(0xFF38F9D7)],
  [Color(0xFFFA709A), Color(0xFFFEE140)],
  [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
  [Color(0xFFFCCF31), Color(0xFFF55555)],
  [Color(0xFF0BA360), Color(0xFF3CBA92)],
];

class _Avatar extends StatelessWidget {
  final String name;
  final Color statusColor;
  const _Avatar({required this.name, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : '?';
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % _kGradients.length;
    final colors = _kGradients[idx];
    return Container(
      width: 44,
      height: 44,
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _WarrantyChip extends StatelessWidget {
  final int days;
  const _WarrantyChip({required this.days});

  @override
  Widget build(BuildContext context) {
    final urgent = days <= 7;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: urgent
            ? Colors.red.shade600.withAlpha(22)
            : Colors.amber.shade700.withAlpha(22),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 11,
            color: urgent ? Colors.red.shade600 : Colors.amber.shade700,
          ),
          const SizedBox(width: 3),
          Text(
            'BH: $days ngày',
            style: TextStyle(
              fontSize: 11,
              color: urgent ? Colors.red.shade700 : Colors.amber.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneChip extends StatelessWidget {
  final String phone;
  const _PhoneChip({required this.phone});

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _call,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withAlpha(18),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_rounded,
                size: 11, color: theme.colorScheme.primary),
            const SizedBox(width: 3),
            Text(
              phone,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
