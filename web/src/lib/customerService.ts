import { db, getSetting, setSetting } from './db';
import { DEFAULT_MESSAGE, SETTING_KEYS } from './constants';
import type { Customer, CustomerStatus, Interaction, MonthlyStats } from '@/types';
import { followUpDelayMs } from '@/types';
import { monthRange } from './dateUtils';

export async function addCustomer(input: {
  name: string;
  phone?: string;
  address?: string;
  note?: string;
  product?: string;
  product_id?: number | null;
  source?: string | null;
  status?: CustomerStatus;
  warrantyEndDate?: Date;
}): Promise<Customer> {
  const now = Date.now();
  const status = input.status ?? 'new';
  const customer: Customer = {
    name: input.name.trim(),
    phone: input.phone?.trim() || null,
    address: input.address?.trim() || null,
    note: input.note?.trim() || null,
    product: input.product?.trim() || null,
    product_id: input.product_id ?? null,
    source: input.source || null,
    status,
    created_at: now,
    last_contact_at: now,
    next_action_at: now + followUpDelayMs(status),
    warranty_end_date: input.warrantyEndDate?.getTime() ?? null,
  };
  const id = await db.customers.add(customer);
  return { ...customer, id };
}

export async function updateCustomer(customer: Customer): Promise<void> {
  if (!customer.id) throw new Error('Customer id required');
  await db.customers.put(customer);
}

export async function deleteCustomer(id: number): Promise<void> {
  await db.transaction('rw', db.customers, db.interactions, db.orders, async () => {
    await db.orders.where('customer_id').equals(id).delete();
    await db.interactions.where('customer_id').equals(id).delete();
    await db.customers.delete(id);
  });
}

export async function getCustomer(id: number): Promise<Customer | undefined> {
  return db.customers.get(id);
}

export async function getNeedsAttention(now = Date.now()): Promise<Customer[]> {
  return db.customers
    .where('next_action_at')
    .belowOrEqual(now)
    .filter((c) => c.status !== 'closed')
    .sortBy('next_action_at');
}

export async function getUpcoming(now = Date.now()): Promise<Customer[]> {
  return db.customers
    .where('next_action_at')
    .above(now)
    .filter((c) => c.status !== 'closed')
    .sortBy('next_action_at');
}

export async function getAllCustomers(): Promise<Customer[]> {
  return db.customers.orderBy('next_action_at').toArray();
}

export async function getOverdueCount(now = Date.now()): Promise<number> {
  const cutoff = now - 3 * 86400000;
  return db.customers
    .where('next_action_at')
    .belowOrEqual(cutoff)
    .filter((c) => c.status !== 'closed')
    .count();
}

/** Khách warm/hot chưa liên hệ ≥ N ngày — gợi ý ưu đãi. */
export async function countPromoCandidates(staleDays = 7): Promise<number> {
  const cutoff = Date.now() - staleDays * 86400000;
  return db.customers
    .filter(
      (c) =>
        (c.status === 'warm' || c.status === 'hot') &&
        (!c.last_contact_at || c.last_contact_at < cutoff),
    )
    .count();
}

/** Khách đã chốt, lâu chưa liên hệ — gợi ý tri ân. */
export async function countLoyaltyCustomers(staleDays = 30): Promise<number> {
  const cutoff = Date.now() - staleDays * 86400000;
  return db.customers
    .filter(
      (c) =>
        c.status === 'closed' &&
        (!c.last_contact_at || c.last_contact_at < cutoff),
    )
    .count();
}

export async function messageSent(customer: Customer): Promise<void> {
  if (!customer.id) return;
  const now = Date.now();
  const updated: Customer = {
    ...customer,
    last_contact_at: now,
    next_action_at: now + followUpDelayMs(customer.status),
  };
  await db.customers.put(updated);
  await db.interactions.add({
    customer_id: customer.id,
    content: 'Đã nhắn tin khách hàng',
    created_at: now,
  });
}

