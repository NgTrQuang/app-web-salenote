import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Receipt, Plus } from 'lucide-react';
import type { Customer, Order } from '@/types';
import { PAYMENT_LABELS, orderCommission, orderDebt, orderProfit, orderRevenue } from '@/types';
import { Breadcrumbs } from '@/components/CustomerTable';
import { PageHeader, Panel, EmptyState, LoadingSpinner, PrimaryButton } from '@/components/ui';
import { getAllOrders } from '@/lib/orderService';
import { getAllCustomers } from '@/lib/customerService';
import { formatMoney } from '@/lib/money';
import { useDataRefresh } from '@/hooks/useDataRefresh';

export function OrdersPage() {
  const refresh = useDataRefresh();
  const [orders, setOrders] = useState<Order[]>([]);
  const [customerMap, setCustomerMap] = useState<Map<number, Customer>>(new Map());
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    Promise.all([getAllOrders(), getAllCustomers()]).then(([ords, customers]) => {
      setOrders(ords);
      setCustomerMap(new Map(customers.map((c) => [c.id!, c])));
      setLoading(false);
    });
  }, [refresh]);

  return (
    <div>
      <Breadcrumbs items={[{ label: 'Bảng điều khiển', to: '/' }, { label: 'Đơn hàng' }]} />

      <PageHeader
        title="Đơn hàng"
        subtitle="Lịch sử ghi đơn và đối soát doanh thu"
        action={
          <Link to="/orders/new">
            <PrimaryButton>
              <Plus className="h-4 w-4" />
              Ghi đơn mới
            </PrimaryButton>
          </Link>
        }
      />

      {loading ? (
        <LoadingSpinner />
      ) : orders.length === 0 ? (
        <EmptyState
          icon={<Receipt className="h-10 w-10" />}
          title="Chưa có đơn hàng"
          description="Ghi đơn từ trang khách hoặc nút Ghi đơn mới."
          action={
            <Link to="/orders/new">
              <PrimaryButton>
                <Plus className="h-4 w-4" />
                Ghi đơn đầu tiên
              </PrimaryButton>
            </Link>
          }
        />
      ) : (
        <Panel noPadding>
          <div className="overflow-x-auto">
            <table className="w-full min-w-[900px] text-left text-sm">
              <thead>
                <tr className="border-b border-slate-200 bg-slate-50 text-xs font-semibold uppercase text-slate-500 dark:border-slate-800 dark:bg-slate-800/50">
                  <th className="px-4 py-3">Ngày</th>
                  <th className="px-4 py-3">Khách</th>
                  <th className="px-4 py-3">Sản phẩm</th>
                  <th className="px-4 py-3 text-right">SL</th>
                  <th className="px-4 py-3 text-right">Doanh thu</th>
                  <th className="px-4 py-3 text-right">Lợi nhuận</th>
                  <th className="px-4 py-3 text-right">HH</th>
                  <th className="px-4 py-3">TT</th>
                  <th className="px-4 py-3 text-right">Công nợ</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                {orders.map((o) => {
                  const customer = customerMap.get(o.customer_id);
                  const debt = orderDebt(o);
                  return (
                    <tr key={o.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/40">
                      <td className="px-4 py-3 whitespace-nowrap text-slate-500">
                        {new Date(o.created_at).toLocaleDateString('vi-VN')}
                      </td>
                      <td className="px-4 py-3">
                        {customer ? (
                          <Link
                            to={`/customers/${customer.id}`}
                            className="font-medium text-brand-600 hover:underline"
                          >
                            {customer.name}
                          </Link>
                        ) : (
                          '—'
                        )}
                      </td>
                      <td className="px-4 py-3">{o.product_name}</td>
                      <td className="px-4 py-3 text-right tabular-nums">{o.quantity}</td>
                      <td className="px-4 py-3 text-right tabular-nums font-medium">
                        {formatMoney(orderRevenue(o))}
                      </td>
                      <td className="px-4 py-3 text-right tabular-nums text-emerald-700 dark:text-emerald-400">
                        {formatMoney(orderProfit(o))}
                      </td>
                      <td className="px-4 py-3 text-right tabular-nums">
                        {formatMoney(orderCommission(o))}
                      </td>
                      <td className="px-4 py-3">
                        <span
                          className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                            o.payment_status === 'paid'
                              ? 'bg-emerald-100 text-emerald-800'
                              : o.payment_status === 'partial'
                                ? 'bg-amber-100 text-amber-800'
                                : 'bg-red-100 text-red-800'
                          }`}
                        >
                          {PAYMENT_LABELS[o.payment_status]}
                        </span>
                      </td>
                      <td
                        className={`px-4 py-3 text-right tabular-nums ${
                          debt > 0 ? 'font-medium text-red-600' : 'text-slate-400'
                        }`}
                      >
                        {debt > 0 ? formatMoney(debt) : '—'}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </Panel>
      )}
    </div>
  );
}
