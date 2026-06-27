import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Receipt, Plus } from 'lucide-react';
import type { Customer, Order } from '@/types';
import { PAYMENT_LABELS, orderCommission, orderDebt, orderProfit, orderRevenue } from '@/types';
import { Breadcrumbs } from '@/components/CustomerTable';
import { PageHeader, Panel, EmptyState, LoadingSpinner, PrimaryButton } from '@/components/ui';
import { Pagination } from '@/components/Pagination';
import { OrderPaymentDialog } from '@/components/OrderPaymentDialog';
import { countOrders, getOrdersPaged } from '@/lib/orderService';
import { getCustomersByIds } from '@/lib/customerService';
import { formatMoney } from '@/lib/money';
import { NAV_HOME_LABEL } from '@/lib/constants';
import { useDataRefresh } from '@/hooks/useDataRefresh';

const PAGE_SIZE = 20;

export function OrdersPage() {
  const refresh = useDataRefresh();
  const [orders, setOrders] = useState<Order[]>([]);
  const [customerMap, setCustomerMap] = useState<Map<number, Customer>>(new Map());
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const [reloadNonce, setReloadNonce] = useState(0);

  useEffect(() => {
    setLoading(true);
    Promise.all([getOrdersPaged(page, PAGE_SIZE), countOrders()])
      .then(async ([ords, count]) => {
        setOrders(ords);
        setTotal(count);
        const ids = [...new Set(ords.map((o) => o.customer_id))];
        const customers = await getCustomersByIds(ids);
        setCustomerMap(new Map(customers.map((c) => [c.id!, c])));
      })
      .finally(() => setLoading(false));
  }, [refresh, page, reloadNonce]);

  function handleSaved() {
    setSelectedOrder(null);
    setSelectedCustomer(null);
    setPage(1);
    setReloadNonce((n) => n + 1);
  }

  return (
    <div>
      <Breadcrumbs items={[{ label: NAV_HOME_LABEL, to: '/' }, { label: 'Đơn hàng' }]} />

      <PageHeader
        title="Đơn hàng"
        subtitle="Lịch sử ghi đơn và đối soát doanh thu — bấm dòng để xem/cập nhật thanh toán"
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
                    <tr
                      key={o.id}
                      className="cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800/40"
                      onClick={() => {
                        setSelectedOrder(o);
                        setSelectedCustomer(customer ?? null);
                      }}
                    >
                      <td className="px-4 py-3 whitespace-nowrap text-slate-500">
                        {new Date(o.created_at).toLocaleDateString('vi-VN')}
                      </td>
                      <td className="px-4 py-3">
                        {customer ? (
                          <Link
                            to={`/customers/${customer.id}`}
                            className="font-medium text-brand-600 hover:underline"
                            onClick={(e) => e.stopPropagation()}
                          >
                            {customer.name}
                          </Link>
                        ) : (
                          '—'
                        )}
                      </td>
                      <td className="max-w-[200px] truncate px-4 py-3" title={o.product_name}>
                        {o.product_name}
                      </td>
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
          <Pagination page={page} pageSize={PAGE_SIZE} total={total} onPageChange={setPage} />
        </Panel>
      )}

      {selectedOrder && selectedCustomer && (
        <OrderPaymentDialog
          order={selectedOrder}
          customer={selectedCustomer}
          onClose={() => {
            setSelectedOrder(null);
            setSelectedCustomer(null);
          }}
          onSaved={handleSaved}
        />
      )}
    </div>
  );
}
