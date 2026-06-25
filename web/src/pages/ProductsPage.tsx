import { useEffect, useState } from 'react';
import { Package, Plus, Pencil, Trash2 } from 'lucide-react';
import type { Product } from '@/types';
import { productStockStatus } from '@/types';
import { Breadcrumbs } from '@/components/CustomerTable';
import {
  PageHeader,
  Panel,
  EmptyState,
  LoadingSpinner,
  FieldLabel,
  TextInput,
  TextArea,
  PrimaryButton,
  SecondaryButton,
  Toast,
} from '@/components/ui';
import {
  getAllProducts,
  addProduct,
  updateProduct,
  deleteProduct,
  toggleProductActive,
  stockStatusLabel,
} from '@/lib/productService';
import { formatMoney, formatMoneyInput, parseMoneyInput } from '@/lib/money';
import { useDataRefresh } from '@/hooks/useDataRefresh';

export function ProductsPage() {
  const refresh = useDataRefresh();
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Product | null>(null);
  const [toast, setToast] = useState('');

  useEffect(() => {
    setLoading(true);
    getAllProducts().then((list) => {
      setProducts(list);
      setLoading(false);
    });
  }, [refresh]);

  function showToast(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(''), 2500);
  }

  async function reloadProducts() {
    const list = await getAllProducts();
    setProducts(list);
  }

  function openAdd() {
    setEditing(null);
    setModalOpen(true);
  }

  function openEdit(p: Product) {
    setEditing(p);
    setModalOpen(true);
  }

  async function handleDelete(p: Product) {
    if (!p.id || !confirm(`Xoá sản phẩm "${p.name}"?`)) return;
    await deleteProduct(p.id);
    await reloadProducts();
    showToast('Đã xoá sản phẩm');
  }

  async function handleToggle(p: Product) {
    await toggleProductActive(p);
    await reloadProducts();
    showToast(p.active ? 'Đã ẩn sản phẩm' : 'Đã kích hoạt sản phẩm');
  }

  const trackedCount = products.filter((p) => p.track_inventory).length;
  const lowCount = products.filter((p) => {
    const s = productStockStatus(p);
    return s === 'low' || s === 'out';
  }).length;

  return (
    <div>
      <Breadcrumbs items={[{ label: 'Bảng điều khiển', to: '/' }, { label: 'Sản phẩm' }]} />

      <PageHeader
        title="Sản phẩm & dịch vụ"
        subtitle={
          trackedCount > 0
            ? `${products.length} mặt hàng · ${trackedCount} theo dõi kho${lowCount > 0 ? ` · ${lowCount} sắp hết/hết` : ''}`
            : 'Danh mục giá vốn, giá bán và hoa hồng mặc định'
        }
        action={
          <PrimaryButton onClick={openAdd}>
            <Plus className="h-4 w-4" />
            Thêm sản phẩm
          </PrimaryButton>
        }
      />

      {loading ? (
        <LoadingSpinner />
      ) : products.length === 0 ? (
        <EmptyState
          icon={<Package className="h-10 w-10" />}
          title="Chưa có sản phẩm"
          description="Thêm sản phẩm để ghi đơn nhanh hơn — giá và hoa hồng tự điền."
          action={
            <PrimaryButton onClick={openAdd}>
              <Plus className="h-4 w-4" />
              Thêm sản phẩm đầu tiên
            </PrimaryButton>
          }
        />
      ) : (
        <Panel noPadding>
          <div className="overflow-x-auto">
            <table className="w-full min-w-[800px] text-left text-sm">
              <thead>
                <tr className="border-b border-slate-200 bg-slate-50 text-xs font-semibold uppercase text-slate-500 dark:border-slate-800 dark:bg-slate-800/50">
                  <th className="px-4 py-3">Tên</th>
                  <th className="px-4 py-3 text-right">Giá vốn</th>
                  <th className="px-4 py-3 text-right">Giá bán</th>
                  <th className="px-4 py-3 text-right">Hoa hồng</th>
                  <th className="px-4 py-3">Lợi nhuận/SP</th>
                  <th className="px-4 py-3">Tồn kho</th>
                  <th className="px-4 py-3">Trạng thái</th>
                  <th className="px-4 py-3 text-right">Thao tác</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                {products.map((p) => (
                  <StockRow key={p.id} product={p} onEdit={openEdit} onDelete={handleDelete} onToggle={handleToggle} />
                ))}
              </tbody>
            </table>
          </div>
        </Panel>
      )}

      {modalOpen && (
        <ProductModal
          key={editing?.id ?? 'new'}
          product={editing}
          onClose={() => setModalOpen(false)}
          onSaved={async (wasEdit) => {
            setModalOpen(false);
            await reloadProducts();
            showToast(wasEdit ? 'Đã cập nhật sản phẩm' : 'Đã thêm sản phẩm');
          }}
        />
      )}

      {toast && <Toast message={toast} />}
    </div>
  );
}

