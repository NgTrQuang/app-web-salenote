import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import {
  Phone,
  MessageSquare,
  Receipt,
  Pencil,
  Trash2,
  Copy,
} from 'lucide-react';
import type { Customer, Interaction, Order } from '@/types';
import {
  PAYMENT_LABELS,
  orderDebt,
  orderProfit,
  orderRevenue,
  summarizeOrders,
  warrantyDaysLeft,
} from '@/types';
import { StatusBadge } from '@/components/StatusBadge';
import { Breadcrumbs } from '@/components/CustomerTable';
import { OrderForm } from '@/components/OrderForm';
import { Panel, PrimaryButton, SecondaryButton, LoadingSpinner, Toast } from '@/components/ui';
import { sourceLabel } from '@/lib/constants';
import {
  applyMessageTemplate,
  deleteCustomer,
  getCustomer,
  getInteractions,
  getMessageTemplate,
  messageSent,
} from '@/lib/customerService';
import { getOrdersByCustomer } from '@/lib/orderService';
import { formatMoney } from '@/lib/money';
import { formatDateTime, relativeTime, nextActionLabel } from '@/lib/dateUtils';
import { MESSAGE_TEMPLATES } from '@/lib/constants';
import { CustomerIntelligencePanel } from '@/components/CustomerIntelligencePanel';
import { BillPreviewDialog } from '@/components/BillPreviewDialog';
import { buildCustomerIntelligence } from '@/lib/insightsService';
import { formatAddressOnly, formatShippingInfo } from '@/lib/shippingUtils';
import { useDataRefresh } from '@/hooks/useDataRefresh';

