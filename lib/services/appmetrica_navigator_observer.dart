import 'package:flutter/material.dart';
import 'package:my_diet/services/appmetrica_service.dart';

/// Отслеживание переходов по именованным маршрутам.
class AppMetricaNavigatorObserver extends NavigatorObserver {
  static final instance = AppMetricaNavigatorObserver._();

  AppMetricaNavigatorObserver._();

  void _track(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || name.isEmpty) return;
    AppMetricaService.reportScreenView(name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _track(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(previousRoute);
  }
}
