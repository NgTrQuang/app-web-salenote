import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show themeModeNotifier, localeModeNotifier;
import '../database/database_helper.dart';
import '../services/backup_service.dart';
import '../services/customer_service.dart';
import '../services/notification_service.dart';
import '../services/pin_service.dart';
import '../utils/constants.dart';
import 'guide_screen.dart';
import 'pin_screen.dart';
import 'splash_screen.dart' show OnboardingScreen;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _backup = BackupService();
  final _customerService = CustomerService();
  final _notifService = NotificationService();
  final _pinService = PinService();
  bool _exportLoading = false;
  bool _csvLoading = false;
  bool _importLoading = false;
  String? _lastBackupDate;
  String _messageTemplate = AppConstants.defaultMessage;
  bool _templateLoaded = false;
  bool _notificationEnabled = false;
  bool _notifLoaded = false;
  int _notifHour = 9;
  int _notifMinute = 0;
  NotifSound _notifSound = NotifSound.defaultSound;
  bool _notifVibrate = true;
  bool _pinEnabled = false;
  bool _pinLoaded = false;
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('vi');

  @override
  void initState() {
    super.initState();
    _loadTemplate();
    _loadNotifState();
    _loadPinState();
    _loadNotifSettings();
    _loadLastBackup();
    _themeMode = themeModeNotifier.value;
    _locale = localeModeNotifier.value;
  }

  Future<void> _loadLastBackup() async {
    final d = await _backup.getLastBackupDate();
    if (mounted) setState(() => _lastBackupDate = d);
  }

  Future<void> _setLocale(Locale locale) async {
    await DatabaseHelper().setSetting(AppConstants.keyLocale, locale.languageCode);
    localeModeNotifier.value = locale;
    if (mounted) setState(() => _locale = locale);
  }

  Future<void> _loadPinState() async {
    final has = await _pinService.hasPin();
    if (mounted) setState(() {
      _pinEnabled = has;
      _pinLoaded = true;
    });
  }

  Future<void> _togglePin(bool value) async {
    final l = AppLocalizations.of(context);
    if (value) {
      // Bật PIN: mở màn hình setup
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
            builder: (_) => const PinScreen(mode: PinMode.setup)),
      );
      if (!mounted) return;
      if (result == true) {
        // PIN đã được lưu trong PinScreen.confirm — cập nhật UI ngay
        setState(() => _pinEnabled = true);
        _showSnack(l.pinEnabled);
      } else {
        // User huỷ: đảm bảo Switch về đúng trạng thái DB
        await _loadPinState();
      }
    } else {
      // Tắt PIN: xoá ngay, không cần xác nhận lại
      await _pinService.removePin();
      if (!mounted) return;
      setState(() => _pinEnabled = false);
      _showSnack(l.pinDisabled);
    }
  }

  Future<void> _setTheme(ThemeMode mode) async {
    final key = mode == ThemeMode.dark
        ? 'dark'
        : mode == ThemeMode.light
            ? 'light'
            : 'system';
    await DatabaseHelper().setSetting(AppConstants.keyThemeMode, key);
    themeModeNotifier.value = mode;
    if (mounted) setState(() => _themeMode = mode);
  }

  Future<void> _loadTemplate() async {
    final t = await _customerService.getMessageTemplate();
    if (mounted) setState(() {
      _messageTemplate = t;
      _templateLoaded = true;
    });
  }

  Future<void> _loadNotifState() async {
    final enabled = await _notifService.isEnabled();
    if (mounted) setState(() {
      _notificationEnabled = enabled;
      _notifLoaded = true;
    });
  }

  Future<void> _loadNotifSettings() async {
    final h = await _notifService.getHour();
    final m = await _notifService.getMinute();
    final s = await _notifService.getSound();
    final v = await _notifService.getVibrate();
    if (mounted) setState(() {
      _notifHour = h;
      _notifMinute = m;
      _notifSound = s;
      _notifVibrate = v;
    });
  }

  Future<void> _pickNotifTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _notifHour, minute: _notifMinute),
      helpText: 'Chọn giờ nhắc',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _notifHour = picked.hour;
      _notifMinute = picked.minute;
    });
    await _notifService.saveSettings(
      hour: _notifHour, minute: _notifMinute,
      sound: _notifSound, vibrate: _notifVibrate,
    );
  }

  Future<void> _pickNotifSound() async {
    final options = [
      (NotifSound.defaultSound, 'Âm thanh mặc định', Icons.notifications_rounded),
      (NotifSound.silent, 'Im lặng (chỉ hiện thông báo)', Icons.volume_off_rounded),
    ];
    final picked = await showDialog<NotifSound>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Chọn âm thanh thông báo'),
        children: options.map((o) {
          final (sound, label, icon) = o;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, sound),
            child: Row(
              children: [
                Icon(icon, size: 20,
                    color: _notifSound == sound
                        ? Theme.of(ctx).colorScheme.primary
                        : Colors.grey.shade500),
                const SizedBox(width: 12),
                Text(label,
                    style: TextStyle(
                      fontWeight: _notifSound == sound
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: _notifSound == sound
                          ? Theme.of(ctx).colorScheme.primary
                          : null,
                    )),
                if (_notifSound == sound) ...[  
                  const Spacer(),
                  Icon(Icons.check_rounded, size: 18,
                      color: Theme.of(ctx).colorScheme.primary),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _notifSound = picked);
    await _notifService.saveSettings(
      hour: _notifHour, minute: _notifMinute,
      sound: _notifSound, vibrate: _notifVibrate,
    );
  }

  Future<void> _toggleVibrate(bool value) async {
    setState(() => _notifVibrate = value);
    await _notifService.saveSettings(
      hour: _notifHour, minute: _notifMinute,
      sound: _notifSound, vibrate: _notifVibrate,
    );
  }

  Future<void> _toggleNotification(bool value) async {
    final l = AppLocalizations.of(context);
    if (value) {
      final granted = await _notifService.requestPermission();
      if (!granted && mounted) {
        _showSnack(l.notifPermRequired, isError: true);
        return;
      }
    }
    await _notifService.setEnabled(value);
    if (mounted) setState(() => _notificationEnabled = value);
    _showSnack(value ? l.notifEnabled : l.notifDisabled);
  }

  Future<void> _editTemplate() async {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: _messageTemplate);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.messageTemplates),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.templateHint,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: InputDecoration(hintText: l.messageTemplates),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(l.save),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || !mounted) return;
    await _customerService.saveMessageTemplate(result);
    setState(() => _messageTemplate = result);
    _showSnack(l.templateSelected);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ));
  }

  Future<void> _export() async {
    final l = AppLocalizations.of(context);
    setState(() => _exportLoading = true);
    try {
      await _backup.shareBackup();
      await _loadLastBackup();
      _showSnack(l.exportSuccess);
    } catch (e) {
      _showSnack('Lỗi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exportLoading = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _csvLoading = true);
    try {
      await _backup.shareCsv();
      _showSnack('Đã xuất CSV thành công!');
    } catch (e) {
      _showSnack('Lỗi xuất CSV: $e', isError: true);
    } finally {
      if (mounted) setState(() => _csvLoading = false);
    }
  }

  Future<void> _import() async {
    final l = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.restoreTitle),
        content: Text(l.restoreContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.restore),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _importLoading = true);
    try {
      final ok = await _backup.importBackup();
      if (!mounted) return;
      if (ok) {
        _showSnack(l.importSuccess);
        Navigator.of(context).pop('restored');
      } else {
        _showSnack(l.importCancelled);
      }
    } on FormatException catch (e) {
      _showSnack('${l.invalidFile}: ${e.message}', isError: true);
    } catch (e) {
      _showSnack('Lỗi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _importLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final bg = theme.scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(l.settingsTitle,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: bg,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.of(context).padding.bottom),
        children: [
          // ── Backup Section ──────────────────────────────────
          _SectionLabel(l.backup),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Trạng thái backup ─────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: _lastBackupDate != null
                        ? Colors.green.shade600.withAlpha(18)
                        : Colors.orange.shade700.withAlpha(18),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: _lastBackupDate != null
                              ? Colors.green.shade600.withAlpha(35)
                              : Colors.orange.shade700.withAlpha(35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _lastBackupDate != null
                              ? Icons.shield_rounded
                              : Icons.warning_amber_rounded,
                          color: _lastBackupDate != null
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _lastBackupDate != null
                                  ? 'Dữ liệu đã an toàn'
                                  : 'Chưa sao lưu',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: _lastBackupDate != null
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _lastBackupDate != null
                                  ? 'Lần cuối: $_lastBackupDate'
                                  : 'Hãy sao lưu để không mất dữ liệu',
                              style: TextStyle(
                                fontSize: 12,
                                color: _lastBackupDate != null
                                    ? Colors.green.shade700.withAlpha(180)
                                    : Colors.orange.shade700.withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Sao lưu ngay ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _exportLoading || _importLoading || _csvLoading
                          ? null
                          : _export,
                      icon: _exportLoading
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cloud_upload_rounded, size: 18),
                      label: Text(
                        _exportLoading ? 'Đang lưu...' : 'Sao lưu ngay',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        backgroundColor: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),

                // ── Xuất CSV ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _exportLoading || _importLoading || _csvLoading
                          ? null
                          : _exportCsv,
                      icon: _csvLoading
                          ? SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.teal.shade700))
                          : Icon(Icons.table_chart_outlined,
                              size: 18, color: Colors.teal.shade700),
                      label: Text(
                        _csvLoading ? 'Đang xuất...' : 'Xuất CSV (Excel)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: Colors.teal.shade400),
                      ),
                    ),
                  ),
                ),

                // ── Divider ───────────────────────────────────
                const SizedBox(height: 14),
                Divider(
                    height: 1, indent: 16, endIndent: 16,
                    color: theme.colorScheme.outlineVariant.withAlpha(80)),

                // ── Khôi phục ─────────────────────────────────
                _ActionTile(
                  icon: Icons.restore_rounded,
                  iconBg: Colors.orange.shade700.withAlpha(30),
                  iconColor: Colors.orange.shade700,
                  title: l.importBackup,
                  subtitle: l.importBackupSub,
                  loading: _importLoading,
                  onTap: _exportLoading || _importLoading || _csvLoading
                      ? null
                      : _import,
                  isLast: true,
                ),
              ],
            ),
          ),

          // ── Notification Section ────────────────────────────
          const SizedBox(height: 28),
          _SectionLabel(l.notifications),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                // Row 1: Bật/tắt nhắc nhở
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade800.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.notifications_outlined,
                            color: Colors.amber.shade800, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.dailyReminder,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(l.dailyReminderSub,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      _notifLoaded
                          ? Switch(
                              value: _notificationEnabled,
                              onChanged: _toggleNotification,
                            )
                          : const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                    ],
                  ),
                ),

                // Sub-options: only show when enabled
                if (_notificationEnabled) ...[
                  Divider(height: 1, indent: 56, endIndent: 16,
                      color: theme.colorScheme.outlineVariant.withAlpha(80)),

                  // Row 2: Giờ nhắc
                  InkWell(
                    onTap: _pickNotifTime,
                    borderRadius: const BorderRadius.vertical(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.access_time_rounded,
                                color: Colors.blue.shade700, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Giờ nhắc',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                Text('Thông báo sẽ gửi lúc giờ này mỗi ngày',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_notifHour.toString().padLeft(2, '0')}:${_notifMinute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded,
                              color: Colors.grey.shade400, size: 20),
                        ],
                      ),
                    ),
                  ),

                  Divider(height: 1, indent: 56, endIndent: 16,
                      color: theme.colorScheme.outlineVariant.withAlpha(80)),

                  // Row 3: Âm thanh
                  InkWell(
                    onTap: _pickNotifSound,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.purple.shade700.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _notifSound == NotifSound.silent
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              color: Colors.purple.shade700, size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Âm thanh',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                Text(
                                  _notifSound == NotifSound.silent
                                      ? 'Im lặng (chỉ hiện thông báo)'
                                      : 'Âm thanh mặc định',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: Colors.grey.shade400, size: 20),
                        ],
                      ),
                    ),
                  ),

                  Divider(height: 1, indent: 56, endIndent: 16,
                      color: theme.colorScheme.outlineVariant.withAlpha(80)),

                  // Row 4: Rung
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.green.shade700.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.vibration_rounded,
                              color: Colors.green.shade700, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Rung',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              Text('Rung kèm theo âm thanh',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _notifVibrate,
                          onChanged: _toggleVibrate,
                        ),
                      ],
                    ),
                  ),

                  // Smart notice
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: theme.colorScheme.primary.withAlpha(30)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 13,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Thông minh: chỉ nhắc khi bạn chưa mở app & có khách cần liên hệ. '
                              'Khi mở app lại, lịch nhắc tự cập nhật theo dữ liệu mới nhất.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.primary,
                                  height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Nút gửi thử
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _notifService.sendTestNotification();
                          if (mounted) {
                            _showSnack('Đã gửi thông báo thử! Kiểm tra thanh thông báo.');
                          }
                        },
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Gửi thử thông báo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(
                              color: theme.colorScheme.primary.withAlpha(80)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Message Template Section ────────────────────────
          const SizedBox(height: 28),
          _SectionLabel(l.messageTemplates),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: _editTemplate,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.purple.shade700.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.message_outlined,
                          color: Colors.purple.shade700, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(l.messageTemplates,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                              ),
                              Icon(Icons.edit_outlined,
                                  size: 16, color: Colors.grey.shade400),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _templateLoaded
                                ? _messageTemplate
                                : AppConstants.defaultMessage,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l.templateHint,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.purple.shade400,
                                fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Appearance / Dark mode ──────────────────────────
          const SizedBox(height: 28),
          _SectionLabel(l.appearance),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _ThemeOptionTile(
                    icon: Icons.brightness_auto_rounded,
                    iconColor: Colors.blueGrey.shade600,
                    iconBg: Colors.blueGrey.shade600.withAlpha(30),
                    label: l.themeSystem,
                    selected: _themeMode == ThemeMode.system,
                    onTap: () => _setTheme(ThemeMode.system),
                  ),
                  Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 0,
                      color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80)),
                  _ThemeOptionTile(
                    icon: Icons.light_mode_rounded,
                    iconColor: Colors.amber.shade700,
                    iconBg: Colors.amber.shade700.withAlpha(30),
                    label: l.themeLight,
                    selected: _themeMode == ThemeMode.light,
                    onTap: () => _setTheme(ThemeMode.light),
                  ),
                  Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 0,
                      color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80)),
                  _ThemeOptionTile(
                    icon: Icons.dark_mode_rounded,
                    iconColor: Colors.indigo.shade400,
                    iconBg: Colors.indigo.shade400.withAlpha(30),
                    label: l.themeDark,
                    selected: _themeMode == ThemeMode.dark,
                    onTap: () => _setTheme(ThemeMode.dark),
                  ),
                ],
              ),
            ),
          ),

          // ── Language ─────────────────────────────────────────
          const SizedBox(height: 28),
          _SectionLabel(l.language),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _ThemeOptionTile(
                    icon: Icons.language_rounded,
                    iconColor: Colors.teal.shade600,
                    iconBg: Colors.teal.shade600.withAlpha(30),
                    label: l.langVi,
                    selected: _locale.languageCode == 'vi',
                    onTap: () => _setLocale(const Locale('vi')),
                  ),
                  Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 0,
                      color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80)),
                  _ThemeOptionTile(
                    icon: Icons.translate_rounded,
                    iconColor: Colors.blue.shade600,
                    iconBg: Colors.blue.shade600.withAlpha(30),
                    label: l.langEn,
                    selected: _locale.languageCode == 'en',
                    onTap: () => _setLocale(const Locale('en')),
                  ),
                ],
              ),
            ),
          ),

          // ── Security / PIN Lock ──────────────────────────────
          const SizedBox(height: 28),
          _SectionLabel(l.security),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.shade700.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.lock_outline_rounded,
                        color: Colors.red.shade700, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.pinLock,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          l.pinLockSub,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  _pinLoaded
                      ? Switch(
                          value: _pinEnabled,
                          onChanged: _togglePin,
                        )
                      : const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                ],
              ),
            ),
          ),
          if (_pinEnabled) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                        builder: (_) =>
                            const PinScreen(mode: PinMode.change)),
                  );
                  if (result == true && mounted) {
                    _showSnack(l.changePinSuccess);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        l.changePin,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // ── Template Library ─────────────────────────────────
          const SizedBox(height: 28),
          _SectionLabel(l.templateLibrary),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: List.generate(
                AppConstants.messageTemplates.length,
                (i) {
                  final t = AppConstants.messageTemplates[i];
                  final isLast = i == AppConstants.messageTemplates.length - 1;
                  final isSelected = _messageTemplate == t;
                  return Column(
                    children: [
                      InkWell(
                        onTap: () async {
                          await _customerService.saveMessageTemplate(t);
                          setState(() => _messageTemplate = t);
                          _showSnack(l.templateSelected);
                        },
                        borderRadius: BorderRadius.vertical(
                          top: i == 0
                              ? const Radius.circular(16)
                              : Radius.zero,
                          bottom: isLast
                              ? const Radius.circular(16)
                              : Radius.zero,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 20,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected
                                        ? theme.colorScheme.onSurface
                                        : Colors.grey.shade600,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast)
                        Divider(
                            height: 1,
                            indent: 48,
                            endIndent: 0,
                            color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80)),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    l.templateLibraryHint,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          // ── Guide ─────────────────────────────────────────────
          const SizedBox(height: 28),
          Card(
            margin: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GuideScreen()),
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.green.shade700.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.help_outline_rounded,
                              color: Colors.green.shade700, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(l.guide,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.grey.shade400, size: 22),
                      ],
                    ),
                  ),
                ),
                Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 0,
                    color: theme.colorScheme.outlineVariant.withAlpha(80)),
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const OnboardingScreen()),
                  ),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.play_lesson_outlined,
                              color: Colors.blue.shade600, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Xem lại hướng dẫn ban đầu',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('3 slides giới thiệu tính năng chính',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.grey.shade400, size: 22),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── About Section ───────────────────────────────────
          const SizedBox(height: 28),
          _SectionLabel(l.about),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.book_rounded,
                            color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.appName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 3),
                        Text(
                          '${l.version} 2.2.0',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.appTagline,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14)),
            ),
            if (selected)
              Icon(Icons.check_rounded,
                  color: theme.colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;

  const _ActionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(16) : Radius.zero,
      bottom: isLast ? const Radius.circular(16) : Radius.zero,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: loading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: iconColor),
                    )
                  : Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: onTap == null
                              ? Colors.grey.shade400
                              : null)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (!loading)
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
