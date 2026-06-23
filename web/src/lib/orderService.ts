import { db } from './db';
import { dayRange, monthRangeFromDate } from './db';
import type { Order, PaymentStatus, SalesSummary } from '@/types';
import { followUpDelayMs, orderRevenue, summarizeOrders } from '@/types';
import { sourceLabel } from './constants';
import { deductStock, restoreStock } from './productService';

export interface CreateOrderInput {
  customer_id: number;
  product_id?: number | null;
  product_name: string;
  quantity: number;
  unit_sell_price: number;
  unit_cost: number;
  unit_commission: number;
  payment_status: PaymentStatus;
  paid_amount: number;
  note?: string;
  markCustomerClosed?: boolean;
}

export async function createOrder(input: CreateOrderInput): Promise<Order> {
  const now = Date.now();
  const revenue = input.quantity * input.unit_sell_price;
  let paid = input.paid_amount;
  if (input.payment_status === 'paid') paid = revenue;
  if (input.payment_status === 'unpaid') paid = 0;

  const order: Order = {
    customer_id: input.customer_id,
    product_id: input.product_id ?? null,
    product_name: input.product_name.trim(),
    quantity: input.quantity,
    unit_sell_price: input.unit_sell_price,
    unit_cost: input.unit_cost,
    unit_commission: input.unit_commission,
    payment_status: input.payment_status,
    paid_amount: paid,
    note: input.note?.trim() || null,
    created_at: now,
  };

  const id = await db.transaction('rw', db.orders, db.customers, db.interactions, db.products, async () => {
    const orderId = await db.orders.add(order);

    if (input.product_id) {
      await deductStock(input.product_id, input.quantity);
    }

    const summary = formatOrderInteraction(order);
    await db.interactions.add({
      customer_id: input.customer_id,
      content: summary,
      created_at: now,
    });

    if (input.markCustomerClosed !== false) {
      const customer = await db.customers.get(input.customer_id);
      if (customer) {
        await db.customers.put({
          ...customer,
          status: 'closed',
          last_contact_at: now,
          next_action_at: now + followUpDelayMs('closed'),
          product_id: input.product_id ?? customer.product_id ?? null,
          product: input.product_name.trim() || customer.product,
        });
      }
    } else {
      const customer = await db.customers.get(input.customer_id);
      if (customer && input.product_id) {
        await db.customers.put({
          ...customer,
          product_id: input.product_id,
          product: input.product_name.trim() || customer.product,
        });
      }
    }

    return orderId;
  });

  return { ...order, id };
}

function formatOrderInteraction(o: Order): string {
  const rev = orderRevenue(o);
  const paid =
    o.payment_status === 'paid'
      ? 'đã thu đủ'
      : o.payment_status === 'partial'
        ? `đã thu ${o.paid_amount.toLocaleString('vi-VN')}đ`
        : 'chưa thu';
  return `Đã chốt đơn: ${o.product_name} × ${o.quantity} — ${rev.toLocaleString('vi-VN')}đ (${paid})`;
}

export async function getAllOrders(): Promise<Order[]> {
  return db.orders.orderBy('created_at').reverse().toArray();
}

export async function getOrdersByCustomer(customerId: number): Promise<Order[]> {
  return db.orders
    .where('customer_id')
    .equals(customerId)
    .reverse()
    .sortBy('created_at');
}

export async function getOrder(id: number): Promise<Order | undefined> {
  return db.orders.get(id);
}

export async function deleteOrder(id: number): Promise<void> {
  const order = await db.orders.get(id);
  if (!order) return;
  await db.transaction('rw', db.orders, db.products, async () => {
    if (order.product_id) {
      await restoreStock(order.product_id, order.quantity);
    }
    await db.orders.delete(id);
  });
}

export async function getOrdersInRange(start: number, end: number): Promise<Order[]> {
  return db.orders.where('created_at').between(start, end, true, false).toArray();
}

export async function getSalesSummaryForDay(date = new Date()): Promise<SalesSummary> {
  const { start, end } = dayRange(date);
  const orders = await getOrdersInRange(start, end);
  return summarizeOrders(orders);
}

export async function getSalesSummaryForMonth(date = new Date()): Promise<SalesSummary> {
  const { start, end } = monthRangeFromDate(date);
  const orders = await getOrdersInRange(start, end);
  return summarizeOrders(orders);
}

export async function getCustomerSalesSummary(customerId: number): Promise<SalesSummary> {
  const orders = await getOrdersByCustomer(customerId);
  return summarizeOrders(orders);
}

/** Doanh thu theo nguồn khách (từ đơn trong khoảng thời gian) */
export async function getRevenueBySource(
  start: number,
  end: number,
): Promise<{ source: string; label: string; revenue: number; order_count: number }[]> {
  const orders = await getOrdersInRange(start, end);
  if (orders.length === 0) return [];

  const customerIds = [...new Set(orders.map((o) => o.customer_id))];
  const customers = await db.customers.where('id').anyOf(customerIds).toArray();
  const sourceByCustomer = new Map(
    customers.map((c) => [c.id!, c.source ?? '_none']),
  );

  const agg = new Map<string, { revenue: number; order_count: number }>();
  for (const o of orders) {
    const src = sourceByCustomer.get(o.customer_id) ?? '_none';
    const cur = agg.get(src) ?? { revenue: 0, order_count: 0 };
    cur.revenue += orderRevenue(o);
    cur.order_count += 1;
    agg.set(src, cur);
  }

  return [...agg.entries()]
    .map(([source, data]) => ({
      source,
      label: source === '_none' ? 'Chưa ghi nguồn' : sourceLabel(source),
      revenue: data.revenue,
      order_count: data.order_count,
    }))
    .sort((a, b) => b.revenue - a.revenue);
}
