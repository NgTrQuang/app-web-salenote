import { getSetting, setSetting } from './db';

import {

  DEFAULT_NOTIF_HOUR,

  DEFAULT_NOTIF_MINUTE,

  SETTING_KEYS,

} from './constants';

import {

  countLoyaltyCustomers,

  countPromoCandidates,

  getMonthlyStats,

  getNeedsAttention,

} from './customerService';

import { getOrdersInRange } from './orderService';

import { buildActionDailyNotification } from './insightsService';
import { formatMoney } from './money';
import { orderRevenue } from '@/types';



export interface NotificationSettings {

  dailyEnabled: boolean;

  weeklyEnabled: boolean;

  monthlyEnabled: boolean;

  loyaltyEnabled: boolean;

  hour: number;

  minute: number;

}



/** Ngày theo giờ máy (không dùng UTC). */

function dateKey(d = new Date()): string {

  const y = d.getFullYear();

  const m = String(d.getMonth() + 1).padStart(2, '0');

  const day = String(d.getDate()).padStart(2, '0');

  return `${y}-${m}-${day}`;

}



function scheduledTodayMs(hour: number, minute: number, now = new Date()): number {

  return new Date(now.getFullYear(), now.getMonth(), now.getDate(), hour, minute, 0).getTime();

}



/** Đã qua giờ nhắc hôm nay chưa (kể cả vài giờ sau — tránh lỡ phút). */

function isPastScheduledTime(hour: number, minute: number, now = new Date()): boolean {

  return now.getTime() >= scheduledTodayMs(hour, minute, now);

}



function parseBool(val: string | undefined): boolean {

  return val === 'true';

}



function parseIntSetting(val: string | undefined, fallback: number): number {

  const n = Number.parseInt(val ?? '', 10);

  return Number.isFinite(n) ? n : fallback;

}



export async function getNotificationSettings(): Promise<NotificationSettings> {

  const [daily, weekly, monthly, loyalty, hour, minute] = await Promise.all([

    getSetting(SETTING_KEYS.notificationEnabled),

    getSetting(SETTING_KEYS.weeklyDigestEnabled),

    getSetting(SETTING_KEYS.monthlyDigestEnabled),

    getSetting(SETTING_KEYS.loyaltyReminderEnabled),

    getSetting(SETTING_KEYS.notificationHour),

    getSetting(SETTING_KEYS.notificationMinute),

  ]);



  return {

    dailyEnabled: parseBool(daily),

    weeklyEnabled: parseBool(weekly),

    monthlyEnabled: parseBool(monthly),

    loyaltyEnabled: parseBool(loyalty),

    hour: parseIntSetting(hour, DEFAULT_NOTIF_HOUR),

    minute: parseIntSetting(minute, DEFAULT_NOTIF_MINUTE),

  };

}



export async function saveNotificationTime(hour: number, minute: number): Promise<void> {

  await Promise.all([

    setSetting(SETTING_KEYS.notificationHour, String(hour)),

    setSetting(SETTING_KEYS.notificationMinute, String(minute)),

  ]);

}



export async function setDailyReminderEnabled(enabled: boolean): Promise<void> {

  await setSetting(SETTING_KEYS.notificationEnabled, String(enabled));

}



export async function setWeeklyDigestEnabled(enabled: boolean): Promise<void> {

  await setSetting(SETTING_KEYS.weeklyDigestEnabled, String(enabled));

}



export async function setMonthlyDigestEnabled(enabled: boolean): Promise<void> {

  await setSetting(SETTING_KEYS.monthlyDigestEnabled, String(enabled));

}



export async function setLoyaltyReminderEnabled(enabled: boolean): Promise<void> {

  await setSetting(SETTING_KEYS.loyaltyReminderEnabled, String(enabled));

}



export function getNotificationPermission(): NotificationPermission {

  if (typeof Notification === 'undefined') return 'denied';

  return Notification.permission;

}



export async function requestNotificationPermission(): Promise<boolean> {

  if (typeof Notification === 'undefined') return false;

  if (Notification.permission === 'granted') return true;

  if (Notification.permission === 'denied') return false;

  const result = await Notification.requestPermission();

  return result === 'granted';

}



function showBrowserNotification(title: string, body: string): void {

  if (typeof Notification === 'undefined') return;

  if (Notification.permission !== 'granted') return;

  try {

    new Notification(title, {

      body,

      icon: '/favicon.svg',

      tag: `salenote-${Date.now()}`,

    });

  } catch {

    // ignore

  }

}



async function buildDailyMessage(): Promise<{ title: string; body: string }> {
  return buildActionDailyNotification();
}



