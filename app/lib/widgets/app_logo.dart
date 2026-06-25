import 'package:flutter/material.dart';

/// Logo Salenote — dùng chung splash, drawer, header, hướng dẫn, cài đặt.
class AppLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final BoxFit fit;
  final Color? fallbackColor;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;

  const AppLogo({
    super.key,
    this.size = 40,
    this.borderRadius = 10,
    this.fit = BoxFit.contain,
    this.fallbackColor,
    this.padding,
    this.backgroundColor,
    this.boxShadow,
  });

  static const assetPath = 'assets/images/logo.png';

  /// Màu brand Salenote (đồng bộ web theme-color #0d9488).
  static const brandTeal = Color(0xFF0D9488);
  static const brandTealDark = Color(0xFF0F766E);
  static const brandTealDeeper = Color(0xFF115E59);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final pad = padding ?? EdgeInsets.zero;

    Widget image = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, __, ___) => _FallbackLogo(
        size: size,
        color: fallbackColor ?? Theme.of(context).colorScheme.primary,
      ),
    );

    if (padding != null || backgroundColor != null || boxShadow != null) {
      return Container(
        width: size + pad.horizontal,
        height: size + pad.vertical,
        padding: pad,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: radius,
          boxShadow: boxShadow,
        ),
        child: ClipRRect(borderRadius: radius, child: image),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(width: size, height: size, child: image),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  final double size;
  final Color color;

  const _FallbackLogo({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(Icons.menu_book_rounded, color: Colors.white, size: size * 0.55),
    );
  }
}
