import { Link } from 'react-router-dom';
import { ChevronRight, MessageSquare, ExternalLink } from 'lucide-react';
import type { Customer } from '@/types';
import { StatusBadge } from './StatusBadge';
import { nextActionLabel } from '@/lib/dateUtils';
import { sourceLabel } from '@/lib/constants';
import { warrantyDaysLeft } from '@/types';

interface CustomerTableProps {
  customers: Customer[];
  urgent?: boolean;
  onQuickMessage?: (customer: Customer) => void;
  compact?: boolean;
}

export function CustomerTable({
  customers,
  urgent,
  onQuickMessage,
  compact,
}: CustomerTableProps) {
  if (customers.length === 0) return null;

  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[640px] text-left text-sm">
          <thead>
            <tr className="border-b border-slate-200 bg-slate-50 text-xs font-semibold uppercase tracking-wide text-slate-500 dark:border-slate-800 dark:bg-slate-800/50 dark:text-slate-400">
              <th className="px-4 py-3">Khách hàng</th>
              {!compact && <th className="px-4 py-3">Nguồn</th>}
              <th className="px-4 py-3">Sản phẩm</th>
              {!compact && <th className="px-4 py-3">Liên hệ</th>}
              <th className="px-4 py-3">Trạng thái</th>
              <th className="px-4 py-3">Nhắc tiếp</th>
              <th className="px-4 py-3 text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
            {customers.map((c) => (
              <CustomerTableRow
                key={c.id}
                customer={c}
                urgent={urgent}
                compact={compact}
                onQuickMessage={onQuickMessage}
              />
            ))}
          </tbody>
        </table>
    </div>
  );
}

function CustomerTableRow({
  customer,
  urgent,
  compact,
  onQuickMessage,
}: {
  customer: Customer;
  urgent?: boolean;
  compact?: boolean;
  onQuickMessage?: (customer: Customer) => void;
}) {
  const warranty = warrantyDaysLeft(customer);

  return (
    <tr
      className={`transition hover:bg-slate-50 dark:hover:bg-slate-800/40 ${
        urgent ? 'bg-red-50/50 dark:bg-red-950/10' : ''
      }`}
    >
      <td className="px-4 py-3">
        <Link
          to={`/customers/${customer.id}`}
          className="group flex items-center gap-3 font-medium text-slate-900 dark:text-white"
        >
          <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-brand-100 text-sm font-bold text-brand-700 dark:bg-brand-900/40 dark:text-brand-300">
            {customer.name.charAt(0).toUpperCase()}
          </span>
          <span className="group-hover:text-brand-600 dark:group-hover:text-brand-400">
            {customer.name}
          </span>
        </Link>
      </td>
      {!compact && (
        <td className="px-4 py-3 text-slate-600 dark:text-slate-400">
          {sourceLabel(customer.source)}
        </td>
      )}
      <td className="max-w-[180px] truncate px-4 py-3 text-slate-600 dark:text-slate-400">
        {customer.product || '—'}
        {warranty != null && (
          <span className="ml-2 inline-block rounded bg-amber-100 px-1.5 py-0.5 text-[10px] font-medium text-amber-800 dark:bg-amber-900/40 dark:text-amber-300">
            BH {warranty}d
          </span>
        )}
      </td>
      {!compact && (
        <td className="px-4 py-3 text-slate-600 dark:text-slate-400">
          {customer.phone ? (
            <a
              href={`tel:${customer.phone}`}
              className="hover:text-brand-600 dark:hover:text-brand-400"
            >
              {customer.phone}
            </a>
          ) : (
            '—'
          )}
        </td>
      )}
      <td className="px-4 py-3">
        <StatusBadge status={customer.status} />
      </td>
      <td
        className={`px-4 py-3 text-sm ${
          urgent ? 'font-medium text-red-600 dark:text-red-400' : 'text-slate-500'
        }`}
      >
        {nextActionLabel(customer.next_action_at)}
      </td>
      <td className="px-4 py-3">
        <div className="flex items-center justify-end gap-2">
          {onQuickMessage && customer.status !== 'closed' && (
            <button
              type="button"
              onClick={() => onQuickMessage(customer)}
              className="inline-flex items-center gap-1 rounded-md border border-slate-200 px-2.5 py-1.5 text-xs font-medium text-slate-700 transition hover:border-brand-300 hover:bg-brand-50 hover:text-brand-700 dark:border-slate-700 dark:text-slate-300 dark:hover:border-brand-800 dark:hover:bg-brand-950/30"
            >
              <MessageSquare className="h-3.5 w-3.5" />
              Đã nhắn
            </button>
          )}
          <Link
            to={`/customers/${customer.id}`}
            className="inline-flex items-center gap-0.5 rounded-md px-2 py-1.5 text-xs font-medium text-brand-600 hover:bg-brand-50 dark:text-brand-400 dark:hover:bg-brand-950/30"
          >
            Chi tiết
            <ExternalLink className="h-3 w-3" />
          </Link>
        </div>
      </td>
    </tr>
  );
}

export function Breadcrumbs({
  items,
}: {
  items: { label: string; to?: string }[];
}) {
  return (
    <nav className="mb-4 flex flex-wrap items-center gap-1 text-sm text-slate-500 dark:text-slate-400">
      {items.map((item, i) => (
        <span key={i} className="flex items-center gap-1">
          {i > 0 && <ChevronRight className="h-4 w-4 shrink-0" />}
          {item.to ? (
            <Link to={item.to} className="hover:text-brand-600 dark:hover:text-brand-400">
              {item.label}
            </Link>
          ) : (
            <span className="font-medium text-slate-800 dark:text-slate-200">
              {item.label}
            </span>
          )}
        </span>
      ))}
    </nav>
  );
}
