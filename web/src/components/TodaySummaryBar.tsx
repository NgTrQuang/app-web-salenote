import type { ReactNode } from 'react';
import { Link } from 'react-router-dom';
import type { SalesSummary } from '@/types';
import { formatMoney } from '@/lib/money';

interface TodaySummaryBarProps {
  today: SalesSummary;
  month: SalesSummary;
  actionCount: number;
  totalDebt: number;
}

export function TodaySummaryBar({
  today,
  month,
  actionCount,
  totalDebt,
}: TodaySummaryBarProps) {
  const parts: ReactNode[] = [];

  if (today.profit > 0 || today.order_count > 0) {
    parts.push(
      <span key="profit">
        Lời hôm nay <strong>{formatMoney(today.profit)}</strong>
      </span>,
    );
  }

  if (month.profit > 0) {
    parts.push(
      <span key="month">
        Tháng lời <strong>{formatMoney(month.profit)}</strong>
      </span>,
    );
  }

  if (today.order_count > 0) {
    parts.push(
      <span key="orders">
        <strong>{today.order_count}</strong> đơn hôm nay
      </span>,
    );
  }

  if (actionCount > 0) {
    parts.push(
      <span key="actions">
        <strong>{actionCount}</strong> việc cần làm
      </span>,
    );
  }

  if (totalDebt > 0) {
    parts.push(
      <Link
        key="debt"
        to="/debts"
        className="font-medium text-amber-700 hover:underline dark:text-amber-400"
      >
        Còn <strong>{formatMoney(totalDebt)}</strong> nợ
      </Link>,
    );
  }

  if (parts.length === 0) {
    return (
      <p className="rounded-lg border border-slate-200 bg-white px-4 py-3 text-sm text-slate-600 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-400">
        Chưa có đơn hôm nay — thêm khách hoặc ghi đơn khi chốt.
      </p>
    );
  }

  return (
    <p className="rounded-lg border border-slate-200 bg-white px-4 py-3 text-sm text-slate-600 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-400">
      {parts.map((part, i) => (
        <span key={i}>
          {i > 0 && <span className="mx-2 text-slate-300 dark:text-slate-600">·</span>}
          {part}
        </span>
      ))}
    </p>
  );
}
