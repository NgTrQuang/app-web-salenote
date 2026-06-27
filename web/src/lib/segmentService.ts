import { db } from './db';

export interface SegmentCustomer {
  customerId: number;
  name: string;
  product: string;
  daysSincePurchase: number;
  lastOrderAt: number;
}

export interface ProductSegment {
  productId: number;
  productName: string;
  customers: SegmentCustomer[];
}

export const SEGMENT_MIN_DAYS = 30;
export const SEGMENT_MIN_COUNT = 3;
const RECENT_CONTACT_DAYS = 7;

export async function getProductReengageSegments(
  now = Date.now(),
): Promise<ProductSegment[]> {
  const [orders, customers, products] = await Promise.all([
    db.orders.toArray(),
    db.customers.toArray(),
    db.products.toArray(),
  ]);
  const customerById = new Map(customers.map((c) => [c.id!, c]));
  const lastByKey = new Map<
    string,
    { orderAt: number; productId: number; productName: string; customerId: number }
  >();

  for (const o of orders) {
    if (!o.product_id) continue;
    const key = `${o.customer_id}-${o.product_id}`;
    const existing = lastByKey.get(key);
    if (!existing || o.created_at > existing.orderAt) {
      lastByKey.set(key, {
        orderAt: o.created_at,
        productId: o.product_id,
        productName: o.product_name,
        customerId: o.customer_id,
      });
    }
  }

  const byProduct = new Map<number, SegmentCustomer[]>();
  const contactCutoff = now - RECENT_CONTACT_DAYS * 86400000;

  for (const data of lastByKey.values()) {
    const daysSince = Math.floor((now - data.orderAt) / 86400000);
    if (daysSince < SEGMENT_MIN_DAYS) continue;

    const c = customerById.get(data.customerId);
    if (!c) continue;
    if (c.last_contact_at >= contactCutoff) continue;

    const entry: SegmentCustomer = {
      customerId: data.customerId,
      name: c.name,
      product: data.productName,
      daysSincePurchase: daysSince,
      lastOrderAt: data.orderAt,
    };

    const list = byProduct.get(data.productId) ?? [];
    list.push(entry);
    byProduct.set(data.productId, list);
  }

  const segments: ProductSegment[] = [];
  for (const [productId, custs] of byProduct) {
    if (custs.length < SEGMENT_MIN_COUNT) continue;
    const product = products.find((p) => p.id === productId);
    segments.push({
      productId,
      productName: product?.name ?? custs[0].product,
      customers: custs.sort((a, b) => b.daysSincePurchase - a.daysSincePurchase),
    });
  }

  segments.sort((a, b) => b.customers.length - a.customers.length);
  return segments;
}

export async function getProductSegment(
  productId: number,
  now = Date.now(),
): Promise<ProductSegment | null> {
  const segments = await getProductReengageSegments(now);
  return segments.find((s) => s.productId === productId) ?? null;
}
