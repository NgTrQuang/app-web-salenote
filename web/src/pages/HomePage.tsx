import { useEffect, useState } from 'react';
import { Users, ChevronDown, ChevronUp } from 'lucide-react';
import type { Customer, SalesSummary } from '@/types';
import { HOME_ANCHORS } from '@/lib/constants';
import { CustomerTable } from '@/components/CustomerTable';
import { SalesDashboard } from '@/components/SalesDashboard';
import { DailyActionCenter } from '@/components/DailyActionCenter';
import { AchievementBanner } from '@/components/AchievementBanner';
import { RevenueInsightCard } from '@/components/RevenueInsightCard';
import { TodaySummaryBar } from '@/components/TodaySummaryBar';
import { GoalProgressCard } from '@/components/GoalProgressCard';
import {
  PageHeader,
  EmptyState,
  LoadingSpinner,
  SearchInput,
  Panel,
} from '@/components/ui';
import { useDataRefresh } from '@/hooks/useDataRefresh';
import { useScrollToHash } from '@/hooks/useScrollToHash';
import { useClientPagination } from '@/hooks/useClientPagination';
import { Pagination } from '@/components/Pagination';
import {
  filterCustomers,
  getNeedsAttention,
  getUpcoming,
  messageSent,
} from '@/lib/customerService';
import { getSalesSummaryForDay, getSalesSummaryForMonth } from '@/lib/orderService';
import { getGoalProgress, type GoalProgress } from '@/lib/goalService';
import {
  getDailyActions,
  getAtRiskSummary,
  getAchievementStats,
  getRevenueInsights,
  type DailyAction,
  type AchievementStats,
  type RevenueInsight,
} from '@/lib/insightsService';
import { SegmentActionDialog } from '@/components/SegmentActionDialog';
import { getProductReengageSegments, type ProductSegment } from '@/lib/segmentService';

const emptySales: SalesSummary = {
  revenue: 0,
  cost: 0,
  profit: 0,
  commission: 0,
  debt: 0,
  order_count: 0,
};

