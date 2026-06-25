import { forwardRef } from 'react';
import type { BillData } from '@/lib/billService';
import { formatBillPaymentLabel } from '@/lib/billService';
import { formatMoney } from '@/lib/money';

interface BillDocumentProps {
  data: BillData;
}

/** Nội dung bill — chỉ dùng xem trước trên màn hình */
export const BillDocument = forwardRef<HTMLDivElement, BillDocumentProps>(function BillDocument(
  { data },
  ref,
) {
  const { shop, order, revenue, debt, shippingName, shippingPhone, shippingAddress } = data;
  const paid = order.paid_amount;

  return (
    <div
      ref={ref}
      className="mx-auto w-full max-w-md bg-white p-6 text-slate-900"
      style={{ fontFamily: 'system-ui, sans-serif' }}
    >
      <div className="border-b border-slate-300 pb-4 text-center">
        <h1 className="text-lg font-bold uppercase tracking-wide">{shop.shopName}</h1>
        {shop.shopPhone && <p className="mt-1 text-sm text-slate-600">SĐT: {shop.shopPhone}</p>}
        <p className="mt-2 text-xs font-semibold uppercase text-slate-500">Phiếu bán hàng</p>
        <p className="text-xs text-slate-500">
          Mã đơn #{order.id} · {new Date(order.created_at).toLocaleString('vi-VN')}
        </p>
      </div>

      <div className="mt-4 space-y-1 text-sm">
        <p>
          <span className="text-slate-500">Khách hàng:</span>{' '}
          <span className="font-semibold">{shippingName}</span>
        </p>
        {shippingPhone && (
          <p>
            <span className="text-slate-500">SĐT:</span> {shippingPhone}
          </p>
        )}
        {shippingAddress && (
          <p>
            <span className="text-slate-500">Địa chỉ:</span> {shippingAddress}
          </p>
        )}
      </div>

      <table className="mt-4 w-full border-collapse text-sm">
        <thead>
          <tr className="border-b border-slate-300 bg-slate-50">
            <th className="py-2 text-left font-semibold">Sản phẩm</th>
            <th className="py-2 text-right font-semibold">SL</th>
            <th className="py-2 text-right font-semibold">Đơn giá</th>
            <th className="py-2 text-right font-semibold">Thành tiền</th>
          </tr>
        </thead>
        <tbody>
          <tr className="border-b border-slate-200">
            <td className="py-2 pr-2">{order.product_name}</td>
            <td className="py-2 text-right tabular-nums">{order.quantity}</td>
            <td className="py-2 text-right tabular-nums">{formatMoney(order.unit_sell_price)}</td>
            <td className="py-2 text-right tabular-nums font-medium">{formatMoney(revenue)}</td>
          </tr>
        </tbody>
      </table>

      <div className="mt-4 space-y-1 border-t border-slate-300 pt-3 text-sm">
        <div className="flex justify-between font-bold">
          <span>Tổng cộng</span>
          <span>{formatMoney(revenue)}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-slate-600">Đã thu</span>
          <span>{formatMoney(paid)}</span>
        </div>
        {debt > 0 && (
          <div className="flex justify-between text-red-700">
            <span>Còn nợ</span>
            <span className="font-semibold">{formatMoney(debt)}</span>
          </div>
        )}
        <div className="flex justify-between">
          <span className="text-slate-600">Thanh toán</span>
          <span>{formatBillPaymentLabel(order)}</span>
        </div>
      </div>

      {order.note && (
        <p className="mt-3 text-sm text-slate-600">
          <span className="font-medium">Ghi chú:</span> {order.note}
        </p>
      )}

      <p className="mt-6 text-center text-xs text-slate-400">
        Phiếu bán hàng — không phải hóa đơn GTGT. Cảm ơn quý khách!
      </p>
    </div>
  );
});
