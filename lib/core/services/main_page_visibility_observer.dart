import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'navigation_service.dart';

/// Whether MainPage is currently the topmost route in the navigator stack
/// (i.e. not covered by a page pushed on top of it, e.g. UploadPage).
final isMainPageTopmostProvider = StateProvider<bool>((ref) => true);

/// Whether UploadPage (`RouteSettings(name: 'upload')`) is currently the
/// topmost route in the navigator stack.
final isUploadPageTopmostProvider = StateProvider<bool>((ref) => false);

/// Tracks the navigator's route stack to determine whether MainPage
/// (identified by `RouteSettings(name: 'main')`) is the topmost route, and
/// mirrors that into [isMainPageTopmostProvider].
class MainPageVisibilityObserver extends NavigatorObserver {
  final List<Route<dynamic>> _stack = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _update();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _update();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _update();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _stack.remove(oldRoute);
    if (newRoute != null) _stack.add(newRoute);
    _update();
  }

  void _update() {
    final topName = _stack.isNotEmpty ? _stack.last.settings.name : null;
    final isTopmostMain = topName == 'main';
    final isTopmostUpload = topName == 'upload';
    // didPush/didPop/didRemove/didReplace can fire mid-build; defer the
    // provider write a tick so it never lands synchronously inside build.
    Future.microtask(() {
      final context = NavigationService.navigatorKey.currentContext;
      if (context == null) return;
      // Fetched fresh above, not a stale reference carried across the
      // microtask gap — safe despite the lint's generic async-gap heuristic.
      // ignore: use_build_context_synchronously
      final container = ProviderScope.containerOf(context, listen: false);
      container.read(isMainPageTopmostProvider.notifier).state =
          isTopmostMain;
      container.read(isUploadPageTopmostProvider.notifier).state =
          isTopmostUpload;
    });
  }
}
