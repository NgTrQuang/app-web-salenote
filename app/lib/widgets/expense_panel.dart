import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../utils/constants.dart';
import '../utils/money.dart';

class ExpensePanel extends StatefulWidget {
  final DateTime date;
  final double grossProfit;

  const ExpensePanel({
    super.key,
    required this.date,
    required this.grossProfit,
  });

  @override
  State<ExpensePanel> createState() => _ExpensePanelState();
}

class _ExpensePanelState extends State<ExpensePanel> {
  final _service = ExpenseService();
  List<Expense> _expenses = [];
  double _totalExpenses = 0;
  double _trueProfit = 0;
  String _category = 'stock';
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ExpensePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date ||
        oldWidget.grossProfit != widget.grossProfit) {
      _load();
    }
  }

  Future<void> _load() async {
    final list = await _service.getExpensesForMonth(widget.date);
    final total = await _service.getExpensesTotalForMonth(widget.date);
    final net = await _service.getTrueProfit(widget.grossProfit, widget.date);
    if (mounted) {
      setState(() {
        _expenses = list;
        _totalExpenses = total;
        _trueProfit = net;
      });
    }
  }

  Future<void> _add() async {
    final amount = parseMoneyInput(_amountCtrl.text);
    if (amount <= 0) return;
    await _service.addExpense(
      category: _category,
      amount: amount,
      note: _noteCtrl.text,
    );
    _amountCtrl.clear();
    _noteCtrl.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chi phí & lãi thật',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Nhập chi phí vận hành để biết tiền thực còn lại',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statBox('Lợi nhuận gộp', formatMoney(widget.grossProfit)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statBox('Chi phí tháng', formatMoney(_totalExpenses),
                      color: Colors.amber.shade800),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statBox('Lãi thật', formatMoney(_trueProfit),
                      color: Colors.green.shade700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Loại chi phí',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: AppConstants.expenseCategories
                  .map((c) => DropdownMenuItem(
                        value: c['key'],
                        child: Text(c['label']!),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? 'stock'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền (VND)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tuỳ chọn)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _add, child: const Text('Thêm chi phí')),
            if (_expenses.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Chi phí tháng này',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ..._expenses.map((e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppConstants.expenseLabel(e.category)),
                    subtitle: e.note != null ? Text(e.note!) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formatMoney(e.amount),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () async {
                            await _service.deleteExpense(e.id!);
                            await _load();
                          },
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}
