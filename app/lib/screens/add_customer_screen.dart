import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/customer_service.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../utils/constants.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _status = 'new';
  String? _source;
  int? _productId;
  List<Product> _products = [];
  bool _saving = false;
  DateTime? _warrantyEndDate;

  @override
  void initState() {
    super.initState();
    ProductService().getAllProducts(activeOnly: true).then((list) {
      if (mounted) setState(() => _products = list);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _productCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickWarrantyDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _warrantyEndDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      helpText: 'Ngày hết bảo hành',
      confirmText: 'Chọn',
      cancelText: 'Bỏ qua',
    );
    if (picked != null && mounted) {
      setState(() => _warrantyEndDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final customer = await CustomerService().addCustomer(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        product:
            _productCtrl.text.trim().isEmpty ? null : _productCtrl.text.trim(),
        productId: _productId,
        source: _source,
        status: _status,
        warrantyEndDate: _warrantyEndDate,
      );
      if (mounted) Navigator.of(context).pop(customer);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(l.addCustomerTitle),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.save,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + MediaQuery.of(context).padding.bottom),
          children: [
            const SizedBox(height: 10),
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l.customerName,
                hintText: l.customerNameHint,
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.customerNameRequired : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              decoration: InputDecoration(
                labelText: l.phone,
                hintText: l.phoneHint,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ giao hàng',
                hintText: 'Số nhà, phường, quận, tỉnh...',
                prefixIcon: Icon(Icons.location_on_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String?>(
              value: _source,
              decoration: const InputDecoration(
                labelText: 'Nguồn khách',
                prefixIcon: Icon(Icons.campaign_outlined),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('— Chọn nguồn —')),
                ...AppConstants.customerSources.map(
                  (s) => DropdownMenuItem(
                    value: s['key'],
                    child: Text(s['label']!),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _source = v),
            ),
            const SizedBox(height: 14),
            if (_products.isNotEmpty)
              DropdownButtonFormField<int?>(
                value: _productId,
                decoration: const InputDecoration(
                  labelText: 'SP từ danh mục',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— Chọn —')),
                  ..._products.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name, overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (id) {
                  setState(() {
                    _productId = id;
                    if (id != null) {
                      final p = _products.firstWhere((x) => x.id == id);
                      _productCtrl.text = p.name;
                    }
                  });
                },
              ),
            if (_products.isNotEmpty) const SizedBox(height: 14),
            TextFormField(
              controller: _productCtrl,
              decoration: InputDecoration(
                labelText: l.product,
                hintText: l.productHint,
                prefixIcon: const Icon(Icons.shopping_bag_outlined),
              ),
              onChanged: (_) => setState(() => _productId = null),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: l.note,
                hintText: l.noteHint,
                prefixIcon: const Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 14),
            _WarrantyDateField(
              date: _warrantyEndDate,
              onPick: _pickWarrantyDate,
              onClear: () => setState(() => _warrantyEndDate = null),
            ),
            const SizedBox(height: 20),
            _SectionLabel(l.status),
            const SizedBox(height: 10),
            _StatusPicker(
              selected: _status,
              onChanged: (s) => setState(() => _status = s),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.person_add_rounded),
                label: Text(l.addCustomerTitle,
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _WarrantyDateField extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;
  const _WarrantyDateField({
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDate = date != null;
    final label = hasDate
        ? '${date!.day.toString().padLeft(2, '0')}/'
          '${date!.month.toString().padLeft(2, '0')}/'
          '${date!.year}'
        : 'Không có bảo hành';

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Ngày hết bảo hành',
          prefixIcon: Icon(
            Icons.shield_outlined,
            color: hasDate ? Colors.amber.shade700 : null,
          ),
          suffixIcon: hasDate
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: hasDate
                ? theme.colorScheme.onSurface
                : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

class _StatusPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _StatusPicker({required this.selected, required this.onChanged});

  static const _items = [
    (
      status: 'new',
      icon: '🔵',
      color: Color(0xFF2196F3),
      bgColor: Color(0xFFE3F2FD),
      labelVi: 'Mới',
      labelEn: 'New',
      hintVi: 'Khách vừa thêm\nNhắc sau 1 ngày',
      hintEn: 'Just added\nRemind in 1 day',
    ),
    (
      status: 'warm',
      icon: '🟠',
      color: Color(0xFFFF9800),
      bgColor: Color(0xFFFFF3E0),
      labelVi: 'Tiềm năng',
      labelEn: 'Warm',
      hintVi: 'Đang cân nhắc\nNhắc sau 2 ngày',
      hintEn: 'Considering\nRemind in 2 days',
    ),
    (
      status: 'hot',
      icon: '🔴',
      color: Color(0xFFE53935),
      bgColor: Color(0xFFFFEBEE),
      labelVi: 'Nóng',
      labelEn: 'Hot',
      hintVi: 'Sắp chốt đơn\nNhắc sau 1 ngày',
      hintEn: 'About to close\nRemind in 1 day',
    ),
    (
      status: 'closed',
      icon: '🟢',
      color: Color(0xFF4CAF50),
      bgColor: Color(0xFFE8F5E9),
      labelVi: 'Đã chốt',
      labelEn: 'Closed',
      hintVi: 'Đã mua hàng\nNhắc sau 7 ngày',
      hintEn: 'Purchased\nRemind in 7 days',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    return Row(
      children: _items.map((item) {
        final isSelected = selected == item.status;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(item.status),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? item.bgColor : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? item.color : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(
                    isVi ? item.labelVi : item.labelEn,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? item.color : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isVi ? item.hintVi : item.hintEn,
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected
                          ? item.color.withAlpha(180)
                          : Colors.grey.shade400,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
