import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart' show FrostAmbientBackdrop;

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
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        navigatorKey: navigator,
        theme: AppTheme.dark(platform: TargetPlatform.android, locale: const Locale('en')),
        home: const Scaffold(body: Text('Home')),
      ),
    ),
  );
  navigator.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: _Counter(key: ValueKey('detail'))),
    ),
  );
  await tester.pumpAndSettle();
  return navigator;
}

Matrix4 _pageTransform(WidgetTester tester) =>
    tester.widget<Transform>(find.ancestor(of: find.byKey(const ValueKey('detail')), matching: find.byType(Transform)).first).transform;

void main() {
  testWidgets('a back swipe shrinks the page with the finger and cancelling restores it, keeping its state', (tester) async {
    await _pumpApp(tester, const Size(400, 800));
    final state = tester.state(find.byKey(const ValueKey('detail')));

    await _backGesture(tester, 'startBackGesture', progress: 0);
    await _backGesture(tester, 'updateBackGestureProgress', progress: .5);
    await tester.pump();
    final swiped = _pageTransform(tester);
    expect(swiped.entry(0, 0), closeTo(.95, .001));
    expect(swiped.getTranslation().x, greaterThan(0), reason: 'a swipe from the left edge shifts the page right');
    expect(find.text('Home'), findsOneWidget, reason: 'the page below shows through');

    await _backGesture(tester, 'cancelBackGesture');
    await tester.pumpAndSettle();
    expect(_pageTransform(tester).entry(0, 0), 1);
    expect(tester.state(find.byKey(const ValueKey('detail'))), same(state));
  });

  testWidgets('a back swipe shrinks the backdrop copy with the page, so it still fills it', (tester) async {
    await _pumpApp(tester, const Size(400, 800));
    await _backGesture(tester, 'startBackGesture', progress: 0);
    await _backGesture(tester, 'updateBackGestureProgress', progress: .5);
    await tester.pump();
    expect(_pageTransform(tester).entry(0, 0), closeTo(.95, .001));
    // The backdrop copy moves and scales with the page, edge to edge.
    expect(tester.getRect(find.byType(FrostAmbientBackdrop)), tester.getRect(find.byType(Scaffold).last));
    await _backGesture(tester, 'cancelBackGesture');
    await tester.pumpAndSettle();
  });

  testWidgets('a committed back swipe pops the page', (tester) async {
    final navigator = await _pumpApp(tester, const Size(400, 800));

    await _backGesture(tester, 'startBackGesture', progress: 0);
    await _backGesture(tester, 'updateBackGestureProgress', progress: .4);
    await tester.pump();
    await _backGesture(tester, 'commitBackGesture');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('detail')), findsNothing);
    expect(navigator.currentState!.canPop(), isFalse);
  });

  testWidgets('beside the sidebar a pushed page grows in from 0.98 without travelling', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.reset);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          navigatorKey: navigator,
          theme: AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en')),
          home: const Scaffold(body: Text('Home')),
        ),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: _Counter(key: ValueKey('detail'))),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final entering = _pageTransform(tester);
    expect(entering.entry(0, 0), inExclusiveRange(.98, 1));
    expect(entering.getTranslation().y, closeTo(0, 3), reason: 'no vertical travel beside the sidebar');
    await tester.pumpAndSettle();
    expect(_pageTransform(tester).entry(0, 0), 1);
  });
}