async function buildWeeklyMessage(): Promise<{ title: string; body: string }> {

  const now = new Date();

  const thisMonday = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  const day = thisMonday.getDay();

  const diffToMonday = day === 0 ? -6 : 1 - day;

  thisMonday.setDate(thisMonday.getDate() + diffToMonday);



  const weekStart = new Date(thisMonday);

  weekStart.setDate(weekStart.getDate() - 7);



  const orders = await getOrdersInRange(weekStart.getTime(), thisMonday.getTime());

  const revenue = orders.reduce((sum, o) => sum + orderRevenue(o), 0);



  if (orders.length === 0) {

    return {

      title: '📊 Salenote — Tổng kết tuần',

      body: 'Tuần qua chưa có đơn — xem khách tiềm năng & lên kế hoạch chăm sóc',

    };

  }

  return {

    title: '📊 Salenote — Tổng kết tuần',

    body: `Tuần qua: ${orders.length} đơn · ${formatMoney(revenue)} doanh thu. Mở app lên kế hoạch tuần mới!`,

  };

}



async function buildMonthlyMessage(): Promise<{ title: string; body: string }> {

  const now = new Date();

  const prevMonth = now.getMonth() === 0 ? 12 : now.getMonth();

  const prevYear = now.getMonth() === 0 ? now.getFullYear() - 1 : now.getFullYear();

  const stats = await getMonthlyStats(prevYear, prevMonth);



  return {

    title: '📅 Salenote — Đầu tháng mới',

    body: `Tháng trước: ${stats.contacts} lượt liên hệ · ${stats.closed} đơn chốt. Xem thống kê & đặt mục tiêu!`,

  };

}



async function buildLoyaltyMessage(): Promise<{ title: string; body: string }> {

  const promoCount = await countPromoCandidates();

  const loyaltyCount = await countLoyaltyCustomers();

  const total = promoCount + loyaltyCount;



  if (total === 0) {

    return {

      title: '🎁 Salenote — Cơ hội tri ân khách',

      body: 'Chưa có khách cần ưu đãi gấp — xem danh sách & chuẩn bị chương trình tri ân',

    };

  }

  return {

    title: '🎁 Salenote — Cơ hội tri ân khách',

    body: `${promoCount} khách tiềm năng · ${loyaltyCount} khách cũ lâu chưa liên hệ — gửi ưu đãi/tri ân nhé!`,

  };

}



export async function sendTestNotification(): Promise<void> {

  const settings = await getNotificationSettings();

  showBrowserNotification(

    '🔔 Salenote — Thông báo thử',

    `Nhắc nhở hàng ngày sẽ gửi lúc ${formatNotifTime(settings.hour, settings.minute)}`,

  );

}



/** Gửi ngay nội dung nhắc hôm nay (nếu chưa gửi) — dùng sau khi đổi giờ hoặc mở lại tab. */

export async function fireDueRemindersNow(now = new Date()): Promise<number> {

  if (typeof Notification === 'undefined') return 0;

  if (Notification.permission !== 'granted') return 0;



  const settings = await getNotificationSettings();

  const anyEnabled =

    settings.dailyEnabled ||

    settings.weeklyEnabled ||

    settings.monthlyEnabled ||

    settings.loyaltyEnabled;

  if (!anyEnabled) return 0;



  if (!isPastScheduledTime(settings.hour, settings.minute, now)) return 0;



  const today = dateKey(now);

  let fired = 0;



  if (settings.dailyEnabled) {

    const last = await getSetting(SETTING_KEYS.notifLastDaily);

    if (last !== today) {

      const msg = await buildDailyMessage();

      showBrowserNotification(msg.title, msg.body);

      await setSetting(SETTING_KEYS.notifLastDaily, today);

      fired++;

    }

  }



  if (settings.weeklyEnabled && now.getDay() === 1) {

    const last = await getSetting(SETTING_KEYS.notifLastWeekly);

    if (last !== today) {

      const msg = await buildWeeklyMessage();

      showBrowserNotification(msg.title, msg.body);

      await setSetting(SETTING_KEYS.notifLastWeekly, today);

      fired++;

    }

  }



  if (settings.monthlyEnabled && now.getDate() === 1) {

    const last = await getSetting(SETTING_KEYS.notifLastMonthly);

    if (last !== today) {

      const msg = await buildMonthlyMessage();

      showBrowserNotification(msg.title, msg.body);

      await setSetting(SETTING_KEYS.notifLastMonthly, today);

      fired++;

    }

  }



  if (settings.loyaltyEnabled && now.getDay() === 5) {

    const last = await getSetting(SETTING_KEYS.notifLastLoyalty);

    if (last !== today) {

      const msg = await buildLoyaltyMessage();

      showBrowserNotification(msg.title, msg.body);

      await setSetting(SETTING_KEYS.notifLastLoyalty, today);

      fired++;

    }

  }



  return fired;

}



/** @deprecated */

export async function checkAndFireReminders(now = new Date()): Promise<void> {

  await fireDueRemindersNow(now);

}



export function formatNotifTime(hour: number, minute: number): string {

  return `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;

}



export function parseTimeInput(value: string): { hour: number; minute: number } | null {

  const m = /^(\d{1,2}):(\d{2})$/.exec(value);

  if (!m) return null;

  const hour = Number.parseInt(m[1], 10);

  const minute = Number.parseInt(m[2], 10);

  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

  return { hour, minute };

}



export function isPastScheduledTimeForSettings(

  settings: NotificationSettings,

  now = new Date(),

): boolean {

  return isPastScheduledTime(settings.hour, settings.minute, now);

}


