import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;

    final sections = [
      _GuideSection(
        icon: Icons.person_add_rounded,
        iconColor: const Color(0xFF1565C0),
        title: l.guide1Title,
        body: l.guide1Body,
      ),
      _GuideSection(
        icon: Icons.swipe_rounded,
        iconColor: const Color(0xFF2E7D32),
        title: l.guide2Title,
        body: l.guide2Body,
      ),
      _GuideSection(
        icon: Icons.label_important_rounded,
        iconColor: const Color(0xFFE65100),
        title: l.guide3Title,
        body: l.guide3Body,
      ),
      _GuideSection(
        icon: Icons.bar_chart_rounded,
        iconColor: const Color(0xFF6A1B9A),
        title: l.guide4Title,
        body: l.guide4Body,
      ),
      _GuideSection(
        icon: Icons.cloud_upload_rounded,
        iconColor: const Color(0xFF00695C),
        title: l.guide5Title,
        body: l.guide5Body,
      ),
      _GuideSection(
        icon: Icons.notifications_active_rounded,
        iconColor: const Color(0xFFF57F17),
        title: l.guide6Title,
        body: l.guide6Body,
      ),
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(l.guideTitle,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: bg,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 32 + MediaQuery.of(context).padding.bottom),
        children: [
          // Header card
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1565C0),
                  const Color(0xFF1976D2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withAlpha(60),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.book_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l.appTagline,
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Guide sections
          ...sections.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return _GuideTile(
              section: s,
              index: i + 1,
              isLast: i == sections.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

class _GuideSection {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _GuideSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });
}

class _GuideTile extends StatefulWidget {
  final _GuideSection section;
  final int index;
  final bool isLast;

  const _GuideTile({
    required this.section,
    required this.index,
    required this.isLast,
  });

  @override
  State<_GuideTile> createState() => _GuideTileState();
}

class _GuideTileState extends State<_GuideTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.section;

    return Padding(
      padding: EdgeInsets.only(bottom: widget.isLast ? 0 : 10),
      child: Card(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: s.iconColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(s.icon, color: s.iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _expanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            s.body,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface
                                  .withAlpha(180),
                              height: 1.6,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