export async function markAsSold(customer: Customer): Promise<void> {
  if (!customer.id) return;
  const now = Date.now();
  const updated: Customer = {
    ...customer,
    status: 'closed',
    last_contact_at: now,
    next_action_at: now + followUpDelayMs('closed'),
  };
  await db.customers.put(updated);
  await db.interactions.add({
    customer_id: customer.id,
    content: 'Đã chốt đơn',
    created_at: now,
  });
}

export async function getInteractions(customerId: number): Promise<Interaction[]> {
  return db.interactions
    .where('customer_id')
    .equals(customerId)
    .reverse()
    .sortBy('created_at');
}

export async function getMonthlyStats(year: number, month: number): Promise<MonthlyStats> {
  const { start, end } = monthRange(year, month);

  const interactions = await db.interactions
    .where('created_at')
    .between(start, end, true, false)
    .toArray();

  const contacts = interactions.length;
  const closed = interactions.filter(
    (i) =>
      i.content === 'Đã chốt đơn' ||
      i.content.startsWith('Đã chốt đơn:') ||
      i.content.startsWith('Ghi đơn:'),
  ).length;

  const newCustomers = await db.customers
    .where('created_at')
    .between(start, end, true, false)
    .count();

  const allWithProduct = await db.customers
    .filter((c) => !!c.product?.trim())
    .toArray();

  const productCounts = new Map<string, number>();
  for (const c of allWithProduct) {
    const p = c.product!.trim();
    productCounts.set(p, (productCounts.get(p) ?? 0) + 1);
  }

  const top_products = [...productCounts.entries()]
    .map(([product, cnt]) => ({ product, cnt }))
    .sort((a, b) => b.cnt - a.cnt)
    .slice(0, 5);

  return {
    contacts,
    closed,
    new_customers: newCustomers,
    top_products,
  };
}

export async function getCurrentStreak(): Promise<number> {
  const now = new Date();
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  const cutoff = todayStart - 365 * 86400000;

  const interactions = await db.interactions
    .where('created_at')
    .between(cutoff, todayStart + 86400000 - 1, true, true)
    .toArray();

  const buckets = new Set(
    interactions.map((i) => Math.floor(i.created_at / 86400000)),
  );
  const sorted = [...buckets].sort((a, b) => b - a);
  if (sorted.length === 0) return 0;

  const todayBucket = Math.floor(todayStart / 86400000);
  let expectedBucket = todayBucket;

  if (sorted[0] === todayBucket - 1) {
    expectedBucket = todayBucket - 1;
  } else if (sorted[0] !== todayBucket) {
    return 0;
  }

  let streak = 0;
  for (const bucket of sorted) {
    if (bucket === expectedBucket) {
      streak++;
      expectedBucket--;
    } else if (bucket < expectedBucket) {
      break;
    }
  }
  return streak;
}

export async function getMessageTemplate(): Promise<string> {
  return (await getSetting(SETTING_KEYS.messageTemplate)) ?? DEFAULT_MESSAGE;
}

export async function saveMessageTemplate(template: string): Promise<void> {
  await setSetting(SETTING_KEYS.messageTemplate, template);
}

export function applyMessageTemplate(
  template: string,
  name: string,
  product: string,
): string {
  return template.replaceAll('{tên}', name).replaceAll('{sản_phẩm}', product);
}

export function filterCustomers(customers: Customer[], query: string): Customer[] {
  const q = query.trim().toLowerCase();
  if (!q) return customers;
  return customers.filter(
    (c) =>
      c.name.toLowerCase().includes(q) ||
      (c.phone?.toLowerCase().includes(q) ?? false) ||
      (c.address?.toLowerCase().includes(q) ?? false) ||
      (c.product?.toLowerCase().includes(q) ?? false),
  );
}

export function filterCustomersBySource(
  customers: Customer[],
  source: string | 'all',
): Customer[] {
  if (source === 'all') return customers;
  if (source === '_none') return customers.filter((c) => !c.source);
  return customers.filter((c) => c.source === source);
}
