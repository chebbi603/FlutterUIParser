import 'package:flutter/cupertino.dart';
import '../analytics/services/analytics_service.dart';

class NavigationBridge {
  static CupertinoTabController? tabController;
  static Map<String, int> routeToIndex = {};
  // Injected predicates to enforce auth based on contract and current session
  static bool Function(String route)? isRouteProtected;
  static bool Function()? isAuthed;

  static bool switchTo(String route) {
    final idx = routeToIndex[route];
    if (idx != null && tabController != null) {
      // Enforce auth for protected routes
      final protected = isRouteProtected != null ? isRouteProtected!(route) : false;
      final authed = isAuthed != null ? isAuthed!() : false;
      if (protected && !authed) {
        // Log redirect attempt and optionally switch to login tab if mapped
        AnalyticsService().logAuthEvent('login_page_viewed', {
          'source': 'redirect_from_protected',
          'attemptedRoute': route,
        });
        final loginIdx = routeToIndex['/login'];
        if (loginIdx != null) {
          tabController!.index = loginIdx;
        }
        return false;
      }
      tabController!.index = idx;
      return true;
    }
    return false;
  }
}
