import { db } from './db';
import type { Customer, Order } from '@/types';
import { orderDebt, orderRevenue, summarizeOrders } from '@/types';
import {
  countLoyaltyCustomers,
  countPromoCandidates,
  getCurrentStreak,
  getNeedsAttention,
  getOverdueCount,
} from './customerService';
import {
  getRevenueBySource,
  getSalesSummaryForMonth,
  getTopSalesProductsByRevenue,
} from './orderService';
import { monthRangeFromDate } from './db';
import { formatMoney } from './money';

export type ActionType = 'contact_hot' | 'contact' | 'collect_debt' | 're_engage';

export interface DailyAction {
  id: string;
  type: ActionType;
  customerId: number;
  customerName: string;
  title: string;
  subtitle: string;
  priority: number;
  amount?: number;
}

export interface AtRiskSummary {
  hotOverdue: number;
  warmOverdue: number;
  newOverdue: number;
  promoStale: number;
  returningLost: number;
  dueToday: number;
  overdue3Days: number;
  debtCustomers: number;
  totalDebt: number;
}

export interface RevenueInsight {
  text: string;
  highlight?: string;
}

export interface AchievementStats {
  streak: number;
  totalRevenue: number;
  totalOrders: number;
  customersCared: number;
  totalInteractions: number;
  monthRevenue: number;
}

export interface CustomerIntelligence {
  orderCount: number;
  totalRevenue: number;
  totalProfit: number;
  totalCommission: number;
  totalDebt: number;
  lastOrderAt: number | null;
  avgOrderValue: number;
  isRepeatBuyer: boolean;
  daysSinceLastPurchase: number | null;
  tierLabel: string;
  tierHint: string;
}

const PROMO_STALE_DAYS = 7;
const RETURNING_STALE_DAYS = 30;
const MAX_ACTIONS = 12;

function daysSince(ms: number, now = Date.now()): number {
  return Math.floor((now - ms) / 86400000);
}

function overdueDays(c: Customer, now = Date.now()): number {
  return Math.max(1, daysSince(c.next_action_at, now));
}

async function getDebtByCustomer(): Promise<Map<number, number>> {
  const orders = await db.orders.toArray();
  const map = new Map<number, number>();
  for (const o of orders) {
    const d = orderDebt(o);
    if (d > 0) {
      map.set(o.customer_id, (map.get(o.customer_id) ?? 0) + d);
    }
  }
  return map;
}

async function getCustomersWithOrders(): Promise<Set<number>> {
  const orders = await db.orders.toArray();
  return new Set(orders.map((o) => o.customer_id));
}

export async function getAtRiskSummary(now = Date.now()): Promise<AtRiskSummary> {
  const due = await getNeedsAttention(now);
  const debtMap = await getDebtByCustomer();
  let totalDebt = 0;
  for (const v of debtMap.values()) totalDebt += v;

  const [promoStale, returningLost, overdue3Days] = await Promise.all([
    countPromoCandidates(PROMO_STALE_DAYS),
    countLoyaltyCustomers(RETURNING_STALE_DAYS),
    getOverdueCount(now),
  ]);

  return {
    hotOverdue: due.filter((c) => c.status === 'hot').length,
    warmOverdue: due.filter((c) => c.status === 'warm').length,
    newOverdue: due.filter((c) => c.status === 'new').length,
    promoStale,
    returningLost,
    dueToday: due.length,
    overdue3Days,
    debtCustomers: debtMap.size,
    totalDebt,
  };
}

