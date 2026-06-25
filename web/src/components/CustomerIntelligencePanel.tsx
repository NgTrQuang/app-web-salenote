import type { CustomerIntelligence } from '@/lib/insightsService';
import { formatMoney } from '@/lib/money';
import { formatDate, relativeTime } from '@/lib/dateUtils';
import { Panel } from './ui';

interface CustomerIntelligencePanelProps {
  intel: CustomerIntelligence;
}

export function CustomerIntelligencePanel({ intel }: CustomerIntelligencePanelProps) {
  return (
    <Panel title="Giá trị khách hàng" subtitle="Biết khách nào đáng đầu tư thời gian">
      <div className="mb-4 flex items-center gap-3 rounded-lg bg-brand-50 px-3 py-2 dark:bg-brand-950/40">
        <span className="rounded-full bg-brand-600 px-2.5 py-0.5 text-xs font-bold text-white">
          {intel.tierLabel}
        </span>
        <p className="text-sm text-slate-600 dark:text-slate-400">{intel.tierHint}</p>
      </div>

      <div className="grid grid-cols-2 gap-3 text-sm sm:grid-cols-3">
        <Stat label="Tổng đơn" value={String(intel.orderCount)} />
        <Stat label="Tổng doanh thu" value={formatMoney(intel.totalRevenue)} />
        <Stat label="Tổng lợi nhuận" value={formatMoney(intel.totalProfit)} highlight />
        <Stat label="Hoa hồng" value={formatMoney(intel.totalCommission)} />
        <Stat
          label="Công nợ"
          value={formatMoney(intel.totalDebt)}
          danger={intel.totalDebt > 0}
        />
        <Stat
          label="TB / đơn"
          value={intel.orderCount > 0 ? formatMoney(intel.avgOrderValue) : '—'}
        />
        <Stat
          label="Lần mua gần nhất"
          value={
            intel.lastOrderAt != null
              ? relativeTime(intel.lastOrderAt)
              : 'Chưa có'
          }
          hint={intel.lastOrderAt != null ? formatDate(intel.lastOrderAt) : undefined}
        />
        <Stat
          label="Mua lặp"
          value={intel.isRepeatBuyer ? 'Có' : 'Chưa'}
          highlight={intel.isRepeatBuyer}
        />
      </div>
    </Panel>
  );
}

function Stat({
  label,
  value,
  hint,
  highlight,
  danger,
}: {
  label: string;
  value: string;
  hint?: string;
  highlight?: boolean;
  danger?: boolean;
}) {
  return (
    <div className="rounded-lg border border-slate-200 px-3 py-2 dark:border-slate-700">
      <p className="text-xs text-slate-500">{label}</p>
      <p
        className={`mt-0.5 font-bold tabular-nums ${
          danger
            ? 'text-red-600 dark:text-red-400'
            : highlight
              ? 'text-emerald-700 dark:text-emerald-400'
              : 'text-slate-900 dark:text-white'
        }`}
      >
        {value}
      </p>
      {hint && <p className="text-xs text-slate-400">{hint}</p>}
    </div>
  );
}
