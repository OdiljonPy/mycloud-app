import 'package:flutter/material.dart';

// Keys are weak: completed pages do not stay alive because of this guard.
final _openingRoutes = Expando<bool>('opening route');

bool isCurrentPage(BuildContext context) =>
    context.mounted && (ModalRoute.of(context)?.isCurrent ?? true);

/// Keeps repeated taps from opening two children of the same page, including
/// while the first action is still loading data before showing its route.
Future<T?> runNavigationOnce<T>(
  BuildContext context,
  Future<T?> Function() open,
) async {
  if (!isCurrentPage(context)) return null;
  final owner = ModalRoute.of(context);
  if (owner != null && _openingRoutes[owner] == true) return null;
  if (owner != null) _openingRoutes[owner] = true;
  try {
    return await open();
  } finally {
    if (owner != null) _openingRoutes[owner] = false;
  }
}

Future<T?> pushPageOnce<T>(BuildContext context, Route<T> route) =>
    runNavigationOnce(context, () async {
      final result = await Navigator.of(context).push(route);
      if (route is TransitionRoute<T>) await route.completed;
      return result;
    });

/// Finishes the page that owns the result. A page that is already popping
/// must never pop the route below it; a covered page must not pop its cover.
void popOwnedPage<T>(BuildContext context, [T? result]) {
  if (!context.mounted) return;
  final owner = ModalRoute.of(context);
  if (owner == null || !owner.isActive) return;
  final navigator = Navigator.of(context);
  if (owner.isCurrent) {
    navigator.pop(result);
  } else {
    navigator.removeRoute(owner, result);
  }
}