export async function getDailyActions(now = Date.now()): Promise<DailyAction[]> {
  const actions: DailyAction[] = [];
  const [due, debtMap, customers, withOrders] = await Promise.all([
    getNeedsAttention(now),
    getDebtByCustomer(),
    db.customers.toArray(),
    getCustomersWithOrders(),
  ]);
  const customerById = new Map(customers.map((c) => [c.id!, c]));

  for (const c of due.filter((x) => x.status === 'hot')) {
    actions.push({
      id: `hot-${c.id}`,
      type: 'contact_hot',
      customerId: c.id!,
      customerName: c.name,
      title: `Chăm khách Nóng: ${c.name}`,
      subtitle: `Quá hạn ${overdueDays(c, now)} ngày${c.product ? ` · ${c.product}` : ''}`,
      priority: 1,
    });
  }

  for (const [customerId, amount] of debtMap.entries()) {
    const c = customerById.get(customerId);
    if (!c) continue;
    actions.push({
      id: `debt-${customerId}`,
      type: 'collect_debt',
      customerId,
      customerName: c.name,
      title: `Thu nợ: ${c.name}`,
      subtitle: `Còn ${formatMoney(amount)} chưa thu`,
      priority: 2,
      amount,
    });
  }

  for (const c of due.filter((x) => x.status === 'warm' || x.status === 'new')) {
    actions.push({
      id: `contact-${c.id}`,
      type: 'contact',
      customerId: c.id!,
      customerName: c.name,
      title: `Liên hệ: ${c.name}`,
      subtitle: `${c.status === 'warm' ? 'Tiềm năng' : 'Mới'} · quá hạn ${overdueDays(c, now)} ngày`,
      priority: c.status === 'warm' ? 3 : 4,
    });
  }

  const promoCutoff = now - PROMO_STALE_DAYS * 86400000;
  for (const c of customers) {
    if (c.status !== 'warm' && c.status !== 'hot') continue;
    if (c.last_contact_at && c.last_contact_at >= promoCutoff) continue;
    if (due.some((d) => d.id === c.id)) continue;
    actions.push({
      id: `promo-${c.id}`,
      type: 'contact',
      customerId: c.id!,
      customerName: c.name,
      title: `Chăm lại: ${c.name}`,
      subtitle: `${c.status === 'hot' ? 'Nóng' : 'Tiềm năng'} · ${daysSince(c.last_contact_at ?? c.created_at, now)} ngày chưa liên hệ`,
      priority: 5,
    });
  }

  const returnCutoff = now - RETURNING_STALE_DAYS * 86400000;
  for (const c of customers) {
    if (c.status !== 'closed') continue;
    if (!withOrders.has(c.id!)) continue;
    if (c.last_contact_at && c.last_contact_at >= returnCutoff) continue;
    actions.push({
      id: `return-${c.id}`,
      type: 're_engage',
      customerId: c.id!,
      customerName: c.name,
      title: `Mời mua lại: ${c.name}`,
      subtitle: `Đã từng mua · ${daysSince(c.last_contact_at ?? c.created_at, now)} ngày chưa chăm`,
      priority: 6,
    });
  }

  actions.sort((a, b) => a.priority - b.priority || (b.amount ?? 0) - (a.amount ?? 0));
  return actions.slice(0, MAX_ACTIONS);
}

export async function getRevenueInsights(now = new Date()): Promise<RevenueInsight[]> {
  const insights: RevenueInsight[] = [];
  const { start, end } = monthRangeFromDate(now);
  const [summary, bySource, topProducts] = await Promise.all([
    getSalesSummaryForMonth(now),
    getRevenueBySource(start, end),
    getTopSalesProductsByRevenue(start, end),
  ]);

  if (summary.debt > 0) {
    insights.push({
      text: `Còn ${formatMoney(summary.debt)} công nợ tháng này — ưu tiên thu trước khi chốt đơn mới`,
      highlight: formatMoney(summary.debt),
    });
  }

  if (bySource.length > 0 && summary.revenue > 0) {
    const top = bySource[0];
    const pct = Math.round((top.revenue / summary.revenue) * 100);
    if (pct >= 20) {
      insights.push({
        text: `${top.label} tạo ${pct}% doanh thu tháng này`,
        highlight: top.label,
      });
    }
    if (bySource.length >= 2) {
      const second = bySource[1];
      const pct2 = Math.round((second.revenue / summary.revenue) * 100);
      if (pct2 >= 10) {
        insights.push({
          text: `${second.label} đóng góp ${pct2}% — cân nhắc đầu tư thêm nguồn này`,
        });
      }
    }
  }

  if (topProducts.length > 0 && summary.revenue > 0) {
    const top = topProducts[0];
    const pct = Math.round(((top.revenue as number) / summary.revenue) * 100);
    insights.push({
      text: `"${top.product}" đang bán chạy nhất (${pct}% doanh thu tháng)`,
      highlight: top.product as string,
    });
  }

  if (insights.length === 0 && summary.revenue === 0) {
    insights.push({
      text: 'Chưa có doanh thu tháng này — tập trung chăm khách Nóng và Tiềm năng trước',
    });
  }

  return insights.slice(0, 3);
}

