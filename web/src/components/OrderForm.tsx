import { useEffect, useState } from 'react';
import type { Customer, PaymentStatus, Product } from '@/types';
import { productStockStatus } from '@/types';
import { getAllProducts, applyProductDefaults, stockStatusLabel } from '@/lib/productService';
import { createOrder } from '@/lib/orderService';
import { formatMoney, formatMoneyInput, parseMoneyInput } from '@/lib/money';
import { PAYMENT_LABELS } from '@/types';
import { FieldLabel, PrimaryButton, SecondaryButton, TextInput, TextArea } from './ui';
import { ProductPicker } from './ProductPicker';

export interface OrderFormValues {
  product_id: number | '';
  product_name: string;
  quantity: number;
  unit_sell_price: string;
  unit_cost: string;
  unit_commission: string;
  payment_status: PaymentStatus;
  paid_amount: string;
  note: string;
  shipping_name: string;
  shipping_phone: string;
  shipping_address: string;
  markCustomerClosed: boolean;
}

const emptyValues = (): OrderFormValues => ({
  product_id: '',
  product_name: '',
  quantity: 1,
  unit_sell_price: '',
  unit_cost: '',
  unit_commission: '',
  payment_status: 'paid',
  paid_amount: '',
  note: '',
  shipping_name: '',
  shipping_phone: '',
  shipping_address: '',
  markCustomerClosed: true,
});

function shippingDefaults(customer: Customer): Pick<OrderFormValues, 'shipping_name' | 'shipping_phone' | 'shipping_address'> {
  return {
    shipping_name: customer.name,
    shipping_phone: customer.phone ?? '',
    shipping_address: customer.address ?? '',
  };
}

interface OrderFormProps {
  customer: Customer;
  onSuccess: () => void;
  onCancel: () => void;
}

