import 'dart:async';

import 'package:cloud_app/core/utils/navigation_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Repeated navigation keeps one route until it closes',
      (tester) async {
    late BuildContext owner;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      owner = context;
      return const Scaffold(body: Text('root'));
    })));
    Route<String> child() => MaterialPageRoute<String>(
        builder: (_) => const Scaffold(body: Text('child')));
    final first = pushPageOnce(owner, child());
    expect(await pushPageOnce(owner, child()), isNull);
    await tester.pumpAndSettle();
    expect(find.text('child'), findsOneWidget);
    Navigator.of(tester.element(find.text('child'))).pop('done');
    await tester.pumpAndSettle();
    expect(await first, 'done');
    final next = pushPageOnce(owner, child());
    await tester.pumpAndSettle();
    expect(find.text('child'), findsOneWidget);
    Navigator.of(tester.element(find.text('child'))).pop();
    await tester.pumpAndSettle();
    await next;
  });

  testWidgets('Guard includes preparation before opening a route',
      (tester) async {
    late BuildContext owner;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      owner = context;
      return const Scaffold();
    })));
    final preparation = Completer<void>();
    var calls = 0;
    Future<void> open() async {
      calls++;
      await preparation.future;
    }

    final first = runNavigationOnce<void>(owner, open);
    await runNavigationOnce<void>(owner, open);
    expect(calls, 1);
    preparation.complete();
    await first;
    await runNavigationOnce<void>(owner, open);
    expect(calls, 2);
  });

  testWidgets('Late completion removes its owner and preserves covering page',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    late BuildContext owner;
    await tester.pumpWidget(MaterialApp(
        navigatorKey: navigator, home: const Scaffold(body: Text('root'))));
    final result = navigator.currentState!
        .push<bool>(MaterialPageRoute(builder: (context) {
      owner = context;
      return const Scaffold(body: Text('owner'));
    }));
    await tester.pumpAndSettle();
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('cover'))));
    await tester.pumpAndSettle();
    popOwnedPage(owner, true);
    await tester.pumpAndSettle();
    expect(await result, isTrue);
    expect(find.text('cover'), findsOneWidget);
    popOwnedPage(owner, true);
    await tester.pumpAndSettle();
    expect(find.text('cover'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('root'), findsOneWidget);
  });
}
