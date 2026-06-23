class AppConstants {
  static const List<String> statuses = ['new', 'warm', 'hot', 'closed'];

  static const Map<String, String> statusLabels = {
    'new': 'Mới',
    'warm': 'Tiềm năng',
    'hot': 'Nóng',
    'closed': 'Đã chốt',
  };

  static const Map<String, int> statusColors = {
    'new': 0xFF2196F3,
    'warm': 0xFFFF9800,
    'hot': 0xFFE53935,
    'closed': 0xFF4CAF50,
  };

  static const String defaultMessage =
      'Anh/chị hỏi sản phẩm hôm trước, hiện shop đang có ưu đãi ạ.';

  static const String keyMessageTemplate = 'message_template';
  static const String keyNotificationEnabled = 'notification_enabled';
  static const String keyNotificationHour = 'notification_hour';
  static const String keyNotificationMinute = 'notification_minute';
  static const String keyNotificationSound = 'notification_sound'; // 'default' | 'email' | 'silent'
  static const String keyNotificationVibrate = 'notification_vibrate';
  static const String keyLastBackupDate = 'last_backup_date';
  static const String keyThemeMode = 'theme_mode';
  static const String keyPinHash = 'pin_hash';
  static const String keyLocale = 'locale';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keySwipeHintShown = 'swipe_hint_shown';
  static const String keyDailyTipDate = 'daily_tip_date';
  static const String keyMilestoneShown = 'milestone_shown';

  // Notification defaults
  static const int defaultNotifHour = 9;
  static const int defaultNotifMinute = 0;

  static const int backupVersion = 2;

  static const List<Map<String, String>> customerSources = [
    {'key': 'facebook', 'label': 'Facebook'},
    {'key': 'zalo', 'label': 'Zalo'},
    {'key': 'tiktok', 'label': 'TikTok / Live'},
    {'key': 'shopee', 'label': 'Shopee / Sàn TMĐT'},
    {'key': 'referral', 'label': 'Giới thiệu (khách cũ)'},
    {'key': 'returning', 'label': 'Khách quen / mua lại'},
    {'key': 'walk_in', 'label': 'Tự đến / quầy'},
    {'key': 'phone', 'label': 'Gọi điện / SMS'},
    {'key': 'other', 'label': 'Khác'},
  ];

  static const Map<String, String> paymentLabels = {
    'paid': 'Đã thu đủ',
    'partial': 'Thu một phần',
    'unpaid': 'Chưa thu',
  };

  static String sourceLabel(String? key) {
    if (key == null || key.isEmpty) return '—';
    for (final s in customerSources) {
      if (s['key'] == key) return s['label']!;
    }
    return key;
  }

  static String stockStatusLabel(String status) {
    switch (status) {
      case 'out':
        return 'Hết hàng';
      case 'low':
        return 'Sắp hết';
      case 'ok':
        return 'Còn hàng';
      default:
        return 'Không theo kho';
    }
  }

  static const List<String> messageTemplates = [
    'Anh/chị hỏi sản phẩm hôm trước, hiện shop đang có ưu đãi ạ.',
    'Chào {tên}, bên mình đang có deal mới cho {sản_phẩm} ạ. Anh/chị có quan tâm không?',
    'Hi {tên}! Shop mình vừa về hàng {sản_phẩm} mới nhé. Anh/chị xem thử không ạ? 😊',
    '{tên} ơi, hôm nay shop có khuyến mãi {sản_phẩm}, giảm đặc biệt cho khách cũ ạ!',
    'Chào {tên}, không biết anh/chị có cần thêm thông tin về {sản_phẩm} không ạ?',
  ];
}
