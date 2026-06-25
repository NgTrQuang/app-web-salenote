export const STATUSES = ['new', 'warm', 'hot', 'closed'] as const;

export const STATUS_LABELS: Record<string, string> = {
  new: 'Mới',
  warm: 'Tiềm năng',
  hot: 'Nóng',
  closed: 'Đã chốt',
};

export const STATUS_COLORS: Record<string, string> = {
  new: '#2196F3',
  warm: '#FF9800',
  hot: '#E53935',
  closed: '#4CAF50',
};

export const DEFAULT_MESSAGE =
  'Anh/chị hỏi sản phẩm hôm trước, hiện shop đang có ưu đãi ạ.';

export const MESSAGE_TEMPLATES = [
  DEFAULT_MESSAGE,
  'Chào {tên}, bên mình đang có deal mới cho {sản_phẩm} ạ. Anh/chị có quan tâm không?',
  'Hi {tên}! Shop mình vừa về hàng {sản_phẩm} mới nhé. Anh/chị xem thử không ạ? 😊',
  '{tên} ơi, hôm nay shop có khuyến mãi {sản_phẩm}, giảm đặc biệt cho khách cũ ạ!',
  'Chào {tên}, không biết anh/chị có cần thêm thông tin về {sản_phẩm} không ạ?',
];

export const SETTING_KEYS = {
  messageTemplate: 'message_template',
  themeMode: 'theme_mode',
  lastBackupDate: 'last_backup_date',
  onboardingDone: 'onboarding_done',
  notificationEnabled: 'notification_enabled',
  notificationHour: 'notification_hour',
  notificationMinute: 'notification_minute',
  weeklyDigestEnabled: 'notification_weekly_enabled',
  monthlyDigestEnabled: 'notification_monthly_enabled',
  loyaltyReminderEnabled: 'notification_loyalty_enabled',
  notifLastDaily: 'notif_last_daily',
  notifLastWeekly: 'notif_last_weekly',
  notifLastMonthly: 'notif_last_monthly',
  notifLastLoyalty: 'notif_last_loyalty',
  shopName: 'shop_name',
  shopPhone: 'shop_phone',
} as const;

export const DEFAULT_NOTIF_HOUR = 9;
export const DEFAULT_NOTIF_MINUTE = 0;

export const APP_NAME = 'Salenote';
export const APP_TAGLINE = 'Sổ Sale Cá Nhân';

/** Nguồn khách — key lưu DB, label hiển thị */
export const CUSTOMER_SOURCES = [
  { key: 'facebook', label: 'Facebook' },
  { key: 'zalo', label: 'Zalo' },
  { key: 'tiktok', label: 'TikTok / Live' },
  { key: 'shopee', label: 'Shopee / Sàn TMĐT' },
  { key: 'referral', label: 'Giới thiệu (khách cũ)' },
  { key: 'returning', label: 'Khách quen / mua lại' },
  { key: 'walk_in', label: 'Tự đến / quầy' },
  { key: 'phone', label: 'Gọi điện / SMS' },
  { key: 'other', label: 'Khác' },
] as const;

export const SOURCE_LABELS: Record<string, string> = Object.fromEntries(
  CUSTOMER_SOURCES.map((s) => [s.key, s.label]),
);

export function sourceLabel(key: string | null | undefined): string {
  if (!key) return '—';
  return SOURCE_LABELS[key] ?? key;
}
