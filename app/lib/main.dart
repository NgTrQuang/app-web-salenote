import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'database/database_helper.dart';
import 'l10n/app_localizations.dart';
import 'services/app_lifecycle_service.dart';
import 'services/backup_service.dart';
import 'services/notification_service.dart';
import 'services/pin_service.dart';
import 'screens/splash_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';
import 'widgets/system_insets_scope.dart';

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
final localeModeNotifier = ValueNotifier<Locale>(const Locale('vi'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved theme & locale
  final db = DatabaseHelper();
  final savedTheme = await db.getSetting(AppConstants.keyThemeMode);
  final savedLocale = await db.getSetting(AppConstants.keyLocale);

  if (savedTheme == 'dark') {
    themeModeNotifier.value = ThemeMode.dark;
  } else if (savedTheme == 'light') {
    themeModeNotifier.value = ThemeMode.light;
  } else {
    themeModeNotifier.value = ThemeMode.system;
  }

  if (savedLocale == 'en') {
    localeModeNotifier.value = const Locale('en');
  } else {
    localeModeNotifier.value = const Locale('vi');
  }

  // Configure system UI — transparent status + nav bar, edge-to-edge safe
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  // Keep system UI visible (status bar + nav bar) — do NOT use EdgeToEdge mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Init lifecycle tracker
  AppLifecycleService.instance.init();

  runApp(const SoKhachApp());

  // Khởi tạo nền sau khi UI lên — tránh crash trước runApp chặn mở app
  _initBackgroundServices();
}

Future<void> _initBackgroundServices() async {
  try {
    await NotificationService().init();
    final notif = NotificationService();
    final anyNotifEnabled = await notif.isEnabled() ||
        await notif.isWeeklyEnabled() ||
        await notif.isMonthlyEnabled() ||
        await notif.isLoyaltyEnabled();
    if (anyNotifEnabled) {
      await notif.rescheduleAllReminders();
      await notif.catchUpMissedReminders();
    }
  } catch (_) {
    // Thông báo lỗi không được chặn mở app
  }
  try {
    BackupService().autoBackupIfNeeded();
  } catch (_) {}
}

class SoKhachApp extends StatelessWidget {
  const SoKhachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, __) => ValueListenableBuilder<Locale>(
        valueListenable: localeModeNotifier,
        builder: (_, locale, __) => MaterialApp(
          title: 'Salenote',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: mode,
          locale: locale,
          supportedLocales: const [Locale('vi'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => SystemInsetsScope(
            child: child ?? const SizedBox.shrink(),
          ),
          home: const SplashGate(),
        ),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF1A73E8), // Google-blue — vibrant, modern
      brightness: brightness,
    );
    final cs = base.colorScheme;
    final bgColor = isDark ? cs.surface : const Color(0xFFF4F6FB);
    final surfaceColor = isDark ? cs.surfaceVariant : Colors.white;

    return base.copyWith(
      scaffoldBackgroundColor: bgColor,
      // ── AppBar ─────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          letterSpacing: -0.3,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness:
              isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      // ── Card ───────────────────────────────────────────────
      cardTheme: CardTheme(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surfaceColor,
        shadowColor: Colors.black.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark
              ? BorderSide.none
              : BorderSide(
                  color: const Color(0xFFE8EBF0),
                  width: 0.8,
                ),
        ),
      ),
      // ── Input ──────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? cs.outlineVariant : const Color(0xFFDDE1EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
          fontSize: 14,
        ),
      ),
      // ── FAB ────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        extendedPadding: EdgeInsets.symmetric(horizontal: 20),
      ),
      // ── SnackBar ───────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF2D2D3A)
            : const Color(0xFF1A1A2E),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      // ── Dialog ─────────────────────────────────────────────
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        elevation: 8,
        shadowColor: Colors.black.withAlpha(40),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      // ── ListTile ───────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      // ── Divider ────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withAlpha(15)
            : const Color(0xFFEEF0F5),
        thickness: 0.8,
        space: 0,
      ),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
