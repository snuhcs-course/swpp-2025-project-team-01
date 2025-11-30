import 'package:flutter/material.dart';
import 'package:re_view/core/lecture_loading_service.dart';

/// LectureLoadingService에 라우트 변경을 알리는 NavigatorObserver
class LectureLoadingNavigatorObserver extends NavigatorObserver {
  LectureLoadingNavigatorObserver(this.service);

  final LectureLoadingService service;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _notifyRouteChange(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _notifyRouteChange(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _notifyRouteChange(newRoute);
    }
  }

  void _notifyRouteChange(Route<dynamic> route) {
    final routeName = route.settings.name;
    service.onRouteChanged(routeName);
  }
}
