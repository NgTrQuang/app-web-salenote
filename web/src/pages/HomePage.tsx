import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Users, Plus, Receipt, Package } from 'lucide-react';
import type { Customer } from '@/types';
import { CustomerTable } from '@/components/CustomerTable';
import { SalesDashboard } from '@/components/SalesDashboard';
import {
  PageHeader,
  EmptyState,
  StatCard,
  LoadingSpinner,
  SearchInput,
  Panel,
  PrimaryButton,
} from '@/components/ui';
import { useDataRefresh } from '@/hooks/useDataRefresh';
import {
  filterCustomers,
  getNeedsAttention,
  getUpcoming,
  getOverdueCount,
  getCurrentStreak,
  messageSent,
} from '@/lib/customerService';
import { getSalesSummaryForDay, getSalesSummaryForMonth } from '@/lib/orderService';
import { getLowStockProducts, stockStatusLabel } from '@/lib/productService';
import { productStockStatus } from '@/types';
import type { SalesSummary, Product } from '@/types';

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
  const [overdueCount, setOverdueCount] = useState(0);
  const [streak, setStreak] = useState(0);
  const [todaySales, setTodaySales] = useState<SalesSummary>(emptySales);
  const [monthSales, setMonthSales] = useState<SalesSummary>(emptySales);
  const [lowStock, setLowStock] = useState<Product[]>([]);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      const [needs, up, overdue, str, today, month, low] = await Promise.all([
        getNeedsAttention(),
        getUpcoming(),
        getOverdueCount(),
        getCurrentStreak(),
        getSalesSummaryForDay(),
        getSalesSummaryForMonth(),
        getLowStockProducts(),
      ]);
      if (!cancelled) {
        setNeedsAttention(needs);
        setUpcoming(up);
        setOverdueCount(overdue);
        setStreak(str);
        setTodaySales(today);
        setMonthSales(month);
        setLowStock(low);
        setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [refresh]);

  const filteredNeeds = filterCustomers(needsAttention, query);
  const filteredUpcoming = filterCustomers(upcoming, query);

  async function handleQuickMessage(customer: Customer) {
    await messageSent(customer);
  }

  if (loading) return <LoadingSpinner />;

  return (
    <div className="space-y-8">
      <PageHeader
        title="Bảng điều khiển"
        subtitle="Doanh số cá nhân — biết tiền và biết khách cần chăm"
        // action={
        //   <div className="flex flex-wrap gap-2">
        //     <Link to="/orders/new">
        //       <PrimaryButton>
        //         <Receipt className="h-4 w-4" />
        //         Ghi đơn
        //       </PrimaryButton>
        //     </Link>
        //     <Link
        //       to="/customers/new"
        //       className="inline-flex items-center gap-2 rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm hover:bg-slate-50 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-200"
        //     >
        //       <Plus className="h-4 w-4" />
        //       Thêm khách
        //     </Link>
        //   </div>
        // }
      />

      <SalesDashboard title="Hôm nay" summary={todaySales} />
      <SalesDashboard title="Tháng này" summary={monthSales} />

      {lowStock.length > 0 && (
        <Panel title={`Cảnh báo tồn kho (${lowStock.length})`}>
          <ul className="space-y-2">
            {lowStock.slice(0, 6).map((p) => {
              const status = productStockStatus(p);
              return (
                <li
                  key={p.id}
                  className="flex items-center justify-between rounded-lg border border-slate-200 px-3 py-2 text-sm dark:border-slate-700"
                >
                  <span className="flex items-center gap-2 font-medium">
                    <Package className="h-4 w-4 text-slate-400" />
                    {p.name}
                  </span>
                  <span
                    className={`rounded-full px-2 py-0.5 text-xs font-semibold ${
                      status === 'out'
                        ? 'bg-red-100 text-red-800 dark:bg-red-950 dark:text-red-300'
                        : 'bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-300'
                    }`}
                  >
                    {p.stock_quantity} · {stockStatusLabel(status)}
                  </span>
                </li>
              );
            })}
          </ul>
          {lowStock.length > 6 && (
            <p className="mt-2 text-xs text-slate-500">+ {lowStock.length - 6} mặt hàng khác</p>
          )}
          <Link
            to="/products"
            className="mt-3 inline-block text-sm font-medium text-brand-600 hover:underline dark:text-brand-400"
          >
            Quản lý tồn kho →
          </Link>
        </Panel>
      )}

      <div>
        <h2 className="mb-3 text-sm font-bold uppercase tracking-wider text-slate-500">
          Chăm khách
        </h2>
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <StatCard
            label="Cần liên hệ ngay"
            value={needsAttention.length}
            variant={needsAttention.length > 0 ? 'warning' : 'default'}
            hint="Ưu tiên xử lý trước"
          />
          <StatCard label="Sắp tới" value={upcoming.length} hint="Chưa đến hạn nhắc" />
          <StatCard
            label="Quá hạn > 3 ngày"
            value={overdueCount}
            variant={overdueCount > 0 ? 'warning' : 'default'}
          />
          <StatCard
            label="Streak liên hệ"
            value={streak > 0 ? `${streak} ngày` : '—'}
            variant={streak >= 7 ? 'success' : 'brand'}
          />
        </div>
      </div>

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
            <CustomerTable
              customers={filteredNeeds}
              urgent
              compact
              onQuickMessage={handleQuickMessage}
            />
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
            <CustomerTable customers={filteredUpcoming} compact />
          )}
        </Panel>
      </div>
    </div>
  );
}
