import { formatMoney } from '@/lib/money';
import type { SalesSummary } from '@/types';
import { StatCard } from './ui';

interface SalesDashboardProps {
  title: string;
  summary: SalesSummary;
  trueProfit?: number | null;
}

export function SalesDashboard({ title, summary, trueProfit }: SalesDashboardProps) {
  const footer =
    trueProfit != null
      ? `Lãi thật (sau chi phí): ${formatMoney(trueProfit)}`
      : summary.debt > 0
        ? `Còn ${formatMoney(summary.debt)} chưa thu — ưu tiên thu nợ`
        : summary.profit > 0
          ? `Lời ${formatMoney(summary.profit)} tháng này`
          : null;

  return (
    <div>
      <h2 className="mb-3 text-sm font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
        {title}
      </h2>
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
        <StatCard label="Doanh thu" value={formatMoney(summary.revenue)} variant="brand" />
        <StatCard label="Lợi nhuận gộp" value={formatMoney(summary.profit)} variant="success" />
        <StatCard label="Hoa hồng dự kiến" value={formatMoney(summary.commission)} variant="brand" />
        <StatCard label="Số đơn" value={summary.order_count} />
        <StatCard
          label="Chưa thu"
          value={formatMoney(summary.debt)}
          variant={summary.debt > 0 ? 'warning' : 'default'}
        />
      </div>
      {footer && (
        <p className="mt-3 text-sm font-medium text-slate-600 dark:text-slate-400">{footer}</p>
      )}
    </div>
  );
}
