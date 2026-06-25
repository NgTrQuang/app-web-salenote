import { AlertTriangle, Flame, Users, RotateCcw, Wallet } from 'lucide-react';
import type { AtRiskSummary } from '@/lib/insightsService';
import { formatMoney } from '@/lib/money';
import { Panel } from './ui';

interface AtRiskAlertsProps {
  summary: AtRiskSummary;
}

export function AtRiskAlerts({ summary }: AtRiskAlertsProps) {
  const items = [
    {
      show: summary.hotOverdue > 0,
      icon: Flame,
      label: 'Khách Nóng quá hạn',
      value: summary.hotOverdue,
      variant: 'danger' as const,
    },
    {
      show: summary.warmOverdue + summary.newOverdue > 0,
      icon: Users,
      label: 'Tiềm năng / Mới chưa chăm',
      value: summary.warmOverdue + summary.newOverdue,
      variant: 'warning' as const,
    },
    {
      show: summary.promoStale > 0,
      icon: AlertTriangle,
      label: 'Khách nóng tiềm năng lâu chưa liên hệ',
      value: summary.promoStale,
      variant: 'warning' as const,
    },
    {
      show: summary.returningLost > 0,
      icon: RotateCcw,
      label: 'Khách từng mua chưa quay lại',
      value: summary.returningLost,
      variant: 'default' as const,
    },
    {
      show: summary.debtCustomers > 0,
      icon: Wallet,
      label: 'Khách còn công nợ',
      value: `${summary.debtCustomers} · ${formatMoney(summary.totalDebt)}`,
      variant: 'danger' as const,
    },
  ].filter((x) => x.show);

  if (items.length === 0) return null;

  return (
    <Panel title="Cảnh báo rủi ro" subtitle="Khách có thể bị mất nếu không hành động">
      <div className="grid gap-3 sm:grid-cols-2">
        {items.map((item) => (
          <div
            key={item.label}
            className={`flex items-center gap-3 rounded-lg border px-3 py-2.5 text-sm ${
              item.variant === 'danger'
                ? 'border-red-200 bg-red-50/60 dark:border-red-900 dark:bg-red-950/20'
                : item.variant === 'warning'
                  ? 'border-amber-200 bg-amber-50/60 dark:border-amber-900 dark:bg-amber-950/20'
                  : 'border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-800/40'
            }`}
          >
            <item.icon
              className={`h-4 w-4 shrink-0 ${
                item.variant === 'danger'
                  ? 'text-red-600'
                  : item.variant === 'warning'
                    ? 'text-amber-600'
                    : 'text-slate-500'
              }`}
            />
            <div className="min-w-0">
              <p className="text-xs text-slate-500">{item.label}</p>
              <p className="font-bold tabular-nums">{item.value}</p>
            </div>
          </div>
        ))}
      </div>
    </Panel>
  );
}
