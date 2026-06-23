import { formatMoney } from '@/lib/money';
import type { SalesSummary } from '@/types';
import { StatCard } from './ui';

interface SalesDashboardProps {
  title: string;
  summary: SalesSummary;
}

export function SalesDashboard({ title, summary }: SalesDashboardProps) {
  return (
    <div>
      <h2 className="mb-3 text-sm font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
        {title}
      </h2>
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
        <StatCard
          label="Doanh thu"
          value={formatMoney(summary.revenue)}
          variant="brand"
        />
        <StatCard
          label="Lợi nhuận"
          value={formatMoney(summary.profit)}
          variant="success"
        />
        <StatCard
          label="Hoa hồng dự kiến"
          value={formatMoney(summary.commission)}
          variant="brand"
        />
        <StatCard label="Số đơn" value={summary.order_count} />
        <StatCard
          label="Công nợ"
          value={formatMoney(summary.debt)}
          variant={summary.debt > 0 ? 'warning' : 'default'}
          hint={summary.debt > 0 ? 'Chưa thu hết' : undefined}
        />
      </div>
    </div>
  );
}
