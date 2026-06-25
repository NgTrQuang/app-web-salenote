import type { Customer, Order } from '@/types';
import { orderRevenue } from '@/types';
import { formatMoney } from './money';

export interface ShippingSnapshot {
  shipping_name: string;
  shipping_phone: string | null;
  shipping_address: string | null;
}

/** Địa chỉ / liên hệ hiển thị trên đơn — ưu tiên snapshot trên order, fallback customer (đơn cũ). */
export function resolveShippingName(order: Order, customer: Customer): string {
  return order.shipping_name?.trim() || customer.name.trim();
}

export function resolveShippingPhone(order: Order, customer: Customer): string {
  return order.shipping_phone?.trim() || customer.phone?.trim() || '';
}

export function resolveShippingAddress(order: Order, customer: Customer): string {
  return order.shipping_address?.trim() || customer.address?.trim() || '';
}

/** Snapshot lúc ghi đơn — luôn lưu giá trị hiệu lực (kể cả khi trùng khách). */
export function snapshotShipping(
  customer: Customer,
  input: {
    shipping_name?: string;
    shipping_phone?: string;
    shipping_address?: string;
  },
): ShippingSnapshot {
  const name = input.shipping_name?.trim() || customer.name.trim();
  const phone = input.shipping_phone?.trim() || customer.phone?.trim() || null;
  const address = input.shipping_address?.trim() || customer.address?.trim() || null;
  return { shipping_name: name, shipping_phone: phone, shipping_address: address };
}

export function shippingDiffersFromCustomer(order: Order, customer: Customer): boolean {
  const name = resolveShippingName(order, customer);
  const phone = resolveShippingPhone(order, customer);
  const address = resolveShippingAddress(order, customer);
  return (
    name !== customer.name.trim() ||
    phone !== (customer.phone?.trim() || '') ||
    address !== (customer.address?.trim() || '')
  );
}

export function formatShippingInfo(customer: Customer, order: Order): string {
  const name = resolveShippingName(order, customer);
  const phone = resolveShippingPhone(order, customer);
  const address = resolveShippingAddress(order, customer);
  const lines = [
    `Người nhận: ${name}`,
    phone ? `SĐT: ${phone}` : null,
    address ? `Địa chỉ: ${address}` : null,
    `Sản phẩm: ${order.product_name} × ${order.quantity}`,
    `Thành tiền: ${formatMoney(orderRevenue(order))}`,
    order.note ? `Ghi chú đơn: ${order.note}` : null,
  ].filter(Boolean);
  return lines.join('\n');
}

export function formatAddressOnly(customer: Customer, order?: Order): string {
  if (order) return resolveShippingAddress(order, customer);
  return customer.address?.trim() || '';
}
