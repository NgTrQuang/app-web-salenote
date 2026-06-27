import { useLiveQuery } from 'dexie-react-hooks';
import { db } from '@/lib/db';

/**
 * Re-render khi dữ liệu cốt lõi đổi.
 * Dùng count + bản ghi mới nhất thay vì toArray() toàn bộ orders/interactions.
 */
export function useDataRefresh(): number {
  const token =
    useLiveQuery(async () => {
      const [
        customers,
        products,
        interactionCount,
        orderCount,
        expenseCount,
        lastInteraction,
        lastOrder,
        settings,
      ] = await Promise.all([
        db.customers.toArray(),
        db.products.toArray(),
        db.interactions.count(),
        db.orders.count(),
        db.expenses.count(),
        db.interactions.orderBy('created_at').last(),
        db.orders.orderBy('created_at').last(),
        db.settings.toArray(),
      ]);

      let h = customers.length * 1_000_000;
      h += interactionCount * 100_000;
      h += products.length * 10_000;
      h += orderCount * 1_000;
      h += expenseCount * 100;

      for (const c of customers) {
        h += (c.id ?? 0) + (c.last_contact_at ?? 0) + (c.next_action_at ?? 0);
      }
      for (const p of products) {
        h +=
          (p.id ?? 0) +
          p.name.length +
          p.cost_price +
          p.default_sell_price +
          (p.active ? 1 : 0) +
          (p.track_inventory ? 100 : 0) +
          (p.stock_quantity ?? 0);
      }

      h += lastInteraction?.created_at ?? 0;
      h += lastOrder?.created_at ?? 0;
      h += (lastOrder?.paid_amount ?? 0) + (lastOrder?.quantity ?? 0);

      for (const s of settings) {
        h += s.key.length + (s.value?.length ?? 0);
      }

      return h;
    }, []) ?? 0;

  return token;
}
