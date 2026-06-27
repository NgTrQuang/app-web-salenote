import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Wallet, ChevronRight } from 'lucide-react';
import { Breadcrumbs } from '@/components/CustomerTable';
import { PageHeader, Panel, EmptyState, LoadingSpinner } from '@/components/ui';
import { getDebtList, type DebtEntry } from '@/lib/debtService';
import { formatMoney } from '@/lib/money';
import { NAV_HOME_LABEL } from '@/lib/constants';
import { useDataRefresh } from '@/hooks/useDataRefresh';
import { useClientPagination } from '@/hooks/useClientPagination';
import { Pagination } from '@/components/Pagination';

function daysSince(ms: number): number {
  return Math.floor((Date.now() - ms) / 86400000);
}

export function DebtsPage() {
  const refresh = useDataRefresh();
  const [debts, setDebts] = useState<DebtEntry[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    getDebtList().then((list) => {
      if (!cancelled) {
        setDebts(list);
        setLoading(false);
      }
    });
    return () => {
      cancelled = true;
    };
  }, [refresh]);

  const totalDebt = debts.reduce((s, d) => s + d.totalDebt, 0);
  const { page, setPage, slice, total, pageSize } = useClientPagination(debts);

  if (loading) return <LoadingSpinner />;

  return (
    <div className="space-y-6">
      <Breadcrumbs
        items={[{ label: NAV_HOME_LABEL, to: '/' }, { label: 'Ai nợ tôi' }]}
      />

      <PageHeader
        title="Ai nợ tôi"
        subtitle={
          debts.length > 0
            ? `${debts.length} khách · Tổng ${formatMoney(totalDebt)} chưa thu`
            : 'Không ai còn nợ — tốt lắm!'
        }
      />

      {debts.length === 0 ? (
        <EmptyState
          icon={<Wallet className="h-10 w-10" />}
          title="Không có công nợ"
          description="Mọi đơn đã thu đủ. Khi ghi đơn chưa thu hết, khách sẽ xuất hiện ở đây."
        />
      ) : (
        <Panel title={`Danh sách nợ (${debts.length})`} noPadding>
          <ul className="divide-y divide-slate-100 dark:divide-slate-800">
            {slice.map((d) => (
              <li key={d.customerId}>
                <Link
                  to={`/customers/${d.customerId}`}
                  className="flex items-center gap-3 px-4 py-3 transition hover:bg-slate-50 dark:hover:bg-slate-800/40"
                >
                  <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-400">
                    <Wallet className="h-5 w-5" />
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-medium text-slate-900 dark:text-white">
                      {d.name}
                    </p>
                    <p className="truncate text-sm text-slate-500">
                      {d.orderCount} đơn chưa thu đủ
                      {d.phone ? ` · ${d.phone}` : ''}
                      {d.oldestOrderAt != null && (
                        <> · {daysSince(d.oldestOrderAt)} ngày</>
                      )}
                    </p>
                  </div>
                  <div className="flex shrink-0 items-center gap-2">
                    <span className="font-semibold text-amber-700 dark:text-amber-400">
                      {formatMoney(d.totalDebt)}
                    </span>
                    <ChevronRight className="h-4 w-4 text-slate-400" />
                  </div>
                </Link>
              </li>
            ))}
          </ul>
          <Pagination page={page} pageSize={pageSize} total={total} onPageChange={setPage} />
        </Panel>
      )}
    </div>
  );
}
