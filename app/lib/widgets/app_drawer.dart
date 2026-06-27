import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/home_screen.dart';
import '../screens/all_customers_screen.dart';
import '../screens/products_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/add_order_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/debts_screen.dart';
import '../screens/guide_screen.dart';
import '../screens/settings_screen.dart';
import '../utils/constants.dart';
import 'app_logo.dart';

/// Sidebar tương đương web Layout — 7 mục chính + ghi đơn nhanh
class AppDrawer extends StatelessWidget {
  final String current;

  const AppDrawer({super.key, this.current = 'home'});

  static void goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Row(
                children: [
                  const AppLogo(size: 44, borderRadius: 10),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.appName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        Text(l.appTagline,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _item(context, 'home', Icons.today_outlined, AppConstants.navHomeLabel, () => goHome(context)),
                  _item(context, 'customers', Icons.people_outline, AppConstants.navCustomersLabel, () => _push(context, const AllCustomersScreen())),
                  _item(context, 'products', Icons.inventory_2_outlined, 'Sản phẩm', () => _push(context, const ProductsScreen())),
                  _item(context, 'orders', Icons.receipt_long_outlined, 'Đơn hàng', () => _push(context, const OrdersScreen())),
                  _item(context, 'debts', Icons.payments_outlined, AppConstants.navDebtsLabel, () => _push(context, const DebtsScreen())),
                  _item(context, 'stats', Icons.bar_chart_outlined, AppConstants.navStatsLabel, () => _push(context, const StatsScreen())),
                  _item(context, 'guide', Icons.menu_book_outlined, l.guideTitle, () => _push(context, const GuideScreen())),
                  _item(context, 'settings', Icons.settings_outlined, l.settings, () => _push(context, const SettingsScreen())),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddOrderScreen()),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart_outlined, size: 20),
                label: const Text('Ghi đơn mới'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'SQLite · Offline · JSON đồng bộ web',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    String id,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final selected = current == id;
    return ListTile(
      leading: Icon(icon,
          color: selected ? Theme.of(context).colorScheme.primary : null),
      title: Text(label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          )),
      selected: selected,
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _push(BuildContext context, Widget screen) {
    if (screen.runtimeType == HomeScreen) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}