export async function getAchievementStats(): Promise<AchievementStats> {
  const [streak, orders, interactions, customers, monthSummary] = await Promise.all([
    getCurrentStreak(),
    db.orders.toArray(),
    db.interactions.toArray(),
    db.customers.toArray(),
    getSalesSummaryForMonth(),
  ]);

  const caredIds = new Set(interactions.map((i) => i.customer_id));
  let totalRevenue = 0;
  for (const o of orders) totalRevenue += orderRevenue(o);

  return {
    streak,
    totalRevenue,
    totalOrders: orders.length,
    customersCared: caredIds.size,
    totalInteractions: interactions.length,
    monthRevenue: monthSummary.revenue,
  };
}

export function buildCustomerIntelligence(
  customer: Customer,
  orders: Order[],
): CustomerIntelligence {
  const summary = summarizeOrders(orders);
  const orderCount = orders.length;
  const lastOrderAt =
    orderCount > 0 ? Math.max(...orders.map((o) => o.created_at)) : null;
  const daysSinceLastPurchase = lastOrderAt != null ? daysSince(lastOrderAt) : null;
  const avgOrderValue = orderCount > 0 ? summary.revenue / orderCount : 0;

  let tierLabel = 'Chưa chốt';
  let tierHint = 'Chưa có đơn hàng — ưu tiên chăm và chốt';
  if (orderCount >= 5 || summary.revenue >= 10_000_000) {
    tierLabel = 'VIP';
    tierHint = 'Khách mang giá trị cao — giữ liên hệ định kỳ';
  } else if (orderCount >= 2) {
    tierLabel = 'Khách quen';
    tierHint = 'Mua lặp lại — cơ hội upsell và giới thiệu';
  } else if (orderCount === 1) {
    tierLabel = 'Đã mua 1 lần';
    tierHint = 'Theo dõi sau bán để mời mua lại';
  }

  return {
    orderCount,
    totalRevenue: summary.revenue,
    totalProfit: summary.profit,
    totalCommission: summary.commission,
    totalDebt: summary.debt,
    lastOrderAt,
    avgOrderValue,
    isRepeatBuyer: orderCount >= 2,
    daysSinceLastPurchase,
    tierLabel,
    tierHint,
  };
}

/** Thông báo hàng ngày — cụ thể, hướng hành động */
export async function buildActionDailyNotification(): Promise<{ title: string; body: string }> {
  const [due, actions, atRisk] = await Promise.all([
    getNeedsAttention(),
    getDailyActions(),
    getAtRiskSummary(),
  ]);

  if (due.length === 0 && actions.length === 0) {
    return {
      title: 'Salenote — Ngày êm ả',
      body: 'Không có việc gấp hôm nay. Xem insight doanh thu & khách cũ cần chăm lại.',
    };
  }

  const firstHot = due.find((c) => c.status === 'hot');
  const firstAction = actions[0];
  const debtAction = actions.find((a) => a.type === 'collect_debt');

  if (firstHot) {
    const days = overdueDays(firstHot);
    const more = due.length - 1;
    return {
      title: `🔥 ${firstHot.name} cần chăm gấp`,
      body:
        more > 0
          ? `Khách Nóng · quá hạn ${days} ngày. Còn ${more} khách khác cần liên hệ hôm nay.`
          : `Khách Nóng · quá hạn ${days} ngày. Mở app để xem việc cần làm.`,
    };
  }

  if (debtAction && debtAction.amount) {
    return {
      title: `💰 Thu nợ: ${debtAction.customerName}`,
      body: `Còn ${formatMoney(debtAction.amount)}. Tổng ${atRisk.debtCustomers} khách còn nợ tháng này.`,
    };
  }

  if (firstAction) {
    const more = actions.length - 1;
    return {
      title: `Việc hôm nay: ${firstAction.customerName}`,
      body:
        more > 0
          ? `${firstAction.subtitle}. Còn ${more} việc khác trong danh sách.`
          : firstAction.subtitle,
    };
  }

  return {
    title: 'Salenote — Việc hôm nay',
    body: `Bạn có ${due.length} khách cần liên hệ hôm nay`,
  };
}