export function HomePage() {
  const refresh = useDataRefresh();
  const [query, setQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [needsAttention, setNeedsAttention] = useState<Customer[]>([]);
  const [upcoming, setUpcoming] = useState<Customer[]>([]);
  const [actions, setActions] = useState<DailyAction[]>([]);
  const [achievements, setAchievements] = useState<AchievementStats | null>(null);
  const [insights, setInsights] = useState<RevenueInsight[]>([]);
  const [goalProgress, setGoalProgress] = useState<GoalProgress | null>(null);
  const [todaySales, setTodaySales] = useState<SalesSummary>(emptySales);
  const [monthSales, setMonthSales] = useState<SalesSummary>(emptySales);
  const [totalDebt, setTotalDebt] = useState(0);
  const [showSales, setShowSales] = useState(false);
  const [showCustomers, setShowCustomers] = useState(false);
  const [segments, setSegments] = useState<ProductSegment[]>([]);
  const [segmentProductId, setSegmentProductId] = useState<number | null>(null);

  useScrollToHash(!loading);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      const [
        needs,
        up,
        dailyActions,
        risk,
        achieve,
        revenueInsights,
        today,
        month,
        goal,
        segs,
      ] = await Promise.all([
        getNeedsAttention(),
        getUpcoming(),
        getDailyActions(),
        getAtRiskSummary(),
        getAchievementStats(),
        getRevenueInsights(),
        getSalesSummaryForDay(),
        getSalesSummaryForMonth(),
        getGoalProgress(),
        getProductReengageSegments(),
      ]);
      if (!cancelled) {
        setNeedsAttention(needs);
        setUpcoming(up);
        setActions(dailyActions);
        setTotalDebt(risk.totalDebt);
        setAchievements(achieve);
        setInsights(revenueInsights);
        setTodaySales(today);
        setMonthSales(month);
        setGoalProgress(goal);
        setSegments(segs);
        setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [refresh]);

  const filteredNeeds = filterCustomers(needsAttention, query);
  const filteredUpcoming = filterCustomers(upcoming, query);
  const needsPage = useClientPagination(filteredNeeds);
  const upcomingPage = useClientPagination(filteredUpcoming);

  async function handleQuickMessage(customer: Customer) {
    await messageSent(customer);
  }

  if (loading) return <LoadingSpinner />;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Hôm nay"
        subtitle="Việc cần làm — không quên khách, không quên tiền"
      />

      <TodaySummaryBar
        today={todaySales}
        month={monthSales}
        actionCount={actions.length}
        totalDebt={totalDebt}
      />

      {goalProgress && <GoalProgressCard progress={goalProgress} />}

      <div id={HOME_ANCHORS.dailyActions} className="scroll-mt-20">
        <DailyActionCenter
          actions={actions}
          onSegmentAction={(productId) => setSegmentProductId(productId)}
        />
      </div>

      <SegmentActionDialog
        segment={segments.find((s) => s.productId === segmentProductId) ?? null}
        onClose={() => setSegmentProductId(null)}
      />

      <RevenueInsightCard insights={insights} />

      {achievements && <AchievementBanner stats={achievements} />}

      <div>
        <button
          type="button"
          onClick={() => setShowSales((v) => !v)}
          className="mb-3 flex w-full items-center justify-between rounded-lg border border-slate-200 bg-white px-4 py-3 text-left text-sm font-semibold text-slate-700 shadow-sm hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200"
        >
          <span>Tiền hôm nay & tháng này</span>
          {showSales ? (
            <ChevronUp className="h-4 w-4 text-slate-400" />
          ) : (
            <ChevronDown className="h-4 w-4 text-slate-400" />
          )}
        </button>
        {showSales && (
          <div className="space-y-4">
            <SalesDashboard title="Hôm nay" summary={todaySales} />
            <SalesDashboard title="Tháng này" summary={monthSales} />
          </div>
        )}
        {!showSales && (
          <p className="text-xs text-slate-500">
            Lời hôm nay: {todaySales.profit.toLocaleString('vi-VN')}đ · Tháng:{' '}
            {monthSales.profit.toLocaleString('vi-VN')}đ — bấm để xem chi tiết
          </p>
        )}
      </div>

      <div>
        <button
          type="button"
          onClick={() => setShowCustomers((v) => !v)}
          className="mb-3 flex w-full items-center justify-between rounded-lg border border-slate-200 bg-white px-4 py-3 text-left text-sm font-semibold text-slate-700 shadow-sm hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200"
        >
          <span>
            Sổ khách hôm nay ({needsAttention.length} cần liên hệ ·{' '}
            {upcoming.length} sắp tới)
          </span>
          {showCustomers ? (
            <ChevronUp className="h-4 w-4 text-slate-400" />
          ) : (
            <ChevronDown className="h-4 w-4 text-slate-400" />
          )}
        </button>

        {showCustomers && (
          <div className="space-y-4">
            <SearchInput
              value={query}
              onChange={setQuery}
              placeholder="Lọc khách theo tên, SĐT, sản phẩm..."
            />

            <div className="grid gap-6 xl:grid-cols-2">
              <Panel title={`Cần liên hệ ngay (${filteredNeeds.length})`} noPadding>
                {filteredNeeds.length === 0 ? (
                  <div className="p-5">
                    <EmptyState
                      icon={<Users className="h-10 w-10" />}
                      title="Không có khách cần nhắn"
                      description="Danh sách trống hoặc không khớp bộ lọc."
                    />
                  </div>
                ) : (
                  <>
                    <CustomerTable
                      customers={needsPage.slice}
                      urgent
                      compact
                      onQuickMessage={handleQuickMessage}
                    />
                    <Pagination
                      page={needsPage.page}
                      pageSize={needsPage.pageSize}
                      total={needsPage.total}
                      onPageChange={needsPage.setPage}
                    />
                  </>
                )}
              </Panel>

              <Panel title={`Sắp tới (${filteredUpcoming.length})`} noPadding>
                {filteredUpcoming.length === 0 ? (
                  <div className="p-5">
                    <p className="text-center text-sm text-slate-500">
                      Không có khách sắp tới trong bộ lọc hiện tại.
                    </p>
                  </div>
                ) : (
                  <>
                    <CustomerTable customers={upcomingPage.slice} compact />
                    <Pagination
                      page={upcomingPage.page}
                      pageSize={upcomingPage.pageSize}
                      total={upcomingPage.total}
                      onPageChange={upcomingPage.setPage}
                    />
                  </>
                )}
              </Panel>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
