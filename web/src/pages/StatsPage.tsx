import { useEffect, useState } from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { Breadcrumbs } from '@/components/CustomerTable';
import { NAV_HOME_LABEL, STATS_ANCHORS } from '@/lib/constants';
import { SalesDashboard } from '@/components/SalesDashboard';
import { PageHeader, Panel, StatCard, LoadingSpinner } from '@/components/ui';
import { getCurrentStreak, getMonthlyStats } from '@/lib/customerService';
import { getOrdersInRange, getRevenueBySource } from '@/lib/orderService';
import { monthRangeFromDate } from '@/lib/db';
import type { MonthlyStats, Order } from '@/types';
import { orderRevenue, summarizeOrders } from '@/types';
import { formatMoney } from '@/lib/money';
import { ExpensePanel } from '@/components/ExpensePanel';
import { GoalProgressCard } from '@/components/GoalProgressCard';
import { RevenueInsightCard } from '@/components/RevenueInsightCard';
import { AchievementBanner } from '@/components/AchievementBanner';
import { getGoalProgress, type GoalProgress } from '@/lib/goalService';
import { getTrueProfit } from '@/lib/expenseService';
import {
  getRevenueInsights,
  getAchievementStats,
  type RevenueInsight,
} from '@/lib/insightsService';
import { useDataRefresh } from '@/hooks/useDataRefresh';
import { useScrollToHash } from '@/hooks/useScrollToHash';