function StockBadge({ product }: { product: Product }) {
  const status = productStockStatus(product);
  if (status === 'none') {
    return <span className="text-slate-400">Không theo kho</span>;
  }
  const colors =
    status === 'out'
      ? 'bg-red-100 text-red-800 dark:bg-red-950 dark:text-red-300'
      : status === 'low'
        ? 'bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-300'
        : 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300';

  return (
    <span className="inline-flex items-center gap-1.5">
      <span className="font-medium tabular-nums">{product.stock_quantity}</span>
      <span className={`rounded-full px-2 py-0.5 text-[10px] font-semibold ${colors}`}>
        {stockStatusLabel(status)}
      </span>
    </span>
  );
}

function StockRow({
  product: p,
  onEdit,
  onDelete,
  onToggle,
}: {
  product: Product;
  onEdit: (p: Product) => void;
  onDelete: (p: Product) => void;
  onToggle: (p: Product) => void;
}) {
  return (
    <tr className={!p.active ? 'opacity-50' : ''}>
      <td className="px-4 py-3 font-medium">{p.name}</td>
      <td className="px-4 py-3 text-right tabular-nums">{formatMoney(p.cost_price)}</td>
      <td className="px-4 py-3 text-right tabular-nums">{formatMoney(p.default_sell_price)}</td>
      <td className="px-4 py-3 text-right tabular-nums">{formatMoney(p.default_commission)}</td>
      <td className="px-4 py-3 text-emerald-700 dark:text-emerald-400">
        {formatMoney(p.default_sell_price - p.cost_price)}
      </td>
      <td className="px-4 py-3">
        <StockBadge product={p} />
      </td>
      <td className="px-4 py-3">
        <button
          type="button"
          onClick={() => onToggle(p)}
          className={`rounded-full px-2 py-0.5 text-xs font-medium ${
            p.active
              ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300'
              : 'bg-slate-200 text-slate-600 dark:bg-slate-800'
          }`}
        >
          {p.active ? 'Đang bán' : 'Đã ẩn'}
        </button>
      </td>
      <td className="px-4 py-3">
        <div className="flex justify-end gap-1">
          <button
            type="button"
            onClick={() => onEdit(p)}
            className="rounded-lg p-2 text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
            title="Sửa sản phẩm"
          >
            <Pencil className="h-4 w-4" />
          </button>
          <button
            type="button"
            onClick={() => onDelete(p)}
            className="rounded-lg p-2 text-red-500 hover:bg-red-50 dark:hover:bg-red-950/30"
            title="Xoá sản phẩm"
          >
            <Trash2 className="h-4 w-4" />
          </button>
        </div>
      </td>
    </tr>
  );
}

