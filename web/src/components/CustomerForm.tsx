import { useEffect, useState } from 'react';
import { STATUSES, STATUS_LABELS, CUSTOMER_SOURCES } from '@/lib/constants';
import type { CustomerStatus } from '@/types';
import { getAllProducts } from '@/lib/productService';
import type { Product } from '@/types';
import { FieldLabel, TextInput, TextArea } from './ui';

export interface CustomerFormValues {
  name: string;
  phone: string;
  source: string;
  product_id: number | '';
  product: string;
  note: string;
  status: CustomerStatus;
  warrantyEndDate: string;
}

interface CustomerFormProps {
  values: CustomerFormValues;
  onChange: (values: CustomerFormValues) => void;
}

export function CustomerForm({ values, onChange }: CustomerFormProps) {
  const [products, setProducts] = useState<Product[]>([]);

  useEffect(() => {
    getAllProducts(true).then(setProducts);
  }, []);

  const set = (patch: Partial<CustomerFormValues>) =>
    onChange({ ...values, ...patch });

  function selectCatalogProduct(productId: number | '') {
    if (productId === '') {
      set({ product_id: '', product: '' });
      return;
    }
    const p = products.find((x) => x.id === productId);
    if (p) {
      set({ product_id: productId, product: p.name });
    }
  }

  return (
    <div className="space-y-4">
      <div>
        <FieldLabel>
          Tên khách <span className="text-red-500">*</span>
        </FieldLabel>
        <TextInput
          value={values.name}
          onChange={(e) => set({ name: e.target.value })}
          placeholder="Nguyễn Văn A"
          required
        />
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <div>
          <FieldLabel>Số điện thoại</FieldLabel>
          <TextInput
            value={values.phone}
            onChange={(e) => set({ phone: e.target.value })}
            placeholder="0901234567"
            type="tel"
          />
        </div>
        <div>
          <FieldLabel>Nguồn khách</FieldLabel>
          <select
            value={values.source}
            onChange={(e) => set({ source: e.target.value })}
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm dark:border-slate-600 dark:bg-slate-900"
          >
            <option value="">— Chọn nguồn —</option>
            {CUSTOMER_SOURCES.map((s) => (
              <option key={s.key} value={s.key}>
                {s.label}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div>
        <FieldLabel>Sản phẩm quan tâm</FieldLabel>
        {products.length > 0 && (
          <select
            value={values.product_id}
            onChange={(e) =>
              selectCatalogProduct(e.target.value === '' ? '' : Number(e.target.value))
            }
            className="mb-2 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm dark:border-slate-600 dark:bg-slate-900"
          >
            <option value="">— Chọn từ danh mục —</option>
            {products.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </select>
        )}
        <TextInput
          value={values.product}
          onChange={(e) => set({ product: e.target.value, product_id: '' })}
          placeholder="Hoặc nhập tên SP / dịch vụ..."
        />
        <p className="mt-1 text-xs text-slate-500">
          Liên kết danh mục giúp ghi đơn tự điền giá và hoa hồng.
        </p>
      </div>

      <div>
        <FieldLabel>Trạng thái</FieldLabel>
        <div className="flex flex-wrap gap-2">
          {STATUSES.map((s) => (
            <button
              key={s}
              type="button"
              onClick={() => set({ status: s })}
              className={`rounded-full px-3 py-1.5 text-xs font-semibold transition ${
                values.status === s
                  ? 'bg-brand-600 text-white'
                  : 'bg-slate-200 text-slate-700 dark:bg-slate-800 dark:text-slate-300'
              }`}
            >
              {STATUS_LABELS[s]}
            </button>
          ))}
        </div>
      </div>

      <div>
        <FieldLabel>Ngày hết bảo hành</FieldLabel>
        <TextInput
          type="date"
          value={values.warrantyEndDate}
          onChange={(e) => set({ warrantyEndDate: e.target.value })}
        />
      </div>

      <div>
        <FieldLabel>Ghi chú</FieldLabel>
        <TextArea
          value={values.note}
          onChange={(e) => set({ note: e.target.value })}
          rows={3}
          placeholder="Khách hỏi giá, cần giao cuối tuần..."
        />
      </div>
    </div>
  );
}