export function OrderForm({ customer, onSuccess, onCancel }: OrderFormProps) {
  const [products, setProducts] = useState<Product[]>([]);
  const [values, setValues] = useState<OrderFormValues>(() => ({
    ...emptyValues(),
    ...shippingDefaults(customer),
  }));
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    getAllProducts(true).then(setProducts);
  }, []);

  useEffect(() => {
    if (products.length === 0) return;
    if (customer.product_id) {
      const linked = products.find((p) => p.id === customer.product_id);
      if (linked) {
        const d = applyProductDefaults(linked, 1);
        setValues({
          ...emptyValues(),
          ...shippingDefaults(customer),
          product_id: customer.product_id,
          product_name: d.product_name,
          unit_sell_price: formatMoneyInput(d.unit_sell_price),
          unit_cost: formatMoneyInput(d.unit_cost),
          unit_commission: formatMoneyInput(d.unit_commission),
        });
        return;
      }
    }
    if (customer.product) {
      setValues((v) => ({ ...v, product_name: customer.product ?? '' }));
    }
  }, [customer.id, customer.name, customer.phone, customer.address, customer.product_id, customer.product, products]);

  const qty = values.quantity || 1;
  const sell = parseMoneyInput(values.unit_sell_price);
  const cost = parseMoneyInput(values.unit_cost);
  const comm = parseMoneyInput(values.unit_commission);
  const revenue = qty * sell;
  const profit = qty * (sell - cost);
  const commission = qty * comm;
  const paid =
    values.payment_status === 'paid'
      ? revenue
      : values.payment_status === 'unpaid'
        ? 0
        : parseMoneyInput(values.paid_amount);
  const debt = Math.max(0, revenue - paid);

  const selectedProduct =
    values.product_id !== '' ? products.find((p) => p.id === values.product_id) : undefined;
  const stockStatus = selectedProduct ? productStockStatus(selectedProduct) : 'none';
  const stockShortage =
    selectedProduct?.track_inventory && qty > (selectedProduct.stock_quantity ?? 0);

  function set(patch: Partial<OrderFormValues>) {
    setValues((v) => ({ ...v, ...patch }));
  }

  function selectProduct(productId: number | '') {
    if (productId === '') {
      set({ product_id: '', product_name: '' });
      return;
    }
    const p = products.find((x) => x.id === productId);
    if (!p) return;
    const d = applyProductDefaults(p, values.quantity);
    set({
      product_id: productId,
      product_name: d.product_name,
      unit_sell_price: formatMoneyInput(d.unit_sell_price),
      unit_cost: formatMoneyInput(d.unit_cost),
      unit_commission: formatMoneyInput(d.unit_commission),
    });
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!values.product_name.trim()) {
      setError('Nhập tên sản phẩm');
      return;
    }
    if (sell <= 0) {
      setError('Giá bán phải lớn hơn 0');
      return;
    }
    if (stockShortage && selectedProduct) {
      const ok = confirm(
        `Tồn kho "${selectedProduct.name}" chỉ còn ${selectedProduct.stock_quantity}, bạn ghi ${qty}. Vẫn lưu đơn? (tồn có thể âm)`,
      );
      if (!ok) return;
    }
    setSaving(true);
    setError('');
    try {
      await createOrder({
        customer_id: customer.id!,
        product_id: values.product_id === '' ? null : values.product_id,
        product_name: values.product_name,
        quantity: qty,
        unit_sell_price: sell,
        unit_cost: cost,
        unit_commission: comm,
        payment_status: values.payment_status,
        paid_amount: paid,
        note: values.note || undefined,
        shipping_name: values.shipping_name,
        shipping_phone: values.shipping_phone,
        shipping_address: values.shipping_address,
        markCustomerClosed: values.markCustomerClosed,
      });
      onSuccess();
    } catch {
      setError('Không thể lưu đơn hàng');
      setSaving(false);
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <div className="grid gap-4 sm:grid-cols-2">
        <div className="sm:col-span-2">
          <FieldLabel>Khách hàng</FieldLabel>
          <p className="rounded-lg bg-slate-50 px-3 py-2 text-sm font-medium dark:bg-slate-800">
            {customer.name}
          </p>
        </div>

        <div className="sm:col-span-2 rounded-lg border border-slate-200 p-4 dark:border-slate-700">
          <p className="mb-3 text-sm font-semibold text-slate-700 dark:text-slate-200">
            Thông tin giao hàng
          </p>
          <p className="mb-3 text-xs text-slate-500">
            Mặc định lấy từ hồ sơ khách — có thể sửa cho đơn này. Địa chỉ sẽ được lưu cố định trên đơn.
          </p>
          <div className="grid gap-3 sm:grid-cols-2">
            <div className="sm:col-span-2">
              <FieldLabel>Người nhận</FieldLabel>
              <TextInput
                value={values.shipping_name}
                onChange={(e) => set({ shipping_name: e.target.value })}
                placeholder="Tên người nhận"
              />
            </div>
            <div>
              <FieldLabel>SĐT giao hàng</FieldLabel>
              <TextInput
                value={values.shipping_phone}
                onChange={(e) => set({ shipping_phone: e.target.value })}
                placeholder="0901234567"
                inputMode="tel"
              />
            </div>
            <div className="sm:col-span-2">
              <FieldLabel>Địa chỉ giao hàng</FieldLabel>
              <TextArea
                value={values.shipping_address}
                onChange={(e) => set({ shipping_address: e.target.value })}
                rows={2}
                placeholder="Số nhà, phường, quận, tỉnh..."
              />
            </div>
          </div>
        </div>

        {products.length > 0 && (
          <div className="sm:col-span-2">
            <ProductPicker
              products={products}
              value={values.product_id}
              onChange={(id) => selectProduct(id)}
            />
            {selectedProduct?.track_inventory && (
              <p
                className={`mt-1.5 text-xs ${
                  stockStatus === 'out' || stockShortage
                    ? 'text-red-600'
                    : stockStatus === 'low'
                      ? 'text-amber-600'
                      : 'text-slate-500'
                }`}
              >
                Tồn kho: {selectedProduct.stock_quantity} — {stockStatusLabel(stockStatus)}
                {stockShortage && ' · Số lượng đơn vượt tồn'}
              </p>
            )}
          </div>
        )}

        <div className="sm:col-span-2">
          <FieldLabel>
            Tên sản phẩm / dịch vụ <span className="text-red-500">*</span>
          </FieldLabel>
          <TextInput
            value={values.product_name}
            onChange={(e) => set({ product_name: e.target.value, product_id: '' })}
            placeholder="Tên sản phẩm trên đơn"
            className="overflow-x-auto"
            required
          />
        </div>

        <div>
          <FieldLabel>Số lượng</FieldLabel>
          <TextInput
            type="number"
            min={1}
            value={values.quantity}
            onChange={(e) => set({ quantity: Math.max(1, parseInt(e.target.value, 10) || 1) })}
          />
        </div>

        <div>
          <FieldLabel>Giá bán / đơn vị</FieldLabel>
          <TextInput
            value={values.unit_sell_price}
            onChange={(e) => set({ unit_sell_price: e.target.value })}
            placeholder="500000"
            inputMode="numeric"
          />
        </div>

        <div>
          <FieldLabel>Giá vốn / đơn vị</FieldLabel>
          <TextInput
            value={values.unit_cost}
            onChange={(e) => set({ unit_cost: e.target.value })}
            placeholder="300000"
            inputMode="numeric"
          />
        </div>

        <div>
          <FieldLabel>Hoa hồng / đơn vị</FieldLabel>
          <TextInput
            value={values.unit_commission}
            onChange={(e) => set({ unit_commission: e.target.value })}
            placeholder="50000"
            inputMode="numeric"
          />
        </div>

        <div>
          <FieldLabel>Thanh toán</FieldLabel>
          <select
            value={values.payment_status}
            onChange={(e) => {
              const ps = e.target.value as PaymentStatus;
              set({
                payment_status: ps,
                paid_amount: ps === 'paid' ? formatMoneyInput(revenue) : values.paid_amount,
              });
            }}
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm dark:border-slate-600 dark:bg-slate-900"
          >
            {(Object.keys(PAYMENT_LABELS) as PaymentStatus[]).map((k) => (
              <option key={k} value={k}>
                {PAYMENT_LABELS[k]}
              </option>
            ))}
          </select>
        </div>

        {values.payment_status === 'partial' && (
          <div>
            <FieldLabel>Đã thu</FieldLabel>
            <TextInput
              value={values.paid_amount}
              onChange={(e) => set({ paid_amount: e.target.value })}
              inputMode="numeric"
            />
          </div>
        )}

        <div className="sm:col-span-2">
          <FieldLabel>Ghi chú đơn</FieldLabel>
          <TextArea
            value={values.note}
            onChange={(e) => set({ note: e.target.value })}
            rows={2}
            placeholder="Ghi chú giao dịch, mã chuyển khoản..."
          />
        </div>

        <div className="sm:col-span-2">
          <label className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={values.markCustomerClosed}
              onChange={(e) => set({ markCustomerClosed: e.target.checked })}
              className="rounded border-slate-300"
            />
            Đánh dấu khách &quot;Đã chốt&quot; và nhắc chăm lại sau 7 ngày
          </label>
        </div>
      </div>

      <div className="mt-4 grid grid-cols-2 gap-3 rounded-lg bg-slate-50 p-4 text-sm dark:bg-slate-800/60 sm:grid-cols-4">
        <div>
          <p className="text-slate-500">Doanh thu</p>
          <p className="font-bold text-brand-700 dark:text-brand-400">{formatMoney(revenue)}</p>
        </div>
        <div>
          <p className="text-slate-500">Lợi nhuận</p>
          <p className="font-bold text-emerald-700 dark:text-emerald-400">{formatMoney(profit)}</p>
        </div>
        <div>
          <p className="text-slate-500">Hoa hồng</p>
          <p className="font-bold text-brand-700 dark:text-brand-400">{formatMoney(commission)}</p>
        </div>
        <div>
          <p className="text-slate-500">Công nợ</p>
          <p
            className={`font-bold ${debt > 0 ? 'text-red-600 dark:text-red-400' : 'text-slate-600 dark:text-slate-300'}`}
          >
            {formatMoney(debt)}
          </p>
        </div>
      </div>

      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}

      <div className="mt-6 flex justify-end gap-2 border-t border-slate-200 pt-4 dark:border-slate-800">
        <SecondaryButton type="button" onClick={onCancel}>
          Huỷ
        </SecondaryButton>
        <PrimaryButton type="submit" disabled={saving}>
          {saving ? 'Đang lưu...' : 'Lưu đơn hàng'}
        </PrimaryButton>
      </div>
    </form>
  );
}
