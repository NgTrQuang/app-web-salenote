import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../database/database_helper.dart';
import '../utils/constants.dart';
import 'insights_service.dart';

/// Sound options for notifications.
enum NotifSound { defaultSound, silent }

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int _dailyNotificationId = 1;
  static const int _weeklyNotificationId = 2;
  static const int _monthlyNotificationId = 3;
  static const int _loyaltyNotificationId = 4;

  static const String _channelName = 'Nhắc nhở Salenote';
  static const String _chDefaultVib = 'salenote_default_vib';
  static const String _chDefaultNoVib = 'salenote_default_novib';
  static const String _chSilentVib = 'salenote_silent_vib';
  static const String _chSilentNoVib = 'salenote_silent_novib';

  final _plugin = FlutterLocalNotificationsPlugin();
  final _db = DatabaseHelper();
  bool _initialized = false;
  bool _tzReady = false;

  Future<void> init() async {
    if (_initialized) return;
    await _ensureLocalTimezone();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<void> _ensureLocalTimezone() async {
    if (_tzReady) return;
    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }
    _tzReady = true;
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      if (granted != true) return false;
      try {
        await android.requestExactAlarmsPermission();
      } catch (_) {}
      return true;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  Future<bool> isEnabled() async {
    final val = await _db.getSetting(AppConstants.keyNotificationEnabled);
    return val == 'true';
  }

  Future<bool> isWeeklyEnabled() async {
    final val = await _db.getSetting(AppConstants.keyWeeklyDigestEnabled);
    return val == 'true';
  }

  Future<bool> isMonthlyEnabled() async {
    final val = await _db.getSetting(AppConstants.keyMonthlyDigestEnabled);
    return val == 'true';
  }

  Future<bool> isLoyaltyEnabled() async {
    final val = await _db.getSetting(AppConstants.keyLoyaltyReminderEnabled);
    return val == 'true';
  }

  Future<int> getHour() async {
    final val = await _db.getSetting(AppConstants.keyNotificationHour);
    return int.tryParse(val ?? '') ?? AppConstants.defaultNotifHour;
  }

  Future<int> getMinute() async {
    final val = await _db.getSetting(AppConstants.keyNotificationMinute);
    return int.tryParse(val ?? '') ?? AppConstants.defaultNotifMinute;
  }

  Future<NotifSound> getSound() async {
    final val = await _db.getSetting(AppConstants.keyNotificationSound);
    switch (val) {
      case 'silent':
        return NotifSound.silent;
      default:
        return NotifSound.defaultSound;
    }
  }

  Future<bool> getVibrate() async {
    final val = await _db.getSetting(AppConstants.keyNotificationVibrate);
    return val != 'false';
  }

  Future<void> setEnabled(bool enabled) async {
    await _db.setSetting(
        AppConstants.keyNotificationEnabled, enabled.toString());
    unawaited(_rescheduleAfterToggle(enabled));
  }

  Future<void> setWeeklyEnabled(bool enabled) async {
    await _db.setSetting(
        AppConstants.keyWeeklyDigestEnabled, enabled.toString());
    unawaited(_rescheduleAfterToggle(enabled));
  }

  Future<void> setMonthlyEnabled(bool enabled) async {
    await _db.setSetting(
        AppConstants.keyMonthlyDigestEnabled, enabled.toString());
    unawaited(_rescheduleAfterToggle(enabled));
  }

  Future<void> setLoyaltyEnabled(bool enabled) async {
    await _db.setSetting(
        AppConstants.keyLoyaltyReminderEnabled, enabled.toString());
    unawaited(_rescheduleAfterToggle(enabled));
  }

  Future<void> _rescheduleAfterToggle(bool enabled) async {
    await rescheduleAllReminders();
    if (enabled) await catchUpMissedReminders();
  }

  /// Gửi ngay nhắc hôm nay nếu đã qua giờ (dùng từ Cài đặt).
  Future<int> fireDueRemindersNow() => catchUpMissedReminders();

  Future<void> saveSettings({
    required int hour,
    required int minute,
    required NotifSound sound,
    required bool vibrate,
  }) async {
    await _db.setSetting(AppConstants.keyNotificationHour, hour.toString());
    await _db.setSetting(AppConstants.keyNotificationMinute, minute.toString());
    await _db.setSetting(AppConstants.keyNotificationSound, _soundKey(sound));
    await _db.setSetting(
        AppConstants.keyNotificationVibrate, vibrate.toString());
    await rescheduleAllReminders();
    await catchUpMissedReminders();
  }

  Future<void> rescheduleAllReminders() async {
    await init();
    if (!await isEnabled() &&
        !await isWeeklyEnabled() &&
        !await isMonthlyEnabled() &&
        !await isLoyaltyEnabled()) {
      await cancelAllReminders();
      return;
    }

    if (await isEnabled()) {
      await scheduleDailyReminder();
    } else {
      await _plugin.cancel(_dailyNotificationId);
    }

    if (await isWeeklyEnabled()) {
      await scheduleWeeklyDigest();
    } else {
      await _plugin.cancel(_weeklyNotificationId);
    }

    if (await isMonthlyEnabled()) {
      await scheduleMonthlyDigest();
    } else {
      await _plugin.cancel(_monthlyNotificationId);
    }

    if (await isLoyaltyEnabled()) {
      await scheduleLoyaltyReminder();
    } else {
      await _plugin.cancel(_loyaltyNotificationId);
    }

    await catchUpMissedReminders();
  }

  Future<void> scheduleSmartReminder() => scheduleDailyReminder();

  Future<void> scheduleDailyReminder() async {
    await init();
    if (!await isEnabled()) return;
    final msg = await _buildDailyMessage();
    await _scheduleRepeating(
      id: _dailyNotificationId,
      hour: await getHour(),
      minute: await getMinute(),
      title: msg.title,
      body: msg.body,
      sound: await getSound(),
      vibrate: await getVibrate(),
      match: DateTimeComponents.time,
    );
  }

  Future<({String title, String body})> _buildDailyMessage() async {
    return InsightsService().buildActionDailyNotification();
  }

  Future<void> scheduleWeeklyDigest() async {
    await init();
    if (!await isWeeklyEnabled()) return;
    final msg = await _buildWeeklyMessage();
    await _scheduleRepeating(
      id: _weeklyNotificationId,
      hour: await getHour(),
      minute: await getMinute(),
      title: msg.title,
      body: msg.body,
      sound: await getSound(),
      vibrate: await getVibrate(),
      match: DateTimeComponents.dayOfWeekAndTime,
      weekday: DateTime.monday,
    );
  }

  Future<({String title, String body})> _buildWeeklyMessage() async {
    final isVi = await _isViLocale();
    final now = DateTime.now();
    final thisMonday = DateTime(now.year, now.month, now.day);
    final diffToMonday = now.weekday == DateTime.sunday ? -6 : 1 - now.weekday;
    final weekStartMonday = thisMonday.add(Duration(days: diffToMonday - 7));
    final weekEndMonday = weekStartMonday.add(const Duration(days: 7));
    final orders = await _db.getOrdersInRange(
      weekStartMonday.millisecondsSinceEpoch,
      weekEndMonday.millisecondsSinceEpoch,
    );
    final revenue = orders.fold<double>(0, (sum, o) => sum + o.revenue);

    return (
      title: isVi ? '📊 Salenote — Tổng kết tuần' : '📊 Salenote — Weekly recap',
      body: orders.isNotEmpty
          ? (isVi
              ? 'Tuần qua: ${orders.length} đơn · ${_formatMoney(revenue)} doanh thu. Mở app lên kế hoạch tuần mới!'
              : 'Last week: ${orders.length} orders · ${_formatMoney(revenue)} revenue. Plan your week!')
          : (isVi
              ? 'Tuần qua chưa có đơn — xem khách tiềm năng & lên kế hoạch chăm sóc'
              : 'No orders last week — review leads and plan follow-ups'),
    );
  }

  Future<void> scheduleMonthlyDigest() async {
    await init();
    if (!await isMonthlyEnabled()) return;
    final msg = await _buildMonthlyMessage();
    await _scheduleRepeating(
      id: _monthlyNotificationId,
      hour: await getHour(),
      minute: await getMinute(),
      title: msg.title,
      body: msg.body,
      sound: await getSound(),
      vibrate: await getVibrate(),
      match: DateTimeComponents.dayOfMonthAndTime,
      dayOfMonth: 1,
    );
  }

  Future<({String title, String body})> _buildMonthlyMessage() async {
    final isVi = await _isViLocale();
    final now = DateTime.now();
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    final stats = await _db.getMonthlyStats(prevYear, prevMonth);

    return (
      title: isVi ? '📅 Salenote — Đầu tháng mới' : '📅 Salenote — New month',
      body: isVi
          ? 'Tháng trước: ${stats['contacts']} lượt liên hệ · ${stats['closed']} đơn chốt. Xem thống kê & đặt mục tiêu!'
          : 'Last month: ${stats['contacts']} contacts · ${stats['closed']} deals. Review stats & set goals!',
    );
  }

  Future<void> scheduleLoyaltyReminder() async {
    await init();
    if (!await isLoyaltyEnabled()) return;
    final msg = await _buildLoyaltyMessage();
    await _scheduleRepeating(
      id: _loyaltyNotificationId,
      hour: await getHour(),
      minute: await getMinute(),
      title: msg.title,
      body: msg.body,
      sound: await getSound(),
      vibrate: await getVibrate(),
      match: DateTimeComponents.dayOfWeekAndTime,
      weekday: DateTime.friday,
    );
  }

  Future<({String title, String body})> _buildLoyaltyMessage() async {
    final isVi = await _isViLocale();
    final promoCount = await _db.countPromoCandidates();
    final loyaltyCount = await _db.countLoyaltyCustomers();
    final total = promoCount + loyaltyCount;

    return (
      title: isVi
          ? '🎁 Salenote — Cơ hội tri ân khách'
          : '🎁 Salenote — Customer appreciation',
      body: total == 0
          ? (isVi
              ? 'Chưa có khách cần ưu đãi gấp — xem danh sách & chuẩn bị chương trình tri ân'
              : 'No urgent promo targets — review your list for outreach')
          : (isVi
              ? '$promoCount khách tiềm năng · $loyaltyCount khách cũ lâu chưa liên hệ — gửi ưu đãi/tri ân nhé!'
              : '$promoCount warm leads · $loyaltyCount past customers — send offers or thank-you gifts!'),
    );
  }

  Future<void> onAppResumed() async {
    if (!await isEnabled() &&
        !await isWeeklyEnabled() &&
        !await isMonthlyEnabled() &&
        !await isLoyaltyEnabled()) {
      return;
    }
    await catchUpMissedReminders();
    await rescheduleAllReminders();
  }

  /// Gửi ngay nếu đã qua giờ nhắc hôm nay mà chưa gửi (mở app sau giờ nhắc).
  Future<int> catchUpMissedReminders() async {
    await init();
    final now = DateTime.now();
    final hour = await getHour();
    final minute = await getMinute();
    final scheduledToday =
        DateTime(now.year, now.month, now.day, hour, minute);
    if (now.isBefore(scheduledToday)) return 0;

    final today = _dateKey(now);
    final sound = await getSound();
    final vibrate = await getVibrate();
    final details = _buildDetails(sound, vibrate);
    var fired = 0;

    if (await isEnabled()) {
      final last = await _db.getSetting(AppConstants.keyNotifLastDaily);
      if (last != today) {
        final msg = await _buildDailyMessage();
        await _plugin.show(_dailyNotificationId, msg.title, msg.body, details);
        await _db.setSetting(AppConstants.keyNotifLastDaily, today);
        fired++;
      }
    }

    if (await isWeeklyEnabled() && now.weekday == DateTime.monday) {
      final last = await _db.getSetting(AppConstants.keyNotifLastWeekly);
      if (last != today) {
        final msg = await _buildWeeklyMessage();
        await _plugin.show(_weeklyNotificationId, msg.title, msg.body, details);
        await _db.setSetting(AppConstants.keyNotifLastWeekly, today);
        fired++;
      }
    }

    if (await isMonthlyEnabled() && now.day == 1) {
      final last = await _db.getSetting(AppConstants.keyNotifLastMonthly);
      if (last != today) {
        final msg = await _buildMonthlyMessage();
        await _plugin.show(_monthlyNotificationId, msg.title, msg.body, details);
        await _db.setSetting(AppConstants.keyNotifLastMonthly, today);
        fired++;
      }
    }

    if (await isLoyaltyEnabled() && now.weekday == DateTime.friday) {
      final last = await _db.getSetting(AppConstants.keyNotifLastLoyalty);
      if (last != today) {
        final msg = await _buildLoyaltyMessage();
        await _plugin.show(_loyaltyNotificationId, msg.title, msg.body, details);
        await _db.setSetting(AppConstants.keyNotifLastLoyalty, today);
        fired++;
      }
    }

    return fired;
  }

  String _dateKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyNotificationId);
  }

  Future<void> cancelAllReminders() async {
    await _plugin.cancel(_dailyNotificationId);
    await _plugin.cancel(_weeklyNotificationId);
    await _plugin.cancel(_monthlyNotificationId);
    await _plugin.cancel(_loyaltyNotificationId);
  }

  Future<void> sendTestNotification() async {
    await init();
    final hour = await getHour();
    final minute = await getMinute();
    final isVi = await _isViLocale();

    await _plugin.show(
      99,
      isVi ? '🔔 Salenote — Thông báo thử' : '🔔 Salenote — Test',
      isVi
          ? 'Nhắc nhở hàng ngày sẽ gửi lúc ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'
          : 'Daily reminder at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      _buildDetails(await getSound(), await getVibrate()),
    );
  }

  String _soundKey(NotifSound s) =>
      s == NotifSound.silent ? 'silent' : 'default';

  String _formatMoney(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}tr';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return '${n.round()}đ';
  }

  NotificationDetails _buildDetails(NotifSound sound, bool vibrate) {
    final vibPattern =
        vibrate ? Int64List.fromList([0, 300, 200, 300]) : null;

    final AndroidNotificationDetails android;
    if (sound == NotifSound.silent) {
      android = AndroidNotificationDetails(
        vibrate ? _chSilentVib : _chSilentNoVib,
        _channelName,
        channelDescription: 'Nhắc nhở kinh doanh & chăm khách',
        importance: Importance.high,
        priority: Priority.high,
        playSound: false,
        enableVibration: vibrate,
        vibrationPattern: vibPattern,
        icon: '@mipmap/ic_launcher',
      );
    } else {
      android = AndroidNotificationDetails(
        vibrate ? _chDefaultVib : _chDefaultNoVib,
        _channelName,
        channelDescription: 'Nhắc nhở kinh doanh & chăm khách',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: vibrate,
        vibrationPattern: vibPattern,
        icon: '@mipmap/ic_launcher',
      );
    }

    return NotificationDetails(
      android: android,
      iOS: DarwinNotificationDetails(
        presentSound: sound != NotifSound.silent,
        presentBadge: true,
        presentAlert: true,
      ),
    );
  }

  Future<void> _scheduleRepeating({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required NotifSound sound,
    required bool vibrate,
    required DateTimeComponents match,
    int? weekday,
    int? dayOfMonth,
  }) async {
    await init();
    await _plugin.cancel(id);

    final scheduled = _nextFireTime(
      hour: hour,
      minute: minute,
      weekday: weekday,
      dayOfMonth: dayOfMonth,
    );
    final details = _buildDetails(sound, vibrate);

    Future<void> scheduleWith(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduled,
          details,
          androidScheduleMode: mode,
          matchDateTimeComponents: match,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

    try {
      await scheduleWith(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      try {
        await scheduleWith(AndroidScheduleMode.inexactAllowWhileIdle);
      } catch (_) {
        // Lịch nền thất bại — catchUpMissedReminders sẽ gửi khi mở app
      }
    }
  }

  tz.TZDateTime _nextFireTime({
    required int hour,
    required int minute,
    int? weekday,
    int? dayOfMonth,
  }) {
    final now = tz.TZDateTime.now(tz.local);

    if (dayOfMonth != null) {
      var scheduled = tz.TZDateTime(
          tz.local, now.year, now.month, dayOfMonth, hour, minute);
      if (scheduled.isBefore(now)) {
        final nextMonth = now.month == 12 ? 1 : now.month + 1;
        final year = now.month == 12 ? now.year + 1 : now.year;
        scheduled =
            tz.TZDateTime(tz.local, year, nextMonth, dayOfMonth, hour, minute);
      }
      return scheduled;
    }

    if (weekday != null) {
      var scheduled = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, hour, minute);
      var daysUntil = (weekday - scheduled.weekday) % 7;
      if (daysUntil == 0 && scheduled.isBefore(now)) daysUntil = 7;
      scheduled = scheduled.add(Duration(days: daysUntil));
      return tz.TZDateTime(tz.local, scheduled.year, scheduled.month,
          scheduled.day, hour, minute);
    }

    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<bool> _isViLocale() async {
    final saved = await _db.getSetting(AppConstants.keyLocale);
    return saved != 'en';
  }
}
