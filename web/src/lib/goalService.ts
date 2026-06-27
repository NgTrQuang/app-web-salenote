import { getSetting, setSetting } from './db';
import { SETTING_KEYS } from './constants';
import { getSalesSummaryForMonth } from './orderService';

export interface GoalProgress {
  goal: number;
  current: number;
  remaining: number;
  orderCount: number;
  ordersNeeded: number | null;
  percent: number;
}

export async function getMonthlyGoal(): Promise<number | null> {
  const v = await getSetting(SETTING_KEYS.monthlyRevenueGoal);
  if (!v) return null;
  const n = parseInt(v, 10);
  return n > 0 ? n : null;
}

export async function setMonthlyGoal(amount: number): Promise<void> {
  if (amount <= 0) {
    await setSetting(SETTING_KEYS.monthlyRevenueGoal, '');
    return;
  }
  await setSetting(SETTING_KEYS.monthlyRevenueGoal, String(amount));
}

export async function getGoalProgress(now = new Date()): Promise<GoalProgress | null> {
  const goal = await getMonthlyGoal();
  if (!goal) return null;

  const summary = await getSalesSummaryForMonth(now);
  const current = summary.revenue;
  const remaining = Math.max(0, goal - current);
  const avg = summary.order_count > 0 ? current / summary.order_count : 0;
  const ordersNeeded = remaining > 0 && avg > 0 ? Math.ceil(remaining / avg) : remaining > 0 ? null : 0;

  return {
    goal,
    current,
    remaining,
    orderCount: summary.order_count,
    ordersNeeded,
    percent: Math.min(100, Math.round((current / goal) * 100)),
  };
}
