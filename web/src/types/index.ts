export type CustomerStatus = 'new' | 'warm' | 'hot' | 'closed';
export type PaymentStatus = 'paid' | 'partial' | 'unpaid';

export interface Customer {
  id?: number;
  name: string;
  phone?: string | null;
  note?: string | null;
  /** Tên SP quan tâm (text hoặc sync từ danh mục) */
  product?: string | null;
  /** Liên kết danh mục sản phẩm */
  product_id?: number | null;
  /** Nguồn khách: facebook, zalo, tiktok, referral, returning, walk_in, other, ... */
  source?: string | null;
  status: CustomerStatus;
  created_at: number;
  last_contact_at: number;
  next_action_at: number;
  warranty_end_date?: number | null;
}

export interface Interaction {
  id?: number;
  customer_id: number;
  content: string;
  created_at: number;
}

export interface Product {
  id?: number;
  name: string;
  cost_price: number;
  default_sell_price: number;
  default_commission: number;
  note?: string | null;
  active: boolean;
  /** Bật theo dõi tồn kho cho mặt hàng này */
  track_inventory: boolean;
  /** Số lượng tồn (chỉ có nghĩa khi track_inventory) */
  stock_quantity: number;
  /** Cảnh báo sắp hết khi tồn <= ngưỡng */
  low_stock_threshold: number;
  created_at: number;
}

export interface Order {
  id?: number;
  customer_id: number;
  product_id?: number | null;
  product_name: string;
  quantity: number;
  unit_sell_price: number;
  unit_cost: number;
  unit_commission: number;
  payment_status: PaymentStatus;
  paid_amount: number;
  note?: string | null;
  created_at: number;
}

export interface Setting {
  key: string;
  value: string;
}

export interface BackupData {
  version?: number;
  customers: Customer[];
  interactions: Interaction[];
  products?: Product[];
  orders?: Order[];
}

export interface MonthlyStats {
  contacts: number;
  closed: number;
  new_customers: number;
  top_products: { product: string; cnt: number }[];
}

export interface SalesSummary {
  revenue: number;
  cost: number;
  profit: number;
  commission: number;
  debt: number;
  order_count: number;
}

export const PAYMENT_LABELS: Record<PaymentStatus, string> = {
  paid: 'Đã thu đủ',
  partial: 'Thu một phần',
  unpaid: 'Chưa thu',
};

export const FOLLOW_UP_DELAY_MS: Record<CustomerStatus, number> = {
  new: 86400000,
  warm: 172800000,
  hot: 86400000,
  closed: 604800000,
};

export function followUpDelayMs(status: CustomerStatus): number {
  return FOLLOW_UP_DELAY_MS[status] ?? 86400000;
}

export function customerNeedsAttention(c: Customer, now = Date.now()): boolean {
  return c.next_action_at <= now;
}

export function warrantyDaysLeft(c: Customer, now = Date.now()): number | null {
  if (!c.warranty_end_date) return null;
  const diff = c.warranty_end_date - now;
  if (diff <= 0) return null;
  return Math.ceil(diff / 86400000);
}

export function orderRevenue(o: Order): number {
  return o.quantity * o.unit_sell_price;
}

export function orderCost(o: Order): number {
  return o.quantity * o.unit_cost;
}

export function orderProfit(o: Order): number {
  return orderRevenue(o) - orderCost(o);
}

export function orderCommission(o: Order): number {
  return o.quantity * o.unit_commission;
}

export function orderDebt(o: Order): number {
  return Math.max(0, orderRevenue(o) - o.paid_amount);
}

export function summarizeOrders(orders: Order[]): SalesSummary {
  return orders.reduce(
    (acc, o) => ({
      revenue: acc.revenue + orderRevenue(o),
      cost: acc.cost + orderCost(o),
      profit: acc.profit + orderProfit(o),
      commission: acc.commission + orderCommission(o),
      debt: acc.debt + orderDebt(o),
      order_count: acc.order_count + 1,
    }),
    { revenue: 0, cost: 0, profit: 0, commission: 0, debt: 0, order_count: 0 },
  );
}

export type StockStatus = 'none' | 'ok' | 'low' | 'out';

export function productStockStatus(p: Product): StockStatus {
  if (!p.track_inventory) return 'none';
  const qty = p.stock_quantity ?? 0;
  if (qty <= 0) return 'out';
  const threshold = p.low_stock_threshold ?? 5;
  if (qty <= threshold) return 'low';
  return 'ok';
}