export function StatsPage() {
  const refresh = useDataRefresh();
  const now = new Date();
  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(now.getMonth() + 1);
  const [stats, setStats] = useState<MonthlyStats | null>(null);
  const [streak, setStreak] = useState(0);
  const [monthOrders, setMonthOrders] = useState<Order[]>([]);
  const [revenueBySource, setRevenueBySource] = useState<
    { source: string; label: string; revenue: number; order_count: number }[]
  >([]);
  const [insights, setInsights] = useState<RevenueInsight[]>([]);
  const [achievements, setAchievements] = useState<Awaited<
    ReturnType<typeof getAchievementStats>
  > | null>(null);
  const [goalProgress, setGoalProgress] = useState<GoalProgress | null>(null);
  const [trueProfit, setTrueProfit] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);

  useScrollToHash(!loading);

  const isCurrentMonth =
    year === now.getFullYear() && month === now.getMonth() + 1;

  useEffect(() => {
    setLoading(true);
    const date = new Date(year, month - 1);
    const { start, end } = monthRangeFromDate(date);
    Promise.all([
      getMonthlyStats(year, month),
      getCurrentStreak(),
      getOrdersInRange(start, end),
      getRevenueBySource(start, end),
      getRevenueInsights(date),
      getAchievementStats(),
      getGoalProgress(date),
    ]).then(async ([s, str, orders, bySource, ins, achieve, goal]) => {
      setStats(s);
      setStreak(str);
      setMonthOrders(orders);
      setRevenueBySource(bySource);
      setInsights(ins);
      setAchievements(achieve);
      setGoalProgress(goal);
      const summary = summarizeOrders(orders);
      setTrueProfit(await getTrueProfit(summary.profit, date));
      setLoading(false);
    });
  }, [year, month, refresh]);

  function prevMonth() {
    if (month === 1) {
      setYear((y) => y - 1);
      setMonth(12);
    } else {
      setMonth((m) => m - 1);
    }
  }

  function nextMonth() {
    if (isCurrentMonth) return;
    if (month === 12) {
      setYear((y) => y + 1);
      setMonth(1);
    } else {
      setMonth((m) => m + 1);
    }
  }

  const monthLabel = new Date(year, month - 1).toLocaleDateString('vi-VN', {
    month: 'long',
    year: 'numeric',
  });

  const conversion =
    stats && stats.contacts > 0
      ? Math.round((stats.closed / stats.contacts) * 100)
      : 0;

  const salesSummary = summarizeOrders(monthOrders);
  const monthDate = new Date(year, month - 1);

  const monthSummaryText =
    trueProfit != null
      ? `Tháng này lời gộp ${formatMoney(salesSummary.profit)} · Lãi thật ${formatMoney(trueProfit)}`
      : salesSummary.profit > 0
        ? `Tháng này lời ${formatMoney(salesSummary.profit)}`
        : 'Chưa có lợi nhuận tháng này';

  return (
    <div className="space-y-8">
      <Breadcrumbs items={[{ label: NAV_HOME_LABEL, to: '/' }, { label: 'Tiền của tôi' }]} />

      <PageHeader
        title="Tiền của tôi"
        subtitle={monthSummaryText}
      />

      <div className="flex items-center justify-between rounded-xl border border-slate-200 bg-white px-4 py-3 shadow-sm dark:border-slate-800 dark:bg-slate-900">
        <button
          type="button"
          onClick={prevMonth}
          className="rounded-lg p-2 text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800"
        >
          <ChevronLeft className="h-5 w-5" />
        </button>
        <span className="text-sm font-semibold capitalize text-slate-900 dark:text-white">
          {monthLabel}
          {streak > 0 && (
            <span className="ml-2 rounded-full bg-orange-100 px-2 py-0.5 text-xs font-medium text-orange-700 dark:bg-orange-950 dark:text-orange-300">
              🔥 {streak} ngày streak
            </span>
          )}
        </span>
        <button
          type="button"
          onClick={nextMonth}
          disabled={isCurrentMonth}
          className="rounded-lg p-2 text-slate-600 hover:bg-slate-100 disabled:opacity-30 dark:hover:bg-slate-800"
        >
          <ChevronRight className="h-5 w-5" />
        </button>
      </div>

      {loading || !stats ? (
        <LoadingSpinner />
      ) : (
        <>
          {goalProgress && isCurrentMonth && <GoalProgressCard progress={goalProgress} />}

          {achievements && <AchievementBanner stats={achievements} />}

          <RevenueInsightCard insights={insights} />

          <SalesDashboard
            title={`Doanh số — ${monthLabel}`}
            summary={salesSummary}
            trueProfit={trueProfit}
          />

          <div id={STATS_ANCHORS.expenses} className="scroll-mt-20">
            <ExpensePanel date={monthDate} grossProfit={salesSummary.profit} />
          </div>

          <div>
            <h2 className="mb-3 text-sm font-bold uppercase tracking-wider text-slate-500">
              Chăm khách — {monthLabel}
            </h2>
            <div className="grid gap-4 sm:grid-cols-3">
              <StatCard label="Lượt liên hệ" value={stats.contacts} hint="Mọi tương tác ghi nhận" />
              <StatCard
                label="Đơn chốt"
                value={stats.closed}
                variant="success"
                hint="Ghi đơn / chốt trong tháng"
              />
              <StatCard
                label="Khách mới"
                value={stats.new_customers}
                variant="brand"
                hint="Khách thêm trong tháng"
              />
            </div>
          </div>

          <div className="grid gap-6 lg:grid-cols-2">
            <Panel title="Tỷ lệ chốt đơn (liên hệ)">
              <p className="text-4xl font-bold tabular-nums text-brand-600">{conversion}%</p>
              <p className="mt-1 text-sm text-slate-500">
                {stats.closed} / {stats.contacts} lượt liên hệ có ghi đơn/chốt
              </p>
              <div className="mt-4 h-2.5 overflow-hidden rounded-full bg-slate-200 dark:bg-slate-700">
                <div
                  className="h-full rounded-full bg-brand-600"
                  style={{ width: `${Math.min(conversion, 100)}%` }}
                />
              </div>
              {stats.contacts === 0 && (
                <p className="mt-3 text-sm text-slate-500">
                  Chưa có liên hệ tháng này — chăm khách trên trang chủ để tích lũy số liệu.
                </p>
              )}
            </Panel>

            <Panel title="Top SP được hỏi (lead)">
              {stats.top_products.length > 0 ? (
                <ul className="space-y-2">
                  {stats.top_products.map((row) => {
                    const max = stats.top_products[0]?.cnt ?? 1;
                    const pct = Math.round((row.cnt / max) * 100);
                    return (
                      <li key={row.product}>
                        <div className="flex justify-between text-sm">
                          <span className="font-medium">{row.product}</span>
                          <span className="text-slate-500">{row.cnt} khách</span>
                        </div>
                        <div className="mt-1 h-1.5 overflow-hidden rounded-full bg-slate-200 dark:bg-slate-700">
                          <div
                            className="h-full rounded-full bg-brand-500"
                            style={{ width: `${pct}%` }}
                          />
                        </div>
                      </li>
                    );
                  })}
                </ul>
              ) : (
                <p className="text-sm text-slate-500">
                  Chưa có sản phẩm quan tâm — ghi SP khi thêm/sửa khách.
                </p>
              )}
            </Panel>
          </div>

          <div id={STATS_ANCHORS.topProducts} className="scroll-mt-20">
            <Panel title="Top doanh thu theo sản phẩm (đơn thực)">
              {monthOrders.length > 0 ? (
                <TopSalesProducts orders={monthOrders} />
              ) : (
                <p className="text-sm text-slate-500">
                  Chưa có đơn tháng này — ghi đơn từ trang khách hoặc Đơn hàng.
                </p>
              )}
            </Panel>
          </div>

          <div id={STATS_ANCHORS.revenueBySource} className="scroll-mt-20">
            <Panel title="Doanh thu theo nguồn khách">
              {revenueBySource.length > 0 ? (
                <RevenueBySourceList rows={revenueBySource} />
              ) : (
                <p className="text-sm text-slate-500">
                  Chưa có doanh thu theo nguồn — ghi nguồn khách khi thêm khách và ghi đơn.
                </p>
              )}
            </Panel>
          </div>
        </>
      )}
    </div>
  );
}

