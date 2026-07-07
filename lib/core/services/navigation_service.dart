import 'package:flutter/material.dart';

class NavigationService {
  NavigationService._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
}
