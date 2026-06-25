import { db } from './db';
import type { Product } from '@/types';
import { productStockStatus } from '@/types';

const DEFAULT_LOW_STOCK = 5;

function normalizeProduct(p: Product): Product {
  return {
    ...p,
    track_inventory: p.track_inventory ?? false,
    stock_quantity: p.stock_quantity ?? 0,
    low_stock_threshold: p.low_stock_threshold ?? DEFAULT_LOW_STOCK,
  };
}

export async function getAllProducts(activeOnly = false): Promise<Product[]> {
  let list = (await db.products.orderBy('name').toArray()).map(normalizeProduct);
  if (activeOnly) list = list.filter((p) => p.active);
  return list;
}

export async function getProduct(id: number): Promise<Product | undefined> {
  const p = await db.products.get(id);
  return p ? normalizeProduct(p) : undefined;
}

export async function addProduct(input: {
  name: string;
  cost_price: number;
  default_sell_price: number;
  default_commission: number;
  note?: string;
  track_inventory?: boolean;
  stock_quantity?: number;
  low_stock_threshold?: number;
}): Promise<Product> {
  const product: Product = {
    name: input.name.trim(),
    cost_price: input.cost_price,
    default_sell_price: input.default_sell_price,
    default_commission: input.default_commission,
    note: input.note?.trim() || null,
    active: true,
    track_inventory: input.track_inventory ?? false,
    stock_quantity: input.track_inventory ? (input.stock_quantity ?? 0) : 0,
    low_stock_threshold: input.low_stock_threshold ?? DEFAULT_LOW_STOCK,
    created_at: Date.now(),
  };
  const id = await db.products.add(product);
  return { ...product, id };
}

export async function updateProduct(product: Product): Promise<void> {
  if (!product.id) throw new Error('Product id required');
  const normalized = normalizeProduct(product);
  if (!normalized.track_inventory) {
    normalized.stock_quantity = 0;
  }
  await db.products.put(normalized);
}

export async function deleteProduct(id: number): Promise<void> {
  await db.products.delete(id);
}

export async function toggleProductActive(product: Product): Promise<void> {
  const nextActive = !product.active;
  await updateProduct({ ...normalizeProduct(product), active: nextActive });

  if (!nextActive && product.id) {
    const linked = await db.customers.filter((c) => c.product_id === product.id).toArray();
    for (const c of linked) {
      if (c.id) {
        await db.customers.update(c.id, { product_id: null });
      }
    }
  }
}

/** SP đang theo dõi kho và sắp hết / hết hàng */
export async function getLowStockProducts(): Promise<Product[]> {
  const list = await getAllProducts(true);
  return list.filter((p) => {
    const s = productStockStatus(p);
    return s === 'low' || s === 'out';
  });
}

/** Trừ tồn khi ghi đơn (gọi trong transaction) */
export async function deductStock(productId: number, quantity: number): Promise<void> {
  const product = await db.products.get(productId);
  if (!product) return;
  const p = normalizeProduct(product);
  if (!p.track_inventory) return;
  await db.products.put({
    ...p,
    stock_quantity: p.stock_quantity - quantity,
  });
}

/** Hoàn tồn khi huỷ đơn (gọi trong transaction) */
export async function restoreStock(productId: number, quantity: number): Promise<void> {
  const product = await db.products.get(productId);
  if (!product) return;
  const p = normalizeProduct(product);
  if (!p.track_inventory) return;
  await db.products.put({
    ...p,
    stock_quantity: p.stock_quantity + quantity,
  });
}

export function applyProductDefaults(product: Product, quantity = 1) {
  const p = normalizeProduct(product);
  return {
    product_id: p.id,
    product_name: p.name,
    quantity,
    unit_sell_price: p.default_sell_price,
    unit_cost: p.cost_price,
    unit_commission: p.default_commission,
  };
}

export function stockStatusLabel(status: ReturnType<typeof productStockStatus>): string {
  switch (status) {
    case 'out':
      return 'Hết hàng';
    case 'low':
      return 'Sắp hết';
    case 'ok':
      return 'Còn hàng';
    default:
      return 'Không theo kho';
  }
}
