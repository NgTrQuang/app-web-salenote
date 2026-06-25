import { useLiveQuery } from 'dexie-react-hooks';
import { db } from '@/lib/db';

/** Re-render when core table data changes (not chỉ khi count đổi) */
export function useDataRefresh(): number {
  const token =
    useLiveQuery(async () => {
      const [customers, interactions, products, orders] = await Promise.all([
        db.customers.toArray(),
        db.interactions.toArray(),
        db.products.toArray(),
        db.orders.toArray(),
      ]);

      let h = customers.length * 1_000_000;
      h += interactions.length * 100_000;
      h += products.length * 10_000;
      h += orders.length * 1_000;

      for (const c of customers) {
        h += (c.id ?? 0) + (c.last_contact_at ?? 0) + (c.next_action_at ?? 0);
      }
      for (const p of products) {
        h +=
          (p.id ?? 0) +
          p.name.length +
          (p.note?.length ?? 0) +
          p.cost_price +
          p.default_sell_price +
          p.default_commission +
          (p.active ? 1 : 0) +
          (p.track_inventory ? 100 : 0) +
          (p.stock_quantity ?? 0) +
          (p.low_stock_threshold ?? 0);
      }
      for (const o of orders) {
        h += (o.id ?? 0) + o.created_at + o.quantity;
      }

      return h;
    }, []) ?? 0;

  return token;
}
