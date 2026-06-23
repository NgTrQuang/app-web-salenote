import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../database/database_helper.dart';
import '../utils/constants.dart';

/// Sound options for notifications.
enum NotifSound { defaultSound, silent }

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int _dailyNotificationId = 1;
  static const String _channelName = 'Nhắc nhở hàng ngày';
  // Separate channel per (sound × vibrate) combo — Android channel settings
  // are immutable after first creation, so each combo needs its own channel ID.
  static const String _chDefaultVib   = 'so_khach_default_vib';
  static const String _chDefaultNoVib = 'so_khach_default_novib';
  static const String _chSilentVib    = 'so_khach_silent_vib';
  static const String _chSilentNoVib  = 'so_khach_silent_novib';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Init ────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
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

  // ── Permission ──────────────────────────────────────────────

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true, badge: true, sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  // ── Settings getters/setters ────────────────────────────────

  Future<bool> isEnabled() async {
    final val = await DatabaseHelper().getSetting(AppConstants.keyNotificationEnabled);
    return val == 'true';
  }

  Future<int> getHour() async {
    final val = await DatabaseHelper().getSetting(AppConstants.keyNotificationHour);
    return int.tryParse(val ?? '') ?? AppConstants.defaultNotifHour;
  }

  Future<int> getMinute() async {
    final val = await DatabaseHelper().getSetting(AppConstants.keyNotificationMinute);
    return int.tryParse(val ?? '') ?? AppConstants.defaultNotifMinute;
  }

  Future<NotifSound> getSound() async {
    final val = await DatabaseHelper().getSetting(AppConstants.keyNotificationSound);
    switch (val) {
      case 'silent': return NotifSound.silent;
      default: return NotifSound.defaultSound;
    }
  }

  Future<bool> getVibrate() async {
    final val = await DatabaseHelper().getSetting(AppConstants.keyNotificationVibrate);
    return val != 'false'; // default true
  }

  Future<void> setEnabled(bool enabled) async {
    await DatabaseHelper().setSetting(AppConstants.keyNotificationEnabled, enabled.toString());
    if (enabled) {
      await scheduleSmartReminder();
    } else {
      await cancelDailyReminder();
    }
  }

  Future<void> saveSettings({
    required int hour,
    required int minute,
    required NotifSound sound,
    required bool vibrate,
  }) async {
    final db = DatabaseHelper();
    await db.setSetting(AppConstants.keyNotificationHour, hour.toString());
    await db.setSetting(AppConstants.keyNotificationMinute, minute.toString());
    await db.setSetting(AppConstants.keyNotificationSound, _soundKey(sound));
    await db.setSetting(AppConstants.keyNotificationVibrate, vibrate.toString());
    // Re-schedule with new settings if enabled
    if (await isEnabled()) await scheduleSmartReminder();
  }

  // ── Smart reminder ──────────────────────────────────────────

  /// Schedule daily reminder. Skips silently if app is currently in foreground
  /// (user is actively using the app — no need to interrupt them).
  Future<void> scheduleSmartReminder() async {
    await init();
    if (!await isEnabled()) return;

    final db = DatabaseHelper();
    final allOverdue = await db.getCustomersNeedingAttention();
    if (allOverdue.isEmpty) {
      await cancelDailyReminder();
      return;
    }

    final hotCount  = allOverdue.where((c) => c['status'] == 'hot').length;
    final warmCount = allOverdue.where((c) => c['status'] == 'warm').length;
    final newCount  = allOverdue.where((c) => c['status'] == 'new').length;
    final total     = allOverdue.length;
    final isVi      = await _isViLocale();

    String title, body;
    if (hotCount > 0) {
      title = isVi ? '🔥 Sổ Khách — Khách NÓNG chờ bạn!' : '🔥 Customer Notebook — Hot leads waiting!';
      body  = isVi
          ? 'Có $hotCount khách Nóng${warmCount > 0 ? ' + $warmCount Tiềm năng' : ''} cần liên hệ ngay!'
          : '$hotCount Hot${warmCount > 0 ? ' + $warmCount Warm' : ''} customers need attention now!';
    } else if (warmCount > 0) {
      title = isVi ? 'Sổ Khách — Đừng quên khách hôm nay!' : 'Customer Notebook — Don\'t forget today!';
      body  = isVi
          ? '$warmCount khách Tiềm năng${newCount > 0 ? ' + $newCount khách Mới' : ''} đang chờ bạn liên hệ'
          : '$warmCount Warm${newCount > 0 ? ' + $newCount New' : ''} customers waiting for follow-up';
    } else {
      title = isVi ? 'Sổ Khách' : 'Customer Notebook';
      body  = isVi
          ? 'Bạn có $total khách cần liên hệ hôm nay'
          : 'You have $total customers to follow up today';
    }

    final hour    = await getHour();
    final minute  = await getMinute();
    final sound   = await getSound();
    final vibrate = await getVibrate();

    await _scheduleAt(
      hour: hour, minute: minute,
      title: title, body: body,
      sound: sound, vibrate: vibrate,
    );
  }

  /// Call this when the app comes to foreground AFTER the scheduled time
  /// has already fired — we cancel the pending one and re-schedule for
  /// tomorrow so the user doesn't get stale notifications.
  Future<void> onAppResumed() async {
    if (!await isEnabled()) return;
    await scheduleSmartReminder();
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyNotificationId);
  }

  /// Gửi thông báo thử ngay lập tức với âm thanh và rung đã cài đặt.
  Future<void> sendTestNotification() async {
    await init();
    final sound   = await getSound();
    final vibrate = await getVibrate();
    final isVi    = await _isViLocale();

    await _plugin.show(
      99,
      isVi ? '🔔 Sổ Khách — Thông báo thử' : '🔔 Customer Notebook — Test',
      isVi
          ? 'Thông báo nhắc nhở của bạn đã được cài đặt thành công!'
          : 'Your reminder notification is set up and working!',
      _buildDetails(sound, vibrate),
    );
  }

  // ── Internal helpers ────────────────────────────────────────

  String _soundKey(NotifSound s) {
    switch (s) {
      case NotifSound.silent: return 'silent';
      default: return 'default';
    }
  }

  /// Builds [NotificationDetails] from sound + vibrate settings.
  ///
  /// Rules:
  /// - **default** : system notification sound, Importance.high, rung nếu bật
  /// - **silent**  : không âm, rung theo toggle (tắt rung = chỉ hiện thông báo)
  NotificationDetails _buildDetails(NotifSound sound, bool vibrate) {
    final bool doVibrate = vibrate;
    final vibPattern = doVibrate ? Int64List.fromList([0, 300, 200, 300]) : null;

    final AndroidNotificationDetails android;
    switch (sound) {
      case NotifSound.silent:
        android = AndroidNotificationDetails(
          doVibrate ? _chSilentVib : _chSilentNoVib,
          _channelName,
          channelDescription: 'Nhắc nhở liên hệ khách hàng',
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: doVibrate,
          vibrationPattern: vibPattern,
          icon: '@mipmap/ic_launcher',
        );
        break;
      default: // defaultSound
        android = AndroidNotificationDetails(
          doVibrate ? _chDefaultVib : _chDefaultNoVib,
          _channelName,
          channelDescription: 'Nhắc nhở liên hệ khách hàng',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: doVibrate,
          vibrationPattern: vibPattern,
          icon: '@mipmap/ic_launcher',
        );
    }

    final ios = DarwinNotificationDetails(
      presentSound: sound != NotifSound.silent,
      presentBadge: true,
      presentAlert: true,
    );

    return NotificationDetails(android: android, iOS: ios);
  }

  Future<void> _scheduleAt({
    required int hour,
    required int minute,
    required String title,
    required String body,
    required NotifSound sound,
    required bool vibrate,
  }) async {
    await init();

    final details = _buildDetails(sound, vibrate);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyNotificationId,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<bool> _isViLocale() async {
    final saved = await DatabaseHelper().getSetting(AppConstants.keyLocale);
    return saved != 'en';
  }
}
