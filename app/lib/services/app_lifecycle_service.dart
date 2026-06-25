import 'package:flutter/material.dart';
import 'notification_service.dart';

/// Singleton that tracks whether the app is currently in the foreground.
/// Widgets should call [AppLifecycleService.instance.attach()] from
/// their [initState] and [detach()] from [dispose], or simply use a
/// [WidgetsBindingObserver] that delegates to this service.
class AppLifecycleService with WidgetsBindingObserver {
  AppLifecycleService._();
  static final AppLifecycleService instance = AppLifecycleService._();

  bool _isInForeground = true;
  bool get isInForeground => _isInForeground;

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isInForeground = true;
        NotificationService().onAppResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _isInForeground = false;
        break;
    }
  }
}
