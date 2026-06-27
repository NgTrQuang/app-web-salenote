import { db } from './db';
import { orderDebt } from '@/types';

export interface DebtEntry {
  customerId: number;
  name: string;
  phone: string | null;
  totalDebt: number;
  orderCount: number;
  oldestOrderAt: number | null;
}

export async function getDebtList(): Promise<DebtEntry[]> {
  const [orders, customers] = await Promise.all([
    db.orders.toArray(),
    db.customers.toArray(),
  ]);
  const customerById = new Map(customers.map((c) => [c.id!, c]));
  const byCustomer = new Map<
    number,
    { debt: number; orderCount: number; oldestAt: number | null }
  >();

  for (const o of orders) {
    const d = orderDebt(o);
    if (d <= 0) continue;
    const cur = byCustomer.get(o.customer_id) ?? {
      debt: 0,
      orderCount: 0,
      oldestAt: null,
    };
    cur.debt += d;
    cur.orderCount += 1;
    cur.oldestAt =
      cur.oldestAt == null ? o.created_at : Math.min(cur.oldestAt, o.created_at);
    byCustomer.set(o.customer_id, cur);
  }

  const list: DebtEntry[] = [];
  for (const [customerId, data] of byCustomer) {
    const c = customerById.get(customerId);
    if (!c) continue;
    list.push({
      customerId,
      name: c.name,
      phone: c.phone ?? null,
      totalDebt: data.debt,
      orderCount: data.orderCount,
      oldestOrderAt: data.oldestAt,
    });
  }

  list.sort((a, b) => b.totalDebt - a.totalDebt);
  return list;
}

export async function getTotalDebt(): Promise<number> {
  const list = await getDebtList();
  return list.reduce((sum, e) => sum + e.totalDebt, 0);
}
