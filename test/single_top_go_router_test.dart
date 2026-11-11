import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/single_top_go_router.dart';
import 'package:go_router/go_router.dart';

import 'support/frost_test_app.dart';

void main() {
  testWidgets('pushing the page on top again does nothing; another page still pushes', (tester) async {
    final router = SingleTopGoRouter(
      initialLocation: '/',
      config: RoutingConfig(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('Home')),
          GoRoute(path: '/work/:id', name: 'work', builder: (_, state) => Text('Work ${state.pathParameters['id']}')),
        ],
      ),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(frostTestRouterApp(router));

    unawaited(router.pushNamed('work', pathParameters: {'id': '7'}));
    await tester.pumpAndSettle();
    unawaited(router.pushNamed('work', pathParameters: {'id': '7'}));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.matches, hasLength(2), reason: 'home and one work page');

    unawaited(router.pushNamed('work', pathParameters: {'id': '8'}));
    await tester.pumpAndSettle();
    expect(find.text('Work 8'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.matches, hasLength(3));
  });
}
