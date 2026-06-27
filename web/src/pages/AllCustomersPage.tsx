import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Users, Plus } from 'lucide-react';
import type { Customer, CustomerStatus } from '@/types';
import { CustomerTable, Breadcrumbs } from '@/components/CustomerTable';
import { PageHeader, EmptyState, LoadingSpinner, SearchInput, Panel } from '@/components/ui';
import { STATUSES, STATUS_LABELS, CUSTOMER_SOURCES, NAV_HOME_LABEL } from '@/lib/constants';
import {
  countAllCustomers,
  countCustomers,
  getCustomersPaged,
} from '@/lib/customerService';
import { useDataRefresh } from '@/hooks/useDataRefresh';
import { DEFAULT_PAGE_SIZE } from '@/hooks/useClientPagination';
import { Pagination } from '@/components/Pagination';

type FilterStatus = CustomerStatus | 'all';
type FilterSource = string | 'all' | '_none';

export function AllCustomersPage() {
  const refresh = useDataRefresh();
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [query, setQuery] = useState('');
  const [status, setStatus] = useState<FilterStatus>('all');
  const [source, setSource] = useState<FilterSource>('all');
  const [page, setPage] = useState(1);
  const [totalFiltered, setTotalFiltered] = useState(0);
  const [totalAll, setTotalAll] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    const filters = { query, status, source };
    Promise.all([
      getCustomersPaged(page, DEFAULT_PAGE_SIZE, filters),
      countCustomers(filters),
      countAllCustomers(),
    ])
      .then(([list, filtered, all]) => {
        setCustomers(list);
        setTotalFiltered(filtered);
        setTotalAll(all);
      })
      .finally(() => setLoading(false));
  }, [refresh, page, query, status, source]);

  const filterLabel =
    totalFiltered === totalAll
      ? `${totalAll} khách`
      : `${totalFiltered} / ${totalAll} khách`;

  return (
    <div>
      <Breadcrumbs items={[{ label: NAV_HOME_LABEL, to: '/' }, { label: 'Sổ khách' }]} />

      <PageHeader
        title="Sổ khách"
        subtitle={`${filterLabel} — bộ nhớ cá nhân, mang theo mọi kênh bán`}
        action={
          <Link
            to="/customers/new"
            className="inline-flex items-center gap-2 rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-brand-700"
          >
            <Plus className="h-4 w-4" />
            Thêm khách
          </Link>
        }
      />

      <div className="mb-4 flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <SearchInput
          value={query}
          onChange={(q) => {
            setQuery(q);
            setPage(1);
          }}
          placeholder="Tìm theo tên, SĐT, sản phẩm..."
          className="max-w-none lg:max-w-sm"
        />
        <div className="flex flex-wrap gap-2">
          <FilterChip
            active={status === 'all'}
            onClick={() => {
              setStatus('all');
              setPage(1);
            }}
            label="Tất cả"
          />
          {STATUSES.map((s) => (
            <FilterChip
              key={s}
              active={status === s}
              onClick={() => {
                setStatus(s);
                setPage(1);
              }}
              label={STATUS_LABELS[s]}
            />
          ))}
        </div>
      </div>

      <div className="mb-4 flex flex-wrap items-center gap-2">
        <span className="text-xs font-semibold uppercase tracking-wide text-slate-500">Nguồn:</span>
        <FilterChip
          active={source === 'all'}
          onClick={() => {
            setSource('all');
            setPage(1);
          }}
          label="Tất cả"
        />
        <FilterChip
          active={source === '_none'}
          onClick={() => {
            setSource('_none');
            setPage(1);
          }}
          label="Chưa ghi"
        />
        {CUSTOMER_SOURCES.map((s) => (
          <FilterChip
            key={s.key}
            active={source === s.key}
            onClick={() => {
              setSource(s.key);
              setPage(1);
            }}
            label={s.label}
          />
        ))}
      </div>

      {loading ? (
        <LoadingSpinner />
      ) : totalFiltered === 0 ? (
        <EmptyState
          icon={<Users className="h-10 w-10" />}
          title="Không có khách"
          description="Thêm khách mới hoặc thử đổi bộ lọc trạng thái / nguồn."
          action={
            <Link
              to="/customers/new"
              className="inline-flex items-center gap-2 rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white"
            >
              <Plus className="h-4 w-4" />
              Thêm khách đầu tiên
            </Link>
          }
        />
      ) : (
        <Panel noPadding>
          <CustomerTable customers={customers} />
          <Pagination
            page={page}
            pageSize={DEFAULT_PAGE_SIZE}
            total={totalFiltered}
            onPageChange={setPage}
          />
        </Panel>
      )}
    </div>
  );
}

function FilterChip({
  active,
  onClick,
  label,
}: {
  active: boolean;
  onClick: () => void;
  label: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`rounded-lg px-3 py-1.5 text-sm font-medium transition ${
        active
          ? 'bg-brand-600 text-white shadow-sm'
          : 'border border-slate-200 bg-white text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300'
      }`}
    >
      {label}
    </button>
  );
}
