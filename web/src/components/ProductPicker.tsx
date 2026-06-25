import { useMemo, useState } from 'react';
import type { Product } from '@/types';
import { formatMoney } from '@/lib/money';
import { FieldLabel, SecondaryButton, TextInput } from './ui';

const PAGE_SIZE = 20;

interface ProductPickerProps {
  products: Product[];
  value: number | '';
  onChange: (productId: number | '') => void;
}

export function ProductPicker({ products, value, onChange }: ProductPickerProps) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const [page, setPage] = useState(1);

  const selected = value !== '' ? products.find((p) => p.id === value) : undefined;

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return products;
    return products.filter((p) => p.name.toLowerCase().includes(q));
  }, [products, query]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const safePage = Math.min(page, totalPages);
  const slice = filtered.slice((safePage - 1) * PAGE_SIZE, safePage * PAGE_SIZE);

  function pick(id: number | '') {
    onChange(id);
    setOpen(false);
    setQuery('');
    setPage(1);
  }

  return (
    <div>
      <FieldLabel>Chọn từ danh mục</FieldLabel>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="flex w-full items-center justify-between gap-2 rounded-lg border border-slate-300 bg-white px-3 py-2 text-left text-sm dark:border-slate-600 dark:bg-slate-900"
      >
        <span className="min-w-0 flex-1 overflow-x-auto whitespace-nowrap">
          {selected
            ? `${selected.name} (${formatMoney(selected.default_sell_price)})`
            : '— Nhập tay —'}
        </span>
        <span className="shrink-0 text-slate-400">▾</span>
      </button>

      {open && (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 p-4 sm:items-center">
          <div className="flex max-h-[85vh] w-full max-w-lg flex-col rounded-xl bg-white shadow-xl dark:bg-slate-900">
            <div className="border-b border-slate-200 p-4 dark:border-slate-800">
              <p className="font-semibold">Chọn sản phẩm</p>
              <TextInput
                className="mt-3"
                value={query}
                onChange={(e) => {
                  setQuery(e.target.value);
                  setPage(1);
                }}
                placeholder="Tìm tên sản phẩm..."
              />
            </div>
            <ul className="flex-1 overflow-y-auto divide-y divide-slate-100 dark:divide-slate-800">
              <li>
                <button
                  type="button"
                  className="w-full px-4 py-3 text-left text-sm hover:bg-slate-50 dark:hover:bg-slate-800"
                  onClick={() => pick('')}
                >
                  — Nhập tay —
                </button>
              </li>
              {slice.map((p) => (
                <li key={p.id}>
                  <button
                    type="button"
                    className={`w-full px-4 py-3 text-left text-sm hover:bg-slate-50 dark:hover:bg-slate-800 ${
                      value === p.id ? 'bg-brand-50 dark:bg-brand-950/40' : ''
                    }`}
                    onClick={() => pick(p.id!)}
                  >
                    <p className="overflow-x-auto whitespace-nowrap font-medium">{p.name}</p>
                    <p className="text-xs text-slate-500">
                      {formatMoney(p.default_sell_price)}
                      {p.track_inventory ? ` · kho: ${p.stock_quantity}` : ''}
                    </p>
                  </button>
                </li>
              ))}
              {slice.length === 0 && (
                <li className="px-4 py-6 text-center text-sm text-slate-500">Không tìm thấy</li>
              )}
            </ul>
            {totalPages > 1 && (
              <div className="flex items-center justify-between border-t border-slate-200 px-4 py-2 text-sm dark:border-slate-800">
                <button
                  type="button"
                  disabled={safePage <= 1}
                  onClick={() => setPage(safePage - 1)}
                  className="disabled:opacity-40"
                >
                  Trước
                </button>
                <span>
                  {safePage}/{totalPages}
                </span>
                <button
                  type="button"
                  disabled={safePage >= totalPages}
                  onClick={() => setPage(safePage + 1)}
                  className="disabled:opacity-40"
                >
                  Sau
                </button>
              </div>
            )}
            <div className="border-t border-slate-200 p-3 dark:border-slate-800">
              <SecondaryButton type="button" className="w-full" onClick={() => setOpen(false)}>
                Đóng
              </SecondaryButton>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
