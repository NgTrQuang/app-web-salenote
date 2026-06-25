import { Sparkles, TrendingUp, Users, Flame } from 'lucide-react';
import type { AchievementStats } from '@/lib/insightsService';
import { formatMoney } from '@/lib/money';

interface AchievementBannerProps {
  stats: AchievementStats;
}

export function AchievementBanner({ stats }: AchievementBannerProps) {
  const cards = [
    {
      icon: Flame,
      value: stats.streak > 0 ? `${stats.streak} ngày` : '—',
      label: 'Chuỗi không bỏ sót khách',
      show: stats.streak > 0,
    },
    {
      icon: Users,
      value: stats.customersCared.toString(),
      label: 'Khách đã chăm sóc',
      show: stats.customersCared > 0,
    },
    {
      icon: TrendingUp,
      value: formatMoney(stats.totalRevenue),
      label: 'Doanh thu tích luỹ',
      show: stats.totalRevenue > 0,
    },
    {
      icon: Sparkles,
      value: stats.totalOrders.toString(),
      label: 'Đơn đã ghi',
      show: stats.totalOrders > 0,
    },
  ].filter((c) => c.show);

  if (cards.length === 0) return null;

  return (
    <div className="rounded-xl border border-brand-200 bg-gradient-to-br from-brand-50 to-white p-4 dark:border-brand-900 dark:from-brand-950/40 dark:to-slate-900">
      <p className="text-xs font-bold uppercase tracking-wider text-brand-700 dark:text-brand-400">
        Salenote đang giúp bạn
      </p>
      <div className="mt-3 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {cards.map((c) => (
          <div key={c.label} className="flex items-center gap-2">
            <c.icon className="h-4 w-4 shrink-0 text-brand-600 dark:text-brand-400" />
            <div>
              <p className="text-lg font-bold tabular-nums text-slate-900 dark:text-white">
                {c.value}
              </p>
              <p className="text-xs text-slate-500">{c.label}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