function TopSalesProducts({ orders }: { orders: Order[] }) {
  const map = new Map<string, number>();
  for (const o of orders) {
    map.set(o.product_name, (map.get(o.product_name) ?? 0) + orderRevenue(o));
  }
  const sorted = [...map.entries()].sort((a, b) => b[1] - a[1]).slice(0, 5);
  const max = sorted[0]?.[1] ?? 1;

  return (
    <ul className="space-y-3">
      {sorted.map(([name, rev]) => (
        <li key={name}>
          <div className="flex justify-between text-sm">
            <span className="font-medium">{name}</span>
            <span className="tabular-nums text-brand-700 dark:text-brand-400">
              {formatMoney(rev)}
            </span>
          </div>
          <div className="mt-1 h-2 overflow-hidden rounded-full bg-slate-200 dark:bg-slate-700">
            <div
              className="h-full rounded-full bg-brand-500"
              style={{ width: `${Math.round((rev / max) * 100)}%` }}
            />
          </div>
        </li>
      ))}
    </ul>
  );
}

function RevenueBySourceList({
  rows,
}: {
  rows: { source: string; label: string; revenue: number; order_count: number }[];
}) {
  const max = rows[0]?.revenue ?? 1;

  return (
    <ul className="space-y-3">
      {rows.map((row) => (
        <li key={row.source}>
          <div className="flex justify-between text-sm">
            <span className="font-medium">{row.label}</span>
            <span className="tabular-nums text-brand-700 dark:text-brand-400">
              {formatMoney(row.revenue)}
              <span className="ml-2 text-xs font-normal text-slate-500">
                ({row.order_count} đơn)
              </span>
            </span>
          </div>
          <div className="mt-1 h-2 overflow-hidden rounded-full bg-slate-200 dark:bg-slate-700">
            <div
              className="h-full rounded-full bg-emerald-500"
              style={{ width: `${Math.round((row.revenue / max) * 100)}%` }}
            />
          </div>
        </li>
      ))}
    </ul>
  );
}
