import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

import 'support/frost_test_app.dart';

class _Counter extends StatefulWidget {
  const _Counter({super.key});

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  @override
  Widget build(BuildContext context) => const Text('Detail');
}

/// Sends what the Android embedding sends during a back swipe from the left
/// edge; only start and update carry an event.
Future<void> _backGesture(WidgetTester tester, String method, {double? progress}) async {
  final event = progress == null
      ? null
      : {
          'touchOffset': [5.0, 300.0],
          'progress': progress,
          'swipeEdge': 0,
        };
  final message = const StandardMethodCodec().encodeMethodCall(MethodCall(method, event));
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage('flutter/backgesture', message, (_) {});
}

Future<GlobalKey<NavigatorState>> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final navigator = GlobalKey<NavigatorState>();
  // The app's pages: a root page with a detail page pushed above it.
  final router = GoRouter(
    navigatorKey: navigator,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Text('Home'),
        routes: [GoRoute(path: 'detail', pageBuilder: (_, state) => FrostDetailPage<void>(key: state.pageKey, child: const _Counter(key: ValueKey('detail'))))],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(child: frostTestRouterApp(router, brightness: Brightness.dark)));
  await tester.pumpAndSettle();
  unawaited(router.push('/detail'));
  await tester.pumpAndSettle();
  return navigator;
}

void main() {
  testWidgets('a committed back swipe pops the page', variant: TargetPlatformVariant.only(TargetPlatform.android), (tester) async {
    final navigator = await _pumpApp(tester, const Size(400, 800));

    await _backGesture(tester, 'startBackGesture', progress: 0);
    await _backGesture(tester, 'updateBackGestureProgress', progress: .4);
    await tester.pump();
    await _backGesture(tester, 'commitBackGesture');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('detail')), findsNothing);
    expect(navigator.currentState!.canPop(), isFalse);
  });
}
