import { useState } from 'react';
import { Copy, FileText } from 'lucide-react';
import type { Customer, Order, PaymentStatus } from '@/types';
import {
  PAYMENT_LABELS,
  orderCommission,
  orderDebt,
  orderProfit,
  orderRevenue,
} from '@/types';
import { updateOrderPayment, updateOrderShipping } from '@/lib/orderService';
import { formatMoney, formatMoneyInput, parseMoneyInput } from '@/lib/money';
import {
  formatShippingInfo,
  resolveShippingAddress,
  resolveShippingName,
  resolveShippingPhone,
  shippingDiffersFromCustomer,
} from '@/lib/shippingUtils';
import { BillPreviewDialog } from './BillPreviewDialog';
import { FieldLabel, PrimaryButton, SecondaryButton, TextArea, TextInput } from './ui';

interface OrderPaymentDialogProps {
  order: Order;
  customer: Customer;
  onClose: () => void;
  onSaved: () => void;
}

export function OrderPaymentDialog({
  order,
  customer,
  onClose,
  onSaved,
}: OrderPaymentDialogProps) {
  const readOnlyPayment = order.payment_status === 'paid';
  const revenue = orderRevenue(order);
  const [status, setStatus] = useState<PaymentStatus>(order.payment_status);
  const [paidInput, setPaidInput] = useState(formatMoneyInput(order.paid_amount));
  const [shippingName, setShippingName] = useState(resolveShippingName(order, customer));
  const [shippingPhone, setShippingPhone] = useState(resolveShippingPhone(order, customer));
  const [shippingAddress, setShippingAddress] = useState(resolveShippingAddress(order, customer));
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [copyMsg, setCopyMsg] = useState('');
  const [showBill, setShowBill] = useState(false);

  const previewOrder: Order = {
    ...order,
    shipping_name: shippingName,
    shipping_phone: shippingPhone || null,
    shipping_address: shippingAddress || null,
  };

  const previewPaid =
    status === 'paid' ? revenue : status === 'unpaid' ? 0 : parseMoneyInput(paidInput);
  const previewDebt = Math.max(0, revenue - previewPaid);
  const differsFromCustomer = shippingDiffersFromCustomer(previewOrder, customer);

  async function handleSave() {
    if (!shippingName.trim()) {
      setError('Nhập tên người nhận');
      return;
    }
    setSaving(true);
    setError('');
    try {
      await updateOrderShipping(order.id!, {
        shipping_name: shippingName,
        shipping_phone: shippingPhone || null,
        shipping_address: shippingAddress || null,
      });
      if (!readOnlyPayment) {
        await updateOrderPayment(order.id!, status, previewPaid);
      }
      onSaved();
    } catch {
      setError('Không thể lưu thay đổi');
      setSaving(false);
    }
  }

  async function copyShipping() {
    await navigator.clipboard.writeText(formatShippingInfo(customer, previewOrder));
    setCopyMsg('Đã sao chép thông tin giao hàng');
    setTimeout(() => setCopyMsg(''), 2500);
  }

  return (
    <>
      <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 p-4 sm:items-center">
        <div className="max-h-[92vh] w-full max-w-md overflow-y-auto rounded-xl bg-white p-5 shadow-xl dark:bg-slate-900">
          <h3 className="text-lg font-bold">{readOnlyPayment ? 'Chi tiết đơn' : 'Cập nhật đơn'}</h3>
          <p className="mt-2 text-sm font-medium">
            {order.product_name} × {order.quantity}
          </p>

          <div className="mt-3 flex flex-wrap gap-2">
            <SecondaryButton type="button" className="text-xs" onClick={() => void copyShipping()}>
              <Copy className="h-3.5 w-3.5" />
              Sao chép giao hàng
            </SecondaryButton>
            <SecondaryButton type="button" className="text-xs" onClick={() => setShowBill(true)}>
              <FileText className="h-3.5 w-3.5" />
              Xem bill
            </SecondaryButton>
          </div>
          {copyMsg && <p className="mt-2 text-xs text-brand-600">{copyMsg}</p>}

          <div className="mt-4 space-y-3 rounded-lg border border-slate-200 p-3 dark:border-slate-700">
            <div className="flex items-center justify-between gap-2">
              <p className="text-sm font-semibold">Giao hàng trên đơn</p>
              {differsFromCustomer && (
                <span className="rounded-full bg-amber-100 px-2 py-0.5 text-[10px] font-medium text-amber-800 dark:bg-amber-950 dark:text-amber-200">
                  Khác hồ sơ khách
                </span>
              )}
            </div>
            <div>
              <FieldLabel>Người nhận</FieldLabel>
              <TextInput value={shippingName} onChange={(e) => setShippingName(e.target.value)} />
            </div>
            <div>
              <FieldLabel>SĐT</FieldLabel>
              <TextInput
                value={shippingPhone}
                onChange={(e) => setShippingPhone(e.target.value)}
                inputMode="tel"
              />
            </div>
            <div>
              <FieldLabel>Địa chỉ</FieldLabel>
              <TextArea
                value={shippingAddress}
                onChange={(e) => setShippingAddress(e.target.value)}
                rows={2}
              />
            </div>
          </div>

          <div className="mt-4 grid grid-cols-2 gap-2 rounded-lg bg-slate-50 p-3 text-sm dark:bg-slate-800/60">
            <div>
              <p className="text-slate-500">Doanh thu</p>
              <p className="font-bold text-brand-700 dark:text-brand-400">{formatMoney(revenue)}</p>
            </div>
            <div>
              <p className="text-slate-500">Lợi nhuận</p>
              <p className="font-bold text-emerald-700 dark:text-emerald-400">
                {formatMoney(orderProfit(order))}
              </p>
            </div>
            <div>
              <p className="text-slate-500">Hoa hồng</p>
              <p className="font-bold text-brand-700 dark:text-brand-400">
                {formatMoney(orderCommission(order))}
              </p>
            </div>
            <div>
              <p className="text-slate-500">Công nợ</p>
              <p
                className={`font-bold ${orderDebt(order) > 0 ? 'text-red-600 dark:text-red-400' : 'text-slate-600'}`}
              >
                {formatMoney(orderDebt(order))}
              </p>
            </div>
          </div>

          {!readOnlyPayment && (
            <div className="mt-4 space-y-3">
              <div>
                <FieldLabel>Trạng thái thanh toán</FieldLabel>
                <select
                  value={status}
                  onChange={(e) => setStatus(e.target.value as PaymentStatus)}
                  className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm dark:border-slate-600 dark:bg-slate-900"
                >
                  {(Object.keys(PAYMENT_LABELS) as PaymentStatus[]).map((k) => (
                    <option key={k} value={k}>
                      {PAYMENT_LABELS[k]}
                    </option>
                  ))}
                </select>
              </div>
              {status === 'partial' && (
                <div>
                  <FieldLabel>Đã thu</FieldLabel>
                  <TextInput
                    value={paidInput}
                    onChange={(e) => setPaidInput(e.target.value)}
                    inputMode="numeric"
                  />
                </div>
              )}
              <p className="text-xs text-slate-500">
                Công nợ sau cập nhật:{' '}
                <span className={previewDebt > 0 ? 'font-semibold text-red-600' : ''}>
                  {formatMoney(previewDebt)}
                </span>
              </p>
            </div>
          )}

          {readOnlyPayment && (
            <p className="mt-4 rounded-lg bg-emerald-50 px-3 py-2 text-sm text-emerald-800 dark:bg-emerald-950/40 dark:text-emerald-300">
              Đã thu đủ — có thể sửa thông tin giao hàng trên đơn.
            </p>
          )}

          {order.note && (
            <p className="mt-3 text-sm text-slate-600 dark:text-slate-400">
              Ghi chú: {order.note}
            </p>
          )}

          {error && <p className="mt-2 text-sm text-red-600">{error}</p>}

          <div className="mt-5 flex justify-end gap-2">
            <SecondaryButton type="button" onClick={onClose}>
              Huỷ
            </SecondaryButton>
            <PrimaryButton type="button" disabled={saving} onClick={() => void handleSave()}>
              {saving ? 'Đang lưu...' : 'Lưu'}
            </PrimaryButton>
          </div>
        </div>
      </div>

      {showBill && (
        <BillPreviewDialog
          customer={customer}
          order={previewOrder}
          onClose={() => setShowBill(false)}
        />
      )}
    </>
  );
}