export function CustomerDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const refresh = useDataRefresh();
  const [customer, setCustomer] = useState<Customer | null>(null);
  const [interactions, setInteractions] = useState<Interaction[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [customMsg, setCustomMsg] = useState('');
  const [showMsg, setShowMsg] = useState(false);
  const [showOrderForm, setShowOrderForm] = useState(false);
  const [billOrder, setBillOrder] = useState<Order | null>(null);
  const [toast, setToast] = useState('');

  async function reloadCustomerData() {
    if (!id) return;
    const [c, ints, ords, tpl] = await Promise.all([
      getCustomer(Number(id)),
      getInteractions(Number(id)),
      getOrdersByCustomer(Number(id)),
      getMessageTemplate(),
    ]);
    setCustomer(c ?? null);
    setInteractions(ints);
    setOrders(ords);
    if (c) {
      setCustomMsg(applyMessageTemplate(tpl, c.name, c.product ?? 'sản phẩm'));
    }
  }

  useEffect(() => {
    void reloadCustomerData();
  }, [id, refresh]);

  function showToastMsg(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(''), 2800);
  }

  async function handleMessageSent() {
    if (!customer) return;
    await messageSent(customer);
    const updated = await getCustomer(customer.id!);
    const ints = await getInteractions(customer.id!);
    setCustomer(updated ?? null);
    setInteractions(ints);
    setShowMsg(false);
    showToastMsg('Đã ghi nhận liên hệ');
  }

  async function handleOrderSaved() {
    setShowOrderForm(false);
    await reloadCustomerData();
    showToastMsg('Đã ghi đơn hàng');
  }

  async function handleDelete() {
    if (!customer?.id) return;
    if (!confirm(`Xoá ${customer.name}? Không thể hoàn tác.`)) return;
    await deleteCustomer(customer.id);
    navigate('/customers', { replace: true });
  }

  async function copyAddress() {
    const text = formatAddressOnly(customer);
    if (!text) {
      showToastMsg('Chưa có địa chỉ');
      return;
    }
    await navigator.clipboard.writeText(text);
    showToastMsg('Đã sao chép địa chỉ');
  }

  async function copyShippingForOrder(order: Order) {
    await navigator.clipboard.writeText(formatShippingInfo(customer, order));
    showToastMsg('Đã sao chép thông tin giao hàng');
  }

  async function copyMessage(text: string) {
    await navigator.clipboard.writeText(text);
    showToastMsg('Đã sao chép tin nhắn');
  }

  if (!customer) return <LoadingSpinner />;

  const warranty = warrantyDaysLeft(customer);
  const salesSummary = summarizeOrders(orders);
  const intelligence = buildCustomerIntelligence(customer, orders);

  return (
    <div>
      <Breadcrumbs
        items={[
          { label: 'Khách hàng', to: '/customers' },
          { label: customer.name },
        ]}
      />

      <div className="grid gap-6 lg:grid-cols-3">
        {/* Thông tin khách */}
        <div className="space-y-6 lg:col-span-1">
          <Panel title="Thông tin khách">
            <div className="flex items-start gap-4">
              <div className="flex h-16 w-16 shrink-0 items-center justify-center rounded-xl bg-brand-100 text-2xl font-bold text-brand-700 dark:bg-brand-900/40">
                {customer.name.charAt(0).toUpperCase()}
              </div>
              <div>
                <h1 className="text-xl font-bold text-slate-900 dark:text-white">
                  {customer.name}
                </h1>
                <div className="mt-2">
                  <StatusBadge status={customer.status} />
                </div>
              </div>
            </div>

            <dl className="mt-6 space-y-4 text-sm">
              {customer.phone && (
                <div>
                  <dt className="text-slate-500">Số điện thoại</dt>
                  <dd className="mt-0.5">
                    <a
                      href={`tel:${customer.phone}`}
                      className="inline-flex items-center gap-1 font-medium text-brand-600 hover:underline"
                    >
                      <Phone className="h-4 w-4" />
                      {customer.phone}
                    </a>
                  </dd>
                </div>
              )}
              <div>
                <dt className="text-slate-500">Địa chỉ giao hàng</dt>
                <dd className="mt-0.5">
                  {customer.address ? (
                    <div className="flex items-start gap-2">
                      <span className="font-medium">{customer.address}</span>
                      <button
                        type="button"
                        onClick={() => void copyAddress()}
                        className="shrink-0 rounded p-1 text-brand-600 hover:bg-brand-50 dark:hover:bg-brand-950/30"
                        title="Sao chép địa chỉ"
                      >
                        <Copy className="h-4 w-4" />
                      </button>
                    </div>
                  ) : (
                    <span className="text-slate-400">Chưa có — thêm khi sửa khách</span>
                  )}
                </dd>
              </div>
              <div>
                <dt className="text-slate-500">Nguồn khách</dt>
                <dd className="mt-0.5 font-medium">{sourceLabel(customer.source)}</dd>
              </div>
              {customer.product && (
                <div>
                  <dt className="text-slate-500">Sản phẩm quan tâm</dt>
                  <dd className="mt-0.5 font-medium">
                    {customer.product}
                    {customer.product_id && (
                      <Link
                        to="/products"
                        className="ml-2 text-xs font-normal text-brand-600 hover:underline"
                      >
                        (danh mục)
                      </Link>
                    )}
                  </dd>
                </div>
              )}
              <div>
                <dt className="text-slate-500">Nhắc tiếp theo</dt>
                <dd className="mt-0.5 font-medium">
                  {nextActionLabel(customer.next_action_at)}
                </dd>
              </div>
              {warranty != null && (
                <div>
                  <dt className="text-slate-500">Bảo hành</dt>
                  <dd className="mt-0.5 font-medium text-amber-700 dark:text-amber-400">
                    Còn {warranty} ngày
                  </dd>
                </div>
              )}
              {customer.note && (
                <div>
                  <dt className="text-slate-500">Ghi chú</dt>
                  <dd className="mt-1 rounded-lg bg-slate-50 p-3 text-slate-700 dark:bg-slate-800 dark:text-slate-300">
                    {customer.note}
                  </dd>
                </div>
              )}
            </dl>

            <div className="mt-6 flex flex-wrap gap-2 border-t border-slate-200 pt-6 dark:border-slate-800">
              <PrimaryButton onClick={() => setShowOrderForm(true)}>
                <Receipt className="h-4 w-4" />
                Ghi đơn
              </PrimaryButton>
              {customer.status !== 'closed' && (
                <PrimaryButton onClick={() => setShowMsg(true)}>
                  <MessageSquare className="h-4 w-4" />
                  Nhắn tin
                </PrimaryButton>
              )}
              <Link to={`/customers/${customer.id}/edit`}>
                <SecondaryButton>
                  <Pencil className="h-4 w-4" />
                  Sửa
                </SecondaryButton>
              </Link>
              <SecondaryButton onClick={handleDelete} className="text-red-600 hover:text-red-700">
                <Trash2 className="h-4 w-4" />
                Xoá
              </SecondaryButton>
            </div>
          </Panel>

          {orders.length > 0 && <CustomerIntelligencePanel intel={intelligence} />}

          {orders.length > 0 && (
            <Panel title="Tổng kết bán hàng (tóm tắt)">
              <dl className="grid grid-cols-2 gap-3 text-sm">
                <div>
                  <dt className="text-slate-500">Doanh thu</dt>
                  <dd className="font-bold text-slate-900 dark:text-white">
                    {formatMoney(salesSummary.revenue)}
                  </dd>
                </div>
                <div>
                  <dt className="text-slate-500">Lợi nhuận</dt>
                  <dd className="font-bold text-emerald-700 dark:text-emerald-400">
                    {formatMoney(salesSummary.profit)}
                  </dd>
                </div>
                <div>
                  <dt className="text-slate-500">Hoa hồng</dt>
                  <dd className="font-bold text-brand-700 dark:text-brand-400">
                    {formatMoney(salesSummary.commission)}
                  </dd>
                </div>
                <div>
                  <dt className="text-slate-500">Công nợ</dt>
                  <dd
                    className={`font-bold ${salesSummary.debt > 0 ? 'text-red-600' : 'text-slate-600'}`}
                  >
                    {formatMoney(salesSummary.debt)}
                  </dd>
                </div>
              </dl>
            </Panel>
          )}
        </div>

        {/* Timeline + Orders */}
        <div className="space-y-6 lg:col-span-2">
          {orders.length > 0 && (
            <Panel title={`Đơn hàng (${orders.length})`} noPadding>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-slate-200 bg-slate-50 text-xs uppercase text-slate-500 dark:border-slate-800">
                      <th className="px-4 py-2 text-left">Ngày</th>
                      <th className="px-4 py-2 text-left">SP</th>
                      <th className="px-4 py-2 text-right">Doanh thu</th>
                      <th className="px-4 py-2 text-right">Lời</th>
                      <th className="px-4 py-2 text-left">TT</th>
                      <th className="px-4 py-2 text-right">Thao tác</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                    {orders.map((o) => (
                      <tr key={o.id}>
                        <td className="px-4 py-2 text-slate-500">
                          {new Date(o.created_at).toLocaleDateString('vi-VN')}
                        </td>
                        <td className="px-4 py-2">
                          {o.product_name} × {o.quantity}
                        </td>
                        <td className="px-4 py-2 text-right font-medium">
                          {formatMoney(orderRevenue(o))}
                        </td>
                        <td className="px-4 py-2 text-right text-emerald-700">
                          {formatMoney(orderProfit(o))}
                        </td>
                        <td className="px-4 py-2 text-xs">
                          {PAYMENT_LABELS[o.payment_status]}
                          {orderDebt(o) > 0 && (
                            <span className="ml-1 text-red-600">
                              nợ {formatMoney(orderDebt(o))}
                            </span>
                          )}
                        </td>
                        <td className="px-4 py-2 text-right">
                          <div className="flex justify-end gap-1">
                            <button
                              type="button"
                              title="Sao chép giao hàng"
                              onClick={() => void copyShippingForOrder(o)}
                              className="rounded p-1.5 text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
                            >
                              <Copy className="h-4 w-4" />
                            </button>
                            <button
                              type="button"
                              title="Xem bill"
                              onClick={() => setBillOrder(o)}
                              className="rounded p-1.5 text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
                            >
                              <Receipt className="h-4 w-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </Panel>
          )}

          <Panel title="Lịch sử liên hệ">
            {interactions.length === 0 ? (
              <p className="text-sm text-slate-500">Chưa có hoạt động nào.</p>
            ) : (
              <div className="relative">
                <div className="absolute bottom-2 left-3 top-2 w-px bg-slate-200 dark:bg-slate-700" />
                <ul className="space-y-4">
                  {interactions.map((i) => (
                    <li key={i.id} className="relative pl-10">
                      <span className="absolute left-1.5 top-1.5 h-3 w-3 rounded-full border-2 border-white bg-brand-500 shadow dark:border-slate-900" />
                      <div className="rounded-lg border border-slate-200 bg-slate-50/50 px-4 py-3 dark:border-slate-800 dark:bg-slate-800/30">
                        <p className="font-medium text-slate-900 dark:text-white">{i.content}</p>
                        <p className="mt-1 text-xs text-slate-500">
                          {formatDateTime(i.created_at)} · {relativeTime(i.created_at)}
                        </p>
                      </div>
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </Panel>
        </div>
      </div>

      {showOrderForm && customer && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
          <div className="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-slate-900">
            <div className="border-b border-slate-200 px-6 py-4 dark:border-slate-800">
              <h2 className="text-lg font-bold">Ghi đơn hàng</h2>
            </div>
            <div className="px-6 py-4">
              <OrderForm
                customer={customer}
                onSuccess={handleOrderSaved}
                onCancel={() => setShowOrderForm(false)}
              />
            </div>
          </div>
        </div>
      )}

      {showMsg && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
          <div
            className="w-full max-w-lg rounded-xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-slate-900"
            role="dialog"
            aria-modal="true"
            aria-labelledby="msg-dialog-title"
          >
            <div className="border-b border-slate-200 px-6 py-4 dark:border-slate-800">
              <h2 id="msg-dialog-title" className="text-lg font-bold">
                Soạn tin nhắn
              </h2>
              <p className="mt-1 text-sm text-slate-500">
                Sao chép và dán vào Zalo / Messenger
              </p>
            </div>
            <div className="px-6 py-4">
              <div className="mb-3 flex flex-wrap gap-2">
                {MESSAGE_TEMPLATES.slice(0, 3).map((t, idx) => (
                  <button
                    key={idx}
                    type="button"
                    onClick={() =>
                      setCustomMsg(
                        applyMessageTemplate(t, customer.name, customer.product ?? 'sản phẩm'),
                      )
                    }
                    className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
                  >
                    Mẫu {idx + 1}
                  </button>
                ))}
              </div>
              <textarea
                value={customMsg}
                onChange={(e) => setCustomMsg(e.target.value)}
                rows={6}
                className="w-full rounded-lg border border-slate-300 p-3 text-sm dark:border-slate-600 dark:bg-slate-800"
              />
            </div>
            <div className="flex justify-end gap-2 border-t border-slate-200 px-6 py-4 dark:border-slate-800">
              <SecondaryButton onClick={() => setShowMsg(false)}>Huỷ</SecondaryButton>
              <SecondaryButton onClick={() => copyMessage(customMsg)}>
                <Copy className="h-4 w-4" />
                Sao chép
              </SecondaryButton>
              <PrimaryButton onClick={handleMessageSent}>Đã nhắn xong</PrimaryButton>
            </div>
          </div>
        </div>
      )}

      {billOrder && (
        <BillPreviewDialog
          customer={customer}
          order={billOrder}
          onClose={() => setBillOrder(null)}
        />
      )}

      {toast && <Toast message={toast} />}
    </div>
  );
}
