import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show localeModeNotifier;
import '../services/pin_service.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'pin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoCtrl,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    _logoCtrl.forward();

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _decideNext();
    });
  }

  Future<void> _decideNext() async {
    final db = DatabaseHelper();
    final onboardingDone =
        await db.getSetting(AppConstants.keyOnboardingDone);

    if (onboardingDone != 'true') {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
      return;
    }

    final hasPin = await PinService().hasPin();
    if (!mounted) return;
    if (hasPin) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const PinScreen(mode: PinMode.unlock),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1565C0),
                Color(0xFF0D47A1),
                Color(0xFF1A237E),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Subtle circle decoration top-right
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(15),
                  ),
                ),
              ),
              // Subtle circle decoration bottom-left
              Positioned(
                bottom: -60,
                left: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(10),
                  ),
                ),
              ),
              // Logo + App name
              Center(
                child: AnimatedBuilder(
                  animation: _logoCtrl,
                  builder: (_, __) => Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(50),
                                  blurRadius: 32,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: Colors.white.withAlpha(30),
                                  blurRadius: 8,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.book_rounded,
                                  color: Color(0xFF1565C0),
                                  size: 54,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Sổ Khách',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Công cụ hành động hàng ngày cho chủ shop',
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Loading indicator at bottom
              Positioned(
                bottom: 52,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _logoFade,
                  builder: (_, __) => Opacity(
                    opacity: _logoFade.value,
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Onboarding ────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentPage = 0;
  late AnimationController _btnCtrl;
  late Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _btnScale = Tween<double>(begin: 1.0, end: 0.95).animate(_btnCtrl);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await DatabaseHelper()
        .setSetting(AppConstants.keyOnboardingDone, 'true');
    if (!mounted) return;
    final hasPin = await PinService().hasPin();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            hasPin ? const PinScreen(mode: PinMode.unlock) : const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    final slides = [
      _OnboardSlide(
        icon: Icons.people_alt_rounded,
        iconColor: const Color(0xFF1565C0),
        title: l.onboard1Title,
        body: l.onboard1Body,
        accentColor: const Color(0xFF1565C0),
      ),
      _OnboardSlide(
        icon: Icons.notifications_active_rounded,
        iconColor: const Color(0xFFE65100),
        title: l.onboard2Title,
        body: l.onboard2Body,
        accentColor: const Color(0xFFE65100),
      ),
      _OnboardSlide(
        icon: Icons.bar_chart_rounded,
        iconColor: const Color(0xFF2E7D32),
        title: l.onboard3Title,
        body: l.onboard3Body,
        accentColor: const Color(0xFF2E7D32),
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              Theme.of(context).brightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      l.onboardSkip,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 14),
                    ),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: slides.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) => _OnboardPage(
                    slide: slides[i],
                    key: ValueKey(i),
                  ),
                ),
              ),

              // Dots + buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Row(
                  children: [
                    // Dots
                    Row(
                      children: List.generate(slides.length, (i) {
                        final active = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 6),
                          width: active ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? slides[_currentPage].accentColor
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    // Next / Start button
                    ScaleTransition(
                      scale: _btnScale,
                      child: GestureDetector(
                        onTapDown: (_) => _btnCtrl.forward(),
                        onTapUp: (_) {
                          _btnCtrl.reverse();
                          if (_currentPage < slides.length - 1) {
                            _pageCtrl.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _finish();
                          }
                        },
                        onTapCancel: () => _btnCtrl.reverse(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            color: slides[_currentPage].accentColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: slides[_currentPage]
                                    .accentColor
                                    .withAlpha(80),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            _currentPage < slides.length - 1
                                ? l.onboardNext
                                : l.onboardStart,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardSlide {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final Color accentColor;

  const _OnboardSlide({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.accentColor,
  });
}

class _OnboardPage extends StatefulWidget {
  final _OnboardSlide slide;
  const _OnboardPage({required this.slide, super.key});

  @override
  State<_OnboardPage> createState() => _OnboardPageState();
}

class _OnboardPageState extends State<_OnboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: widget.slide.iconColor.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.slide.icon,
                  size: 58,
                  color: widget.slide.iconColor,
                ),
              ),
              const SizedBox(height: 36),
              Text(
                widget.slide.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.slide.body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
