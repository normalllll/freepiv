import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';

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

void main() {
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
}
