import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Đồng bộ inset hệ thống cho Android edge-to-edge (15+).
///
/// Trên Android < 15, [MediaQuery.viewPadding] thường bằng 0 → layout giữ nguyên.
/// Trên Android 15+, đảm bảo [MediaQuery.padding] phản ánh status/nav bar để tránh tràn.
class SystemInsetsScope extends StatelessWidget {
  const SystemInsetsScope({super.key, required this.child});

  final Widget child;

  static bool get enabled => !kIsWeb && Platform.isAndroid;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final mq = MediaQuery.of(context);
    final view = mq.viewPadding;
    if (view == EdgeInsets.zero) return child;

    return MediaQuery(
      data: mq.copyWith(
        padding: EdgeInsets.only(
          top: view.top,
          bottom: view.bottom,
          left: view.left,
          right: view.right,
        ),
      ),
      child: child,
    );
  }
}
