import Dexie, { type EntityTable } from 'dexie';
import type { Customer, Interaction, Order, Product, Setting } from '@/types';

class SalenoteDatabase extends Dexie {
  customers!: EntityTable<Customer, 'id'>;
  interactions!: EntityTable<Interaction, 'id'>;
  products!: EntityTable<Product, 'id'>;
  orders!: EntityTable<Order, 'id'>;
  settings!: EntityTable<Setting, 'key'>;

  constructor() {
    super('salenote');
    this.version(1).stores({
      customers: '++id, name, status, next_action_at, created_at',
      interactions: '++id, customer_id, created_at',
      settings: 'key',
    });
    this.version(2).stores({
      customers: '++id, name, status, next_action_at, created_at',
      interactions: '++id, customer_id, created_at',
      products: '++id, name, active, created_at',
      orders: '++id, customer_id, product_id, created_at, payment_status',
      settings: 'key',
    });
    this.version(3).stores({
      customers: '++id, name, status, source, product_id, next_action_at, created_at',
      interactions: '++id, customer_id, created_at',
      products: '++id, name, active, created_at',
      orders: '++id, customer_id, product_id, created_at, payment_status',
      settings: 'key',
    });
    this.version(4).stores({
      customers: '++id, name, status, source, product_id, next_action_at, created_at',
      interactions: '++id, customer_id, created_at',
      products: '++id, name, active, track_inventory, created_at',
      orders: '++id, customer_id, product_id, created_at, payment_status',
      settings: 'key',
    });
  }
}

export const db = new SalenoteDatabase();

export async function getSetting(key: string): Promise<string | undefined> {
  const row = await db.settings.get(key);
  return row?.value;
}

export async function setSetting(key: string, value: string): Promise<void> {
  await db.settings.put({ key, value });
}

export async function exportAll() {
  const [customers, interactions, products, orders] = await Promise.all([
    db.customers.toArray(),
    db.interactions.toArray(),
    db.products.toArray(),
    db.orders.toArray(),
  ]);
  return { customers, interactions, products, orders };
}

export async function importAll(data: {
  customers: Customer[];
  interactions: Interaction[];
  products?: Product[];
  orders?: Order[];
}): Promise<void> {
  await db.transaction('rw', db.customers, db.interactions, db.products, db.orders, async () => {
    await db.customers.clear();
    await db.interactions.clear();
    await db.products.clear();
    await db.orders.clear();
    await db.customers.bulkAdd(data.customers);
    await db.interactions.bulkAdd(data.interactions);
    if (data.products?.length) await db.products.bulkAdd(data.products);
    if (data.orders?.length) await db.orders.bulkAdd(data.orders);
  });
}

export function dayRange(date = new Date()): { start: number; end: number } {
  const start = new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
  return { start, end: start + 86400000 };
}

export function monthRangeFromDate(date = new Date()): { start: number; end: number } {
  const start = new Date(date.getFullYear(), date.getMonth(), 1).getTime();
  const end = new Date(date.getFullYear(), date.getMonth() + 1, 1).getTime();
  return { start, end };
}
