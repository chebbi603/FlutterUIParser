import 'package:flutter/cupertino.dart';

class NavigationBridge {
  static CupertinoTabController? tabController;
  static Map<String, int> routeToIndex = {};

  static bool switchTo(String route) {
    final idx = routeToIndex[route];
    if (idx != null && tabController != null) {
      tabController!.index = idx;
      return true;
    }
    return false;
  }
}