function ProductModal({
  product,
  onClose,
  onSaved,
}: {
  product: Product | null;
  onClose: () => void;
  onSaved: (wasEdit: boolean) => void;
}) {
  const [name, setName] = useState(product?.name ?? '');
  const [cost, setCost] = useState(formatMoneyInput(product?.cost_price ?? 0));
  const [sell, setSell] = useState(formatMoneyInput(product?.default_sell_price ?? 0));
  const [commission, setCommission] = useState(
    formatMoneyInput(product?.default_commission ?? 0),
  );
  const [note, setNote] = useState(product?.note ?? '');
  const [trackInventory, setTrackInventory] = useState(product?.track_inventory ?? false);
  const [stockQty, setStockQty] = useState(String(product?.stock_quantity ?? 0));
  const [lowThreshold, setLowThreshold] = useState(String(product?.low_stock_threshold ?? 5));
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim()) {
      setError('Nhập tên sản phẩm');
      return;
    }
    setSaving(true);
    setError('');
    const data = {
      name: name.trim(),
      cost_price: parseMoneyInput(cost),
      default_sell_price: parseMoneyInput(sell),
      default_commission: parseMoneyInput(commission),
      note: note.trim() || null,
      track_inventory: trackInventory,
      stock_quantity: trackInventory ? Math.max(0, parseInt(stockQty, 10) || 0) : 0,
      low_stock_threshold: trackInventory ? Math.max(0, parseInt(lowThreshold, 10) || 5) : 5,
    };
    try {
      if (product?.id) {
        await updateProduct({
          ...product,
          ...data,
          active: product.active,
          created_at: product.created_at,
        });
        onSaved(true);
      } else {
        await addProduct(data);
        onSaved(false);
      }
    } catch {
      setError('Không thể lưu sản phẩm');
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
      <div className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-slate-900">
        <div className="border-b border-slate-200 px-6 py-4 dark:border-slate-800">
          <h2 className="text-lg font-bold">{product ? 'Sửa sản phẩm' : 'Thêm sản phẩm'}</h2>
        </div>
        <form onSubmit={handleSubmit} className="px-6 py-4">
          <div className="space-y-4">
            <div>
              <FieldLabel>Tên sản phẩm *</FieldLabel>
              <TextInput value={name} onChange={(e) => setName(e.target.value)} required />
            </div>
            <div className="grid grid-cols-3 gap-3">
              <div>
                <FieldLabel>Giá vốn</FieldLabel>
                <TextInput value={cost} onChange={(e) => setCost(e.target.value)} inputMode="numeric" />
              </div>
              <div>
                <FieldLabel>Giá bán</FieldLabel>
                <TextInput value={sell} onChange={(e) => setSell(e.target.value)} inputMode="numeric" />
              </div>
              <div>
                <FieldLabel>Hoa hồng</FieldLabel>
                <TextInput
                  value={commission}
                  onChange={(e) => setCommission(e.target.value)}
                  inputMode="numeric"
                />
              </div>
            </div>

            <div className="rounded-lg border border-slate-200 p-4 dark:border-slate-700">
              <label className="flex items-start gap-2 text-sm">
                <input
                  type="checkbox"
                  checked={trackInventory}
                  onChange={(e) => setTrackInventory(e.target.checked)}
                  className="mt-0.5 rounded border-slate-300"
                />
                <span>
                  <span className="font-medium text-slate-900 dark:text-white">Theo dõi tồn kho</span>
                  <span className="mt-0.5 block text-xs text-slate-500">
                    Bật cho hàng vật lý. Dịch vụ / đặt hộ / không quản kho thì để tắt.
                  </span>
                </span>
              </label>

              {trackInventory && (
                <div className="mt-4 grid grid-cols-2 gap-3">
                  <div>
                    <FieldLabel>Tồn hiện tại</FieldLabel>
                    <TextInput
                      type="number"
                      min={0}
                      value={stockQty}
                      onChange={(e) => setStockQty(e.target.value)}
                    />
                  </div>
                  <div>
                    <FieldLabel>Cảnh báo khi còn ≤</FieldLabel>
                    <TextInput
                      type="number"
                      min={0}
                      value={lowThreshold}
                      onChange={(e) => setLowThreshold(e.target.value)}
                    />
                  </div>
                </div>
              )}
            </div>

            <div>
              <FieldLabel>Ghi chú</FieldLabel>
              <TextArea value={note} onChange={(e) => setNote(e.target.value)} rows={2} />
            </div>
          </div>

          {error && <p className="mt-3 text-sm text-red-600">{error}</p>}

          <div className="mt-6 flex justify-end gap-2">
            <SecondaryButton type="button" onClick={onClose}>
              Huỷ
            </SecondaryButton>
            <PrimaryButton type="submit" disabled={saving}>
              {saving ? 'Đang lưu...' : 'Lưu'}
            </PrimaryButton>
          </div>
        </form>
      </div>
    </div>
  );
}
