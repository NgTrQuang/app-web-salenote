import { useEffect, useState } from 'react';
import { Trash2 } from 'lucide-react';
import type { Expense, ExpenseCategory } from '@/types';
import { EXPENSE_CATEGORIES, EXPENSE_LABELS } from '@/lib/constants';
import {
  addExpense,
  deleteExpense,
  getExpensesForMonth,
  getExpensesTotalForMonth,
  getTrueProfit,
} from '@/lib/expenseService';
import { formatMoney, parseMoneyInput } from '@/lib/money';
import { Panel, PrimaryButton, FieldLabel, TextInput } from './ui';
import { useDataRefresh } from '@/hooks/useDataRefresh';

interface ExpensePanelProps {
  date: Date;
  grossProfit: number;
}

export function ExpensePanel({ date, grossProfit }: ExpensePanelProps) {
  const refresh = useDataRefresh();
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [totalExpenses, setTotalExpenses] = useState(0);
  const [trueProfit, setTrueProfit] = useState(grossProfit);
  const [category, setCategory] = useState<ExpenseCategory>('stock');
  const [amountInput, setAmountInput] = useState('');
  const [note, setNote] = useState('');

  useEffect(() => {
    Promise.all([
      getExpensesForMonth(date),
      getExpensesTotalForMonth(date),
      getTrueProfit(grossProfit, date),
    ]).then(([list, total, net]) => {
      setExpenses(list);
      setTotalExpenses(total);
      setTrueProfit(net);
    });
  }, [date, grossProfit, refresh]);

  async function handleAdd(e: React.FormEvent) {
    e.preventDefault();
    const amount = parseMoneyInput(amountInput);
    if (amount <= 0) return;
    await addExpense({ category, amount, note });
    setAmountInput('');
    setNote('');
  }

  async function handleDelete(id: number) {
    await deleteExpense(id);
  }

  return (
    <Panel
      title="Chi phí & lãi thật"
      subtitle="Nhập chi phí vận hành để biết tiền thực còn lại"
    >
      <div className="mb-4 grid gap-3 sm:grid-cols-3">
        <div className="rounded-lg bg-slate-50 p-3 dark:bg-slate-800/60">
          <p className="text-xs text-slate-500">Lợi nhuận gộp</p>
          <p className="text-lg font-bold text-slate-900 dark:text-white">
            {formatMoney(grossProfit)}
          </p>
        </div>
        <div className="rounded-lg bg-amber-50 p-3 dark:bg-amber-950/30">
          <p className="text-xs text-amber-700 dark:text-amber-400">Chi phí tháng</p>
          <p className="text-lg font-bold text-amber-800 dark:text-amber-300">
            {formatMoney(totalExpenses)}
          </p>
        </div>
        <div className="rounded-lg bg-emerald-50 p-3 dark:bg-emerald-950/30">
          <p className="text-xs text-emerald-700 dark:text-emerald-400">Lãi thật</p>
          <p className="text-lg font-bold text-emerald-800 dark:text-emerald-300">
            {formatMoney(trueProfit)}
          </p>
        </div>
      </div>

      <form onSubmit={(e) => void handleAdd(e)} className="mb-4 grid gap-3 sm:grid-cols-4">
        <div>
          <FieldLabel>Loại chi phí</FieldLabel>
          <select
            value={category}
            onChange={(e) => setCategory(e.target.value as ExpenseCategory)}
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm dark:border-slate-600 dark:bg-slate-900"
          >
            {EXPENSE_CATEGORIES.map((c) => (
              <option key={c.key} value={c.key}>
                {c.label}
              </option>
            ))}
          </select>
        </div>
        <div>
          <FieldLabel>Số tiền</FieldLabel>
          <TextInput
            value={amountInput}
            onChange={(e) => setAmountInput(e.target.value)}
            placeholder="500.000"
            inputMode="numeric"
          />
        </div>
        <div className="sm:col-span-2">
          <FieldLabel>Ghi chú (tuỳ chọn)</FieldLabel>
          <TextInput value={note} onChange={(e) => setNote(e.target.value)} placeholder="VD: Ship tháng 6" />
        </div>
        <div className="sm:col-span-4">
          <PrimaryButton type="submit">Thêm chi phí</PrimaryButton>
        </div>
      </form>

      {expenses.length === 0 ? (
        <p className="text-sm text-slate-500">
          Chưa ghi chi phí tháng này — thêm nhập hàng, ship, quảng cáo… để tính lãi thật.
        </p>
      ) : (
        <ul className="divide-y divide-slate-100 dark:divide-slate-800">
          {expenses.map((e) => (
            <li key={e.id} className="flex items-center justify-between py-2 text-sm">
              <div>
                <span className="font-medium">{EXPENSE_LABELS[e.category] ?? e.category}</span>
                {e.note && <span className="ml-2 text-slate-500">· {e.note}</span>}
                <span className="ml-2 text-xs text-slate-400">
                  {new Date(e.created_at).toLocaleDateString('vi-VN')}
                </span>
              </div>
              <div className="flex items-center gap-2">
                <span className="font-semibold tabular-nums">{formatMoney(e.amount)}</span>
                <button
                  type="button"
                  onClick={() => e.id != null && void handleDelete(e.id)}
                  className="rounded p-1 text-slate-400 hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-950/40"
                  aria-label="Xóa"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            </li>
          ))}
        </ul>
      )}
    </Panel>
  );
}
